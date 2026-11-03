# Rúbrica de la pieza audiovisual

Versión 1.0 (3 de noviembre de 2026). Desde la clase 13 solo cambia por erratas. Así se califica la entrega de la clase 16.

## Qué evalúa y qué no

**Evalúa** la pieza audiovisual de la entrega de la clase 16 (capstone, parte 5: "Video + image + audio/motion"): imagen en movimiento, sonido y montaje. Hay tres formatos posibles: corto, redes o transmedia.

**No evalúa** el resto del Entregable 4 (hero visual, copy, newsletter, social assets) ni las otras partes del capstone (research, UX, web, asistente, SEO, n8n, analytics). Cada una tiene su propio entregable. En transmedia, la segunda pieza se evalúa solo por su papel en el recorrido, no como entregable aparte.

**Principio: se califica el criterio del alumno, no el resultado de la herramienta.** Lo que cuenta son decisiones que se pueden ver en el material: qué pidió, qué obtuvo, qué ajustó, qué conservó y por qué.

**Nunca suman puntos:**
- el número de versiones de un prompt;
- la proporción de hallazgos incorporados o rechazados;
- la longitud de las lecciones o de las justificaciones;
- el volumen de créditos gastados.

## Antes de calificar: requisitos de entrega

Son comprobaciones de sí o no, sin puntos. Si falta una, la entrega no se califica hasta corregirla.

| Requisito | Cómo se comprueba |
|---|---|
| PR de nivel Revisión con el gate en verde | Marca verde en el PR |
| Reto en frío presente y cada hallazgo con respuesta | El gate revisa la sección `## Reto en frío` |
| Permiso aprobado si la pieza toca un tema sensible, pasó el tope de créditos o se publica fuera del aula | El issue `[Permiso]` tiene respuesta de Daria |
| Montaje final entregado con fecha de corte | Archivo en Drive. El PR registra su link y su fecha de modificación; un cambio posterior a la fecha de corte no se considera |
| Clips y montaje accesibles para Daria | Daria abre cada link sin pedir acceso |
| Sección `## Uso de IA` con "Hizo la IA" y "Hice yo" | Existe y no está vacía (la calidad se evalúa en el criterio 5) |
| Lista de control de material de terceros | Para cada música, imagen, logo o voz ajena: fuente, licencia y fecha. Para cada parte generada: herramienta y prompt (`04_prompts/`) |

## Criterios (100 puntos)

Cada nivel vale un porcentaje fijo del peso: Insuficiente 40 %, En desarrollo 70 %, Logrado 90 %, Destacado 100 %. **Destacado se gana por el efecto de las decisiones del alumno en la pieza, no por cumplir un rasgo concreto.**

Cada evidencia se califica en un solo criterio:
- el reto en frío y las lecciones van solo en el 5;
- la intención visual, solo en el 3;
- la transparencia y los créditos, solo en el 6;
- lo que se descartó del brief, solo en el 1.

**Prueba de público.** Se usa en los criterios 1 y 2. Antes de entregar, dos compañeros que no conocen el brief ven la pieza y escriben en una línea qué entendieron o qué les quedó. El alumno pega esas dos líneas en el PR, y se comparan con `que_debe_lograr`.

### 1. Brief y concepto (15)
"Observable" quiere decir que el espectador puede contestar una pregunta concreta al terminar. Ejemplo: "¿qué objeto olvidado te llamó la atención?".

| Nivel | Descriptor |
|---|---|
| Insuficiente | El brief no define un efecto en el público, o la pieza no tiene relación con él. |
| En desarrollo | El efecto es vago ("que guste", "que se vea bien") o la prueba de público no lo confirma. |
| Logrado | El efecto es observable y la prueba de público lo confirma, aunque sea en parte. |
| Destacado | La prueba de público lo confirma con claridad y el brief muestra qué se dejó fuera para lograrlo (`fuera_de_alcance`). |

### 2. Estructura según el formato (20)
Pregunta común a los tres formatos: ¿la estructura es adecuada al formato y a lo que el brief declara? Los packs de abajo son orientaciones, no requisitos. Una pieza que se aparta de su pack, como un corto contemplativo sin giro, puede llegar a Logrado si el brief lo justifica.

| Nivel | Descriptor |
|---|---|
| Insuficiente | La estructura impide que el público reciba lo que el brief busca. |
| En desarrollo | Se entiende, pero la estructura trabaja contra el efecto: sobran tramos o falta el cierre que el brief pide. |
| Logrado | La estructura sirve al efecto del brief y al formato. |
| Destacado | La estructura hace más fuerte el efecto que la prueba de público reporta. |

### 3. Dirección visual y montaje (20)
Se evalúa el control que ejerce el alumno: qué pidió y qué obtuvo. No se evalúa la consistencia que da la herramienta por sí sola.

| Nivel | Descriptor |
|---|---|
| Insuficiente | Los planos no se relacionan con su `proposito` y el alumno no identifica los desajustes. |
| En desarrollo | La mayoría de los planos cumple su `proposito`, pero hay desajustes de estilo, luz o cámara sin nombrar. |
| Logrado | Cada plano cumple su `proposito`, o el desajuste está nombrado en el shotlist o en el prompt (aceptado, corregido o imposible con el modelo). El montaje (orden, cortes, duraciones) sigue lo que pide el brief. |
| Destacado | Las decisiones de imagen y montaje se ven en la pieza y refuerzan el efecto: un cambio de luz, un corte o una duración elegida a propósito. |

### 4. Sonido (10)
El silencio decidido cuenta. En redes, una pieza que se entiende sin sonido no pierde puntos en este criterio. Los derechos del audio se revisan en la lista de control y en el criterio 6, no aquí.

| Nivel | Descriptor |
|---|---|
| Insuficiente | El sonido contradice la intención de la pieza o no hay ninguna decisión sobre él. |
| En desarrollo | Hay una decisión de sonido, pero no acompaña el ritmo ni la intención. |
| Logrado | El sonido, incluido el silencio, responde a lo que pide el brief y está anotado en `05_audio/`. |
| Destacado | El sonido refuerza el efecto de una forma que la imagen sola no lograría. |

### 5. Proceso y criterio propio (20)
Evidencia: el historial de commits, el shotlist, `04_prompts/`, la sección del reto en frío, el aprendizaje final y la conversación con Daria (ver "Fechas y cómo se califica").

| Nivel | Descriptor |
|---|---|
| Insuficiente | El repo no deja ver cómo se hizo; el orden de los commits no corresponde al ciclo (por ejemplo, clips antes que brief). |
| En desarrollo | El proceso está completo, pero las lecciones son genéricas y no se pueden contrastar con el clip o con el prompt ("aprendí a ser específico"). |
| Logrado | Cada respuesta del reto, sea Incorporo o Rechazo, da una razón que cita la escena, el plano o el brief. Las lecciones nombran algo verificable ("pedí X, salió Y, ajusté Z"; "v1 sirvió: confirmé Z"). Hay un aprendizaje final que propone una regla o una tarjeta. |
| Destacado | Las decisiones de proceso mejoraron la pieza de forma visible respecto de su versión anterior, y el alumno administró su tope de créditos con prioridades claras ("con lo que tenía, prioricé X"). |

### 6. Transparencia y créditos (15)
Este criterio solo mira que el público sepa qué es generado y de quién es lo que no hiciste.

| Nivel | Descriptor |
|---|---|
| Insuficiente | Hay material de terceros sin crédito, o la pieza no dice que usa IA. |
| En desarrollo | Todo tiene crédito, pero la pieza no indica qué partes son generadas. |
| Logrado | Créditos completos; la pieza o su descripción indica qué es generado con IA; "Hizo la IA / Hice yo" es específico. |
| Destacado | La pieza le deja claro al público qué es sintético sin romper la experiencia, y el alumno explica cómo lo resolvió. |

### Tope por cimiento ausente

Si el criterio 1 queda en Insuficiente, la calificación final tiene un tope de **69 sobre 100**: un punto por debajo de la mínima aprobatoria de Amerike (7). Una entrega sin brief no aprueba.

## Packs por formato (orientación del criterio 2)

| | Corto | Redes | Transmedia |
|---|---|---|---|
| Duración | 1 pieza de 20 a 40 s | 3 piezas verticales de 8 a 12 s | 1 pieza de 15 a 30 s y otra pieza en otro medio (imágenes, web o audio) |
| Tope de créditos (cada alumno puede declarar uno menor en su brief) | 80 | 80 | 80 |
| Qué se espera | Un recorrido reconocible, con giro o sin él si el brief lo justifica. Cada escena del guion tiene su cobertura | Gancho al inicio y acción final (CTA) presentes en el diseño y justificados. Lectura sin sonido por imagen o texto (si el brief excluye subtítulos, por imagen). 9:16 en el montaje final | Cada medio aporta algo que el otro no tiene. El recorrido entre medios es claro y la identidad es compartida |
| Qué no se exige | Que sea "autoral" o tenga un final que reinterpreta | Desempeño real (vistas, likes). No se publica sin Permiso | Que la segunda pieza sea la web del Entregable 3 |

Las duraciones admiten una tolerancia de 10 %. Con 80 créditos, el modelo recomendado es **Seedance 2.0 Mini a 720p** (o Seedance 2.0 fast a 480p): 1 crédito por segundo, lo que deja margen para un reintento por plano. Con Seedance 2.0 fast a 720p (2.5 créditos por segundo) solo alcanzan unos 32 s sin reintentos.

## Fechas y cómo se califica

| Cuándo | Qué pasa |
|---|---|
| Clase 15 | **Prueba de público**: en parejas, ves la pieza de tu compañero sin conocer su brief y escribes en una línea qué entendiste o qué te quedó (unos 10 minutos). Pega las líneas que te escriban en tu PR |
| 7 de diciembre de 2026, 23:59 (hora del centro de México) | **Fecha de corte.** Tu montaje final en Drive cuenta solo si su fecha de modificación es igual o anterior a esta |
| Clase 16, 8 de diciembre | Daria revisa los requisitos y después los 6 criterios sobre tu PR de entrega (ya mergeado). Conversación de 3 a 5 minutos sobre tu proceso y tu "Hice yo"; no se califica por sí sola, confirma lo que muestra tu repo |

Recibes un comentario por criterio, con tu nivel y una acción concreta para subir.

**Créditos:** con 80 créditos, usa Seedance 2.0 Mini a 720p (1 crédito por segundo) para que te alcance un reintento por plano. La receta `/lca425:prompt-video` te muestra cuánto te queda antes de cada plano. Si vas a pasarte, pide Permiso antes ([niveles](https://github.com/daniknn/lca425-estandar/blob/main/docs/niveles.md#permiso)).
