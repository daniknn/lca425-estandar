"""Pruebas del workflow reutilizable del gate.

Un repo nuevo solo le presta a GITHUB_TOKEN el permiso `contents: read`. Si el workflow
reutilizable pide algo más, GitHub ni siquiera lo arranca (startup_failure) en el repo
del alumno. Esta prueba lo atrapa antes de publicar.
"""
import os
import re
import unittest

AQUI = os.path.dirname(os.path.abspath(__file__))
GATE_YML = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "..", ".github", "workflows", "gate.yml"))
PERMITIDOS = {"contents": "read"}


def bloque_permissions(texto):
    m = re.search(r"^permissions:\n((?:[ \t]+\S.*\n)+)", texto, re.M)
    if not m:
        return {}
    pares = re.findall(r"^[ \t]+([\w-]+):\s*(\S+)", m.group(1), re.M)
    return dict(pares)


class TestWorkflowGate(unittest.TestCase):
    def test_existe(self):
        self.assertTrue(os.path.isfile(GATE_YML), GATE_YML)

    def test_solo_pide_contents_read(self):
        with open(GATE_YML, encoding="utf-8") as f:
            permisos = bloque_permissions(f.read())
        self.assertEqual(permisos, PERMITIDOS,
                         "El gate solo puede pedir contents: read; otro permiso rompe el arranque en repos de alumnos.")

    def test_es_reutilizable(self):
        with open(GATE_YML, encoding="utf-8") as f:
            self.assertIn("workflow_call:", f.read())


if __name__ == "__main__":
    unittest.main()
