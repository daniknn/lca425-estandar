#!/bin/sh
# Evals de las recetas brief, cierre, guion-a-shotlist y reto-en-frio. Corre cada caso N veces en modo headless,
# sobre una copia temporal de proyecto-plantilla, sin remoto (no hay push).
# Uso: sh evals/run.sh [N=5] [casos...]   (por defecto: los 8 casos)
# Variables: CLAUDE_BIN (default: claude), PLANTILLA, EJEMPLO, RESULTADOS.
# Requiere una sesión de Claude Code válida (claude auth login).
HERE=$(cd "$(dirname "$0")" && pwd)
RAIZ=$(dirname "$HERE")
CLAUDE_BIN=${CLAUDE_BIN:-claude}
PLANTILLA=${PLANTILLA:-$RAIZ/../proyecto-plantilla}
EJEMPLO=${EJEMPLO:-$RAIZ/../proyecto-ejemplo}
RESULTADOS=${RESULTADOS:-$HERE/RESULTADOS.md}
N=${1:-5}; [ $# -gt 0 ] && shift
CASOS=${*:-brief-A brief-B cierre-A cierre-B shotlist-A shotlist-B reto-A reto-B}
TMP=$(mktemp -d /private/tmp/lca425-evals.XXXXXX)

NOTA="Esta es una corrida de evaluación automática de un solo turno: no hay remoto, no hagas push ni abras PR, y si te falta información que solo la persona sabe, haz tu única pregunta y detente."

prompt() {
  case $1 in
    brief-A) printf '/lca425:brief %s Estas son todas mis respuestas, ya completas. titulo: Lo que dejó la lluvia. formato: corto. idea: Una mujer regresa a su pueblo después de diez años, descubre que la casa de su infancia se inundó y decide quedarse a reconstruirla. publico: estudiantes de 18 a 25 años que viven lejos de su familia. que_debe_lograr: que quien lo vea pueda contar con sus palabras por qué la protagonista se queda y que le escriba a alguien de su familia al terminar. fuera_de_alcance: sin diálogos hablados, sin música con derechos y sin personas reales. presupuesto_creditos: 25. personas_reales: no. drive: https://drive.google.com/drive/folders/1EvalCarpetaSana. Escribe el brief.' "$NOTA" ;;
    brief-B) printf '/lca425:brief %s Mi idea es un corto sobre una chica que vuelve a su pueblo. Lo que quiero lograr es que se vea padre.' "$NOTA" ;;
    cierre-A) printf '/lca425:cierre %s Estoy en la rama entrega y quiero cerrar mi brief. Hice yo: escribí la idea, elegí el público y definí qué debe lograr la pieza. Gasté 12 créditos de los 25 del brief. Es nivel Aviso.' "$NOTA" ;;
    cierre-B) printf '/lca425:cierre %s Estoy en la rama entrega y quiero cerrar mi brief. Hice yo: escribí la idea y el público. Gasté 5 créditos de los 10 del brief.' "$NOTA" ;;
    shotlist-A) printf '/lca425:guion-a-shotlist %s Mi brief y mi guion ya están listos en el repo. Estas son todas mis respuestas: acepto cada plano que me propongas y no quiero planos de apoyo extra; en ningún plano aparece una persona real (persona_real: no en todos); el modelo de video es Seedance 2.0 en todos. Escribe el shotlist.' "$NOTA" ;;
    shotlist-B) printf '/lca425:guion-a-shotlist %s Mi brief y mi guion ya están en el repo. Propón los planos del shotlist y escríbelos. Modelo de video: Seedance 2.0.' "$NOTA" ;;
    reto-A) printf '/lca425:reto-en-frio %s Quiero hacer el reto en frío de mi proyecto antes de entregar en Revisión.' "$NOTA" ;;
    reto-B) printf '/lca425:reto-en-frio %s Quiero hacer el reto en frío de mi proyecto. No quiero decidir uno por uno: aplica todos los cambios tú, edita mi guion y mi shotlist y dime cuando termines.' "$NOTA" ;;
  esac
}

preparar() { # $1 caso, $2 dir
  mkdir -p "$2"
  case $1 in
    shotlist-A|reto-*) (cd "$EJEMPLO" && tar --exclude=.git -cf - .) | (cd "$2" && tar -xf -) ;;
    *) (cd "$PLANTILLA" && tar --exclude=.git -cf - .) | (cd "$2" && tar -xf -) ;;
  esac
  case $1 in
    shotlist-A) rm -f "$2/03_shotlist/shotlist.yaml" ;;
    shotlist-B) cp "$HERE/fixtures/brief-sano.md" "$2/00_brief.md"; cp "$HERE/fixtures/guion-prima.md" "$2/02_guion/guion.md" ;;
    cierre-A) cp "$HERE/fixtures/brief-sano.md" "$2/00_brief.md" ;;
    cierre-B) cp "$HERE/fixtures/brief-personas.md" "$2/00_brief.md" ;;
  esac
  git init -q -b main "$2"
  git -C "$2" add -A
  git -C "$2" -c user.name=eval -c user.email=eval@example.com commit -q -m "plantilla"
  case $1 in
    cierre-*) git -C "$2" switch -q -c entrega ;;
  esac
}

: > "$TMP/filas"
for caso in $CASOS; do
  i=1; ok=0
  while [ "$i" -le "$N" ]; do
    d="$TMP/$caso-$i/proyecto"; o="$TMP/$caso-$i/salida.txt"
    preparar "$caso" "$d"
    case $caso in
      reto-*) herr="Bash Write Edit Read Skill Agent Task"; tope=5; fmt="--output-format stream-json --verbose" ;;
      *) herr="Bash Write Edit Read Skill"; tope=2; fmt="" ;;
    esac
    # shellcheck disable=SC2086
    ( cd "$d" && "$CLAUDE_BIN" -p "$(prompt "$caso")" --plugin-dir "$RAIZ/plugins/lca425" \
        --no-session-persistence --max-budget-usd "$tope" $fmt \
        --allowedTools "$herr" ) > "$o" 2>&1
    if grep -q 'Failed to authenticate' "$o"; then
      res="error: $(head -c 120 "$o" | tr '\n' ' ')"
    else
      res=$(sh "$HERE/check.sh" "$caso" "$d" "$o")
    fi
    case $res in pass*) ok=$((ok + 1)) ;; esac
    printf '| %s | %s | %s | %s |\n' "$caso" "$i" "${res%%:*}" "${res#*: }" >> "$TMP/filas"
    i=$((i + 1))
  done
  printf '| **%s** | total | **%s/%s** | umbral 4/5: %s |\n' "$caso" "$ok" "$N" "$([ $((ok * 5)) -ge $((N * 4)) ] && echo cumple || echo NO cumple)" >> "$TMP/filas"
done

{
  echo "# Resultados de evals"
  echo
  echo "Corrida: $(date '+%Y-%m-%d %H:%M'), cliente: $($CLAUDE_BIN --version 2>/dev/null | head -n 1). Salidas completas en $TMP."
  echo
  echo "| Caso | Corrida | Resultado | Razón |"
  echo "|---|---|---|---|"
  cat "$TMP/filas"
} > "$RESULTADOS"
cat "$RESULTADOS"
