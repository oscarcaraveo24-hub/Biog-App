# Prompt para Claude Code — Integrar el Manzano (apple_tree) al pipeline completo de granos en Bio-G

> Pega esto como instrucción inicial en Claude Code, dentro del repo `bio_g`.
> Idioma de trabajo: español. Identificadores/código en inglés tal cual aparecen.

---

## Contexto

Bio-G es una app Flutter que evalúa salud de cultivos a partir de telemetría de sensores (humedad, temp suelo, pH, EC, resistencia, N, P, K). Los **granos y hortalizas** (frijol, maíz, etc.) están bien integrados: cada uno tiene su motor AgroScore en `lib/core/agro/<crop>_agro_score_engine.dart`, que delega la interpretación NPK en `NutrientRecommendationEngine` y produce un `AgroEvalResult` con bandas **bajo / óptimo / alto / exceso**. Ese mismo `eval` alimenta el ring de salud del dashboard, la card de NPK del dashboard y la pantalla de detalle NPK. Una sola fuente de verdad.

El **manzano (apple_tree / "Manzano")** fue agregado después con un ciclo perenne distinto, pero **NO reutiliza esa maquinaria**: un motor improvisado y a medias vive dentro de `apple_tree_crop_definition.dart` y produce verdictos incorrectos.

### Bugs confirmados (reproducibles)

1. **El NPK del árbol nunca detecta "alto" ni "exceso".** Con N = 71 mg/kg y objetivo 20–40 mg/kg, el árbol muestra **"Óptimo"** cuando debería ser **"Alto/Exceso"**. Causa: `AppleTreeCropDefinition._nutrientMetric` (en `lib/core/crops/apple_tree/apple_tree_crop_definition.dart`) compara contra un umbral bajo fijo (`lowThreshold` 15/8/80) y llama "óptimo" a todo lo que esté por encima. **Ignora por completo los rangos objetivo** (`nTargetRange` 20–40, `pTargetRange` 60–80, `kTargetRange` 35–55) que el perfil YA define.

2. **La pantalla de detalle NPK muestra el objetivo mal escalado** ("22 a 48 mg/kg" en vez de 20–40). Causa: `resolveAppleTreeTargets` (en `lib/core/crops/apple_tree/apple_tree_universal_profile.dart`, ~línea 833) mete los rangos en ppm reales (20–40) dentro de `nIndex/pIndex/kIndex`, pero `NutrientTargetRangeResolver.comparableRange` interpreta esos campos como un **índice 0–100** y los multiplica por el cap del cultivo (default 120 porque el manzano no está en `NpkCaps`): 20/100×120≈24, 40/100×120=48 → de ahí el "22 a 48".

3. **El icono de la variedad/perfil del manzano no se muestra** en dashboard ni seeds screen (los granos sí muestran el icono de la variedad elegida). Los assets existen y `varietyId` se guarda como `ap_01_golden` etc.

> NOTA IMPORTANTE: En un turno anterior se hizo un parche en sentido **equivocado**: se **alejó** al árbol de `NutrientRecommendationEngine` (se gateó con `&& !isTree`). Hay que **revertir** eso, porque la dirección correcta es la opuesta: hacer del manzano un cultivo de primera clase DENTRO de ese motor. Ver sección "Revertir parche previo".

---

## Objetivo

Integrar el manzano al **mismo pipeline que los granos**, reutilizando `NutrientRecommendationEngine`, `NutrientTargetRangeResolver` y `NpkCaps`, con un motor dedicado `AppleTreeAgroScoreEngine` espejo de `BeanAgroScoreEngine`. Resultado esperado: dashboard (ring + card NPK), detalle NPK y alertas, todos consistentes y correctos, detectando bajo/óptimo/alto/exceso con las reglas fenológicas del manzano (doc 05). Más iconos de variedad y tests.

**Fuente de verdad agronómica:** los 5 documentos en `temp/manzano/`. Lee especialmente:
- `05_Guia_Fertilizacion_NPK_Targets_BioG_Manzano_v1_1_mejorado.txt` (targets, escala 0–1, reglas N/P/K por etapa).
- `01_Ficha_Tecnica_Universal_Perfiles_BioG_Manzano_AP_v1.txt` (perfiles AP-01..AP-05, etapas).
- `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Manzano_v1.txt` (alertas/riesgos).

Verifica también contra fuentes públicas confiables (IRTA, extensión universitaria, hojas de manejo de manzano) que los rangos de suficiencia de N/P/K en suelo y las reglas (p. ej. N alto tardío retrasa madurez y color; K alto + bitter pit; P bajo pesa en establecimiento) sean correctos. Si algo del doc contradice el consenso técnico, anótalo y propón el ajuste; no lo cambies sin avisar.

---

## Trabajo a realizar

### 1. `NpkCaps` — agregar el manzano
Archivo: `lib/core/agro/npk_caps.dart`.
- Agrega `case 'apple_tree': case 'crop_apple_tree': case 'manzano':` para N, P y K, devolviendo caps razonables para que el medidor (gauge `ppm/cap`) quede bien centrado (sugerencia inicial: N≈90, P≈110, K≈80 — ajústalos para que el óptimo del perfil quede ~en medio del gauge; documenta el porqué).

### 2. Rango de suficiencia explícito en ppm
Archivo: `lib/core/crops/apple_tree/apple_tree_universal_profile.dart`, función `resolveAppleTreeTargets` (~L833).
- Pobla `nSoilPpmRange / pSoilPpmRange / kSoilPpmRange` con los rangos **reales en ppm** (los que hoy están en `nTargetRange/pTargetRange/kTargetRange`). Así `NutrientTargetRangeResolver.comparableRange` los usará directamente (vía `soilPpmRangeFor`) sin escalar por cap, y el detalle mostrará el objetivo correcto (20–40, no 22–48).
- Mantén `nIndex/pIndex/kIndex` coherentes (o conviértelos a verdadero índice 0–100) para no romper rutas legacy. Verifica que ninguna pantalla dependa del valor crudo de `nIndex` como ppm.
- Revisa que cada etapa (`TreeStageIds`: rootEstablishment, budbreak/flowering, fruitSet, fruitFill, harvest_maturity/postHarvest, dormancy, etc.) tenga rangos con **bandas suaves** (`lowMax < optimalMin` y `optimalMax < highMin`) para que exista zona "bajo"/"alto" antes de "crítico". Hoy varias etapas tienen `optimalMin==lowMax` y `optimalMax==highMin` (saltan de óptimo a crítico). Ajústalos con base en el doc 05.

> **DECISIÓN DEL USUARIO sobre "alto" vs "exceso" (IMPORTANTE):** En manzano, estar **alto NO es tan malo** y NO debe penalizar ni alarmar (zona "alto útil", ~0.65–0.80 del doc 05). Solo el **EXCESO** (zona ~0.80–1.00, por encima de `highMin`) debe marcarse y bajar el score. Concretamente:
> - Define la banda "alto" como una zona **amplia y tolerante** por encima del óptimo: `highMin` debe quedar bastante por encima de `optimalMax`, de modo que un valor moderadamente alto caiga en "alto" (tratado casi como óptimo, sin warning ni penalización) y solo un valor claramente desproporcionado supere `highMin` y se interprete como **exceso**.
> - En el mapeo de etiquetas, "alto" → label tipo `lowPriority`/`noPriority` (sin penalización, `_nutrientPenaltyFactor` ≈ 1.0, sin alerta). "Exceso" (≥ `highMin`) → `possibleExcess`/`reviewAccumulation` (warning + penalización del score).
> - Ejemplo del usuario: N=71 con óptimo 20–40. Decide con base en el doc 05 + fuentes si 71 cae en "alto tolerable" o en "exceso". Si es claramente exceso (probable, es ~1.8× el óptimo), debe marcarse exceso; si lo consideras "alto útil", no alarmar. Documenta el umbral elegido.

### 3. Reglas NPK fenológicas del manzano (doc 05)
Crea `lib/core/agro/apple_tree_nutrition_modifier.dart` espejando el patrón de `chili_nutrition_modifier.dart` / `eggplant_nutrition_modifier.dart`, y engánchalo en `NutrientRecommendationEngine.interpret` con un helper `_isAppleTreeCrop(cropKey)` (igual que `_isChiliCrop`, etc., ~L99-160 de `nutrient_recommendation_engine.dart`). Reglas a codificar (del doc 05, §3 y §5):
- **N**: "más N no es más fruta". Pero recuerda la decisión del usuario: *alto* no penaliza; solo *exceso* sí. La excepción fenológica es tardía: **exceso** de N en `fruitFill`/`harvest_maturity` → advertencia/penalización (retrasa madurez, color, endurecimiento de madera), y penalizar más en **AP-02 Red** y **AP-04 Gala** cerca de madurez (color/calidad). N alto temprano en árbol joven/deficiente es aceptable (sin penalización).
- **K**: sube su peso tras cuajado (`fruitSet`, `fruitFill`, `harvest_maturity`). K alto en `fruitFill` puede ser útil, **pero** si hay historial de bitter pit / Ca o Mg bajo → no celebrar, elevar warning. K alto + EC alta → riesgo salino.
- **P**: P bajo pesa más en `planting_transplant`, `root_establishment`, `budbreak`, `flowering` y primeras semanas post-floración. En pH>7.5 el problema puede ser **disponibilidad** (bloqueo), no falta real → el mensaje debe hablar de disponibilidad. No generar alerta fuerte por P bajo en `harvest_maturity`.
- **Disponibilidad/pH/EC**: si pH, EC, humedad o compactación están fuera de rango, bajar confianza en la lectura NPK ("presente pero no disponible").

### 4. Motor dedicado `AppleTreeAgroScoreEngine`
Crea `lib/core/agro/apple_tree_agro_score_engine.dart` **espejo de** `lib/core/agro/bean_agro_score_engine.dart`:
- Método estático `evaluate({required BioGTelemetry t, required <treeStage>, required <treeProfile/targets>, AlertsState alertsState, StageTargets? targetsOverride, StageWeights? weightsOverride, String? cropLabel, ...})` que devuelve `({AgroEvalResult eval, AlertsState nextAlertsState})`.
- Para suelo (humedad, soilTemp, pH, EC, resistencia) usa la lógica `_evalLegacy` (bandas por `AgroRange`) igual que bean.
- Para N/P/K llama a `NutrientRecommendationEngine.interpret(cropKey: 'apple_tree', stageKey: <treeStageId>, targets: treeTargets, weights: treeWeights, ph, ec, soilMoisturePct, ...)` y mapea `interpretation.label.agroBand` → banda, igual que `_interpretBeanNutrient`.
- Calcula `soilControlScore01` ponderado por `StageWeights` + `criticalPenalty` y `_nutrientPenaltyFactor` (idéntico a bean) para que un nutriente en exceso o bajo **sí baje el ring**.
- Define los sets de etapas críticas/semicríticas del manzano (floración, cuajado, llenado) para el `severityBump` de alertas.

### 5. Conectar la definición del cultivo al nuevo motor
Archivo: `lib/core/crops/apple_tree/apple_tree_crop_definition.dart`.
- `evaluateTelemetry(...)` debe **delegar** en `AppleTreeAgroScoreEngine.evaluate(...)` (mira cómo `BeanCropDefinition.evaluateTelemetry` ~L92 llama a `BeanAgroScoreEngine.evaluate`).
- **Elimina** la lógica improvisada `_metric`, `_nutrientMetric`, `_soilControlScore`, `_nutrientPriorityScore`, `_scoreForBand`, los `_xBand` y `_TreeStageSensitivity` **solo si** ya no se usan tras delegar (las alertas por etapa `_buildTreeAlerts` puedes conservarlas o migrarlas al motor; mantén la cobertura de alertas).

### 6. Revertir/adaptar el parche previo
En el turno anterior se modificaron dos archivos en sentido contrario al deseado. Ahora que el árbol usa el motor correcto, los árboles deben pasar por **el mismo camino que los granos**:
- `lib/screens/npk/npk_screen.dart`: **quita** el gating `&& !isTree` en las 3 llamadas a `NutrientRecommendationEngine.interpret`, **quita** el helper `_toneFromAgroBand` y las ramas `isTree ?` que leen `treeEvalN/P/K` para insight/desc/action/window/tone. Trees vuelven a usar `interpretation` como los granos. (Quita el import de `tree_lifecycle.dart` si queda sin uso.)
- `lib/screens/dashboard/dashboard_presenter.dart`: el bloque que arma el título/subtítulo NPK (`if (isPlanted && telemetry != null && !isTree)`, ~L271) debe incluir a los árboles. Quita el `&& !isTree` y elimina el bloque especial `if (isTree && treeContext != null) { npkTitle = ...; _treeNpkStatusSubtitle(...) }` (~L336) y el helper `_treeNpkStatusSubtitle`, de modo que el árbol arme su `N: … · P: … · K: …` con el **mismo** builder de granos (que ahora será correcto). Conserva el resto de la UI específica del árbol (treeStatus card, riego por etapa).
- El ring de salud (`_calcSoilHealthRealistic`) ya usa `eval.soilControlScore01`: como el nuevo motor produce un score que penaliza exceso/bajo, el ring dejará de mostrar 100% cuando haya un problema. Verifícalo.

### 7. Iconos de variedad del manzano (dashboard + seeds screen)
Síntoma: al elegir variedad/perfil (AP-01..05) el icono no aparece; los granos sí lo muestran. Datos ya verificados: `varietyId` se guarda como `ap_01_golden`; los assets `assets/icons/wizard/ic_apple_*.png` existen y la carpeta está en `pubspec.yaml`; `CropPresentationResolver._resolveAppleTreeIcon` mapea bien vía `appleTreeProfileIcon`.
- Traza por qué `runtime.cropIconAsset` no llega como icono de variedad a la UI del árbol. Sospechosos en orden:
  1. `CropPresentationResolver.resolve` (L206): `cropId = CropCatalog.canonicalCropKey(...)`. Confirma que para el árbol ese `cropId` **es igual** a `CropCatalog.appleTreeCropId` usado en el `switch` de `_resolveIconAsset` (L442); si no, cae en `default → _genericPlantIconAsset`.
  2. Render: en el dashboard (`dashboard_*`) y en `seeds_screen.dart`, confirma que la UI del árbol pinta `runtime.cropIconAsset` (o `topCardIconAsset`, que ya prioriza `runtime.cropIconAsset`) y no fuerza un icono de etapa/`ic_arbol.png`/neutro. En `seeds_screen.dart` ~L242 el `heroAsset` del árbol usa stage o `ic_arbol.png`; el **icono superior** (`topCardIconAsset`) debe ser el de la variedad como en granos.
- Objetivo: misma conducta que granos — variedad elegida → su icono en dashboard y seeds screen. Perfil general/AP-SKIP → icono neutro del manzano.

### 8. Tests
Sigue el estilo de `test/core/apple_tree/apple_tree_universal_profile_test.dart` y `test/core/crop_runtime_resolver_test.dart` (no existen tests de motores de granos, así que crea los del manzano):
- `test/core/apple_tree/apple_tree_agro_score_engine_test.dart`:
  - N = 71 ppm en etapa de producción/llenado → banda **exceso** (NO óptimo) con warning + `soilControlScore01` más bajo que el caso todo-en-rango.
  - N **moderadamente alto** (apenas por encima de `optimalMax`, dentro de "alto útil") → banda **alto** SIN warning y SIN penalización notable del score (validar la decisión "alto no es tan malo").
  - Test de no-regresión: un caso de **frijol** con N alto sigue dando exactamente la misma banda/label que hoy (el cambio no afecta a granos).
  - P por debajo de `lowMax` en establecimiento/floración → prioridad alta / acción recomendada.
  - Todo dentro de rango → óptimo / `noPriority` y ring alto.
  - N alto en `harvest_maturity` para AP-02 Red / AP-04 Gala → penalización/advertencia mayor que en árbol joven.
  - K alto en `fruitFill` con historial de bitter pit (si se modela) → warning.
- `test/core/apple_tree/apple_tree_targets_test.dart`: `comparableRange` del manzano devuelve los ppm reales (p. ej. N 20–40), NO el escalado por cap (24–48).
- Un test de consistencia (puede ir en `crop_runtime_resolver_test.dart`): para un mismo telemetry de árbol, la banda del `eval` (ring/dashboard) y la banda mostrada en el detalle NPK coinciden.

---

## Verificación obligatoria antes de terminar
1. `flutter analyze` sin errores nuevos.
2. `flutter test` — todos verdes, incluidos los nuevos.
3. Caso manual del usuario: árbol con N=71, P y K dados → el dashboard NO debe decir 100% si hay un nutriente fuera de rango; el detalle NPK debe decir N "Alto/Exceso" con objetivo 20–40; ring, card NPK y detalle **coinciden**.
4. Elegir una variedad (p. ej. AP-01 Golden) → su icono aparece en dashboard y seeds screen.
5. Diff final claro y explicación de cualquier desviación respecto al doc 05 que hayas encontrado al cruzar con fuentes técnicas.

## Restricciones
- **NO DESMADRAR LO QUE YA FUNCIONA (máxima prioridad).** Frijol, maíz, trigo, cebada, avena, tomate, pepino, chile, berenjena, calabaza, lechuga, espinaca, cebolla, ajo y los flujos de semillas/siembra deben quedar **idénticos**, byte por byte en comportamiento. Por eso:
  - Todo cambio en archivos COMPARTIDOS (`NutrientRecommendationEngine`, `NpkCaps`, `NutrientTargetRangeResolver`, `crop_presentation_resolver`, `npk_screen`, `dashboard_presenter`, `seeds_screen`) debe ser **puramente aditivo y gateado por cultivo** (`_isAppleTreeCrop(cropKey)` / `case 'apple_tree'`). No modifiques ni reordenes las ramas/caps/reglas de otros cultivos.
  - La única excepción es **revertir** el parche previo del manzano (sección 6), que justamente fue lo que tocó código compartido con `!isTree`; al revertirlo, los granos vuelven exactamente a su ruta original.
  - Antes y después: corre `flutter test` completo y compara. Si algún test existente cambia de resultado, te equivocaste de enfoque.
- **Valida las recomendaciones sin romper nada.** Cruza los rangos y reglas del manzano con el doc 05 y fuentes públicas confiables, pero implementa esa validación SOLO en la ruta del manzano. No "corrijas" de paso rangos/labels de otros cultivos aunque te parezcan mejorables; si detectas algo, anótalo aparte sin tocarlo.
- No inventes un sistema paralelo: **reutiliza** `NutrientRecommendationEngine`, `NutrientTargetRangeResolver`, `NpkCaps`, `AgroEvalResult`, `StageTargets`, `StageWeights`, `AlertsEngine`. El manzano debe verse, en arquitectura, como un cultivo más.
- El ciclo perenne (resolución de etapa por `PerennialStageResolver`/`tree_lifecycle`) NO cambia; lo único que cambia bajo el capó es que la interpretación NPK/score pasa por el motor compartido.
- Mantén toda la cobertura de alertas por etapa existente.
- Trabaja en una rama y commits pequeños y descriptivos.
