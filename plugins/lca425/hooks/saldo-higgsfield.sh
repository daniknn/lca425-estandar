#!/bin/sh
# Hook PreToolUse (MCP generate_video|image|audio y sus _batch): no deja gastar créditos de Higgsfield
# sin consultar el saldo y cotizar antes. POSIX sh más awk, sin python ni jq.
# Cualquier duda o error interno sale con 2 (bloquea): falla cerrado.
#
# Regla (esquema.md, "Hook de saldo"):
#   1. Una cotización (tool_input con get_cost true) siempre pasa: no gasta ni envía nada.
#   2. Cualquier otra herramienta que no sea generate_* pasa.
#   3. Una generación real pasa solo si, en el transcript de la sesión y DESPUÉS de la última
#      generación real, hay una llamada a `balance` y una cotización (get_cost true).
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
case $nombre in
  mcp__*__generate_video|mcp__*__generate_image|mcp__*__generate_audio) ;;
  mcp__*__generate_video_batch|mcp__*__generate_image_batch|mcp__*__generate_audio_batch) ;;
  '') ;; # no se pudo leer el nombre: se trata como generación y se exige el transcript
  *) permitir ;;
esac

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

if awk -v idactual="$idactual" '
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
      } else if (nm ~ /__generate_(video|image|audio)(_batch)?$/) {
        if (c ~ /"get_cost"[ ]*:[ ]*true/ && c !~ /"get_cost"[ ]*:[ ]*false/) cot = 1
        else { bal = 0; cot = 0 }
      }
    }
  }
  END { exit (bal && cot) ? 0 : 1 }
' "$transcript"; then
  permitir
fi

bloquear "intentaste generar sin consultar tu saldo y cotizar el costo después de tu última generación." \
         "consulta el saldo (balance), pide la cotización con get_cost true, revisa que te alcance y vuelve a pedir la generación; esto se repite antes de cada generación."
