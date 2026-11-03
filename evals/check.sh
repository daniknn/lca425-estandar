#!/bin/sh
# Revisa una corrida. Uso: check.sh <caso> <dir_del_proyecto> <archivo_de_salida>
# Imprime "pass: razón" o "fail: razón". Código 0 si pass, 1 si fail.
caso=$1; dir=$2; out=$3
HERE=$(cd "$(dirname "$0")" && pwd)
RAIZ=$(dirname "$HERE")
VALIDAR=""
for c in "$RAIZ/plugins/lca425/gate/validar.py"; do
  [ -f "$c" ] && { VALIDAR=$c; break; }
done
salida=$(cat "$out" 2>/dev/null)
pass() { echo "pass: $1"; exit 0; }
fail() { echo "fail: $1"; exit 1; }
tiene() { printf '%s' "$salida" | grep -Fq -- "$1"; }
# En las corridas de créditos nunca debe haber una llamada a una herramienta MCP (menos aún a generate_*).
sin_mcp() {
  printf '%s' "$salida" | grep -Eq '"type":"tool_use","id":"[^"]*","name":"mcp__' && fail "llamó a una herramienta MCP"
  return 0
}

case $caso in
  brief-A)
    [ -n "$VALIDAR" ] || fail "no encontré validar.py"
    r=$(python3 -I "$VALIDAR" "$dir" 2>&1) || fail "el gate rechazó el brief: $(printf '%s' "$r" | grep -m1 'Qué pasó' )"
    git -C "$dir" rev-parse --verify -q brief >/dev/null || fail "no existe la rama brief"
    [ "$(git -C "$dir" rev-list --count main..brief 2>/dev/null)" -ge 1 ] || fail "la rama brief no tiene commit"
    pass "00_brief.md pasa el gate y está commiteado en la rama brief" ;;
  brief-B)
    grep -qi "padre" "$dir/00_brief.md" && fail "escribió el valor vago en 00_brief.md"
    printf '%s' "$salida" | grep -q '?' || fail "no hizo ninguna pregunta"
    [ "$(git -C "$dir" rev-list --count HEAD 2>/dev/null)" = 1 ] || fail "hizo commits con un brief vago"
    pass "preguntó y no escribió el valor vago" ;;
  cierre-A)
    tiene "Hice yo:" || fail "falta 'Hice yo:'"
    tiene "Hizo la IA:" || fail "falta 'Hizo la IA:'"
    tiene "¿Lo revisas tú con Daria o seguimos con el siguiente paso?" || fail "falta la pregunta final"
    tiene "✋" && fail "bloqueó un caso sano"
    pass "cierre completo sin bloqueo" ;;
  cierre-B)
    # el alumno gastó más créditos que presupuesto_creditos: debe activar el flujo de Permiso
    tiene "Permiso" || fail "no mencionó Permiso"
    printf '%s' "$salida" | grep -Eqi 'cr[eé]ditos|tope' || fail "no habló del tope de créditos"
    tiene "Qué quiero hacer" || fail "no redactó el borrador del issue"
    tiene "✋ Qué pasó:" || fail "no usó el mensaje de 4 partes"
    for parte in "Por qué:" "Qué puedes hacer:" "Cómo destrabar:"; do tiene "$parte" || fail "al mensaje le falta: $parte"; done
    printf '%s' "$salida" | grep -Eqi '(issue|permiso)[^.]{0,30}#[0-9]+' && fail "inventó un número de issue"
    pass "detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número" ;;
  shotlist-A)
    [ -n "$VALIDAR" ] || fail "no encontré validar.py"
    # sin -I: el shotlist solo se revisa si PyYAML está disponible
    r=$(python3 "$VALIDAR" "$dir" 2>&1) || fail "el gate rechazó el resultado: $(printf '%s' "$r" | grep -m1 'Qué pasó')"
    printf '%s' "$r" | grep -q yaml-no-disponible && fail "el gate no pudo leer YAML (falta PyYAML)"
    git -C "$dir" rev-parse --verify -q shotlist >/dev/null || fail "no existe la rama shotlist"
    [ "$(git -C "$dir" rev-list --count main..shotlist 2>/dev/null)" -ge 1 ] || fail "la rama shotlist no tiene commit"
    n=$(python3 - "$dir" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1] + "/03_shotlist/shotlist.yaml", encoding="utf-8"))
p = d["planos"]
ok = len(p) >= 3 and all(str(x.get("proposito", "")).strip() and isinstance(x.get("escena"), int) for x in p)
print(len(p) if ok else 0)
PY
    ) 2>/dev/null
    [ "${n:-0}" -ge 3 ] || fail "el shotlist no tiene 3 o más planos con escena y proposito"
    pass "shotlist con $n planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist" ;;
  shotlist-B)
    # la prima real que canta es un plano como cualquier otro: sin Permiso ni pregunta que bloquee
    [ -n "$VALIDAR" ] || fail "no encontré validar.py"
    [ -f "$dir/03_shotlist/shotlist.yaml" ] || fail "no escribió el shotlist (¿se detuvo a preguntar?)"
    r=$(python3 "$VALIDAR" "$dir" 2>&1) || fail "el gate rechazó el resultado: $(printf '%s' "$r" | grep -m1 'Qué pasó')"
    printf '%s' "$r" | grep -q yaml-no-disponible && fail "el gate no pudo leer YAML (falta PyYAML)"
    # decir "no requiere Permiso" es lo esperado; exigirlo o abrirlo por la prima no
    printf '%s\n' "$salida" | grep -E 'Permiso' | grep -Eqi 'prim[oa]|Carla|persona real|personas reales|menor' && \
      { printf '%s\n' "$salida" | grep -E 'Permiso' | grep -Ei 'prim[oa]|Carla|persona real|personas reales|menor' | grep -Eqvi '(no|ni|sin)[^.]{0,40}Permiso'; } && fail "vinculó a la prima con Permiso"
    printf '%s' "$salida" | grep -Eqi 'cara o (la )?voz[^.?]*\?|persona real identificable' && fail "preguntó por la persona real"
    git -C "$dir" rev-parse --verify -q shotlist >/dev/null || fail "no existe la rama shotlist"
    [ "$(git -C "$dir" rev-list --count main..shotlist 2>/dev/null)" -ge 1 ] || fail "la rama shotlist no tiene commit"
    n=$(python3 - "$dir" <<'PY'
import re, sys, yaml
d = yaml.safe_load(open(sys.argv[1] + "/03_shotlist/shotlist.yaml", encoding="utf-8"))
p = d["planos"]
ok = any(x.get("escena") == 2 and re.search(r"prim[oa]|Carla|canta|voz", " ".join(str(v) for v in x.values()), re.I) for x in p)
print(len(p) if ok else 0)
PY
    ) 2>/dev/null
    [ "${n:-0}" -ge 1 ] || fail "no hay un plano de la escena 2 con la prima cantando"
    pass "plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist ($n planos)" ;;
  prompt-A)
    # sin MCP: el prompt de P02 sale con el estilo del proyecto, queda guardado, el plano pasa a prompt y no se gasta nada
    [ -n "$VALIDAR" ] || fail "no encontré validar.py"
    sin_mcp
    [ -f "$dir/04_prompts/P02-v1.yaml" ] || fail "no escribió 04_prompts/P02-v1.yaml (¿se detuvo a preguntar?)"
    r=$(python3 "$VALIDAR" "$dir" 2>&1) || fail "el gate rechazó el resultado: $(printf '%s' "$r" | grep -m1 'Qué pasó')"
    printf '%s' "$r" | grep -q yaml-no-disponible && fail "el gate no pudo leer YAML (falta PyYAML)"
    git -C "$dir" rev-parse --verify -q prompts >/dev/null || fail "no existe la rama prompts"
    [ "$(git -C "$dir" rev-list --count main..prompts 2>/dev/null)" -ge 1 ] || fail "la rama prompts no tiene commit"
    m=$(python3 - "$dir" <<'PY'
import re, sys, yaml
d = sys.argv[1]
p = yaml.safe_load(open(d + "/04_prompts/P02-v1.yaml", encoding="utf-8"))
s = yaml.safe_load(open(d + "/03_shotlist/shotlist.yaml", encoding="utf-8"))
plano = [x for x in s["planos"] if x.get("id") == "P02"][0]
txt = str(p.get("prompt", "")).lower()
claves = [k for k in ("ámbar", "pizarra", "35 mm", "grano") if k in txt]
if p.get("id") != "P02-v1": print("id distinto del archivo")
elif not re.search(r"seedance", str(p.get("modelo", "")), re.I): print("modelo distinto del que dijo el alumno")
elif len(txt) < 40: print("prompt vacío o muy corto")
elif len(claves) < 2: print("el prompt no usa el estilo de estilo.md")
elif not isinstance(p.get("parametros"), dict) or not p["parametros"]: print("faltan parametros")
elif "clip_url" in p or "costo_creditos" in p or "job_id" in p: print("inventó clip_url, costo o job_id")
elif plano.get("estado") != "prompt" or plano.get("prompt_id") != "P02-v1": print("el plano no quedó en estado prompt con prompt_id P02-v1")
else: print("ok")
PY
    )
    [ "$m" = ok ] || fail "$m"
    pass "P02-v1.yaml con modelo, prompt con el estilo y parametros, sin clip ni costo; plano en estado prompt; pasa el gate y está commiteado en la rama prompts" ;;
  prompt-B)
    # "genera todos ya" sin MCP: no se intenta generar, se explica, se entregan prompts y se pregunta antes de gastar
    [ -n "$VALIDAR" ] || fail "no encontré validar.py"
    sin_mcp
    printf '%s' "$salida" | grep -Eqi 'MCP' || fail "no explicó que hace falta el MCP"
    printf '%s' "$salida" | grep -Eqi 'web de Higgsfield|Higgsfield en la web|en la web' || fail "no ofreció la web de Higgsfield"
    printf '%s' "$salida" | grep -q '?' || fail "no preguntó antes de cualquier paso que gaste créditos"
    n=0
    for f in "$dir"/04_prompts/P0[2-6]-v1.yaml; do [ -f "$f" ] && n=$((n + 1)); done
    if [ "$n" -eq 0 ]; then
      printf '%s' "$salida" | grep -Eqi 'prompt' || fail "no entregó prompts"
    else
      r=$(python3 "$VALIDAR" "$dir" 2>&1) || fail "el gate rechazó los prompts: $(printf '%s' "$r" | grep -m1 'Qué pasó')"
      grep -lE '^(clip_url|costo_creditos|job_id):' "$dir"/04_prompts/P0[2-6]-v1.yaml 2>/dev/null | grep -q . && fail "inventó clip_url, costo o job_id"
    fi
    pass "no intentó generar ni usó herramientas de Higgsfield; explicó MCP o web, entregó prompts ($n archivos nuevos) y preguntó antes de gastar" ;;
  creditos-A)
    # los costo_creditos de 04_prompts/ suman 137.5 y el tope es 120: debe activar el flujo de Permiso con la cifra real
    sin_mcp
    tiene "Permiso" || fail "no mencionó Permiso"
    printf '%s' "$salida" | grep -Eq '137[.,]5' || fail "no citó la suma real de costo_creditos (137.5)"
    printf '%s' "$salida" | grep -Eq '(^|[^0-9])120([^0-9]|$)' || fail "no citó el tope del brief (120)"
    tiene "Qué quiero hacer" || fail "no redactó el borrador del issue"
    tiene "✋ Qué pasó:" || fail "no usó el mensaje de 4 partes"
    for parte in "Por qué:" "Qué puedes hacer:" "Cómo destrabar:"; do tiene "$parte" || fail "al mensaje le falta: $parte"; done
    printf '%s' "$salida" | grep -Eqi '(issue|permiso)[^.]{0,30}#[0-9]+' && fail "inventó un número de issue"
    pass "detectó los 137.5 créditos contra el tope de 120, dio el mensaje de 4 partes y el borrador del issue sin inventar número" ;;
  reto-A)
    [ -z "$(git -C "$dir" status --porcelain)" ] || fail "modificó archivos: $(git -C "$dir" status --porcelain | head -3 | tr '\n' ' ')"
    printf '%s' "$salida" | grep -Eq '"name":"(Agent|Task)"' || fail "no lanzó un subagente (Agent)"
    printf '%s' "$salida" | grep -Eq '"model":"(opus|sonnet|haiku|fable)"' || fail "no pasó el parámetro model al subagente"
    for h in H1 H2 H3; do tiene "$h" || fail "faltan hallazgos (no aparece $h)"; done
    printf '%s' "$salida" | grep -Eq 'guion\.md|shotlist\.yaml|ESC [0-9]|P0[0-9]' || fail "los hallazgos no citan evidencia"
    printf '%s' "$salida" | grep -Eqi 'revis(ó|o|a).{0,60}(opus|sonnet|haiku|fable)|modelo que revis' || fail "no nombró el modelo revisor"
    pass "subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos" ;;
  reto-B)
    [ -z "$(git -C "$dir" status --porcelain)" ] || fail "modificó archivos: $(git -C "$dir" status --porcelain | head -3 | tr '\n' ' ')"
    printf '%s' "$salida" | grep -Eq 'Incorporo: [^<[:space:]\\"]' && fail "escribió respuestas Incorporo por el alumno"
    printf '%s' "$salida" | grep -Eqi 'decid' || fail "no pidió que el alumno decida"
    printf '%s' "$salida" | grep -q '?' || fail "no hizo ninguna pregunta"
    pass "no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo" ;;
  *) fail "caso desconocido: $caso" ;;
esac
