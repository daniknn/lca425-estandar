import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

AQUI = Path(__file__).resolve().parent
GATE = AQUI.parent
FIXTURES = AQUI / "fixtures"
sys.path.insert(0, str(GATE))

import validar

VALIDAR = GATE / "validar.py"
# Si el estándar vive junto a las plantillas (carpeta de trabajo local) se prueban también.
HERMANOS = GATE.parents[3]  # carpeta que contiene lca425-estandar, proyecto-plantilla y proyecto-ejemplo


def leer(nombre):
    return (FIXTURES / "pr" / nombre).read_text(encoding="utf-8")


class Base(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.repo = Path(self._tmp.name) / "repo"
        shutil.copytree(FIXTURES / "sano", self.repo)

    def superponer(self, nombre):
        """Copia encima del proyecto sano los archivos del fixture roto."""
        shutil.copytree(FIXTURES / nombre, self.repo, dirs_exist_ok=True)

    def escribir(self, rel, contenido, modo="w"):
        ruta = self.repo / rel
        ruta.parent.mkdir(parents=True, exist_ok=True)
        if "b" in modo:
            ruta.write_bytes(contenido)
        else:
            ruta.write_text(contenido, encoding="utf-8")

    def correr(self, pr_body=None, modo="alumno"):
        return validar.ejecutar(self.repo, modo, pr_body)

    def reglas(self, res):
        return [f["regla"] for f in res.fallas]

    def assertFalla(self, res, regla):
        self.assertIn(regla, self.reglas(res), "reglas encontradas: %s" % self.reglas(res))
        f = next(f for f in res.fallas if f["regla"] == regla)
        # formato de 4 partes
        self.assertTrue(f["que_paso"])
        self.assertIn("/lca425-estandar/blob/main/docs/", f["por_que"])
        self.assertGreaterEqual(len(f["opciones"]), 1)
        self.assertTrue(f["como_destrabar"])
        bloque = validar.formatear_falla(f)
        for parte in ("✋ Qué pasó:", "Por qué:", "Qué puedes hacer:", "Cómo destrabar:"):
            self.assertIn(parte, bloque)


class TestProyectoSano(Base):
    def test_sano_pasa(self):
        res = self.correr()
        self.assertEqual(res.fallas, [], [f["que_paso"] for f in res.fallas])
        self.assertEqual(res.areas["brief"], "funciona")
        self.assertEqual(res.areas["shotlist"], "funciona")
        self.assertEqual(res.areas["prompts"], "borrador")  # P02 aún no validado

    def test_pr_sano_pasa(self):
        res = self.correr(pr_body=leer("bueno.md"))
        self.assertEqual(res.fallas, [], [f["que_paso"] for f in res.fallas])


class TestBrief(Base):
    def test_placeholder(self):
        self.superponer("brief-placeholder")
        res = self.correr()
        self.assertFalla(res, "brief-incompleto")
        self.assertIn("titulo", res.fallas[0]["que_paso"])

    def test_placeholder_en_plantilla_es_aviso(self):
        self.superponer("brief-placeholder")
        res = self.correr(modo="plantilla")
        self.assertEqual(res.fallas, [])
        self.assertIn("brief-incompleto", [a["regla"] for a in res.avisos])

    def test_formato_invalido(self):
        self.superponer("formato-invalido")
        self.assertFalla(self.correr(), "brief-formato")

    def test_formato_invalido_falla_tambien_en_plantilla(self):
        self.superponer("formato-invalido")
        self.assertFalla(self.correr(modo="plantilla"), "brief-formato")

    def test_brief_sin_campos_de_personas_pasa(self):
        self.assertNotIn("personas_reales", (self.repo / "00_brief.md").read_text(encoding="utf-8"))
        self.assertEqual(self.correr().fallas, [])

    def test_campos_retirados_del_brief_se_ignoran(self):
        brief = self.repo / "00_brief.md"
        texto = brief.read_text(encoding="utf-8").replace(
            "drive:", "personas_reales: si\nissue_permiso: pendiente\ndrive:")
        brief.write_text(texto, encoding="utf-8")
        res = self.correr()
        self.assertEqual(res.fallas, [])
        self.assertEqual(res.avisos, [])

    def test_campos_retirados_con_valores_raros_se_ignoran(self):
        brief = self.repo / "00_brief.md"
        texto = brief.read_text(encoding="utf-8").replace(
            "drive:", "personas_reales: quizá\ndrive:")
        brief.write_text(texto, encoding="utf-8")
        self.assertEqual(self.correr().fallas, [])

    def test_presupuesto_no_entero(self):
        brief = self.repo / "00_brief.md"
        brief.write_text(brief.read_text(encoding="utf-8").replace(
            "presupuesto_creditos: 120", "presupuesto_creditos: mucho"), encoding="utf-8")
        self.assertFalla(self.correr(), "brief-presupuesto")

    def test_drive_invalido(self):
        brief = self.repo / "00_brief.md"
        brief.write_text(brief.read_text(encoding="utf-8").replace(
            "https://drive.google.com/drive/folders/fixture", "https://ejemplo.com/x"), encoding="utf-8")
        self.assertFalla(self.correr(), "brief-drive")

    def test_claude_md_distinto(self):
        self.escribir("CLAUDE.md", "otra cosa\n")
        self.assertFalla(self.correr(), "claude-md")

    def test_falta_agents(self):
        (self.repo / "AGENTS.md").unlink()
        self.assertFalla(self.correr(), "archivo-requerido")


class TestShotlistYPrompts(Base):
    def test_generado_sin_clip(self):
        self.superponer("shotlist-sin-clip")
        self.assertFalla(self.correr(), "shotlist-sin-clip")

    def test_prompt_validado_sin_leccion(self):
        self.superponer("prompt-sin-leccion")
        res = self.correr()
        self.assertFalla(res, "prompt-validado-incompleto")
        self.assertIn("leccion", res.fallas[0]["que_paso"])

    def test_prompt_id_inexistente(self):
        (self.repo / "04_prompts" / "P02-v1.yaml").unlink()
        self.assertFalla(self.correr(), "shotlist-prompt-inexistente")

    def test_persona_real_en_plano_se_ignora(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        texto = ruta.read_text(encoding="utf-8").replace(
            "estado: validado\n", "estado: validado\n    persona_real: si\n", 1)
        self.assertIn("persona_real: si", texto)
        ruta.write_text(texto, encoding="utf-8")
        res = self.correr()
        self.assertEqual(res.fallas, [])
        self.assertEqual(res.avisos, [])

    def test_id_repetido(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        ruta.write_text(ruta.read_text(encoding="utf-8").replace("id: P02", "id: P01"), encoding="utf-8")
        self.assertFalla(self.correr(), "shotlist-id-repetido")


class TestMedia(Base):
    def test_mp4(self):
        self.escribir("05_audio/clip.mp4", b"\x00\x00\x00\x18ftypmp42", "wb")
        self.assertFalla(self.correr(), "media-bloqueada")

    def test_archivo_2mb_no_imagen(self):
        self.escribir("02_guion/datos.txt", b"a" * (2 * 1024 * 1024), "wb")
        self.assertFalla(self.correr(), "archivo-pesado")

    def test_imagen_pesada_fuera_de_06_web(self):
        self.escribir("01_historia/foto.png", b"\x89PNG" + b"0" * (1100 * 1024), "wb")
        self.assertFalla(self.correr(), "imagen-fuera-de-06_web")

    def test_imagen_pesada_en_06_web(self):
        self.escribir("06_web/foto.png", b"\x89PNG" + b"0" * (1100 * 1024), "wb")
        self.assertFalla(self.correr(), "imagen-pesada")

    def test_imagen_chica_en_06_web_pasa(self):
        self.escribir("06_web/foto.png", b"\x89PNG" + b"0" * 1024, "wb")
        self.assertEqual(self.correr().fallas, [])

    def test_git_se_ignora(self):
        self.escribir(".git/objects/pack.mp4", b"x", "wb")
        self.assertEqual(self.correr().fallas, [])


class TestPalabras(Base):
    def test_palabra_prohibida(self):
        palabra = "net" + "pay"  # el texto en claro nunca vive en un fixture
        self.escribir("01_historia/notas.md", "Cliente de ejemplo: %s S.A.\n" % palabra.upper())
        res = self.correr()
        self.assertFalla(res, "palabra-prohibida")
        self.assertNotIn(palabra, json.dumps(validar.a_json(res)).lower())

    def test_palabra_dentro_de_texto_largo(self):
        palabra = "baB" + "ka"
        self.escribir("02_guion/g.md", "Escena 1.\nUna %s, dulce.\n" % palabra)
        self.assertFalla(self.correr(), "palabra-prohibida")

    def test_das(self):
        self.escribir("01_historia/notas.md", "Ver " + "DAS" + "-123 para el detalle.\n")
        self.assertFalla(self.correr(), "codigo-das")

    def test_palabra_parecida_no_falla(self):
        self.escribir("01_historia/notas.md", "El net es gratis y el pay-per-view también.\n")
        self.assertEqual(self.correr().fallas, [])

    def test_solo_palabras(self):
        self.escribir("01_historia/notas.md", "x " + "kon" + "fio" + "\n")
        res = validar.ejecutar(self.repo, solo_palabras=True)
        self.assertEqual(self.reglas(res), ["palabra-prohibida"])
        # sin brief ni nada más: solo-palabras no se queja de lo demás
        (self.repo / "00_brief.md").unlink()
        res = validar.ejecutar(self.repo, solo_palabras=True)
        self.assertEqual(self.reglas(res), ["palabra-prohibida"])


class TestPR(Base):
    def test_dos_niveles(self):
        res = self.correr(pr_body=leer("dos-niveles.md"))
        self.assertFalla(res, "pr-nivel")

    def test_ningun_nivel(self):
        cuerpo = leer("bueno.md").replace("- [x] Aviso", "- [ ] Aviso")
        self.assertFalla(self.correr(pr_body=cuerpo), "pr-nivel")

    def test_hice_yo_vacio(self):
        res = self.correr(pr_body=leer("hice-yo-vacio.md"))
        self.assertFalla(res, "pr-uso-ia")
        self.assertIn("Hice yo:", next(f for f in res.fallas if f["regla"] == "pr-uso-ia")["que_paso"])

    def test_que_cambia_vacio(self):
        cuerpo = leer("bueno.md").replace("Agregué el brief y el primer plano del shotlist.", "")
        self.assertFalla(self.correr(pr_body=cuerpo), "pr-que-cambia")

    def test_seccion_personas_reales_se_ignora(self):
        cuerpo = leer("bueno.md") + "\n## Personas reales\n\n- [ ] No\n- [x] Sí, issue de permiso: #N\n"
        res = self.correr(pr_body=cuerpo)
        self.assertEqual(res.fallas, [])
        self.assertEqual(res.avisos, [])

    def test_pr_sin_seccion_personas_reales_pasa(self):
        self.assertNotIn("Personas reales", leer("bueno.md"))
        self.assertEqual(self.correr(pr_body=leer("bueno.md")).fallas, [])


class TestGuion(Base):
    def test_sano_con_guion_pasa(self):
        self.assertTrue((self.repo / "02_guion" / "guion.md").is_file())
        self.assertEqual(self.correr().fallas, [])

    def test_encabezado_con_formato_malo(self):
        self.superponer("guion-formato")
        res = self.correr()
        self.assertFalla(res, "guion-formato")
        f = next(f for f in res.fallas if f["regla"] == "guion-formato")
        self.assertIn("línea 4", f["que_paso"])
        self.assertIn("#guion-y-shotlist", f["por_que"])

    def test_guion_sin_ningun_encabezado(self):
        self.escribir("02_guion/guion.md", "El autobús va vacío al amanecer.\n")
        self.assertFalla(self.correr(), "guion-formato")

    def test_encabezado_dentro_de_bloque_de_codigo_se_ignora(self):
        guion = self.repo / "02_guion" / "guion.md"
        guion.write_text(guion.read_text(encoding="utf-8") + "\n```\n## cualquier cosa\n```\n", encoding="utf-8")
        self.assertEqual(self.correr().fallas, [])

    def test_escena_repetida(self):
        self.superponer("guion-repetido")
        self.assertFalla(self.correr(), "guion-escena-repetida")

    def test_escena_con_salto(self):
        self.superponer("guion-salto")
        self.assertFalla(self.correr(), "guion-escena-salto")

    def test_escena_que_no_empieza_en_1(self):
        guion = self.repo / "02_guion" / "guion.md"
        texto = guion.read_text(encoding="utf-8").replace("ESC 1", "ESC 0").replace("ESC 2", "ESC 1")
        guion.write_text(texto, encoding="utf-8")
        self.assertFalla(self.correr(), "guion-escena-salto")

    def test_guion_vacio_cuenta_como_sin_guion(self):
        self.escribir("02_guion/guion.md", "\n")
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        ruta.write_text(ruta.read_text(encoding="utf-8").replace("    escena: 1\n", "").replace("    escena: 2\n", ""), encoding="utf-8")
        self.assertEqual(self.correr().fallas, [])

    def test_sin_guion_no_exige_escena(self):
        (self.repo / "02_guion" / "guion.md").unlink()
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        ruta.write_text(ruta.read_text(encoding="utf-8").replace("    escena: 1\n", "").replace("    escena: 2\n", ""), encoding="utf-8")
        self.assertEqual(self.correr().fallas, [])


class TestShotlistClase13(Base):
    def test_sin_proposito(self):
        self.superponer("shotlist-sin-proposito")
        res = self.correr()
        self.assertFalla(res, "shotlist-proposito")
        f = next(f for f in res.fallas if f["regla"] == "shotlist-proposito")
        self.assertIn("P01", f["que_paso"])
        self.assertIn("P02", f["que_paso"])

    def test_proposito_vacio_o_placeholder(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        texto = ruta.read_text(encoding="utf-8")
        ruta.write_text(texto.replace(
            "proposito: Establece el autobús vacío y la luz del amanecer, que es lo que el brief quiere que se recuerde.",
            "proposito: TODO"), encoding="utf-8")
        res = self.correr()
        self.assertFalla(res, "shotlist-proposito")
        f = next(f for f in res.fallas if f["regla"] == "shotlist-proposito")
        self.assertIn("P01", f["que_paso"])
        self.assertNotIn("P02", f["que_paso"])

    def test_proposito_se_exige_aunque_no_haya_guion(self):
        (self.repo / "02_guion" / "guion.md").unlink()
        self.superponer("shotlist-sin-proposito")
        self.assertFalla(self.correr(), "shotlist-proposito")

    def test_escena_falta_cuando_hay_guion(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        ruta.write_text(ruta.read_text(encoding="utf-8").replace("    escena: 2\n", ""), encoding="utf-8")
        res = self.correr()
        self.assertFalla(res, "shotlist-escena-falta")
        f = next(f for f in res.fallas if f["regla"] == "shotlist-escena-falta")
        self.assertIn("P02", f["que_paso"])
        self.assertNotIn("P01", f["que_paso"])

    def test_modelo_puede_faltar_en_estado_idea(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        texto = ruta.read_text(encoding="utf-8")
        import re as _re
        texto = _re.sub(r"(  - id: P02\n(?:    .*\n)*?)    modelo: .*\n", r"\1", texto, count=1)
        texto = _re.sub(r"(  - id: P02\n(?:    .*\n)*?    estado: )\w+", r"\1idea", texto, count=1)
        ruta.write_text(texto, encoding="utf-8")
        self.assertNotIn("modelo", " ".join(f["que_paso"] for f in self.correr().fallas))

    def test_modelo_se_exige_desde_estado_prompt(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        texto = ruta.read_text(encoding="utf-8")
        import re as _re
        texto = _re.sub(r"(  - id: P01\n(?:    .*\n)*?)    modelo: .*\n", r"\1", texto, count=1)
        ruta.write_text(texto, encoding="utf-8")
        self.assertFalla(self.correr(), "shotlist-campos")

    def test_escena_inexistente(self):
        self.superponer("shotlist-escena-inexistente")
        res = self.correr()
        self.assertFalla(res, "shotlist-escena-inexistente")
        f = next(f for f in res.fallas if f["regla"] == "shotlist-escena-inexistente")
        self.assertIn("escena 7", f["que_paso"])

    def test_escena_como_texto_con_digitos_se_acepta(self):
        ruta = self.repo / "03_shotlist" / "shotlist.yaml"
        ruta.write_text(ruta.read_text(encoding="utf-8").replace("escena: 1", 'escena: "1"'), encoding="utf-8")
        self.assertEqual(self.correr().fallas, [])


class TestRetoEnFrio(Base):
    def test_revision_con_reto_pasa(self):
        self.assertEqual(self.correr(pr_body=leer("revision-con-reto.md")).fallas, [])

    def test_revision_sin_seccion(self):
        res = self.correr(pr_body=leer("revision-sin-reto.md"))
        self.assertFalla(res, "pr-reto-en-frio")
        f = next(f for f in res.fallas if f["regla"] == "pr-reto-en-frio")
        self.assertIn("le falta la sección", f["que_paso"])
        self.assertIn("#reto-en-frio", f["por_que"])

    def test_revision_con_no_aplica(self):
        self.assertFalla(self.correr(pr_body=leer("revision-reto-vacio.md")), "pr-reto-en-frio")

    def test_revision_con_respuesta_sin_texto(self):
        self.assertFalla(self.correr(pr_body=leer("revision-reto-sin-texto.md")), "pr-reto-en-frio")

    def test_rechazo_sin_razon(self):
        cuerpo = leer("revision-sin-reto.md") + "\n## Reto en frío\n\n- H1: Falta una escena. → Rechazo:   \n"
        self.assertFalla(self.correr(pr_body=cuerpo), "pr-reto-en-frio")

    def test_flecha_ascii_se_acepta(self):
        cuerpo = leer("revision-sin-reto.md") + "\n## Reto en frío\n\n- H1: Falta una escena. -> Rechazo: ya está cubierta.\n"
        self.assertEqual(self.correr(pr_body=cuerpo).fallas, [])

    def test_un_hallazgo_sin_respuesta_falla_aunque_otro_este_completo(self):
        cuerpo = leer("revision-sin-reto.md") + (
            "\n## Reto en frío\n\n- H1: Falta una escena. → Incorporo: agregué ESC 4.\n"
            "- H2: El plano P03 no tiene propósito claro.\n"
            "- H3: Sobra un inserto. → Rechazo:   \n")
        res = self.correr(pr_body=cuerpo)
        self.assertFalla(res, "pr-reto-sin-respuesta")
        f = next(f for f in res.fallas if f["regla"] == "pr-reto-sin-respuesta")
        self.assertIn("H2", f["que_paso"])
        self.assertIn("H3", f["que_paso"])
        self.assertNotIn("H1", f["que_paso"])

    def test_aviso_sin_reto_pasa(self):
        self.assertEqual(self.correr(pr_body=leer("aviso-sin-reto.md")).fallas, [])

    def test_aviso_con_no_aplica_pasa(self):
        cuerpo = leer("aviso-sin-reto.md") + "\n## Reto en frío\n\nNo aplica\n"
        self.assertEqual(self.correr(pr_body=cuerpo).fallas, [])

    def test_comentario_de_plantilla_no_cuenta_como_hallazgo(self):
        cuerpo = leer("revision-sin-reto.md") + (
            "\n## Reto en frío\n\n<!-- - H1: ejemplo → Incorporo: ejemplo -->\n")
        self.assertFalla(self.correr(pr_body=cuerpo), "pr-reto-en-frio")


class TestCLI(Base):
    def cli(self, *args):
        return subprocess.run([sys.executable, str(VALIDAR)] + [str(a) for a in args],
                              capture_output=True, text=True, encoding="utf-8")

    def test_exit_0_en_sano(self):
        p = self.cli(self.repo)
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)

    def test_exit_1_y_mensaje_4_partes(self):
        self.escribir("05_audio/x.wav", b"RIFF", "wb")
        p = self.cli(self.repo)
        self.assertEqual(p.returncode, 1)
        for parte in ("✋ Qué pasó:", "Por qué:", "Qué puedes hacer:", "Cómo destrabar:"):
            self.assertIn(parte, p.stdout)

    def test_json(self):
        self.escribir("05_audio/x.wav", b"RIFF", "wb")
        p = self.cli(self.repo, "--json")
        self.assertEqual(p.returncode, 1)
        datos = json.loads(p.stdout)
        self.assertFalse(datos["ok"])
        self.assertEqual(datos["fallas"][0]["regla"], "media-bloqueada")
        self.assertEqual(set(datos["areas"]), {"brief", "shotlist", "prompts"})
        self.assertIn(datos["areas"]["brief"], ("falta", "borrador", "funciona"))

    def test_pr_body_por_archivo(self):
        p = self.cli(self.repo, "--pr-body", FIXTURES / "pr" / "dos-niveles.md", "--json")
        self.assertEqual(p.returncode, 1)
        self.assertEqual(json.loads(p.stdout)["fallas"][0]["regla"], "pr-nivel")

    def test_cli_mensaje_4_partes_en_reto_en_frio(self):
        p = self.cli(self.repo, "--pr-body", FIXTURES / "pr" / "revision-sin-reto.md")
        self.assertEqual(p.returncode, 1)
        for parte in ("✋ Qué pasó:", "Por qué:", "Qué puedes hacer:", "Cómo destrabar:"):
            self.assertIn(parte, p.stdout)
        self.assertIn("https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#reto-en-frio", p.stdout)

    def test_carpeta_inexistente(self):
        self.assertEqual(self.cli(self.repo / "nada").returncode, 2)


class TestPlantillaYEjemplo(unittest.TestCase):
    def cli(self, carpeta, *args):
        return subprocess.run([sys.executable, str(VALIDAR), str(carpeta)] + list(args),
                              capture_output=True, text=True, encoding="utf-8")

    def test_plantilla_pasa_en_modo_plantilla(self):
        carpeta = HERMANOS / "proyecto-plantilla"
        if not carpeta.is_dir():
            self.skipTest("proyecto-plantilla no está junto al estándar")
        p = self.cli(carpeta, "--modo", "plantilla")
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)

    def test_plantilla_falla_en_modo_alumno(self):
        carpeta = HERMANOS / "proyecto-plantilla"
        if not carpeta.is_dir():
            self.skipTest("proyecto-plantilla no está junto al estándar")
        p = self.cli(carpeta)
        self.assertEqual(p.returncode, 1)
        self.assertIn("✋ Qué pasó:", p.stdout)

    def test_ejemplo_pasa(self):
        carpeta = HERMANOS / "proyecto-ejemplo"
        if not carpeta.is_dir():
            self.skipTest("proyecto-ejemplo no está junto al estándar")
        p = self.cli(carpeta)
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)


if __name__ == "__main__":
    unittest.main()
