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
