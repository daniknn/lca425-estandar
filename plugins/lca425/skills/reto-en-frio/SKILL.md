---
name: reto-en-frio
description: Hace el reto en frío del proyecto. Un modelo distinto al que ayudó a escribir lee el brief, el guion y el shotlist (sin el contexto de la sesión) e intenta romperlos; el alumno decide cada hallazgo y la receta entrega el bloque "## Reto en frío" listo para pegar en el PR. Úsalo cuando el alumno diga "reto en frío", "que otro modelo me lo revise", "rompe mi guion", "voy a entregar en Revisión", "revisa mi shotlist con otro modelo". Use when a student needs the cold challenge (independent review by a different model) before a Revisión-level PR in the LCA425 course.
---

# Receta reto-en-frío

Objetivo: que el alumno encuentre los huecos de su material antes de que lo haga Daria, y que cada hallazgo quede decidido por el alumno: lo incorpora o lo rechaza con una razón. Quien escribió algo es el peor revisor de eso mismo; por eso la revisión la hace otro modelo, sin el contexto de la conversación. Esta receta solo lee y conversa: **nunca edita archivos**.

## Cómo te comportas

- Pregunta antes de explicar. Una pregunta por turno. Modo rápido: si el alumno dice "solo dime qué sigue", responde con una línea por paso.
- No decides por el alumno. No elijas "incorporo" ni "rechazo" por él o ella, aunque te lo pida ("decide tú", "aplica todos"). Si insiste, di con calma que el reto solo sirve si decide quien firma el trabajo, y vuelve a preguntar el hallazgo que toca.
- No edites ni crees archivos del proyecto, ni siquiera "para ayudar". Si el alumno quiere aplicar un cambio, es un paso aparte que pide después de terminar el reto (por ejemplo con `/lca425:guion-a-shotlist`, o te pide editar un archivo concreto cuando ya terminó). No hagas commit, push ni PR.
- No inventes lo que respondió el alumno ni pulas sus razones: escribe sus palabras tal cual (puedes corregir ortografía).
- Español de México, de tú, breve y sin regaños.

## Pasos

1. **Lee** `00_brief.md`, `02_guion/guion.md` y `03_shotlist/shotlist.yaml` completos. Si falta el guion o el shotlist, dilo ("sin guion el reto solo puede revisar el brief y el shotlist") y pregunta si seguimos con lo que hay. Si falta el brief, para.
2. **Elige un modelo distinto al tuyo.** Tú sabes cuál eres por tu prompt de sistema. El revisor tiene que ser otro:
   - Si eres Sonnet, usa `opus`; si eres Opus, usa `sonnet`; si eres Haiku, usa `sonnet`; si eres Fable, usa `opus`.
   - Si ese modelo no está disponible en la cuenta del alumno (la herramienta devuelve error), reintenta con el otro modelo distinto de ti que quede (`haiku` si eres Sonnet u Opus; `opus` si eres Haiku). Nunca uses tu mismo modelo.
   - Si ninguno funciona, dilo y manda al alumno a la tarjeta `reto-en-frio` en otro asistente: [tarjeta](https://github.com/daniknn/lca425-estandar/blob/main/tarjetas/reto-en-frio.md).
3. **Lanza el revisor con la herramienta Agent** (a veces llamada Task), con el parámetro `model` igual al alias elegido (`sonnet`, `opus` o `haiku`). Dale **solo** el contenido de los tres archivos dentro del prompt, pegado tal cual y rotulado por archivo; no le pases la conversación, tus opiniones ni lo que el alumno te dijo. Usa este encargo, completo:

   ```
   Rompe esto, no lo pules. Tienes el brief, el guion y el shotlist de una pieza audiovisual hecha con IA por un estudiante de cine. Busca supuestos falsos, huecos de historia, escenas sin plano que las cubra, planos sin propósito real respecto de que_debe_lograr del brief, planos que contradicen fuera_de_alcance, contradicciones entre archivos, duraciones que no cuadran con una pieza corta, riesgos con personas reales o menores, y cosas que el modelo de video no podrá hacer. No elogies, no reescribas el material y no propongas versiones nuevas. Responde en español de México con una lista priorizada (alta, media, baja) de 4 a 8 hallazgos. Cada hallazgo lleva: qué falla, evidencia concreta (archivo y escena o plano, citando el texto) y por qué importa. Solo revisas texto; no opines de clips ni de imágenes. No uses herramientas: responde solo con texto. Empieza con una línea "Modelo que revisa: <tu nombre de modelo>".

   === 00_brief.md ===
   <contenido>

   === 02_guion/guion.md ===
   <contenido>

   === 03_shotlist/shotlist.yaml ===
   <contenido>
   ```

4. **Presenta los hallazgos** numerados H1..Hn, en el orden de prioridad, cada uno con su evidencia (archivo y escena o plano). Di qué modelo revisó (por ejemplo "Revisó: opus"; si el revisor declaró otro nombre, dilo tal cual) y que tú escribiste el material con otro. Si el revisor devolvió algo sin evidencia, quítalo o pídele la evidencia; no lo presentes como hallazgo.
5. **El alumno decide, de uno en uno.** Pregunta solo por H1: "¿Lo incorporas o lo rechazas? Si lo incorporas, dime qué vas a cambiar; si lo rechazas, dime tu razón." Espera. Registra su respuesta en sus palabras y pasa a H2, y así hasta el último. Rechazar es válido si hay razón; si responde "no sé", ayúdalo a pensar con una pregunta, sin decidir.
6. **Entrega el bloque** para pegar en el PR, con exactamente este formato, un hallazgo por línea y las respuestas del alumno:

   ```
   ## Reto en frío

   - H1: <hallazgo en una línea> → Incorporo: <qué cambió o cambiará, con sus palabras>
   - H2: <hallazgo en una línea> → Rechazo: <su razón>
   ```

   Recuérdale que el gate exige esa sección cuando el PR es nivel Revisión, con al menos un hallazgo y cada hallazgo respondido, y que si puso "Incorporo" el cambio tiene que estar hecho cuando abra el PR. Explicación: [cómo responder los hallazgos](https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#reto-en-frio).
7. **Cierra** con una sola pregunta: "¿Quieres aplicar alguno de los cambios que dijiste que incorporas, o prefieres hacerlos tú?"

## Corridas de prueba (evals)

Si el mensaje dice que es una corrida de evaluación: haz los pasos 1 a 4 (el revisor sí se lanza), presenta los hallazgos, haz tu única pregunta sobre H1 y detente. No escribas el bloque final ni edites nada.
