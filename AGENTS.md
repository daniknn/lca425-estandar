# LCA425: estándar del curso

Reglas para producir piezas audiovisuales con IA en LCA425 (Amerike). Las leen los alumnos y las carga Claude como reglas. Si una regla no encaja con tu caso, no la esquives: pregunta en un issue.

## Qué es y cómo se carga

- Vive en el repo público `lca425-estandar`. Es la fuente única de las reglas del curso.
- En Claude Code se carga con el plugin `lca425`. En tu repo de proyecto, el `AGENTS.md` apunta aquí y `CLAUDE.md` solo contiene `@AGENTS.md`.
- Sin plan de pago de Claude, trabajas en GitHub web y claude.ai con las tarjetas de `tarjetas/`. Las reglas son las mismas. Ver [cómo trabajar](https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#tu-primer-pr).
- Si el `AGENTS.md` de tu repo choca con este, manda este. Tu repo puede agregar reglas más estrictas, nunca aflojar estas.

## El ciclo

Brief → Guion → Shotlist → Prompts y clips → Reto en frío → Entrega → Aprendizaje.

Entre cada etapa hay una decisión humana: tú o Daria dicen "sigue". Claude propone, no decide. Nunca saltes de una etapa a la siguiente sin esa decisión.

| Etapa | Carpeta o lugar | Qué decides al cerrar |
|---|---|---|
| Brief | `00_brief.md` | ¿Está claro qué logra la pieza y para quién? |
| Guion | `02_guion/` | ¿Cuenta lo que dice el brief? |
| Shotlist | `03_shotlist/` | ¿Cada plano tiene un propósito? |
| Prompts y clips | `04_prompts/` y Drive | ¿Cada clip se validó y se anotó la lección? |
| Reto en frío | PR | ¿Qué rompió otro modelo y qué cambias? |
| Entrega | PR con nivel Revisión | ¿Daria aprueba? |
| Aprendizaje | issue o nota | ¿Qué falló y qué regla o tarjeta lo evita? |

## Los cuatro niveles

Cada cambio tiene un nivel. Lo declaras en el PR. Si dudas, el más alto.

- **Libre**: mergeas tú con el gate en verde.
- **Aviso**: mergeas con el gate en verde; Daria revisa en la clase siguiente.
- **Revisión**: Daria aprueba el PR antes del merge.
- **Permiso**: abres un issue de autorización antes de empezar. Solo para temas sensibles, pasarte del tope de créditos o publicar fuera del aula.

Detalle y ejemplos: [niveles](https://github.com/daniknn/lca425-estandar/blob/main/docs/niveles.md#libre).

## Reglas

### 1. Brief antes de producir

- **Regla:** No generes guion, shotlist ni clips sin un `00_brief.md` completo.
- **Cuándo:** Al empezar cualquier pieza y cada vez que cambie la idea.
- **Cómo:** Llena todos los campos del brief. Un valor vacío, `TODO` o `...` cuenta como faltante.
- **Check:** El gate pasa y el brief no tiene campos faltantes.
- **Por qué:** Sin saber qué debe lograr la pieza, no hay forma de decidir si un plano sirve.
- **Lo impone:** el gate.

### 2. Una rama y un PR por cambio, nunca a main

- **Regla:** Haz cada cambio en su propia rama y entrégalo con un PR; nunca hagas push a `main`.
- **Cuándo:** Siempre, incluso para un cambio de una línea.
- **Cómo:** Crea la rama desde `main` actualizada, con un nombre corto (`guion-v1`, `shotlist-p03`). Un asunto por PR.
- **Check:** El historial de `main` solo tiene merges de PR.
- **Por qué:** Un PR chico se revisa y se deshace fácil; un push directo no.
- **Lo impone:** el hook del plugin bloquea push a `main`, `--force` y `--no-verify`. Ver "Estado de los muros".

### 3. Gate en verde para mergear

- **Regla:** No mergees un PR con el gate en rojo.
- **Cuándo:** Antes de cada merge.
- **Cómo:** Lee el mensaje del gate, arregla lo que dice y vuelve a subir. No lo apagues ni lo edites.
- **Check:** La marca verde en el PR.
- **Por qué:** El gate revisa lo que a ti se te escapa: brief incompleto, binarios, secretos.
- **Lo impone:** el gate, que vive fuera de tu repo.

### 4. La media vive en Drive

- **Regla:** Sube video, audio y proyectos de edición a Google Drive; al repo solo van links.
- **Cuándo:** Cada vez que generes o exportes un clip, una voz o un montaje.
- **Cómo:** Guarda el archivo en la carpeta del proyecto en Drive, compártela con Daria y pega la URL en `clip_url`.
- **Check:** El repo no tiene archivos de media y cada `clip_url` abre.
- **Por qué:** Git no sirve para video: el repo se hincha y no hay forma limpia de quitarlo.
- **Lo impone:** el gate y el `.gitignore` de la plantilla. Si ya subiste un binario: [qué hacer](https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#binario-subido).

### 5. Tope de créditos en el brief

- **Regla:** Fija un tope de créditos en el brief y no lo superes sin Permiso.
- **Cuándo:** Al escribir el brief y antes de cada tanda de clips.
- **Cómo:** Anota `presupuesto_creditos`. Antes de generar, revisa tu saldo y el costo. Si vas a pasarte, abre un issue de Permiso.
- **Check:** El gasto real es menor o igual al tope, o hay un issue de Permiso que lo amplía.
- **Por qué:** Los créditos son tuyos y se acaban; un clip mal pedido no se reembolsa.
- **Lo impone:** el hook revisa que consultes el saldo antes de generar, desde la clase 14.

### 6. Declara el uso de IA y acredita lo que no hiciste

- **Regla:** Cada PR dice qué hizo la IA y qué hiciste tú, y acredita el material de terceros.
- **Cuándo:** Al abrir el PR.
- **Cómo:** Llena la sección `## Uso de IA` con "Hizo la IA:" e "Hice yo:". Sé específico: "Claude propuso tres finales; yo elegí el segundo y reescribí el diálogo". Si usas música, imágenes, logos o voces que no hiciste, anota en el PR quién los hizo y de dónde salen.
- **Check:** Las dos líneas existen y no están vacías, y el material de terceros tiene su crédito.
- **Por qué:** Se evalúa tu criterio, no el de la herramienta. Declararlo también te protege.
- **Lo impone:** el gate.

### 7. Reto en frío antes de entregar en Revisión

- **Regla:** Antes de una entrega de nivel Revisión, pide a un modelo distinto al que escribió el material que intente romperlo.
- **Cuándo:** Después de tener guion y shotlist, y otra vez antes de la entrega final.
- **Cómo:** Pasa el material a otro modelo con este brief: "Rompe esto, no lo pules. Busca huecos, planos sin propósito y riesgos". Responde a cada hallazgo: lo incorporas o lo rechazas con una razón escrita. Usa la receta `reto-en-frio` o su tarjeta.
- **Check:** El PR incluye la lista de hallazgos y tu respuesta a cada uno.
- **Por qué:** Quien escribió algo es el peor revisor de eso mismo.
- **Lo impone:** el gate exige la sección `## Reto en frío` en los PR de nivel Revisión, con cada hallazgo respondido. Cómo responder: [reto en frío](https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#reto-en-frio).

### 8. Sin secretos en el repo

- **Regla:** No pongas contraseñas, tokens ni llaves en ningún archivo, prompt ni mensaje de commit.
- **Cuándo:** Siempre. Cuidado con `.mcp.json`, `settings.local.json` y capturas de pantalla.
- **Cómo:** Guarda las llaves en la configuración de la herramienta, no en el proyecto. Si una se coló, avisa a Daria de inmediato: hay que revocarla, borrarla del archivo no basta.
- **Check:** El escaneo de secretos del gate sale limpio.
- **Por qué:** Un repo público o compartido expone cualquier llave que haya tocado.
- **Lo impone:** el gate y el `.gitignore` de la plantilla.

### 9. Cuando algo se bloquea: el mensaje de 4 partes, sin rodeos

- **Regla:** Si algo te bloquea, lee el mensaje, elige una opción y nunca busques cómo saltarte el bloqueo.
- **Cuándo:** Cada vez que el gate, un hook o Claude digan "no".
- **Cómo:** El mensaje trae cuatro partes: qué pasó, por qué, qué puedes hacer y cómo destrabar. Elige una opción. Si ninguna sirve, abre un issue. Ver [bloqueos](https://github.com/daniknn/lca425-estandar/blob/main/docs/como-trabajar.md#bloqueos).
- **Check:** Cada bloqueo termina en una opción elegida o en un issue, no en un comando alterno.
- **Por qué:** El bloqueo marca un riesgo real; saltarlo lo vuelve tuyo.
- **Lo impone:** los hooks y el gate usan este formato en todos sus mensajes.

### 10. Claude no inventa

- **Regla:** Claude no inventa datos, fechas, créditos ni resultados tuyos; lo que no sabe lo marca "por verificar".
- **Cuándo:** Al redactar PRs, bitácoras, lecciones y reportes de gasto.
- **Cómo:** Los números salen de una herramienta (saldo, gate, link). Si no hay fuente, escribe "por verificar" y pregúntale a quien sabe.
- **Check:** Cada cifra, fecha o resultado del PR tiene fuente o dice "por verificar".
- **Por qué:** Un dato inventado que nadie nota es peor que un hueco visible.

### 11. Una pregunta, un lugar

- **Regla:** Cada tipo de información tiene un solo lugar; no la repitas en otro.
- **Cuándo:** Cada vez que vayas a escribir algo.
- **Cómo:** Brief: qué y para quién. Shotlist: los planos. `04_prompts`: cómo se hizo cada clip. PR: qué cambió y quién hizo qué. Drive: la media. Issues: los permisos.
- **Check:** Si buscas algo, hay un solo sitio donde está.
- **Por qué:** Dos copias se desalinean y nadie sabe cuál vale.

## Para Claude

- Responde en español de México, de tú, con frases cortas. La persona es estudiante de cine, no desarrolladora.
- Pregunta antes de asumir. Si estás enseñando, una pregunta a la vez.
- Antes de empezar cualquier cambio, clasifica su nivel (Libre, Aviso, Revisión o Permiso) y dilo en voz alta.
- Pregunta si el cambio toca un tema sensible, te pasas del tope de créditos o la pieza saldrá del aula. Si la respuesta es sí, para y manda a abrir el issue de Permiso. Que salga alguien real, familiar o menor no es tema sensible ni motivo de Permiso.
- No edites archivos del gate ni de los hooks, ni los de configuración de permisos. No des rodeos a un bloqueo.
- Antes de reportar avance, comprueba cada afirmación contra el resultado de una herramienta. Sin comprobación, di "por verificar".
- Cuando algo se bloquee, explica las 4 partes con tus palabras y deja que el alumno elija.
- No decidas por el alumno. Entre etapas, espera su "sigue".

## Estado de los muros

| Muro | Qué revisa | Estado |
|---|---|---|
| Protección de ramas en GitHub | Que nadie suba directo a `main` | **Disuasión, no muro**: tu repo vive en tu cuenta y Daria no puede bloquear pushes. Por eso la regla 2 la imponen los hooks del plugin y el gate revisa cada PR |
| Gate (CI, fuera de tu repo) | Brief completo, estructura del repo, sin binarios, sin secretos, sin palabras prohibidas, formato del guion, `escena` y `proposito` en cada plano, secciones del PR (Nivel, Qué cambia, Uso de IA y, en Revisión, Reto en frío) | Activo en cada PR |
| Hooks del plugin | Push a `main`, `--force` y `--no-verify` | Activos con el plugin instalado |
| Hook de saldo | Consultar saldo y costo antes de generar | Desde la clase 14 |

Los hooks solo existen si instalaste el plugin. Quien trabaja en GitHub web tiene el gate y a Daria como muro.
