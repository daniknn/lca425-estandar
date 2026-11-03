#!/bin/sh
# Pruebas de los hooks: alimenta JSON a cada script y compara el código de salida.
# Uso: sh plugins/lca425/hooks/tests/run.sh
HERE=$(cd "$(dirname "$0")" && pwd)
HOOKS=$(dirname "$HERE")
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Repo temporal en main y otro en una rama de trabajo.
git init -q -b main "$TMP/enmain" && git -C "$TMP/enmain" commit -q --allow-empty -m init
git init -q -b main "$TMP/enrama" && git -C "$TMP/enrama" commit -q --allow-empty -m init
git -C "$TMP/enrama" switch -q -c feat/x

pass=0; fail=0
esperar() { # $1 nombre, $2 código esperado, $3 script, $4 json
  salida=$(printf '%s' "$4" | sh "$HOOKS/$3" 2>&1 >/dev/null); code=$?
  if [ "$code" = "$2" ]; then pass=$((pass + 1)); printf 'ok   %s (exit %s)\n' "$1" "$code"
  else fail=$((fail + 1)); printf 'FAIL %s (esperaba %s, salió %s)\n%s\n' "$1" "$2" "$code" "$salida"; fi
  ULTIMA=$salida
}
bash_json() { printf '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "$1" "$2"; }
G=proteger-git.sh

esperar "push origin main"            2 $G "$(bash_json 'git push origin main' "$TMP/enrama")"
mensaje=$ULTIMA
esperar "push origin master"          2 $G "$(bash_json 'git push origin master' "$TMP/enrama")"
esperar "push origin feat/x"          0 $G "$(bash_json 'git push origin feat/x' "$TMP/enmain")"
esperar "push -u origin brief"        0 $G "$(bash_json 'git push -u origin brief' "$TMP/enmain")"
esperar "git push desnudo en main"    2 $G "$(bash_json 'git push' "$TMP/enmain")"
esperar "git push desnudo en rama"    0 $G "$(bash_json 'git push' "$TMP/enrama")"
esperar "push origin HEAD en main"    2 $G "$(bash_json 'git push origin HEAD' "$TMP/enmain")"
esperar "push HEAD:main"              2 $G "$(bash_json 'git push origin HEAD:main' "$TMP/enrama")"
esperar "git -C repo push origin main" 2 $G "$(bash_json "git -C $TMP/enrama push origin main" "/")"
esperar "encadenado cd && push main"  2 $G "$(bash_json 'cd x && git push origin main' "$TMP/enrama")"
esperar "bash -c con push main"       2 $G "$(bash_json 'bash -c \"git push origin main\"' "$TMP/enrama")"
esperar "push --force"                2 $G "$(bash_json 'git push --force origin feat/x' "$TMP/enrama")"
esperar "push -f"                     2 $G "$(bash_json 'git push -f origin feat/x' "$TMP/enrama")"
esperar "push --force-with-lease"     2 $G "$(bash_json 'git push --force-with-lease origin feat/x' "$TMP/enrama")"
esperar "push +refspec"               2 $G "$(bash_json 'git push origin +feat/x' "$TMP/enrama")"
esperar "commit --no-verify"          2 $G "$(bash_json 'git commit --no-verify -m x' "$TMP/enrama")"
esperar "commit -n"                   2 $G "$(bash_json 'git commit -n -m x' "$TMP/enrama")"
esperar "push --no-verify"            2 $G "$(bash_json 'git push --no-verify origin feat/x' "$TMP/enrama")"
esperar "commit normal"               0 $G "$(bash_json 'git commit -m \"nuevo brief\"' "$TMP/enmain")"
esperar "ls"                          0 $G "$(bash_json 'ls -la' "$TMP/enmain")"
esperar "git status"                  0 $G "$(bash_json 'git status' "$TMP/enmain")"
esperar "entrada ilegible con git"    2 $G 'esto no es json pero dice git push'
esperar "entrada ilegible sin git"    0 $G 'basura sin relevancia'
esperar "ruta con 'git' en cwd, ls"   0 $G "$(bash_json 'ls' '/tmp/git-cosas')"

# ---------------------------------------------------------------- saldo-higgsfield.sh
S=saldo-higgsfield.sh
SRV=mcp__aaaa-bbbb
usar() { printf '%s\n' "$1" >> "$2"; }
tu() { # $1 id, $2 herramienta, $3 input JSON: una línea de transcript con una llamada MCP
  printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_%s","name":"%s__%s","input":%s}]}}\n' "$1" "$SRV" "$2" "$3"
}
BAL='{}'
QUOTE='{"params":{"model":"seedance_2_0","prompt":"x","duration":5,"get_cost":true}}'
REAL='{"params":{"model":"seedance_2_0","prompt":"x","duration":5,"get_cost":false}}'
REAL2='{"params":{"model":"seedance_2_0","prompt":"x","duration":5}}'
gen_json() { # $1 herramienta, $2 transcript_path, $3 get_cost (true|false|ninguno)
  case $3 in
    ninguno) ti='{"params":{"model":"seedance_2_0","prompt":"x"}}' ;;
    *) ti='{"params":{"model":"seedance_2_0","prompt":"x","get_cost":'$3'}}' ;;
  esac
  printf '{"session_id":"s","transcript_path":"%s","cwd":"/","hook_event_name":"PreToolUse","tool_name":"%s__%s","tool_input":%s,"tool_use_id":"toolu_actual"}' "$2" "$SRV" "$1" "$ti"
}
nuevo_tr() { : > "$TMP/$1.jsonl"; printf '%s' "$TMP/$1.jsonl"; }

# transcript sin nada relevante
T=$(nuevo_tr vacio); usar '{"type":"user","message":{"role":"user","content":"hola"}}' "$T"
# transcript con saldo pero sin cotización
T2=$(nuevo_tr soloSaldo); usar "$(tu 1 balance "$BAL")" "$T2"
# transcript con cotización pero sin saldo
T3=$(nuevo_tr soloCotiza); usar "$(tu 1 generate_video "$QUOTE")" "$T3"
# transcript con saldo y cotización
T4=$(nuevo_tr ambos); usar "$(tu 1 balance "$BAL")" "$T4"; usar "$(tu 2 generate_video "$QUOTE")" "$T4"
# lo mismo, en el otro orden
T5=$(nuevo_tr ambosAlReves); usar "$(tu 1 generate_video "$QUOTE")" "$T5"; usar "$(tu 2 balance "$BAL")" "$T5"
# ya hubo una generación real después de saldo y cotización
T6=$(nuevo_tr yaGeneroUna); cp "$T4" "$T6"; usar "$(tu 3 generate_video "$REAL")" "$T6"
# generación previa y luego saldo y cotización nuevos
T7=$(nuevo_tr generoYRepite); cp "$T6" "$T7"; usar "$(tu 4 balance "$BAL")" "$T7"; usar "$(tu 5 generate_video "$QUOTE")" "$T7"
# la llamada actual ya está escrita en el transcript (se excluye por su id)
T8=$(nuevo_tr actualYaEscrita); cp "$T4" "$T8"; usar "$(tu actual generate_video "$REAL")" "$T8"
# texto que parece saldo y cotización, pero citado (comillas escapadas): no cuenta
T9=$(nuevo_tr citado)
usar '{"type":"user","message":{"role":"user","content":"{\"type\":\"tool_use\",\"id\":\"toolu_9\",\"name\":\"mcp__aaaa-bbbb__balance\",\"input\":{}} {\"type\":\"tool_use\",\"id\":\"toolu_8\",\"name\":\"mcp__aaaa-bbbb__generate_video\",\"input\":{\"get_cost\":true}}"}}' "$T9"
# saldo, cotización y una generación sin get_cost en absoluto
T10=$(nuevo_tr sinGetCost); cp "$T4" "$T10"; usar "$(tu 3 generate_video "$REAL2")" "$T10"
# un batch real también reinicia
T11=$(nuevo_tr batchReal); cp "$T4" "$T11"; usar "$(tu 3 generate_video_batch "$REAL")" "$T11"
# dos llamadas MCP en la misma línea
T12=$(nuevo_tr mismaLinea)
usar "{\"type\":\"assistant\",\"message\":{\"role\":\"assistant\",\"content\":[{\"type\":\"tool_use\",\"id\":\"toolu_1\",\"name\":\"${SRV}__balance\",\"input\":{}},{\"type\":\"tool_use\",\"id\":\"toolu_2\",\"name\":\"${SRV}__generate_video\",\"input\":$QUOTE}]}}" "$T12"

esperar "saldo: cotización permitida"                      0 $S "$(gen_json generate_video "$T" true)"
esperar "saldo: cotización permitida aun sin transcript"   0 $S "$(gen_json generate_video "$TMP/no-existe.jsonl" true)"
esperar "saldo: generar sin saldo bloqueado"               2 $S "$(gen_json generate_video "$T" false)"
mensaje_saldo=$ULTIMA
esperar "saldo: generar sin get_cost, sin saldo, bloqueado" 2 $S "$(gen_json generate_video "$T" ninguno)"
esperar "saldo: con saldo y sin cotización bloqueado"      2 $S "$(gen_json generate_video "$T2" false)"
esperar "saldo: con cotización y sin saldo bloqueado"      2 $S "$(gen_json generate_video "$T3" false)"
esperar "saldo: con saldo y cotización permitido"          0 $S "$(gen_json generate_video "$T4" false)"
esperar "saldo: cotización y luego saldo permitido"        0 $S "$(gen_json generate_video "$T5" false)"
esperar "saldo: sin get_cost pero con saldo y cotización"  0 $S "$(gen_json generate_video "$T4" ninguno)"
esperar "saldo: segunda generación sin saldo nuevo bloqueada" 2 $S "$(gen_json generate_video "$T6" false)"
esperar "saldo: segunda generación con saldo y cotización nuevos" 0 $S "$(gen_json generate_video "$T7" false)"
esperar "saldo: llamada actual ya escrita se excluye"      0 $S "$(gen_json generate_video "$T8" false)"
esperar "saldo: texto citado no cuenta como saldo"         2 $S "$(gen_json generate_video "$T9" false)"
esperar "saldo: generación sin get_cost reinicia"          2 $S "$(gen_json generate_video "$T10" false)"
esperar "saldo: batch real reinicia"                       2 $S "$(gen_json generate_video "$T11" false)"
esperar "saldo: dos llamadas en la misma línea"            0 $S "$(gen_json generate_video "$T12" false)"
esperar "saldo: generate_image sin saldo bloqueado"        2 $S "$(gen_json generate_image "$T" false)"
esperar "saldo: generate_audio sin saldo bloqueado"        2 $S "$(gen_json generate_audio "$T" false)"
esperar "saldo: generate_video_batch sin saldo bloqueado"  2 $S "$(gen_json generate_video_batch "$T" false)"
esperar "saldo: generate_image con saldo y cotización"     0 $S "$(gen_json generate_image "$T4" false)"
esperar "saldo: transcript inexistente bloqueado"          2 $S "$(gen_json generate_video "$TMP/no-existe.jsonl" false)"
esperar "saldo: transcript_path vacío bloqueado"           2 $S "$(gen_json generate_video "" false)"
esperar "saldo: sin transcript_path bloqueado"             2 $S '{"tool_name":"mcp__aaaa-bbbb__generate_video","tool_input":{"params":{"prompt":"x"}}}'
esperar "saldo: entrada ilegible bloqueada"                2 $S 'basura que no es json'
esperar "saldo: balance no se bloquea"                     0 $S "$(printf '{"tool_name":"%s__balance","tool_input":{}}' "$SRV")"
esperar "saldo: models_explore no se bloquea"              0 $S "$(printf '{"tool_name":"%s__models_explore","tool_input":{"action":"list","type":"video"}}' "$SRV")"
esperar "saldo: otra herramienta MCP no se bloquea"        0 $S "$(printf '{"tool_name":"mcp__otro__scene_builder_3d_generate_video","tool_input":{}}')"
esperar "saldo: Bash no se bloquea"                        0 $S "$(bash_json 'ls' '/')"
# un prompt que cita "get_cost":true entre comillas escapadas no es una cotización
esperar "saldo: prompt con get_cost citado no es cotización" 2 $S "$(printf '{"transcript_path":"%s","tool_name":"%s__generate_video","tool_input":{"params":{"prompt":"pon \\"get_cost\\":true"}}}' "$T" "$SRV")"

# El mensaje de bloqueo tiene las 4 partes y el link del doc.
for parte in "Qué pasó:" "Por qué:" "Qué puedes hacer:" "Cómo destrabar:" "como-trabajar.md#tu-primer-pr"; do
  case $mensaje in *"$parte"*) pass=$((pass + 1)); printf 'ok   mensaje contiene "%s"\n' "$parte" ;;
    *) fail=$((fail + 1)); printf 'FAIL mensaje sin "%s"\n' "$parte" ;; esac
done

for parte in "Qué pasó:" "Por qué:" "Qué puedes hacer:" "Cómo destrabar:" "como-trabajar.md#creditos"; do
  case $mensaje_saldo in *"$parte"*) pass=$((pass + 1)); printf 'ok   mensaje de saldo contiene "%s"\n' "$parte" ;;
    *) fail=$((fail + 1)); printf 'FAIL mensaje de saldo sin "%s"\n' "$parte" ;; esac
done

# hooks.json: el matcher de saldo apunta al script y cubre solo generate_*.
if grep -q 'saldo-higgsfield.sh' "$HOOKS/hooks.json" && grep -q '\^mcp__\.\*__generate_(video|image|audio)(_batch)?\$' "$HOOKS/hooks.json"; then
  pass=$((pass + 1)); printf 'ok   hooks.json registra el hook de saldo con su matcher\n'
else fail=$((fail + 1)); printf 'FAIL hooks.json no registra el hook de saldo con su matcher\n'; fi

printf '\n%s ok, %s fallos\n' "$pass" "$fail"
[ "$fail" = 0 ]
