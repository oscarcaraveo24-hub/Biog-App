# Cierre · Plan de nitrógeno declarado + línea de tiempo del cultivo — 13/14 sep 2026

Sesión sobre el nuevo motor nutricional (Guía v0.4) después de la auditoría doble de guías (12–13 sep). Resuelve la pregunta de Oscar: *«¿qué pasa con el agricultor que fertiliza una sola vez fuerte y ya no vuelve? ¿Le vamos a estar pidiendo nitrógeno?»*

## 0. Estado en una frase

El motor ya no exige fraccionar a quien no fracciona: el productor declara **una vez por temporada** cómo va a fertilizar (una sola vez / dos veces / tres o más) en una tarjeta no bloqueante de la pantalla NPK; el resolver del plan pliega el reparto de N de la guía a esa declaración (respetando lo que la literatura permite para ese cultivo **y esa textura de suelo**), las ventanas plegadas dejan de abrir N y de pesar, y la pantalla de cultivo estrena una **línea de tiempo** con las etapas del ciclo y los marcadores de nutrición en cinco estados. **Verificación: pendiente del vigilante (ver §7).**

## 1. Decisiones que mandan (y una enmienda a la Guía)

1. **La magnitud del salto de CE NO se convierte en kilos, nunca.** Investigado a fondo (13 sep): Baldi et al. 2026 (*Horticulturae* 12(7):898, sondas Weihai JXCT: R² 0.05–0.24, relaciones N:P:K fijas); Parra Barragán et al. 2026 (excluyeron NPK por colinealidad con CE); Shin et al. 2026 (*Agriculture* 16(2):137, TEROS 12 en campo: +54 % de masa = +12 % de CE = 10 µS/cm, el término de error del sensor). Humedad (+84–111 %), temperatura (±20 %) y textura (31 %) mueven la CE más que la dosis. Regla 5 de §37 intacta: «respuesta compatible» ≠ «nutriente absoluto medido».
2. **Enmienda al principio «el agricultor no confirma nada» (5–6 sep).** Se conserva para las aplicaciones: sigue sin existir registro manual de fertilización. Se abre UNA excepción consciente: la **declaración de temporada**, categórica (nunca kilos), una vez por ciclo, con tres puertas de entrada (tarjeta NPK hoy; hoja del sensor y «Cambiar» en la línea, fases siguientes). Evidencia: la categoría «¿fraccionaste?» es robusta al retraso (Banco Mundial: Wollburg et al. 2021; Beegle et al.); la cantidad no lo es (+1.9–8.8 %/mes).
3. **Es por cultivo × textura, no por cultivo.** Clark et al. 2020 (49 sitio-años): sin diferencia única/fraccionada en 76–84 % de los sitios; arena > 4–10 % favorece fraccionar; arcilla > 34–37 % favorece la única. Cruz-Alvarez et al. 2020 (Jiménez, Chih., 5 años, nogal, 41 % arcilla): única = fraccionada. La textura **ya se captura en el onboarding** (`soilTextureId`) y hoy llega al motor nutricional; antes no.
4. **Guardarraíles, no prohibiciones ciegas.** Cada guía comestible declara `splitRequirement` (tolera única / conviene fraccionar / hay que fraccionar), `minNitrogenPasses` (+ variantes en arena y arcilla), `maxSinglePassKgN` cuando hay fuente (cebolla 112 kg N/ha, PNW 546; nogal 120), `singlePassStageKey` (frijol: en vegetativo, Henson & Bliss 1991) y `splitNotesEs` citable. Las opciones que no aplican **se muestran deshabilitadas con la razón**, no se esconden.
5. **Incorporación obligatoria con dosis concentrada.** Con urea en superficie en suelo calcáreo: 20 % de pérdida promedio, hasta 60 % en 24 días sin riego posterior; 11 mm de riego inmediato la deja < 5 % (MSU EB0208; Engel 2011; Holcomb 2011). Toda ventana plegada lleva la regla primero.
6. **Tono, no cantidad, tras una respuesta «mayor de lo habitual».** Sin declaración, si la ventana de N anterior cerró `attendedDetected` con `ResponseVerdict.greater`, la siguiente ventana de N se degrada a orientativa (no pesa) y cambia el copy. Solo la inmediata.
7. **Un dato, tres puertas.** `NutritionSeasonDeclaration` (deviceId, seasonKey, cropKey, passes, declaredAt, sourceId) persistido junto al libro de ventanas. Hoy escribe la tarjeta NPK; las fases 2–4 añaden riego, hoja del sensor, «Cambiar» y editor de plan.

## 2. Qué se construyó (Fase 1)

| Pieza | Qué hace | Archivos |
|---|---|---|
| Declaración | Modelo + JSON; enum `NitrogenPassPlan {single, two, threeOrMore}` | `lib/core/agro/nutrition/nutrition_season_declaration.dart` |
| Guía | `NitrogenSplitRequirement`, campos de fraccionamiento, `copyWithStageRules`, `nitrogenWindowRules`, `ruleIndexFor`; `StageNutritionRule.copyWith/primaryStageKey` | `nutrition_guide.dart`, `nutrition_guides.dart` (23 guías comestibles clasificadas con cita) |
| Resolver | guía × textura × declaración × libro → guía efectiva + opciones de la tarjeta + ventanas plegadas + degradación por tono | `nutrition_plan_resolver.dart` |
| Motor | `NutritionReadinessInput.soilTexture/seasonDeclaration/withPlan`; `evaluate()` resuelve el plan y decide con la guía efectiva; `neutralizeFoldedWindows` (una ventana ya abierta que se pliega cierra sin pesar); `NutritionEvaluation.plan`; `scaleDose` público; versión 1.1.0 | `nutrition_readiness_engine.dart`, `engine_versions.dart` |
| Memoria | Tabla `nutrition_declarations` (esquema v2 con `onUpgrade`), save/load/delete; `NutritionCoordinator.declaration/planFor/declare/clearDeclaration/seasonKeyFor/soilTextureFor`; `BioGStore.declareNutritionPlan/clearNutritionPlan` | `nutrition_local_storage.dart`, `nutrition_coordinator.dart`, `biog_store.dart` |
| Calendario | `CropStageSchedule` por muestreo del motor fenológico (sin tocar 17 motores); árboles: las 11 etapas cronológicas completas (plantación → … → post-cosecha) con `cycleStartIndex` en reposo; ornamentales por ids | `lib/core/crops/crop_stage_schedule.dart` |
| Línea de tiempo | VM puro (`NutritionTimelineVm`: fases + marcadores en 5 estados, nombre corto, «Etapa X de N») y widget: riel horizontal con scroll que se centra solo en la etapa actual, TODAS las etapas con su nombre, insignias de fertilización («◆ N», «✓ NPK»…), leyenda con los estados presentes, glow y pulso con movimiento reducido, arco de ciclo en árboles, hoja de detalle | `nutrition_timeline_vm.dart`, `lib/widgets/nutrition/nutrition_timeline.dart`, `seeds_screen.dart` |
| Pregunta en NPK | «¿Cómo vas a fertilizar esta temporada?» a PANTALLA COMPLETA la primera vez (no deja ver NPK sin contestar; la flecha al Panel sigue disponible); lenguaje visual del onboarding: fondo, cabecera con el icono del cultivo, tres tarjetas como «Campo / Huerto / Maceta» con una, dos o tres esferas de nitrógeno (`ic_nitrogen`), ★ Guía en la recomendada, candado con razón en las que no aplican, caja de explicación, «Continuar»; contestada, NPK aparece tal cual y el icono de ajustes de la barra la vuelve a abrir (con cierre) | `lib/widgets/npk/nutrition_plan_gate.dart`, `npk_screen.dart` |
| NPK, arco | El arco tiene siempre el mismo tamaño (`kNpkGaugeHeight`, cede solo en pantallas muy cortas); el bloque de texto y la fila de cifras se desplazan si no caben; el centro muestra el estado («Estable», «Al alza», «Calibrando», «Sin señal») y no el dato crudo, que baja a la fila «Dato crudo del sensor» | `npk_screen.dart`, `npk_gauge_card.dart` (`centerLabel`/`centerCaption`, informes intactos) |
| Navegación | Al salir de una pestaña su scroll vuelve arriba (`_tabScroll` en Panel, Historial, Cultivo, Ambiente y Cuenta): al regresar, la pantalla empieza desde el inicio | `dashboard_screen.dart`, `history_screen.dart`, `seeds_screen.dart`, `environment_screen.dart`, `account_screen.dart` |
| Pruebas | Resolver (opciones, plegado, guardarraíles, tono, neutralización, invariantes de las 23 guías × 8 texturas), declaración (JSON), calendario (17 motores + árboles + cactus), VM (fases, marcadores, libro, plegado, huerto) | `test/core/agro/nutrition/nutrition_plan_resolver_test.dart`, `nutrition_season_declaration_test.dart`, `nutrition_timeline_vm_test.dart`, `test/core/crops/crop_stage_schedule_test.dart` |

## 3. El caso de Oscar, congelado en test

Maíz, suelo arcilloso, declaración «una sola vez»: las tres ventanas de N (0.33 fondo, 0.40 V6–V8, 0.27 V10–V12) se pliegan en la de fondo → **160–240 kg N/ha ≈ 348–522 kg de urea/ha en una sola pasada**, con «riega o incorpora en 24 h» como primera regla; V6–V8 y V10–V12 quedan orientativas (marcador punteado, sin ⚠, sin score). En arena la misma declaración no aplica (mínimo 3) y la tarjeta lo dice.

## 4. Clasificación por cultivo (resumen; la cita completa vive en `splitNotesEs`)

Tolera única: cebada maltera (NDSU), avena (INIFAP Chih.), frijol (en vegetativo), durazno (Penn State). Conviene fraccionar (mín. 2; 1 en arcilla donde la literatura lo respalda): maíz (1 en arcilla), nogal (1 en arcilla, tope 120), manzano, peral, mango, aguacate, lechuga y espinaca (tope 45). Hay que fraccionar: trigo de riego (−30 % con todo a la siembra), tomate, chile, berenjena, pepino, calabaza, cebolla (tope 112, mín. 3–4), ajo, cítricos (3+), pistache (bimodal 30/70). Sin clasificar (sin opción de concentrar): girasol, ornamentales.

## 5. Fases siguientes (acordadas)

- **Fase 2 — riego**: paso «¿Cómo riegas?» en onboarding junto a la textura (rodado / aspersión o pivote / goteo / temporal). Alimenta el resolver (segundo moderador), el motor de riego y la regla de volatilización.
- **Fase 3 — el tap del sensor**: al cerrar la primera ventana con ✓, hoja «Detectamos tu fertilización. ¿Fue la única del ciclo?» (dos pasos: confirmar → corregir; SEP-EMA +5.6 pp; DI2 > DI1) + «Cambiar» en la línea de tiempo. Escriben el mismo registro (`sourceId`).
- **Fase 4 — plan tocable** (patrón Atfarm/Haifa): el plan como tarjetas editables; colapsar es declarar.
- Pendientes previos: C-3 dosis por planta/maceta (`dose_expression.dart` sigue sin conectar), C-4 escalar por meta de rendimiento, micronutrientes, subida a Supabase (migración escrita, no aplicada; `nutrition_declarations` aún sin migración).

## 6. Riesgos y notas de diseño

- Revisión de Oscar (14 sep) tras probar la primera versión: la tarjeta arriba de NPK comprimía el arco y la línea de tiempo mostraba solo 3 etapas del aguacate sin explicar nada. Se reemplazó por la pantalla completa (la pregunta se contesta antes de ver NPK), se devolvió NPK a su layout, se fijó el arco, se sacó el dato crudo del centro, y la línea muestra ahora el ciclo entero con nombres, insignias y leyenda.
- La pregunta a pantalla completa lleva un pestillo local (`_answeredHere`): si el guardado fallara, la pantalla no atrapa al productor (aparece con cierre y un aviso).
- El arco fijo cede solo cuando la pantalla no deja `kNpkMinLowerBlock` (150 px) para el texto; nunca por la longitud del texto.
- La línea de tiempo dice la verdad del sensor: ✓ significa «respuesta compatible», la dosis del marcador es «lo que recomienda la guía», y así lo dice la hoja.
- Muestrear el motor (420 días máx.) cuesta ~420 llamadas puras por cultivo/perfil/fecha; va memoizado (12 entradas).
- Sin declaración y sin textura, todo se comporta como antes (guía intacta).
- **Bug corregido (14 sep, segunda prueba de Oscar): la pregunta volvía a salir en cada entrada a NPK aunque ya se hubiera contestado.** Causa raíz: la declaración se guardaba con el id de cultivo de la app (`crop_avocado_tree`) y el resolver la comparaba con la clave de la guía (`avocado_tree`) texto contra texto → «no coincide» → nunca se aplicaba (y la pantalla NPK es una ruta nueva cada vez, así que el pestillo local no ayudaba). No era un problema de persistencia. Arreglo: `NutritionGuideCatalog.canonicalKey` (misma normalización y alias que `forCrop`) y el resolver compara en canónico; test de regresión con las cuatro grafías. Además, `declare()` imprime en debug si la declaración persistió y si el plan efectivo la aplica.
- Historial (vista NPK): el renglón «Tendencia» desbordaba a la derecha con textos largos («N a la baja · K a la baja»); el valor va ahora flexible con hasta dos renglones.

## 7. Verificación

- La primera versión compiló y corrió en el teléfono de Oscar (14 sep, temprano): de ahí salió la revisión de UI de §6.
- Dos revisiones estáticas independientes sobre todo el código nuevo (sin compilador): 0 errores; 3 lints y 5 detalles lógicos en la primera, 5 avisos y 7 detalles lógicos en la segunda — todos corregidos (pestillo de la puerta, presupuesto de scroll de la tarjeta de cultivo, arco fijo con mínimo, reintento del centrado, arco de ciclo conectado, insignia de ventana plegada, reuso del runtime).
- Tercera revisión estática (14 sep, tarde) sobre la pantalla de la pregunta v3, el arreglo del resolver, el coordinador y el historial: 0 errores de compilación; 2 nits y 5 detalles de UX, corregidos los que aplicaban (opacidad del botón al guardar, resincronía en `didUpdateWidget`, la razón del candado no borra la elección, semántica de accesibilidad en las tarjetas). La flecha al Panel se deja a propósito: la pregunta bloquea NPK, no la app.
- **Pendiente:** `flutter analyze` y la suite. El vigilante (`tools\claude_test_watcher.ps1`) no corre desde el 8 de sep. Peticiones en cola: `024_analyze`, `025_test_plan`, `026_test_resolver_regresion` (además de 019–023 de la sesión anterior). En el `flutter run` de Oscar, la línea `[nutrition] plan efectivo tras declarar: aplica la declaración` confirma el arreglo en el teléfono.
