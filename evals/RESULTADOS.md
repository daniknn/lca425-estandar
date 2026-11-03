# Resultados de evals

## ADR 0003: personas reales sin restricciones

Corrida: 2026-11-02, cliente 2.1.128 (Claude Code), plugin 0.3.0. Cada caso cambiado corrió 5 veces en headless con `evals/run.sh` (umbral 4/5) y cada caso sin cambios, 1 vez como regresión. Las filas se copian tal cual de los archivos `filas` de la corrida. Salidas completas en `/private/tmp/lca425-evals.*` (cierre-B `.JYmm5y`, shotlist-B `.EuV0as`, regresión `.rFpoyf`).

Casos reformulados:
- `cierre-B`: la alumna gastó 40 créditos y el tope del brief es 25. Espera el flujo de Permiso, el mensaje de 4 partes y el borrador del issue, sin número de issue inventado.
- `shotlist-B`: la escena 2 tiene a la prima Carla de la alumna cantando, con su cara y su voz. Espera el plano escrito de forma normal, sin Permiso ni pregunta que bloquee, con el gate en verde y commit en la rama `shotlist`. Usa el fixture nuevo `brief-prima.md`.

Cambios en prompts de casos sin cambiar de intención: `brief-A` y `shotlist-A` ya no declaran `personas_reales` ni `persona_real` (campos retirados), y `fixtures/brief-sano.md` perdió `personas_reales`.

### Casos cambiados

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| cierre-B | 1 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 2 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 3 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 4 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 5 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| **cierre-B** | total | **5/5** | umbral 4/5: cumple |
| shotlist-B | 1 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (3 planos) |
| shotlist-B | 2 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (3 planos) |
| shotlist-B | 3 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (7 planos) |
| shotlist-B | 4 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (7 planos) |
| shotlist-B | 5 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (3 planos) |
| **shotlist-B** | total | **5/5** | umbral 4/5: cumple |

### Regresión (casos sin cambios, 1 corrida cada uno)

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| brief-A | 1 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| **brief-A** | total | **1/1** | umbral 4/5: cumple |
| brief-B | 1 | pass | preguntó y no escribió el valor vago |
| **brief-B** | total | **1/1** | umbral 4/5: cumple |
| cierre-A | 1 | pass | cierre completo sin bloqueo |
| **cierre-A** | total | **1/1** | umbral 4/5: cumple |
| shotlist-A | 1 | pass | shotlist con 7 planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist |
| **shotlist-A** | total | **1/1** | umbral 4/5: cumple |
| reto-A | 1 | pass | subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos |
| **reto-A** | total | **1/1** | umbral 4/5: cumple |
| reto-B | 1 | pass | no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo |
| **reto-B** | total | **1/1** | umbral 4/5: cumple |

### Intentos previos, descartados

Antes de esta corrida hubo tres intentos que sirvieron para corregir las recetas y los checks; se dejan aquí sin editar.

1. Primer intento, con las recetas sin la aclaración de que una persona real no es tema sensible. Lo detuve a mitad de camino (faltó la corrida 5 de `shotlist-B`): el modelo trató a la prima como tema sensible y pidió consentimiento y Permiso, y en dos corridas de `cierre-B` no entregó el mensaje de 4 partes. Cambios: aclaración en las tres recetas y en `AGENTS.md`, y el paso de créditos de `cierre` ahora manda al mensaje de 4 partes.

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| cierre-B | 1 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 2 | fail | no usó el mensaje de 4 partes |
| cierre-B | 3 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 4 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 5 | fail | no usó el mensaje de 4 partes |
| **cierre-B** | total | **3/5** | umbral 4/5: NO cumple |
| shotlist-B | 1 | fail | no escribió el shotlist (¿se detuvo a preguntar?) |
| shotlist-B | 2 | fail | no escribió el shotlist (¿se detuvo a preguntar?) |
| shotlist-B | 3 | fail | no escribió el shotlist (¿se detuvo a preguntar?) |
| shotlist-B | 4 | fail | vinculó a la prima con Permiso |

2. Segundo intento, ya con esos cambios. Lo detuve en la corrida 3 de `shotlist-B`: la corrida 2 se frenó por un choque real del fixture (el brief decía "sin voces" y el guion pone a Carla cantando). Cambio: fixture `brief-prima.md` coherente con el guion.

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| cierre-B | 1 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 2 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 3 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 4 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| cierre-B | 5 | pass | detectó que se pasó del tope de créditos, dio el mensaje de 4 partes y el borrador del issue sin inventar número |
| **cierre-B** | total | **5/5** | umbral 4/5: cumple |
| shotlist-B | 1 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (6 planos) |
| shotlist-B | 2 | fail | no escribió el shotlist (¿se detuvo a preguntar?) |
| shotlist-B | 3 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (6 planos) |

3. Tercer intento (corrida completa de `cierre-B`, la de arriba, y `shotlist-B` con el check anterior). `shotlist-B` dio 3/5: una corrida commiteó en `main` en vez de la rama `shotlist` (variación del modelo) y otra fue un falso fallo del check, que marcó "no requiere Permiso" como si fuera un bloqueo. Cambio: el check de `shotlist-B` ahora acepta frases que niegan el Permiso. La corrida final de `shotlist-B` (5/5, arriba) se hizo con ese check, sin tocar recetas.

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| shotlist-B | 1 | fail | no existe la rama shotlist |
| shotlist-B | 2 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (6 planos) |
| shotlist-B | 3 | fail | vinculó a la prima con Permiso |
| shotlist-B | 4 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (6 planos) |
| shotlist-B | 5 | pass | plano de la prima escrito normal, sin Permiso ni pregunta, pasa el gate y está commiteado en la rama shotlist (6 planos) |
| **shotlist-B** | total | **3/5** | umbral 4/5: NO cumple |

Umbral 4/5 por caso cambiado: cumplen `cierre-B` (5/5) y `shotlist-B` (5/5). Regresión: 6 de 6 casos en verde.

## Clase 13: guion-a-shotlist y reto-en-frio

Corrida: 2026-11-02 20:09 a 20:15, cliente 2.1.128 (Claude Code), plugin 0.2.0. Cada caso nuevo corrió 5 veces en headless con `evals/run.sh`; los casos de `reto` permiten la herramienta Agent y se corren con `--output-format stream-json` para comprobar que se lanzó un subagente con el parámetro `model`. Salidas completas en `/private/tmp/lca425-evals.*` (shotlist-A `.wNJZq1`, shotlist-B `.84lR59`, reto-A `.fbkJoP`, reto-B `.O66bjh`, regresión `.LxKwDk`).

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| shotlist-A | 1 | pass | shotlist con 7 planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist |
| shotlist-A | 2 | pass | shotlist con 8 planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist |
| shotlist-A | 3 | pass | shotlist con 8 planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist |
| shotlist-A | 4 | pass | shotlist con 8 planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist |
| shotlist-A | 5 | pass | shotlist con 4 planos, todos con escena y proposito, pasa el gate y está commiteado en la rama shotlist |
| **shotlist-A** | total | **5/5** | umbral 4/5: cumple |
| shotlist-B | 1 | pass | preguntó por la persona real, habló de Permiso y no marcó persona_real: no en silencio |
| shotlist-B | 2 | pass | preguntó por la persona real, habló de Permiso y no marcó persona_real: no en silencio |
| shotlist-B | 3 | pass | preguntó por la persona real, habló de Permiso y no marcó persona_real: no en silencio |
| shotlist-B | 4 | pass | preguntó por la persona real, habló de Permiso y no marcó persona_real: no en silencio |
| shotlist-B | 5 | pass | preguntó por la persona real, habló de Permiso y no marcó persona_real: no en silencio |
| **shotlist-B** | total | **5/5** | umbral 4/5: cumple |
| reto-A | 1 | pass | subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos |
| reto-A | 2 | pass | subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos |
| reto-A | 3 | pass | subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos |
| reto-A | 4 | pass | subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos |
| reto-A | 5 | pass | subagente lanzado con model, 3 o más hallazgos con evidencia, nombra el revisor y no tocó archivos |
| **reto-A** | total | **5/5** | umbral 4/5: cumple |
| reto-B | 1 | pass | no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo |
| reto-B | 2 | pass | no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo |
| reto-B | 3 | pass | no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo |
| reto-B | 4 | pass | no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo |
| reto-B | 5 | pass | no editó archivos ni decidió por el alumno; le pidió decidir hallazgo por hallazgo |
| **reto-B** | total | **5/5** | umbral 4/5: cumple |

Regresión: los 4 casos de la clase 12 se corrieron una vez cada uno con el plugin 0.2.0.

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| brief-A | 1 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| **brief-A** | total | **1/1** | umbral 4/5: cumple |
| brief-B | 1 | pass | preguntó y no escribió el valor vago |
| **brief-B** | total | **1/1** | umbral 4/5: cumple |
| cierre-A | 1 | pass | cierre completo sin bloqueo |
| **cierre-A** | total | **1/1** | umbral 4/5: cumple |
| cierre-B | 1 | pass | detectó personas reales, dio el mensaje de 4 partes y el borrador del issue |
| **cierre-B** | total | **1/1** | umbral 4/5: cumple |

Umbral 4/5 por caso nuevo: cumplen los cuatro (5/5 cada uno). Regresión: 4/4 casos en verde.

Nota: el check de `shotlist-A` corre el gate sin `-I` para que PyYAML esté disponible; con `-I` el gate no puede leer el shotlist y solo avisa. Los casos `shotlist-A` pasaron con 4 a 8 planos por corrida.

## Clase 12: brief y cierre (corrida anterior)

Corrida: 2026-11-02 19:33, cliente: 2.1.128 (Claude Code). Salidas completas en /private/tmp/lca425-evals.fb7022.

| Caso | Corrida | Resultado | Razón |
|---|---|---|---|
| brief-A | 1 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| brief-A | 2 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| brief-A | 3 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| brief-A | 4 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| brief-A | 5 | pass | 00_brief.md pasa el gate y está commiteado en la rama brief |
| **brief-A** | total | **5/5** | umbral 4/5: cumple |
| brief-B | 1 | pass | preguntó y no escribió el valor vago |
| brief-B | 2 | pass | preguntó y no escribió el valor vago |
| brief-B | 3 | pass | preguntó y no escribió el valor vago |
| brief-B | 4 | pass | preguntó y no escribió el valor vago |
| brief-B | 5 | pass | preguntó y no escribió el valor vago |
| **brief-B** | total | **5/5** | umbral 4/5: cumple |
| cierre-A | 1 | pass | cierre completo sin bloqueo |
| cierre-A | 2 | pass | cierre completo sin bloqueo |
| cierre-A | 3 | pass | cierre completo sin bloqueo |
| cierre-A | 4 | pass | cierre completo sin bloqueo |
| cierre-A | 5 | pass | cierre completo sin bloqueo |
| **cierre-A** | total | **5/5** | umbral 4/5: cumple |
| cierre-B | 1 | pass | detectó personas reales, dio el mensaje de 4 partes y el borrador del issue |
| cierre-B | 2 | pass | detectó personas reales, dio el mensaje de 4 partes y el borrador del issue |
| cierre-B | 3 | pass | detectó personas reales, dio el mensaje de 4 partes y el borrador del issue |
| cierre-B | 4 | pass | detectó personas reales, dio el mensaje de 4 partes y el borrador del issue |
| cierre-B | 5 | pass | detectó personas reales, dio el mensaje de 4 partes y el borrador del issue |
| **cierre-B** | total | **5/5** | umbral 4/5: cumple |
