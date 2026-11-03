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

# El mensaje de bloqueo tiene las 4 partes y el link del doc.
for parte in "Qué pasó:" "Por qué:" "Qué puedes hacer:" "Cómo destrabar:" "como-trabajar.md#tu-primer-pr"; do
  case $mensaje in *"$parte"*) pass=$((pass + 1)); printf 'ok   mensaje contiene "%s"\n' "$parte" ;;
    *) fail=$((fail + 1)); printf 'FAIL mensaje sin "%s"\n' "$parte" ;; esac
done

printf '\n%s ok, %s fallos\n' "$pass" "$fail"
[ "$fail" = 0 ]
