#!/bin/sh
# Hook PreToolUse (Bash): bloquea push a main/master, --force y --no-verify.
# POSIX sh, sin python ni jq. Cualquier duda o error interno sale con 2 (bloquea).
trap 'exit 2' EXIT
set -u

DOC="https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#tu-primer-pr"
input=$(cat | tr '\n\r' '  ')

bloquear() { # $1 qué pasó, $2 por qué, $3 cómo destrabar
  {
    printf '✋ Qué pasó: %s\n' "$1"
    printf 'Por qué: %s · %s\n' "$2" "$DOC"
    printf 'Qué puedes hacer:\n'
    printf '  1. Crea una rama (por ejemplo `git switch -c mi-cambio`), súbela y abre un PR.\n'
    printf '  2. Pídele a Claude: "crea una rama y abre un PR con mis cambios".\n'
    printf '  3. Si no tienes claro cómo seguir, pregunta a Daria.\n'
    printf 'Cómo destrabar: %s\n' "$3"
  } >&2
  trap - EXIT
  exit 2
}

permitir() { trap - EXIT; exit 0; }

extraer() { # $1 clave del JSON; imprime su valor sin escapes
  printf '%s' "$input" \
    | sed -n -E 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
    | head -n 1 \
    | sed -e 's/\\"/"/g' -e 's/\\[nrt]/ /g' -e 's/\\\\/\\/g'
}

cmd=$(extraer command)
cwd=$(extraer cwd)

if [ -z "$cmd" ]; then
  case $input in
    *git*) bloquear "no pude leer el comando de git que intentabas correr." \
             "regla de seguridad: si no puedo verificar un comando de git, no lo dejo pasar" \
             "pide el mismo cambio otra vez con un comando más simple, o pregunta a Daria." ;;
  esac
  permitir
fi

rama_actual() { # $1 directorio opcional (de git -C)
  d=${1:-}
  case $d in
    '') d=${cwd:-.} ;;
    /*) ;;
    *) d="${cwd:-.}/$d" ;;
  esac
  git -C "$d" symbolic-ref --short -q HEAD 2>/dev/null || true
}

es_principal() { case $1 in main|master|refs/heads/main|refs/heads/master) return 0 ;; esac; return 1; }

segmentos=$(printf '%s\n' "$cmd" | tr ';&|' '\n\n\n' | tr -d "\"'\`()")

set -f
while IFS= read -r seg; do
  set -- $seg
  while [ $# -gt 0 ]; do
    case $1 in git|*/git) break ;; esac
    shift
  done
  [ $# -gt 0 ] || continue
  shift
  gdir=""
  while [ $# -gt 0 ]; do
    case $1 in
      -C) shift; gdir=${1:-}; [ $# -gt 0 ] && shift ;;
      -c|--git-dir|--work-tree|--namespace) shift; [ $# -gt 0 ] && shift ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  sub=${1:-}
  [ $# -gt 0 ] && shift

  for t in "$@"; do
    case $t in
      --no-verify) bloquear "intentaste saltarte las revisiones locales con --no-verify." \
                     "regla del curso: las revisiones antes de subir no se omiten · protegen que el gate no falle después" \
                     "quita la bandera y corre el comando normal; si una revisión te estorba, cuéntale a Daria cuál." ;;
    esac
  done
  if [ "$sub" = commit ]; then
    for t in "$@"; do
      case $t in
        --*) ;;
        -*n*) bloquear "intentaste saltarte las revisiones locales con -n." \
                "regla del curso: las revisiones antes de subir no se omiten · protegen que el gate no falle después" \
                "quita la bandera y corre el comando normal; si una revisión te estorba, cuéntale a Daria cuál." ;;
      esac
    done
  fi

  [ "$sub" = push ] || continue

  npos=0
  for t in "$@"; do
    case $t in
      --force|--force-with-lease*|--force-if-includes|+*) bloquear "intentaste un push forzado." \
          "regla del curso: nunca se fuerza un push · puede borrar el trabajo de otras personas" \
          "haz un push normal desde una rama; si el push normal falla, copia el mensaje y pregunta a Daria." ;;
      --all|--mirror) bloquear "intentaste subir todas las ramas, incluida main." \
          "regla del curso: main solo recibe cambios por PR · un push directo se salta el gate y la revisión" \
          "sube solo tu rama, por nombre, y abre un PR." ;;
      --*) ;;
      -*f*) bloquear "intentaste un push forzado (-f)." \
          "regla del curso: nunca se fuerza un push · puede borrar el trabajo de otras personas" \
          "haz un push normal desde una rama; si el push normal falla, copia el mensaje y pregunta a Daria." ;;
      -*) ;;
      *) npos=$((npos + 1))
         if [ "$npos" -ge 2 ]; then
           dst=${t##*:}
           [ "$dst" = HEAD ] && dst=$(rama_actual "$gdir")
           if es_principal "$dst"; then
             bloquear "intentaste hacer push directo a main." \
               "regla del curso: main solo recibe cambios por PR · un push directo se salta el gate y la revisión de Daria" \
               "no empujes a main: trabaja en una rama y abre un PR."
           fi
         fi ;;
    esac
  done

  if [ "$npos" -le 1 ]; then
    if es_principal "$(rama_actual "$gdir")"; then
      bloquear "estás en main y un git push subiría tus cambios directo a main." \
        "regla del curso: main solo recibe cambios por PR · un push directo se salta el gate y la revisión de Daria" \
        "cambia a una rama con tus cambios (git switch -c mi-cambio), súbela y abre un PR."
    fi
  fi
done <<EOF2
$segmentos
EOF2

permitir
