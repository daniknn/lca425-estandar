# Cómo trabajar

Guía práctica para ramas, PR y bloqueos. Las reglas de fondo están en el [AGENTS.md](https://github.com/daniknn/lca425-estandar/blob/main/AGENTS.md).

<a id="tu-primer-pr"></a>
## Tu primer PR

Un PR es una propuesta de cambio. Haces el cambio en una rama, lo propones, el gate lo revisa y, si todo está bien, lo mergeas. Nunca subes directo a `main`.

Tu primer PR: completar `00_brief.md`.

### Antes: crea tu repo (una sola vez)

1. Abre https://github.com/daniknn/proyecto-plantilla y pulsa **Use this template → Create a new repository**.
2. Nombre: `lca425-<tu-usuario>`. Visibilidad: **Private**. Pulsa **Create repository**.
3. En tu repo nuevo: **Settings → Collaborators → Add people** y agrega a `daniknn` (Daria). Sin esto, Daria no puede ver ni revisar tu trabajo.

### Vía A: Claude Code con el plugin

1. La primera vez, en la Terminal: `claude update`. Luego, dentro de Claude Code, instala el plugin:
   ```
   /plugin marketplace add daniknn/lca425-estandar
   /plugin install lca425@lca425
   ```
2. Al inicio de cada clase, actualiza: `/plugin marketplace update lca425` y después `/reload-plugins`.
3. Abre tu repo de proyecto en Claude Code.
4. Escribe `/lca425:brief`. Claude te hará una pregunta a la vez.
5. Claude crea la rama, hace el cambio y abre el PR. El brief es nivel Aviso: lo mergeas con el gate en verde y Daria lo revisa en la clase siguiente.
6. Llena el PR: Nivel, Qué cambia, Uso de IA, Personas reales.
7. Espera la marca verde del gate y mergea.

### Vía B: solo GitHub web y claude.ai

Para quien no tiene plan de pago de Claude.

1. Abre claude.ai y pega la tarjeta `tarjetas/brief.md`. Responde sus preguntas. Te devuelve el texto del brief.
2. En GitHub, abre tu repo, entra a `00_brief.md` y pulsa el lápiz (Edit).
3. Pega el texto. Al guardar, elige "Create a new branch for this commit" y ponle un nombre corto, como `brief-v1`. Nunca elijas "commit directly to main".
4. Pulsa "Propose changes" y luego "Create pull request".
5. Llena el PR: Nivel (el brief es Aviso), Qué cambia, Uso de IA, Personas reales.
6. Espera la marca verde. Si no llega, abre "Details", lee el mensaje y corrige.
7. Cuando esté en verde, pulsa "Merge pull request".

Cuando termines el cambio, usa la tarjeta `tarjetas/cierre.md`. Te ayuda a revisar tu PR antes de pedir revisión.

### Qué comprobar antes de mergear

- El gate está en verde.
- Marcaste un solo nivel.
- La sección "Uso de IA" tiene las dos líneas.
- No subiste video, audio ni llaves.

<a id="binario-subido"></a>
## Si subiste un video o un binario

Pasa. Un video o un archivo de audio entró al repo. No lo arregles tú por tu cuenta.

**No hagas** `--force` ni intentes reescribir el historial. Empeora el problema en un repo compartido.

**Lo que se hace:**
1. Para. No sigas subiendo cambios.
2. Abre un issue en tu repo: "Subí un binario por error". Di qué archivo es y en qué PR o commit, y avísale a Daria.
3. Guarda el archivo en tu carpeta de Drive y apunta su link.
4. Copia a tu computadora los textos de tu proyecto: brief, guion, shotlist, prompts.
5. Con el OK de Daria, borra el repo (**Settings → Delete this repository**) y créalo otra vez desde la plantilla, como en [tu primer PR](#tu-primer-pr). Invita de nuevo a Daria.
6. Sube solo los textos, en un PR. La media se queda en Drive.

Para que no se repita, revisa que los clips vayan a Drive y que `clip_url` apunte ahí.

<a id="bloqueos"></a>
## Cuando algo se bloquea

Un bloqueo no es un regaño: es el sistema avisándote de un riesgo. Lo dice siempre con el mismo formato de cuatro partes.

```
✋ Qué pasó: <una línea>
Por qué: <el nivel o la regla, el riesgo y un link>
Qué puedes hacer:
  1. <la opción más simple>
  2. <otra opción>
  3. <pedir permiso a Daria, si aplica>
Cómo destrabar: <el paso exacto>
```

**Qué haces:**
1. **Lee las cuatro partes**, completas. Casi siempre la respuesta está en "Qué puedes hacer".
2. **Elige una opción.** Empieza por la más simple.
3. **Si ninguna sirve, pregunta en un issue.** Cuenta qué intentabas, copia el mensaje del bloqueo y di qué opción probaste.
4. **Si pide Permiso**, abre el issue siguiendo [niveles](https://github.com/daniknn/lca425-estandar/blob/main/docs/niveles.md#permiso).

**Qué no haces:**
- No buscas otro comando para lograr lo mismo.
- No le pides a Claude que lo esquive.
- No editas el gate ni los hooks.

Si Claude te sugiere un rodeo, dile que no y abre el issue.
