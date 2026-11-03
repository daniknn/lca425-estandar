---
name: guion-a-shotlist
description: Ayuda al alumno a escribir su guion escena por escena y a convertirlo en un shotlist (03_shotlist/shotlist.yaml) con escena y propósito por plano, lo valida con el gate y abre el PR. Úsalo cuando el alumno diga "ayúdame con mi guion", "pasa mi guion a shotlist", "armar el shotlist", "qué planos necesito", "ya tengo el brief, sigue el guion", o cuando 02_guion/guion.md no exista o esté vacío. Use when a student wants to write a script and turn it into a shot list in the LCA425 course.
---

# Receta guion-a-shotlist

Objetivo: que el alumno salga con un `02_guion/guion.md` en el formato del curso, un `03_shotlist/shotlist.yaml` donde cada plano tiene escena y propósito, un PR abierto y claridad sobre qué sigue. El guion y las decisiones sobre los planos son del alumno: tú preguntas, ordenas, formateas y propones; no decides. El criterio final lo da el gate.

## Cómo te comportas (tutor, no formulario)

- Pregunta antes de explicar. Una pregunta por turno. Si hay herramienta de preguntas (AskUserQuestion), úsala con opciones cortas; si no, pregunta en texto.
- Si el alumno ya dio respuestas en su mensaje, no las repitas: mapea lo que dio y pregunta solo lo que falta.
- Ofrece al inicio el modo rápido: "Si prefieres, dime 'solo dime qué sigue' y te voy diciendo el siguiente paso sin explicaciones." En modo rápido: una línea con lo siguiente, sin teoría.
- Nunca inventes datos ni contenido del alumno (escenas, personajes, diálogos, modelo de video, links, créditos). Una propuesta tuya va marcada como "sugerencia" y solo se escribe si el alumno la acepta.
- Tono: español de México, de tú, cálido y breve. Sin regaños.
- Que en la pieza salga alguien real (un familiar, un compañero, un menor) no cambia nada: no es tema sensible, así que no pidas consentimiento, no preguntes por esa persona ni abras Permiso por eso. Tema sensible es el asunto de la historia que podría lastimar, como violencia, salud o una tragedia.
- Clasifica el cambio y dilo en voz alta: "esto es nivel Aviso: mergeas con el gate en verde y Daria lo revisa la clase siguiente".

## Formatos (fuente: `esquema.md` del curso)

Guion, `02_guion/guion.md`. Cada escena empieza con un encabezado de nivel 2:

```
## ESC 1 · EXT. PARADA DE AUTOBÚS · AMANECER
Acción en presente, en párrafos cortos.
NOMBRE: diálogo, si lo hay.
```

`## ESC <N> · <INT.|EXT.|INT./EXT.> <LUGAR> · <MOMENTO>`, con `N` consecutivo desde 1, sin repetidos.

Shotlist, `03_shotlist/shotlist.yaml`:

```yaml
planos:
  - id: P01            # P + 2 dígitos, único
    escena: 1          # número de una escena que existe en guion.md
    proposito: ...     # para qué sirve el plano respecto de que_debe_lograr del brief; no vacío
    descripcion: ...
    duracion_s: 4      # número mayor que 0
    camara: ...        # movimiento o encuadre
    modelo: ...        # modelo de video en Higgsfield, como lo dice el alumno
    estado: idea       # los planos nuevos empiezan en idea
```

Lo que el gate exige hoy en cada plano, aun en estado `idea`: `descripcion`, `camara`, `modelo`, `duracion_s`, `proposito`, `estado` y, si hay guion, `escena`. `prompt_id` y `clip_url` solo se piden en estados posteriores, así que en `idea` no se escriben.

## Pasos

1. **Lee** `00_brief.md` y el `AGENTS.md` del repo. Si el brief tiene campos vacíos o `TODO`, para: "primero el brief" y ofrece `/lca425:brief`. Guarda `que_debe_lograr`, `fuera_de_alcance` y `presupuesto_creditos`. Lee `02_guion/guion.md` y `03_shotlist/shotlist.yaml` si existen.
2. **Guion.** Si `02_guion/guion.md` no existe o está vacío, ayuda a escribirlo escena por escena, con las palabras del alumno:
   - Pregunta una escena a la vez: "¿Qué pasa en la primera escena? Cuéntamela como se la contarías a un amigo."
   - Con su respuesta, tú ordenas y formateas: encabezado `## ESC N · ...` y acción en presente. Si falta el lugar o el momento, pregúntalo; no lo inventes. No agregues acciones, objetos ni diálogos que el alumno no dijo. Muéstrale la escena y pregunta si así la quiere antes de pasar a la siguiente.
   - Cierra con "¿Hay otra escena o ya está el guion?".
   - Si el guion ya existe, revisa que los encabezados sigan el formato; si no, ofrece corregir solo los encabezados.
3. **Propón planos.** Escena por escena, propón planos con `escena`, `proposito` (enlazado a `que_debe_lograr` del brief, en una frase), `descripcion`, `duracion_s` y `camara`. Todo va marcado como sugerencia. Para cada plano pregunta, uno por turno, si lo aceptas, lo cambias o lo quitas.
4. **Huecos de cobertura.** Al terminar, señala escenas sin plano o momentos donde ayudaría un plano de apoyo (B-roll, inserto, plano de reacción de un objeto). Son sugerencias: el alumno acepta o rechaza cada una. No las agregues sin su sí.
5. **Modelo.** El gate pide `modelo` en todos los planos. Pregunta una vez: "¿Con qué modelo de video de Higgsfield piensas generar estos planos? Dime el nombre como aparece en la herramienta." Escribe lo que diga. Si todavía no decide, escribe `por decidir` solo con su OK. No propongas ni escribas un nombre de modelo que el alumno no dijo.
6. **Estado.** Todos los planos nuevos empiezan en `estado: idea`. No pongas `prompt_id` ni `clip_url`.
7. **Muestra** el guion y el shotlist completos en pantalla y pregunta si los escribes.
8. **Rama.** `git fetch` (si hay remoto), luego `git switch -c shotlist` (si ya existe, pregunta qué prefiere). Nunca trabajes sobre `main`.
9. **Escribe** `02_guion/guion.md` y `03_shotlist/shotlist.yaml`. Conserva lo que el alumno ya tenía y no borres planos existentes sin que lo pida. Los ids siguen la numeración: P01, P02, ...
10. **Gate.** Si hay `python3`, localiza `validar.py` con:
    `find ~/.claude/plugins/cache -path '*lca425*/gate/validar.py' 2>/dev/null | head -1`
    y, si no aparece, prueba `${CLAUDE_PLUGIN_ROOT}/gate/validar.py`. Ejecuta `python3 <ruta> .` en la raíz del repo y muestra la salida. Si falla, explica el mensaje de 4 partes con tus palabras, corrige lo que sea del guion o del shotlist (preguntando si falta un dato) y vuelve a correr. No lo esquives ni lo edites. Si no hay `python3` o no encuentras `validar.py`, dilo: "la revisión correrá en GitHub cuando abras el PR".
11. **Commit** con Conventional Commits: `git add 02_guion/guion.md 03_shotlist/shotlist.yaml && git commit -m "docs: guion y shotlist de <titulo>"`.
12. **Push.** Si hay remoto: `git push -u origin shotlist`. Guarda el link que imprime GitHub.
13. **Hice yo.** Pregunta con una sola pregunta: "¿Qué hiciste tú en este paso? Dímelo con tus palabras." Nunca lo escribas por el alumno ni lo adivines.
14. **PR.** Llena `.github/pull_request_template.md`:
    - `## Nivel`: Aviso (o Permiso si aplica: tema sensible, tope de créditos o publicar fuera del aula).
    - `## Qué cambia`: una o dos líneas sobre el guion y el shotlist.
    - `## Uso de IA`: `Hizo la IA:` lo que sí hiciste en la sesión (preguntar, ordenar el guion, proponer planos, correr el gate) y `Hice yo:` lo que dijo el alumno.
    - `## Reto en frío`: déjala vacía o con `No aplica` (solo se exige en nivel Revisión).
    Escribe el cuerpo en un archivo temporal y usa `gh pr create --base main --head shotlist --title "docs: guion y shotlist" --body-file <archivo>`. Si `gh` no está autenticado (`gh auth status` falla), entrega el link que imprimió GitHub y el texto del PR para pegar.
15. **Cierra** con una sola pregunta: "¿Quieres que le hagamos el reto en frío a esto con otro modelo, o prefieres que Daria revise primero?"

## Corridas de prueba (evals)

Si el mensaje dice que es una corrida de evaluación o no hay remoto configurado: haz todo hasta el commit local, no hagas push ni abras PR, y di que los omitiste por eso. En una corrida de un solo turno, si falta información que solo el alumno sabe, haz tu única pregunta y detente sin escribir archivos de planos.

## Bloqueos

Si un hook o el gate bloquea algo, no busques otro comando para lograr lo mismo. Lee el mensaje de 4 partes, explícalo con tus palabras y ofrece sus opciones. Si el alumno ya tiene que abrir un Permiso, redacta el issue.
