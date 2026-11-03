#!/bin/sh
# Hook PreToolUse (herramientas MCP de Higgsfield que gastan créditos): no deja gastar créditos
# sin consultar el saldo y, cuando la herramienta se puede cotizar, sin cotizar antes. POSIX sh más awk, sin python ni jq.
# Cualquier duda o error interno sale con 2 (bloquea): falla cerrado.
#
# Regla (esquema.md, "Hook de saldo"):
#   1. Una cotización siempre pasa: tool_input con get_cost true, o ads_studio_generate sin
#      expected_credits (esa primera llamada solo cotiza y pide aprobación).
#   2. Cualquier herramienta fuera de la lista GASTO pasa.
#   3. Un gasto real pasa solo si, en el transcript y DESPUÉS del último gasto real, hay una
#      llamada a `balance` y, si la herramienta está en COTIZABLE, también una cotización
#      (get_cost true, ads_studio_quote o ads_studio_generate sin expected_credits).
#      Las herramientas que no se pueden cotizar (upscale_video, execute_preset, ...) piden solo saldo.
#   4. Si no se puede leer el transcript, bloquea.
#
# Formato del transcript que se asume (comprobado en transcripts reales de Claude Code, 2.1.x):
# un archivo JSONL, un evento JSON por línea, compacto (sin espacios tras `:` ni `,`). Cada llamada a
# una herramienta aparece en un mensaje del asistente como un bloque
#   {"type":"tool_use","id":"toolu_...","name":"mcp__<servidor>__<herramienta>","input":{...}}
# El nombre del servidor varía por cuenta (aquí es un UUID), por eso solo se compara el sufijo del
# nombre. El texto citado dentro de mensajes o resultados de herramientas llega con las comillas
# escapadas (\"type\":\"tool_use\"), así que no se confunde con una llamada real. Si el bloque de la
# llamada que se está evaluando ya está en el transcript, se excluye por su `tool_use_id` (el hook lo
# recibe en su entrada). En una prueba con Claude Code 2.1.128 el bloque todavía no estaba escrito
# cuando corrió el hook; la exclusión es una salvaguarda. Si el hook no trae el id y el bloque ya está
# escrito, la llamada cuenta como generación previa y se bloquea (falla en el lado seguro).
trap 'exit 2' EXIT
set -u

GASTO='generate_(video|image|audio|3d)(_batch)?|execute_preset|upscale_(image|video)|outpaint_image|remove_background|reframe|ads_studio_generate|ai_influencer_generate|build_ai_influencer|shorts_studio_create|scene_builder_3d_generate_(video|angles)|motion_control|dubbing|voice_change|create_voice(_from_confirmed_audio)?|apps_invoke'
COTIZABLE='generate_(video|image|audio|3d)(_batch)?|upscale_image|outpaint_image|reframe|shorts_studio_create|ads_studio_generate'

DOC="https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#creditos"
input=$(cat | tr '\n\r' '  ')

bloquear() { # $1 qué pasó, $2 cómo destrabar
  {
    printf '✋ Qué pasó: %s\n' "$1"
    printf 'Por qué: tus créditos de Higgsfield se acaban y no se reembolsan · generar sin ver saldo ni costo puede vaciarlos o pasarte de tu tope · %s\n' "$DOC"
    printf 'Qué puedes hacer:\n'
    printf '  1. Pide primero la cotización del clip (get_cost true): no gasta nada y te dice cuánto costaría.\n'
    printf '  2. Consulta tu saldo (balance) antes de generar y compara con lo que te queda de tu tope.\n'
    printf '  3. Si el costo no te alcanza, baja la duración o la resolución, o pide Permiso a Daria.\n'
    printf 'Cómo destrabar: %s\n' "$2"
  } >&2
  trap - EXIT
  exit 2
}

permitir() { trap - EXIT; exit 0; }

extraer() { # $1 clave del JSON; imprime su valor de texto sin escapes
  printf '%s' "$input" \
    | sed -n -E 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
    | head -n 1 \
    | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

nombre=$(extraer tool_name)
herr=${nombre##*__}
necesita_cot=1
if [ -n "$nombre" ]; then
  case $nombre in mcp__*) ;; *) permitir ;; esac
  printf '%s' "$herr" | grep -Eqx "$GASTO" || permitir
  printf '%s' "$herr" | grep -Eqx "$COTIZABLE" || necesita_cot=0
fi # sin nombre legible: se trata como gasto cotizable y se exige el transcript

# ads_studio_generate sin expected_credits solo cotiza y pide aprobación: no gasta.
if [ "$herr" = ads_studio_generate ] && ! printf '%s' "$input" | grep -q '"expected_credits"'; then
  permitir
fi

# Cotización: get_cost true y ningún get_cost false (en un batch, una sola generación real lo anula).
if printf '%s' "$input" | grep -Eq '"get_cost"[[:space:]]*:[[:space:]]*true' \
   && ! printf '%s' "$input" | grep -Eq '"get_cost"[[:space:]]*:[[:space:]]*false'; then
  permitir
fi

transcript=$(extraer transcript_path)
if [ -z "$transcript" ] || [ ! -f "$transcript" ] || [ ! -r "$transcript" ]; then
  bloquear "no pude comprobar que consultaste tu saldo y el costo antes de generar." \
           "pide la cotización (get_cost true) y consulta el saldo (balance) en esta sesión, y vuelve a pedir la generación."
fi

idactual=$(extraer tool_use_id)

if awk -v idactual="$idactual" -v gasto="^mcp__.*__($GASTO)$" -v necesita_cot="$necesita_cot" '
  BEGIN { bal = 0; cot = 0 }
  {
    linea = $0
    gsub(/"type":"tool_use"/, "\001&", linea)
    n = split(linea, partes, "\001")
    for (i = 2; i <= n; i++) {
      c = partes[i]
      if (idactual != "") {
        p = index(c, "\"id\":\"" idactual "\"")
        if (p > 0 && p < 40) continue
      }
      if (!match(c, /"name":"mcp__[^"]*"/)) continue
      nm = substr(c, RSTART + 8, RLENGTH - 9)
      if (nm ~ /__balance$/) {
        bal = 1
      } else if (nm ~ /__ads_studio_quote$/) {
        cot = 1
      } else if (nm ~ gasto) {
        if (c ~ /"get_cost"[ ]*:[ ]*true/ && c !~ /"get_cost"[ ]*:[ ]*false/) cot = 1
        else if (nm ~ /__ads_studio_generate$/ && c !~ /"expected_credits"/) cot = 1
        else { bal = 0; cot = 0 }
      }
    }
  }
  END { exit (bal && (cot || necesita_cot == 0)) ? 0 : 1 }
' "$transcript"; then
  permitir
fi

bloquear "intentaste gastar créditos sin consultar tu saldo (y cotizar, si la herramienta lo permite) después de tu último gasto." \
         "consulta el saldo (balance); si la herramienta acepta get_cost, pide la cotización; revisa que te alcance y vuelve a pedirlo. Se repite antes de cada gasto."
