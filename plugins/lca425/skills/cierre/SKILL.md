---
name: cierre
description: Ritual de cierre antes de abrir o actualizar un PR de entrega en LCA425. Corre el gate, arma un plan de pruebas para Daria, revisa tope de créditos, registra "Hizo la IA / Hice yo" y llena el PR. Úsalo cuando el alumno diga "cierre", "voy a entregar", "listo para el PR", "revisa antes de entregar", "abre el PR", o cuando se bloquee algo y necesite el mensaje o el issue de Permiso. Use when a student is about to deliver a piece or open a PR in the LCA425 course.
---

# Receta cierre

Objetivo: que el PR llegue a Daria con evidencia, honesto y completo, y que el alumno sepa qué entrega y qué hizo cada quien. La confianza solo cuenta junto a la salida del gate.

## Cómo te comportas

- Pregunta antes de explicar. Una pregunta por turno (herramienta de preguntas si existe, si no, texto). Modo rápido: si el alumno dice "solo dime qué sigue", responde con una línea por paso.
- No inventes datos del alumno: ni qué hizo él o ella, ni créditos gastados, ni links. Lo que no sabes, lo preguntas.
- Español de México, de tú, breve y sin regaños. Honestidad primero: si algo falló o no se hizo, se dice con la salida.
- Que en la pieza salga alguien real (un familiar, un compañero, un menor) no cambia nada: no es tema sensible, así que no pidas consentimiento, no preguntes por esa persona ni abras Permiso por eso. Tema sensible es el asunto de la historia que podría lastimar, como violencia, salud o una tragedia.

## Pasos

1. **Estado.** Revisa la rama (`git branch --show-current`; si es `main`, para y propón crear una rama) y `git status`. Lee `00_brief.md` y el `AGENTS.md` del repo.
2. **Gate.** Si hay `python3`, localiza `validar.py` con
   `find ~/.claude/plugins/cache -path '*lca425*/gate/validar.py' 2>/dev/null | head -1`
   (alternativa: `${CLAUDE_PLUGIN_ROOT}/gate/validar.py`) y corre `python3 <ruta> .`. Muestra la salida tal cual, verde o roja. Si falla, explica cada mensaje con tus palabras y corrige lo que sea tuyo; no edites el gate ni lo esquives. Sin `python3` o sin `validar.py`, dilo: la revisión correrá en GitHub.
3. **Plan de pruebas para Daria.** Máximo 5 líneas: qué archivos mirar, qué debería ver en cada uno y qué comprobar a mano (por ejemplo "abrir el brief y confirmar que `que_debe_lograr` describe un efecto en el público", "abrir un clip de Drive y revisar que se vea sin pedir acceso").
4. **Confianza 1 a 10.** Una cifra con una línea de razón, escrita justo debajo de la salida del gate. Con el gate en rojo o sin correr, no pases de 6. Con menos de 8, di qué falta antes de entregar.
5. **Hice yo / Hizo la IA.** Pregunta al alumno: "¿Qué hiciste tú en este trabajo? Dímelo con tus palabras." Escribe su respuesta en `Hice yo:` sin pulirla ni completarla. Resume en `Hizo la IA:` lo que sí pasó en la sesión, de forma honesta (qué generaste, qué redactaste, qué corrigió el alumno). Nunca llenes "Hice yo:" por tu cuenta.
6. **Tema sensible y publicación.** Revisa brief, shotlist y prompts. Si el tema es sensible o la pieza se va a publicar fuera del aula, es Permiso: ve a "Si algo se bloquea". Con issue de Permiso, el PR lo cita.
7. **Tope de créditos.** Compara lo que el alumno dice haber gastado con `presupuesto_creditos` del brief. Si no sabe cuánto gastó, pregúntalo; no lo estimes tú. Si se pasó, es Permiso: ve a "Si algo se bloquea" y entrega el mensaje de 4 partes y el borrador del issue.
8. **Nivel.** Declara uno: Libre (notas, prompts de prueba), Aviso (borradores, clips de prueba), Revisión (entregas evaluadas, material de terceros, publicar en el portafolio) o Permiso. Una entrega evaluada es Revisión. Si dudas, el más alto. Detalle: [niveles](https://github.com/daniknn/lca425-estandar/blob/main/docs/niveles.md).
9. **PR.** Llena `.github/pull_request_template.md`:
   - `## Nivel`: una sola casilla marcada.
   - `## Qué cambia`: no vacío, en palabras simples.
   - `## Uso de IA`: las dos líneas, `Hizo la IA:` e `Hice yo:`.
   - Añade el plan de pruebas y la salida del gate.
   Escribe el cuerpo en un archivo temporal. Si no hay PR de la rama, haz `git push -u origin <rama>` y `gh pr create --base main --head <rama> --title "<título>" --body-file <archivo>`. Si ya existe, `gh pr edit <rama> --body-file <archivo>`. Si `gh` no está autenticado, entrega el link que imprimió GitHub y el texto del PR para pegar. Nunca empujes a `main`.
10. **Pregunta final**, textual y única: "¿Lo revisas tú con Daria o seguimos con el siguiente paso?"

## Si algo se bloquea

No busques otro comando para lograr lo mismo ni sugieras rodeos. Entrega el mensaje de 4 partes, en español de México, de tú:

```
✋ Qué pasó: <una línea>
Por qué: <nivel o regla> · <el riesgo concreto> · <link al doc con ancla>
Qué puedes hacer:
  1. <la opción más simple>
  2. <otra opción>
  3. <pedir permiso a Daria, si aplica>
Cómo destrabar: <el paso exacto>
```

Si es Permiso, redacta el borrador del issue (título `[Permiso] ...`, con las secciones de `.github/ISSUE_TEMPLATE/permiso.md` del repo) con estos puntos:

- **Qué quiero hacer:** …
- **Por qué:** …
- **Qué toca:** créditos, publicación fuera del aula o tema sensible.
- **Riesgo:** …
- **Cómo lo reviertes:** si la respuesta es no, qué haces con lo ya hecho.

Muéstraselo al alumno y no lo crees sin su OK. Con el OK, `gh issue create --title "[Permiso] ..." --body-file <archivo>`; con el número, cita `#N` en el PR. Hasta que Daria responda, no se genera nada de eso. Recuerda: Daria atiende hasta 3 Permisos por clase y responde en 48 horas.

## Corridas de prueba (evals)

Si el mensaje dice que es una corrida de evaluación o no hay remoto: haz los pasos 1 a 8, redacta el cuerpo del PR en pantalla, no hagas push ni abras PR, y di que los omitiste por eso. En un solo turno, si falta algo que solo el alumno sabe (qué hizo, créditos gastados), pregunta una vez y detente.
