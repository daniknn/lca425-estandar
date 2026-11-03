# Niveles del aula

Cada cambio en tu repo tiene un nivel. El nivel dice quién decide y cuándo. Lo declaras en el PR, en la sección `## Nivel`, con una sola casilla marcada. Si dudas entre dos, marca el más alto.

Regla de oro: el nivel depende de lo que toca el cambio, no de qué tan grande es.

| Nivel | Quién decide | Cuándo |
|---|---|---|
| Libre | Tú | Mergeas con el gate en verde |
| Aviso | Tú, y Daria revisa después | Mergeas con el gate en verde; Daria revisa en la clase siguiente |
| Revisión | Tú, y Daria califica después | Mergeas con el gate en verde; el gate exige el reto en frío respondido |
| Permiso | Daria | Issue de autorización antes de empezar |

<a id="libre"></a>
## Libre

**Qué pasa:** haces el cambio, abres el PR, el gate pone verde y mergeas tú.

**Ejemplos:**
- Probar un prompt para ver cómo responde el modelo y anotarlo en `04_prompts/`.
- Notas de bitácora sobre lo que aprendiste.
- Corregir una falta de ortografía en el brief.

**Quién decide:** tú.

<a id="aviso"></a>
## Aviso

**Qué pasa:** mergeas con el gate en verde. Daria lo revisa en la clase siguiente y te dice si hay que corregir algo.

**Ejemplos:**
- Un borrador de guion en `02_guion/`.
- Un borrador de shotlist con planos todavía en estado `idea` o `prompt`.
- Clips de prueba generados dentro de tu tope de créditos, dentro de lo que no necesita Permiso.

**Quién decide:** tú mergeas; Daria valida después.

<a id="revision"></a>
## Revisión

**Qué pasa:** antes de abrir el PR haces el reto en frío con otro modelo y respondes cada hallazgo (regla 7 del [AGENTS.md](https://github.com/daniknn/lca425-estandar/blob/main/AGENTS.md)). El gate revisa que la sección `## Reto en frío` esté completa; con el gate en verde, mergeas tú. Daria califica la entrega después, sobre el PR mergeado.

**Ejemplos:**
- La entrega final de la pieza.
- Material de terceros: una canción, un logo o una imagen que no hiciste tú.

**Quién decide:** tú mergeas; Daria califica después. Publicar la pieza fuera del aula, por ejemplo en tu portafolio, es [Permiso](#permiso).

<a id="permiso"></a>
## Permiso

**Qué pasa:** abres un issue de autorización (título `[Permiso] ...`) antes de empezar. Hasta que Daria responda, no generas nada de eso. Cuando haya respuesta, el PR cita el issue (`#N`).

**Cuándo aplica:**
- Temas sensibles.
- Pasarte del tope de créditos del brief.
- Publicar fuera del aula.

**Ejemplos:**
- Una pieza sobre un tema delicado que podría lastimar a quien la vea: Permiso.
- Ya gastaste tu tope de créditos y quieres generar otra tanda: Permiso.
- Subir la pieza a tus redes: Permiso.
- Un clip de prueba dentro de tu tope, con la gente que tú quieras en el plano: no necesita Permiso, es Aviso.

**Quién decide:** Daria. Responde en un plazo de 48 horas. Cada clase se atienden hasta 3 issues de Permiso, así que no dejes el tuyo para el último día.

### Cómo abrir un issue de Permiso

1. En tu repo, ve a Issues → New issue → elige la plantilla **Permiso**. El título empieza con `[Permiso]`.
2. Llena cada punto: qué quieres hacer, por qué, qué toca (créditos, publicación, tema sensible), el riesgo y cómo lo reviertes si la respuesta es no. La receta `cierre` de Claude Code te lo redacta si se lo pides; sin Claude Code, usa la tarjeta `cierre`.
3. Anota el número del issue (`#N`) y cítalo en el PR.
4. Espera la respuesta. Si Daria pide más información, contéstale en el mismo issue.
