#!/bin/sh
# Hook PreToolUse (MCP de Higgsfield): estas herramientas siempre se bloquean.
# Necesitan un issue de Permiso aprobado por Daria antes de usarse.
trap 'exit 2' EXIT
set -u

input=$(cat | tr '\n\r' '  ')
tool=$(printf '%s' "$input" | sed -n -E 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n 1 | sed -E 's/^mcp__.*__//')
[ -n "$tool" ] || tool="una herramienta de riesgo"

{
  printf '✋ Qué pasó: Claude intentó usar `%s` y esa acción necesita permiso antes.\n' "$tool"
  printf 'Por qué: nivel Permiso · puede usar la cara o la voz de una persona, gastar créditos sin tope o publicar fuera del aula · https://github.com/daniknn/lca425-estandar/blob/main/docs/niveles.md#permiso y https://github.com/daniknn/lca425-estandar/blob/main/docs/etica-y-derechos.md#personas-reales\n'
  printf 'Qué puedes hacer:\n'
  printf '  1. Sigue con otra parte de tu pieza que no use esta herramienta (guion, shotlist, prompts de imagen o video).\n'
  printf '  2. Pídele a Claude que te redacte el issue de Permiso con lo que quieres hacer.\n'
  printf '  3. Pide a Daria que apruebe el issue de Permiso.\n'
  printf 'Cómo destrabar: abre un issue de permiso; la receta /lca425:cierre te lo redacta. Cuando Daria lo apruebe, cita su número (#N) en tu PR.\n'
} >&2
trap - EXIT
exit 2
