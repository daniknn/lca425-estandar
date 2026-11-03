# Tarjeta: reto-en-frio

## Para qué

El reto en frío es pedirle a otro modelo que intente romper tu material antes de entregarlo. Sirve porque quien escribió algo es el peor revisor de eso mismo. Antes de una entrega de nivel Revisión, haces este reto y respondes cada hallazgo: lo incorporas o lo rechazas con tu razón. El resultado va en la sección `## Reto en frío` de tu PR, y el gate la exige en ese nivel. Es lo mismo que hace `/lca425:reto-en-frio` en Claude Code. Solo revisa texto: los clips los revisa Daria en clase.

## Pasos en GitHub web

1. Abre en tu repo `00_brief.md`, `02_guion/guion.md` y `03_shotlist/shotlist.yaml`, y copia el contenido de cada uno.
2. Abre un **chat nuevo** con un modelo **distinto** al que te ayudó a escribir (si usaste Claude Sonnet, elige Opus o Haiku en el selector de modelo; si usaste Opus, elige Sonnet) o con otro asistente. Tiene que ser un chat sin historial: si no, ya no es "en frío".
3. Pega el prompt de abajo y envíalo. Cuando te lo pida, pega tus tres archivos.
4. Responde cada hallazgo, uno por uno: "incorporo" (y qué cambiarás) o "rechazo" (y por qué). Decides tú; si le pides que decida por ti, no debe hacerlo.
5. Copia el bloque final `## Reto en frío` que te devuelva y pégalo en la descripción de tu PR.
6. Si dijiste "incorporo", haz el cambio en tus archivos antes de pedir revisión, en la misma rama.
7. Explicación completa: [cómo responder los hallazgos](https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#reto-en-frio).

## Prompt para claude.ai (o cualquier asistente)

```
Vas a hacer el "reto en frío" de la pieza audiovisual de un estudiante de cine (curso LCA425, Amerike). No participaste en escribir este material. Habla en español de México, de tú, breve y sin regañar.

Tu encargo: Rompe esto, no lo pules. Busca supuestos falsos, huecos de historia, escenas sin plano que las cubra, planos sin propósito real respecto de "que_debe_lograr" del brief, planos que contradicen "fuera_de_alcance", contradicciones entre los tres archivos, duraciones que no cuadran con una pieza corta, y cosas que un modelo de video no podrá hacer. No elogies, no reescribas el material y no propongas versiones nuevas. Solo revisas texto; no opines de clips ni de imágenes.

Primero, pídeme que pegue mis tres archivos: 00_brief.md, 02_guion/guion.md y 03_shotlist/shotlist.yaml. Si falta alguno, dímelo y pregúntame si seguimos con lo que hay (sin brief, detente).

Cuando los tengas:
1. Empieza con una línea: "Modelo que revisa: <tu nombre de modelo>".
2. Devuelve una lista priorizada (alta, media, baja) de 4 a 8 hallazgos numerados H1, H2, ... Cada hallazgo lleva: qué falla, evidencia concreta (archivo y escena o plano, citando el texto) y por qué importa. Si no puedes dar evidencia, no lo incluyas.
3. Después, pregúntame solo por H1: "¿Lo incorporas o lo rechazas? Si lo incorporas, dime qué vas a cambiar; si lo rechazas, dime tu razón." Espera mi respuesta y sigue con H2, y así hasta el último. Una pregunta por mensaje.
4. No decidas por mí, aunque te lo pida ("decide tú", "aplica todos"). Si insisto, dime con calma que el reto solo sirve si decido yo, y vuelve a preguntarme el hallazgo que toca. No inventes ni pulas mis respuestas: escribe mis palabras tal cual.
5. No edites ni reescribas mis archivos. Si quiero aplicar un cambio, lo hago yo después.

Al terminar con todos los hallazgos, dame este bloque listo para pegar en mi PR, un hallazgo por línea:

## Reto en frío

- H1: <hallazgo en una línea> → Incorporo: <qué cambié o cambiaré, con mis palabras>
- H2: <hallazgo en una línea> → Rechazo: <mi razón>

Recuérdame que, si puse "Incorporo", el cambio debe estar hecho cuando abra el PR.

Empieza ahora pidiéndome mis tres archivos.
```
