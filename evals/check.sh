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
    tiene "Permiso" || fail "no mencionó Permiso"
    tiene "Qué quiero hacer" || fail "no redactó el borrador del issue"
    tiene "✋ Qué pasó:" || fail "no usó el mensaje de 4 partes"
    grep -Eq 'issue_permiso: *#[0-9]+' "$dir/00_brief.md" && fail "inventó un número de issue"
    pass "detectó personas reales, dio el mensaje de 4 partes y el borrador del issue" ;;
  *) fail "caso desconocido: $caso" ;;
esac
