#!/usr/bin/env python3
"""Gate de LCA425: valida un repo de alumno (o la plantilla) contra el esquema del curso.

Uso:
    python3 validar.py <repo_path> [--modo alumno|plantilla] [--pr-body ARCHIVO] [--json]
    python3 validar.py <repo_path> --solo-palabras

Python 3.9+, solo biblioteca estándar. PyYAML se usa solo para archivos .yaml, si está instalado.
Sale con 0 si no hay fallas y con 1 si hay al menos una.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import unicodedata
from pathlib import Path

BASE_DOCS = "https://github.com/daniknn/lca425-estandar/blob/main/docs/"

CAMPOS_BRIEF = [
    "titulo",
    "formato",
    "idea",
    "publico",
    "que_debe_lograr",
    "fuera_de_alcance",
    "presupuesto_creditos",
    "personas_reales",
    "issue_permiso",
    "drive",
]
FORMATOS = ("corto", "redes", "transmedia")
ESTADOS = ("idea", "prompt", "generado", "validado")

EXT_BLOQUEADAS = {
    ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm",
    ".wav", ".mp3", ".aac", ".m4a", ".flac", ".aif", ".aiff",
    ".psd", ".ai", ".aep", ".prproj", ".drp", ".fcpxml",
    ".zip", ".rar", ".7z",
}
EXT_IMAGEN = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg"}
LIMITE_BYTES = 1024 * 1024
LIMITE_LECTURA_TEXTO = 5 * 1024 * 1024

RE_DRIVE = re.compile(r"^https://drive\.google\.com/\S+$")
RE_ISSUE = re.compile(r"^#\d+$")
RE_ID_PLANO = re.compile(r"^P\d{2}$")
RE_ID_SEGURO = re.compile(r"^[A-Za-z0-9_-]+$")
RE_DAS = re.compile(r"\bDAS-\d+\b")


# ---------------------------------------------------------------- resultado

class Resultado:
    def __init__(self):
        self.fallas = []
        self.avisos = []
        self.areas = {"brief": "falta", "shotlist": "falta", "prompts": "falta"}

    def falla(self, regla, archivo, que_paso, por_que, opciones, como_destrabar, area=None):
        self.fallas.append({
            "regla": regla,
            "archivo": archivo,
            "que_paso": que_paso,
            "por_que": por_que,
            "opciones": list(opciones),
            "como_destrabar": como_destrabar,
            "area": area,
        })

    def aviso(self, regla, archivo, mensaje):
        self.avisos.append({"regla": regla, "archivo": archivo, "mensaje": mensaje})

    def hay_falla(self, area):
        return any(f["area"] == area for f in self.fallas)


def link(doc, ancla=""):
    return BASE_DOCS + doc + (("#" + ancla) if ancla else "")


def formatear_falla(f):
    lineas = [
        "[%s] %s" % (f["regla"], f["archivo"]),
        "✋ Qué pasó: %s" % f["que_paso"],
        "Por qué: %s" % f["por_que"],
        "Qué puedes hacer:",
    ]
    for i, op in enumerate(f["opciones"], 1):
        lineas.append("  %d. %s" % (i, op))
    lineas.append("Cómo destrabar: %s" % f["como_destrabar"])
    return "\n".join(lineas)


# ---------------------------------------------------------------- utilidades

def es_placeholder(valor):
    v = (valor or "").strip()
    if v == "" or v.upper() == "TODO" or v == "...":
        return True
    return v.startswith("<") and v.endswith(">")


def sin_acentos(texto):
    d = unicodedata.normalize("NFD", texto)
    return "".join(c for c in d if unicodedata.category(c) != "Mn")


def leer_texto(ruta):
    try:
        return Path(ruta).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None


def parsear_frontmatter(texto):
    """Frontmatter plano `clave: valor`. Devuelve dict o None si no hay frontmatter."""
    lineas = texto.splitlines()
    if not lineas or lineas[0].strip() != "---":
        return None
    datos = {}
    for linea in lineas[1:]:
        if linea.strip() == "---":
            return datos
        if not linea.strip() or linea.lstrip().startswith("#"):
            continue
        if ":" not in linea:
            continue
        clave, valor = linea.split(":", 1)
        valor = valor.strip()
        if len(valor) >= 2 and valor[0] == valor[-1] and valor[0] in "\"'":
            valor = valor[1:-1]
        datos[clave.strip()] = valor
    return None  # frontmatter sin cierre


class CargadorYaml:
    def __init__(self, res):
        self.res = res
        try:
            import yaml  # opcional: solo se usa para leer archivos .yaml
            self.yaml = yaml
        except ImportError:
            self.yaml = None
        self.avisado = False

    def cargar(self, ruta, rel):
        """Devuelve (datos, estado). estado: 'ok' | 'sin_yaml' | 'invalido'."""
        if self.yaml is None:
            if not self.avisado:
                self.avisado = True
                msg = ("Falta PyYAML para leer los archivos .yaml; instálalo con: "
                       "python3 -m pip install pyyaml==6.0.2")
                if os.environ.get("CI"):
                    self.res.falla(
                        "yaml-no-disponible", rel, msg,
                        "Configuración del gate · sin PyYAML no se pueden revisar shotlist ni prompts · "
                        + link("como-trabajar.md", "bloqueos"),
                        ["Avísale a Daria: este fallo es de la configuración del gate, no de tu proyecto."],
                        "Daria corrige el workflow del estándar y vuelves a correr el gate.",
                    )
                else:
                    self.res.aviso("yaml-no-disponible", rel, msg)
            return None, "sin_yaml"
        try:
            with open(ruta, "r", encoding="utf-8") as fh:
                return self.yaml.safe_load(fh), "ok"
        except Exception as exc:  # yaml.YAMLError, UnicodeDecodeError, OSError
            linea = ""
            mark = getattr(exc, "problem_mark", None)
            if mark is not None:
                linea = " (cerca de la línea %d)" % (mark.line + 1)
            return exc, "invalido" + linea


def yaml_invalido(res, rel, area, detalle):
    res.falla(
        "yaml-invalido", rel,
        "No pude leer %s como YAML%s." % (rel, detalle),
        "Formato del archivo · si el YAML no se lee, el gate no puede revisar tus planos ni prompts · "
        + link("como-trabajar.md", "tu-primer-pr"),
        ["Revisa que cada línea tenga la forma `campo: valor` y que la sangría use espacios, no tabuladores.",
         "Pega el archivo en Claude y pídele que encuentre el error de formato sin cambiar tu contenido."],
        "Corrige el formato y sube el cambio otra vez.",
        area=area,
    )


def norm_sino(valor):
    """YAML 1.1 convierte `no` en False; lo normalizamos. Devuelve 'si' | 'no' | None."""
    if valor is False:
        return "no"
    if isinstance(valor, str) and valor.strip().lower() in ("si", "no"):
        return valor.strip().lower()
    return None


def es_texto_util(valor):
    return isinstance(valor, str) and not es_placeholder(valor)


# ---------------------------------------------------------------- archivos requeridos

def revisar_requeridos(repo, res):
    for nombre in ("AGENTS.md", "CLAUDE.md", "00_brief.md"):
        if not (repo / nombre).is_file():
            res.falla(
                "archivo-requerido", nombre,
                "Falta el archivo %s en la raíz de tu repo." % nombre,
                "Estructura del proyecto · el repo se lee igual en todos los proyectos del curso · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Cópialo desde la plantilla del curso (proyecto-plantilla).",
                 "Si lo borraste sin querer, recupéralo desde el historial de tu repo en GitHub."],
                "Agrega %s con el contenido de la plantilla y sube el cambio." % nombre,
            )
    claude = repo / "CLAUDE.md"
    if claude.is_file():
        contenido = leer_texto(claude)
        if contenido is None or contenido.strip() != "@AGENTS.md":
            res.falla(
                "claude-md", "CLAUDE.md",
                "CLAUDE.md debe contener exactamente `@AGENTS.md` y nada más.",
                "Estructura del proyecto · así Claude Code lee las reglas del curso desde un solo lugar · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Reemplaza todo el contenido de CLAUDE.md por la línea `@AGENTS.md`.",
                 "Si quieres agregar notas propias, ponlas en 00_brief.md, no en CLAUDE.md."],
                "Deja CLAUDE.md con una sola línea: @AGENTS.md",
            )


# ---------------------------------------------------------------- brief

def revisar_brief(repo, modo, res):
    """Devuelve el dict del frontmatter (o {}) para usarlo en las demás reglas."""
    ruta = repo / "00_brief.md"
    if not ruta.is_file():
        return {}
    texto = leer_texto(ruta)
    datos = parsear_frontmatter(texto) if texto is not None else None
    if datos is None:
        res.falla(
            "brief-sin-frontmatter", "00_brief.md",
            "00_brief.md no tiene el bloque de campos al inicio (entre dos líneas `---`).",
            "Brief · el gate y tus recetas leen esos campos para saber qué estás haciendo · "
            + link("como-trabajar.md", "tu-primer-pr"),
            ["Corre /lca425:brief en Claude Code y deja que lo arme contigo.",
             "O copia el encabezado de 00_brief.md desde la plantilla y llénalo."],
            "Agrega el bloque de campos al inicio del archivo y súbelo de nuevo.",
            area="brief",
        )
        return {}

    faltantes = []
    for campo in CAMPOS_BRIEF:
        if campo == "issue_permiso":
            continue  # solo se exige si personas_reales es si; se revisa abajo
        if es_placeholder(datos.get(campo)):
            faltantes.append(campo)

    personas = datos.get("personas_reales", "")
    personas_si = (not es_placeholder(personas)) and personas.strip().lower() == "si"
    if faltantes:
        if modo == "plantilla":
            res.aviso("brief-incompleto", "00_brief.md",
                      "Campos por llenar (normal en la plantilla): " + ", ".join(faltantes))
        else:
            res.falla(
                "brief-incompleto", "00_brief.md",
                "En 00_brief.md faltan o siguen como plantilla estos campos: %s." % ", ".join(faltantes),
                "Brief · sin brief completo no hay forma de saber qué debe lograr tu pieza · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Abre Claude Code en este repo y corre /lca425:brief; te hace las preguntas una por una.",
                 "Usa la tarjeta `brief` en claude.ai y pega el resultado en 00_brief.md.",
                 "Si no sabes qué poner en un campo, pregúntale a Daria en clase."],
                "Escribe tus palabras en cada campo (sin dejar `< >`, `TODO` ni `...`) y sube el cambio.",
                area="brief",
            )

    # Valores presentes pero inválidos (siempre falla, también en plantilla)
    formato = datos.get("formato")
    if not es_placeholder(formato) and formato.strip() not in FORMATOS:
        res.falla(
            "brief-formato", "00_brief.md",
            "El formato `%s` no es válido; debe ser corto, redes o transmedia." % formato,
            "Brief · cada formato tiene su propia rúbrica y sus propios entregables · "
            + link("como-trabajar.md", "tu-primer-pr"),
            ["Escribe exactamente una de estas palabras: corto, redes, transmedia.",
             "Si tu idea no encaja en ninguno, cuéntasela a Daria antes de seguir."],
            "Corrige el campo `formato` en 00_brief.md y sube el cambio.",
            area="brief",
        )

    presupuesto = datos.get("presupuesto_creditos")
    if not es_placeholder(presupuesto) and not re.fullmatch(r"\d+", presupuesto.strip()):
        res.falla(
            "brief-presupuesto", "00_brief.md",
            "presupuesto_creditos debe ser un número entero de 0 o más; encontré `%s`." % presupuesto,
            "Brief · el tope de créditos protege tu saldo de Higgsfield y el de tu proyecto · "
            + link("niveles.md", "permiso"),
            ["Escribe solo el número, por ejemplo 120.",
             "Si no sabes cuánto gastarás, calcula con el costo que muestra Higgsfield antes de generar."],
            "Corrige el campo y sube el cambio. Si necesitas pasarte del tope, abre un issue de permiso.",
            area="brief",
        )

    if not es_placeholder(personas) and personas.strip().lower() not in ("si", "no"):
        res.falla(
            "brief-personas-reales", "00_brief.md",
            "personas_reales debe ser si o no; encontré `%s`." % personas,
            "Ética y derechos · aquí declaras si aparece la cara o la voz de alguien real · "
            + link("etica-y-derechos.md", "personas-reales"),
            ["Escribe `si` si aparece la cara o voz de una persona real identificable.",
             "Escribe `no` si solo hay objetos, paisajes o personajes inventados."],
            "Corrige el campo y sube el cambio.",
            area="brief",
        )

    issue = datos.get("issue_permiso")
    if personas_si:
        if es_placeholder(issue) or not RE_ISSUE.match(issue.strip()):
            res.falla(
                "personas-reales-sin-issue", "00_brief.md",
                "Marcaste personas_reales: si, pero issue_permiso no tiene un issue válido (formato #N).",
                "Nivel Permiso · la cara o voz de una persona real necesita autorización antes de empezar · "
                + link("niveles.md", "permiso"),
                ["Abre un issue con la etiqueta `permiso` y escribe su número en issue_permiso, por ejemplo #4.",
                 "Si en realidad no aparece nadie real, cambia personas_reales a `no`.",
                 "Pídele a Daria que revise tu caso si tienes dudas."],
                "Abre un issue de permiso; la receta /lca425:cierre te lo redacta.",
                area="brief",
            )

    drive = datos.get("drive")
    if not es_placeholder(drive) and not RE_DRIVE.match(drive.strip()):
        res.falla(
            "brief-drive", "00_brief.md",
            "El campo drive debe ser un link que empiece con https://drive.google.com/ ; encontré `%s`." % drive,
            "Media fuera del repo · el video y el audio viven en tu carpeta de Drive, no en GitHub · "
            + link("como-trabajar.md", "binario-subido"),
            ["Crea la carpeta del proyecto en tu Drive, compártela con Daria y pega su link.",
             "Copia el link desde Drive con la opción Compartir > Copiar vínculo."],
            "Corrige el campo drive y sube el cambio.",
            area="brief",
        )
    return datos


# ---------------------------------------------------------------- shotlist y prompts

def orden_estado(estado):
    return ESTADOS.index(estado) if estado in ESTADOS else -1


def revisar_shotlist(repo, brief, res, yamlc):
    rel = "03_shotlist/shotlist.yaml"
    ruta = repo / rel
    if not ruta.is_file():
        return
    datos, estado = yamlc.cargar(ruta, rel)
    if estado == "sin_yaml":
        res.areas["shotlist"] = "borrador"
        return
    if estado.startswith("invalido"):
        yaml_invalido(res, rel, "shotlist", estado[len("invalido"):])
        return
    planos = datos.get("planos") if isinstance(datos, dict) else None
    if not isinstance(planos, list) or not planos:
        res.falla(
            "shotlist-sin-planos", rel,
            "El shotlist no tiene la lista `planos:` con al menos un plano.",
            "Shotlist · cada plano es la unidad de trabajo que se genera y se revisa · "
            + link("como-trabajar.md", "tu-primer-pr"),
            ["Corre la receta de shotlist en Claude Code, o copia el ejemplo de proyecto-ejemplo.",
             "Escribe un solo plano a mano para empezar."],
            "Agrega `planos:` con al menos un plano y sube el cambio.",
            area="shotlist",
        )
        return

    vistos = set()
    hay_idea = False
    for i, p in enumerate(planos, 1):
        if not isinstance(p, dict):
            res.falla(
                "shotlist-plano", rel,
                "El plano número %d no tiene la forma `campo: valor`." % i,
                "Shotlist · cada plano necesita sus campos para poder generarse y revisarse · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Compara ese plano con el de proyecto-ejemplo."],
                "Corrige el plano y sube el cambio.",
                area="shotlist",
            )
            continue
        pid = p.get("id")
        etiqueta = str(pid) if pid else "plano #%d" % i
        if not isinstance(pid, str) or not RE_ID_PLANO.match(pid):
            res.falla(
                "shotlist-id", rel,
                "El id del plano #%d (`%s`) debe ser P y dos dígitos, por ejemplo P01." % (i, pid),
                "Shotlist · los ids únicos conectan cada plano con su prompt y su clip · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Usa P01, P02, P03... en orden."],
                "Corrige el id y sube el cambio.",
                area="shotlist",
            )
        elif pid in vistos:
            res.falla(
                "shotlist-id-repetido", rel,
                "El id %s aparece más de una vez." % pid,
                "Shotlist · si dos planos comparten id, no se sabe cuál prompt ni cuál clip es de cuál · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Dale a cada plano su propio número."],
                "Renumera los planos repetidos y sube el cambio.",
                area="shotlist",
            )
        else:
            vistos.add(pid)

        faltan = [c for c in ("descripcion", "camara", "modelo") if not es_texto_util(p.get(c))]
        dur = p.get("duracion_s")
        if isinstance(dur, bool) or not isinstance(dur, (int, float)) or dur <= 0:
            faltan.append("duracion_s (número mayor que 0)")
        if faltan:
            res.falla(
                "shotlist-campos", rel,
                "Al plano %s le faltan o tiene mal estos campos: %s." % (etiqueta, ", ".join(faltan)),
                "Shotlist · sin esos datos el plano no se puede generar ni evaluar · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Llénalos con tus palabras; mira proyecto-ejemplo como modelo.",
                 "Pídele a tu Claude que te pregunte los datos que faltan."],
                "Completa el plano y sube el cambio.",
                area="shotlist",
            )

        est = p.get("estado")
        if est not in ESTADOS:
            res.falla(
                "shotlist-estado", rel,
                "El estado del plano %s (`%s`) debe ser idea, prompt, generado o validado." % (etiqueta, est),
                "Shotlist · el estado dice qué tan avanzado va cada plano · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Elige uno de los cuatro estados, en minúsculas."],
                "Corrige el estado y sube el cambio.",
                area="shotlist",
            )
            continue
        nivel = orden_estado(est)
        if est == "idea":
            hay_idea = True

        if nivel >= orden_estado("prompt"):
            prompt_id = p.get("prompt_id")
            if not isinstance(prompt_id, str) or not RE_ID_SEGURO.match(prompt_id):
                res.falla(
                    "shotlist-prompt-id", rel,
                    "El plano %s está en estado %s pero no tiene un prompt_id válido." % (etiqueta, est),
                    "Shotlist · cada plano con prompt apunta a su archivo en 04_prompts/ · "
                    + link("como-trabajar.md", "tu-primer-pr"),
                    ["Escribe el id del prompt, por ejemplo P01-v1.",
                     "Si aún no tienes prompt, regresa el estado a `idea`."],
                    "Agrega el prompt_id y su archivo en 04_prompts/ y sube el cambio.",
                    area="shotlist",
                )
            elif not (repo / "04_prompts" / (prompt_id + ".yaml")).is_file():
                res.falla(
                    "shotlist-prompt-inexistente", rel,
                    "El plano %s apunta a 04_prompts/%s.yaml, pero ese archivo no existe." % (etiqueta, prompt_id),
                    "Shotlist · cada prompt usado debe quedar guardado para poder repetirlo y revisarlo · "
                    + link("como-trabajar.md", "tu-primer-pr"),
                    ["Crea 04_prompts/%s.yaml con el prompt que usaste." % prompt_id,
                     "Corrige el prompt_id si lo escribiste distinto al nombre del archivo."],
                    "Crea o renombra el archivo y sube el cambio.",
                    area="shotlist",
                )
        if nivel >= orden_estado("generado"):
            clip = p.get("clip_url")
            if not isinstance(clip, str) or not RE_DRIVE.match(clip.strip()):
                res.falla(
                    "shotlist-sin-clip", rel,
                    "El plano %s está en estado %s pero no tiene clip_url de Drive." % (etiqueta, est),
                    "Media fuera del repo · el clip vive en tu Drive y el repo solo guarda el link · "
                    + link("como-trabajar.md", "binario-subido"),
                    ["Sube el clip a tu carpeta de Drive y pega su link en clip_url (https://drive.google.com/...).",
                     "Si todavía no lo generas, regresa el estado a `prompt`."],
                    "Agrega clip_url y sube el cambio. Nunca subas el video al repo.",
                    area="shotlist",
                )

        pr = norm_sino(p.get("persona_real"))
        if pr is None:
            res.falla(
                "shotlist-persona-real", rel,
                "El plano %s necesita persona_real: si o no." % etiqueta,
                "Ética y derechos · en cada plano declaras si aparece alguien real · "
                + link("etica-y-derechos.md", "personas-reales"),
                ["Escribe `no` si solo hay objetos, paisajes o personajes inventados.",
                 "Escribe `si` si aparece la cara o voz de alguien real; entonces necesitas permiso."],
                "Corrige el campo y sube el cambio.",
                area="shotlist",
            )
        elif pr == "si":
            issue = brief.get("issue_permiso", "")
            personas = (brief.get("personas_reales", "") or "").strip().lower()
            if personas != "si" or es_placeholder(issue) or not RE_ISSUE.match(issue.strip()):
                res.falla(
                    "persona-real-sin-permiso", rel,
                    "El plano %s tiene persona_real: si, pero el brief no declara un issue de permiso." % etiqueta,
                    "Nivel Permiso · la cara o voz de una persona real necesita autorización antes de empezar · "
                    + link("niveles.md", "permiso"),
                    ["Abre un issue con la etiqueta `permiso`, y en 00_brief.md pon personas_reales: si e issue_permiso: #N.",
                     "Si el plano no tiene a nadie real, cambia persona_real a `no`.",
                     "Pídele a Daria que revise tu caso."],
                    "Abre un issue de permiso; la receta /lca425:cierre te lo redacta.",
                    area="shotlist",
                )

    if res.hay_falla("shotlist") or hay_idea:
        res.areas["shotlist"] = "borrador"
    else:
        res.areas["shotlist"] = "funciona"


def revisar_prompts(repo, res, yamlc):
    carpeta = repo / "04_prompts"
    archivos = sorted(carpeta.glob("*.yaml")) if carpeta.is_dir() else []
    if not archivos:
        return
    todos_validados = True
    for ruta in archivos:
        rel = "04_prompts/" + ruta.name
        datos, estado = yamlc.cargar(ruta, rel)
        if estado == "sin_yaml":
            res.areas["prompts"] = "borrador"
            return
        if estado.startswith("invalido"):
            yaml_invalido(res, rel, "prompts", estado[len("invalido"):])
            continue
        if not isinstance(datos, dict):
            res.falla(
                "prompt-formato", rel,
                "%s no tiene la forma `campo: valor`." % ruta.name,
                "Prompts · cada prompt se guarda con sus campos para poder repetirlo · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Compara con 04_prompts/P01-v1.yaml de proyecto-ejemplo."],
                "Corrige el archivo y sube el cambio.",
                area="prompts",
            )
            continue
        problemas = []
        if datos.get("id") != ruta.stem:
            problemas.append("id debe ser igual al nombre del archivo (%s)" % ruta.stem)
        if not es_texto_util(datos.get("modelo")):
            problemas.append("falta modelo")
        if not es_texto_util(datos.get("prompt")):
            problemas.append("falta prompt")
        if "parametros" in datos and datos["parametros"] is not None and not isinstance(datos["parametros"], dict):
            problemas.append("parametros debe ser un mapa campo: valor")
        validado = norm_sino(datos.get("validado"))
        if validado is None:
            problemas.append("validado debe ser si o no")
        if problemas:
            res.falla(
                "prompt-campos", rel,
                "En %s: %s." % (ruta.name, "; ".join(problemas)),
                "Prompts · un prompt sin sus datos no se puede repetir ni revisar · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Compara con 04_prompts/P01-v1.yaml de proyecto-ejemplo.",
                 "Pídele a tu Claude que revise el formato sin cambiar tu prompt."],
                "Corrige los campos y sube el cambio.",
                area="prompts",
            )
        if validado != "si":
            todos_validados = False
        else:
            faltan = []
            clip = datos.get("clip_url")
            if not isinstance(clip, str) or not RE_DRIVE.match(clip.strip()):
                faltan.append("clip_url (link de Drive)")
            if not es_texto_util(datos.get("leccion")):
                faltan.append("leccion")
            if faltan:
                res.falla(
                    "prompt-validado-incompleto", rel,
                    "El prompt %s está validado, pero le falta: %s." % (ruta.stem, ", ".join(faltan)),
                    "Prompts · validar un prompt significa guardar el clip y lo que aprendiste · "
                    + link("como-trabajar.md", "tu-primer-pr"),
                    ["Escribe en `leccion` qué funcionó o qué no, en una o dos oraciones.",
                     "Pega en clip_url el link del clip en tu Drive.",
                     "Si aún no lo validas, cambia validado a `no`."],
                    "Completa los campos y sube el cambio.",
                    area="prompts",
                )
    if res.hay_falla("prompts") or not todos_validados:
        res.areas["prompts"] = "borrador"
    else:
        res.areas["prompts"] = "funciona"


# ---------------------------------------------------------------- media

def recorrer(repo):
    for raiz, dirs, archivos in os.walk(str(repo)):
        dirs[:] = sorted(d for d in dirs if d != ".git")
        for nombre in sorted(archivos):
            ruta = Path(raiz) / nombre
            if ruta.is_symlink():
                continue
            yield ruta, ruta.relative_to(repo).as_posix()


def revisar_media(repo, res):
    for ruta, rel in recorrer(repo):
        ext = ruta.suffix.lower()
        try:
            tam = ruta.stat().st_size
        except OSError:
            continue
        if ext in EXT_BLOQUEADAS:
            res.falla(
                "media-bloqueada", rel,
                "El archivo %s es de un tipo (%s) que no va en el repo." % (rel, ext),
                "Media fuera del repo · el video, el audio y los proyectos de edición pesan y no se pueden "
                "borrar del historial de git · " + link("como-trabajar.md", "binario-subido"),
                ["Sube el archivo a tu carpeta de Drive y pega su link en el shotlist o en el brief.",
                 "Quítalo de tu repo antes de subir el cambio."],
                "Mueve el archivo a Drive y bórralo del repo. Si ya estaba en un commit anterior, sigue "
                "la guía `binario-subido` (link arriba); nunca uses --force.",
            )
        elif ext in EXT_IMAGEN:
            if not rel.startswith("06_web/"):
                res.falla(
                    "imagen-fuera-de-06_web", rel,
                    "La imagen %s está fuera de 06_web/." % rel,
                    "Media fuera del repo · las imágenes solo van en 06_web/ y de hasta 1 MB · "
                    + link("como-trabajar.md", "binario-subido"),
                    ["Si es parte de tu web, muévela a 06_web/ (y que pese 1 MB o menos).",
                     "Si es material de producción (frames, referencias), déjala en tu carpeta de Drive."],
                    "Muévela a 06_web/ o a Drive y sube el cambio.",
                )
            elif tam > LIMITE_BYTES:
                res.falla(
                    "imagen-pesada", rel,
                    "La imagen %s pesa %.1f MB y el límite es 1 MB." % (rel, tam / LIMITE_BYTES),
                    "Media fuera del repo · los archivos pesados no se pueden quitar luego del historial · "
                    + link("como-trabajar.md", "binario-subido"),
                    ["Comprímela o redúcela de tamaño (por ejemplo con squoosh.app) hasta 1 MB o menos.",
                     "O déjala en tu Drive y usa el link."],
                    "Sustituye la imagen por una más ligera y sube el cambio.",
                )
        elif tam > LIMITE_BYTES:
            res.falla(
                "archivo-pesado", rel,
                "El archivo %s pesa %.1f MB y el límite es 1 MB." % (rel, tam / LIMITE_BYTES),
                "Media fuera del repo · los archivos pesados no se pueden quitar luego del historial · "
                + link("como-trabajar.md", "binario-subido"),
                ["Muévelo a tu carpeta de Drive y deja en el repo solo el link.",
                 "Si es texto, divídelo o resúmelo."],
                "Mueve el archivo a Drive y bórralo del repo; nunca uses --force.",
            )


# ---------------------------------------------------------------- palabras prohibidas

def cargar_hashes():
    ruta = Path(__file__).resolve().parent / "palabras-prohibidas.sha256"
    if not ruta.is_file():
        return None
    hashes = set()
    for linea in ruta.read_text(encoding="utf-8").splitlines():
        linea = linea.strip().lower()
        if linea and not linea.startswith("#"):
            hashes.add(linea)
    return hashes


def revisar_palabras(repo, res):
    hashes = cargar_hashes()
    if hashes is None:
        res.falla(
            "palabras-config", "plugins/lca425/gate/palabras-prohibidas.sha256",
            "No encontré la lista de hashes del gate junto a validar.py.",
            "Configuración del gate · sin la lista no se puede revisar el texto del repo · "
            + link("como-trabajar.md", "bloqueos"),
            ["Avísale a Daria: este fallo es de la configuración del gate, no de tu proyecto."],
            "Daria restaura el archivo en el repo del estándar.",
        )
        return
    cache = {}

    def prohibido(token):
        h = cache.get(token)
        if h is None:
            h = cache[token] = hashlib.sha256(token.encode("utf-8")).hexdigest() in hashes
        return h

    for ruta, rel in recorrer(repo):
        try:
            if ruta.stat().st_size > LIMITE_LECTURA_TEXTO:
                continue
            datos = ruta.read_bytes()
        except OSError:
            continue
        if b"\0" in datos:
            continue
        try:
            texto = datos.decode("utf-8")
        except UnicodeDecodeError:
            continue

        lineas_pal = []
        pista = None
        lineas_das = []
        for n, linea in enumerate(texto.splitlines(), 1):
            if RE_DAS.search(linea):
                lineas_das.append(n)
            for tok in set(re.split(r"[^0-9a-z]+", linea.lower())):
                if tok and prohibido(tok):
                    lineas_pal.append(n)
                    pista = tok[0] + "*" * (len(tok) - 1)
                    break
        if lineas_pal:
            res.falla(
                "palabra-prohibida", rel,
                "En %s (línea %s) hay una palabra de la lista de palabras que no van en el repo "
                "(empieza así: %s)." % (rel, ", ".join(str(x) for x in lineas_pal[:5]), pista),
                "Privacidad · nombres de clientes y de empresas reales no deben quedar en un repo ni en su "
                "historial · " + link("como-trabajar.md", "bloqueos"),
                ["Cambia esa palabra por una descripción genérica (por ejemplo, \"una empresa de pagos\").",
                 "Si es un dato de un cliente o de una empresa real, quítalo del texto.",
                 "Si crees que es un error de la lista, avísale a Daria."],
                "Edita la línea indicada y sube el cambio de nuevo.",
            )
        if lineas_das:
            res.falla(
                "codigo-das", rel,
                "En %s (línea %s) aparece un código interno con el formato DAS-número." % (
                    rel, ", ".join(str(x) for x in lineas_das[:5])),
                "Privacidad · esos códigos vienen de un sistema de seguimiento ajeno al curso y no van en tu repo · "
                + link("como-trabajar.md", "bloqueos"),
                ["Quita el código y describe la tarea con tus palabras.",
                 "Si lo copiaste de un texto que te dieron, pregúntale a Daria qué referencia usar."],
                "Edita la línea indicada y sube el cambio de nuevo.",
            )


# ---------------------------------------------------------------- cuerpo del PR

def secciones_pr(cuerpo):
    cuerpo = re.sub(r"<!--.*?-->", "", cuerpo, flags=re.DOTALL)
    secs = {}
    actual = None
    for linea in cuerpo.splitlines():
        m = re.match(r"^##\s+(.+?)\s*$", linea)
        if m:
            actual = sin_acentos(m.group(1)).lower()
            secs.setdefault(actual, [])
        elif actual is not None:
            secs[actual].append(linea)
    return {k: "\n".join(v) for k, v in secs.items()}


def casillas(texto):
    """[(marcada, etiqueta)] de las líneas `- [ ] etiqueta`."""
    salida = []
    for linea in texto.splitlines():
        m = re.match(r"^\s*[-*]\s*\[( |x|X)\]\s*(.*)$", linea)
        if m:
            salida.append((m.group(1) in "xX", m.group(2).strip()))
    return salida


def revisar_pr(cuerpo, res):
    archivo = "cuerpo del PR"
    secs = secciones_pr(cuerpo)

    def falta_seccion(nombre, regla, doc, ancla, riesgo):
        res.falla(
            regla, archivo,
            "Al cuerpo del PR le falta la sección `## %s`." % nombre,
            "%s · %s" % (riesgo, link(doc, ancla)),
            ["Usa la plantilla del PR de tu repo: aparece sola al abrir un PR nuevo.",
             "Copia la sección desde la plantilla (.github/pull_request_template.md)."],
            "Edita la descripción del PR, agrega la sección y se vuelve a revisar sola.",
        )

    # Nivel
    sec = secs.get("nivel")
    if sec is None:
        falta_seccion("Nivel", "pr-nivel", "niveles.md", "libre",
                      "Niveles · el nivel dice quién revisa tu cambio y cuándo")
    else:
        marcadas = []
        for marcada, etiqueta in casillas(sec):
            palabra = sin_acentos(etiqueta).lower()
            for nivel in ("libre", "aviso", "revision", "permiso"):
                if palabra.startswith(nivel) and marcada:
                    marcadas.append(nivel)
        if len(marcadas) != 1:
            que = ("Hay %d niveles marcados en `## Nivel` y debe haber exactamente uno." % len(marcadas)
                   if marcadas else "No hay ningún nivel marcado en `## Nivel`.")
            res.falla(
                "pr-nivel", archivo, que,
                "Niveles · el nivel dice quién revisa tu cambio y cuándo · " + link("niveles.md", "libre"),
                ["Marca solo uno: Libre, Aviso, Revisión o Permiso.",
                 "Si dudas entre dos, elige el más alto de los dos.",
                 "Si crees que es Permiso, pídeselo a Daria en un issue antes de seguir."],
                "Edita la descripción del PR para dejar una sola casilla marcada.",
            )

    # Qué cambia
    sec = secs.get("que cambia")
    if sec is None:
        falta_seccion("Qué cambia", "pr-que-cambia", "como-trabajar.md", "tu-primer-pr",
                      "Tu primer PR · quien revisa necesita saber qué cambió")
    else:
        contenido = [l.strip() for l in sec.splitlines() if l.strip()]
        if not contenido or all(es_placeholder(l) for l in contenido):
            res.falla(
                "pr-que-cambia", archivo,
                "La sección `## Qué cambia` está vacía.",
                "Tu primer PR · quien revisa necesita saber qué cambió · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Escribe una o dos oraciones con lo que agregaste o cambiaste.",
                 "Pídele a tu Claude que resuma el cambio y revisa que sea cierto."],
                "Escribe qué cambia en la descripción del PR; el gate se vuelve a correr solo.",
            )

    # Uso de IA
    sec = secs.get("uso de ia")
    if sec is None:
        falta_seccion("Uso de IA", "pr-uso-ia", "como-trabajar.md", "tu-primer-pr",
                      "Uso de IA · declarar qué hizo la IA y qué hiciste tú es parte de la evaluación")
    else:
        vacios = []
        for etiqueta, nombre in (("Hizo la IA", "Hizo la IA:"), ("Hice yo", "Hice yo:")):
            valor = None
            for linea in sec.splitlines():
                m = re.match(r"^\s*(?:[-*]\s*)?(?:\*\*)?%s:(?:\*\*)?\s*(.*)$" % re.escape(etiqueta), linea)
                if m:
                    valor = m.group(1).strip()
                    break
            if valor is None or es_placeholder(valor):
                vacios.append(nombre)
        if vacios:
            res.falla(
                "pr-uso-ia", archivo,
                "En `## Uso de IA` falta escribir: %s" % ", ".join(vacios),
                "Uso de IA · declarar qué hizo la IA y qué hiciste tú es parte de la evaluación · "
                + link("como-trabajar.md", "tu-primer-pr"),
                ["Escribe una línea en cada una, aunque sea corta.",
                 "Si la IA no hizo nada, escribe \"Nada\"; si no hiciste nada tú, es momento de hacer algo."],
                "Completa las dos líneas en la descripción del PR; el gate se vuelve a correr solo.",
            )

    # Personas reales
    sec = secs.get("personas reales")
    if sec is None:
        falta_seccion("Personas reales", "pr-personas-reales", "etica-y-derechos.md", "personas-reales",
                      "Ética y derechos · la cara o voz de alguien real necesita permiso")
    else:
        marcadas = []
        for marcada, etiqueta in casillas(sec):
            if marcada:
                marcadas.append(etiqueta)
        palabras = [sin_acentos(e).lower() for e in marcadas]
        no = [e for e, p in zip(marcadas, palabras) if re.match(r"^no\b", p)]
        si = [e for e, p in zip(marcadas, palabras) if re.match(r"^si\b", p)]
        if len(marcadas) != 1 or (not no and not si):
            res.falla(
                "pr-personas-reales", archivo,
                "En `## Personas reales` debe haber exactamente una casilla marcada: No, o Sí con su issue.",
                "Ética y derechos · la cara o voz de alguien real necesita permiso · "
                + link("etica-y-derechos.md", "personas-reales"),
                ["Marca No si solo hay objetos, paisajes o personajes inventados.",
                 "Marca Sí y escribe el número de tu issue de permiso, por ejemplo #4."],
                "Edita la descripción del PR; si marcas Sí, abre antes un issue de permiso.",
            )
        elif si and not re.search(r"#\d+", si[0]):
            res.falla(
                "pr-personas-reales", archivo,
                "Marcaste Sí en `## Personas reales`, pero no escribiste el número del issue de permiso (#N).",
                "Nivel Permiso · la cara o voz de una persona real necesita autorización antes de empezar · "
                + link("niveles.md", "permiso"),
                ["Escribe el número de tu issue de permiso, por ejemplo #4.",
                 "Si no aparece nadie real, marca No.",
                 "Pídele permiso a Daria con un issue de permiso si todavía no lo abres."],
                "Abre un issue de permiso; la receta /lca425:cierre te lo redacta.",
            )


# ---------------------------------------------------------------- orquestación

def ejecutar(repo_path, modo="alumno", pr_body=None, solo_palabras=False):
    repo = Path(repo_path).resolve()
    res = Resultado()
    if solo_palabras:
        revisar_palabras(repo, res)
        return res
    yamlc = CargadorYaml(res)
    revisar_requeridos(repo, res)
    brief = revisar_brief(repo, modo, res)
    revisar_shotlist(repo, brief, res, yamlc)
    revisar_prompts(repo, res, yamlc)
    revisar_media(repo, res)
    revisar_palabras(repo, res)
    if pr_body is not None:
        revisar_pr(pr_body, res)

    # areas
    if (repo / "00_brief.md").is_file():
        incompleto = any(es_placeholder(brief.get(c)) for c in CAMPOS_BRIEF if c != "issue_permiso")
        res.areas["brief"] = "borrador" if (res.hay_falla("brief") or incompleto or not brief) else "funciona"
    return res


def a_json(res):
    return {
        "ok": not res.fallas,
        "fallas": [{k: v for k, v in f.items() if k != "area"} for f in res.fallas],
        "avisos": res.avisos,
        "areas": res.areas,
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Gate de LCA425")
    ap.add_argument("repo_path")
    ap.add_argument("--modo", choices=("alumno", "plantilla"), default="alumno")
    ap.add_argument("--pr-body", metavar="ARCHIVO")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--solo-palabras", action="store_true",
                    help="solo revisa palabras prohibidas y códigos DAS- (para el CI del estándar)")
    args = ap.parse_args(argv)

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    if not os.path.isdir(args.repo_path):
        print("No existe la carpeta: %s" % args.repo_path, file=sys.stderr)
        return 2
    cuerpo = None
    if args.pr_body:
        try:
            with open(args.pr_body, "r", encoding="utf-8") as fh:
                cuerpo = fh.read()
        except OSError as exc:
            print("No pude leer el cuerpo del PR: %s" % exc, file=sys.stderr)
            return 2

    res = ejecutar(args.repo_path, args.modo, cuerpo, args.solo_palabras)

    if args.json:
        print(json.dumps(a_json(res), ensure_ascii=False, indent=2))
    else:
        for aviso in res.avisos:
            print("Aviso [%s] %s: %s" % (aviso["regla"], aviso["archivo"], aviso["mensaje"]))
        for f in res.fallas:
            print()
            print(formatear_falla(f))
        print()
        if res.fallas:
            print("Gate en rojo: %d cosa(s) por resolver." % len(res.fallas))
        else:
            print("Gate en verde.")
    return 1 if res.fallas else 0


if __name__ == "__main__":
    sys.exit(main())
