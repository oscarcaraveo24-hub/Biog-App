# Cierre · Nuevo motor nutricional (fases 0–8 de la Guía v0.4) — 6 sep 2026

Sesión de implementación de la *Guía oficial del nuevo motor nutricional v0.4* (31 ago 2026) sobre BIO-G, con el matiz acordado el 5 de septiembre: **el agricultor no registra fertilizaciones; el sensor y las tendencias lo hacen todo.**

## 0. Estado en una frase

El motor NPK legado (bandas por lectura cruda, déficit ppm, dosis target − raw) está apagado y sustituido por un motor de *preparación nutricional* que decide por etapa y guía, observa la respuesta del suelo con la CE normalizada por humedad y un libro de ventanas persistido, y solo penaliza cuando una ventana importante cierra sin evidencia. Todo compila lógicamente por revisión estática; **`flutter analyze` y `flutter test` siguen pendientes** porque no hay Dart en el entorno de Claude (ver §7).

## 1. Decisiones de diseño que mandan

1. **Tres capas** (Guía §3): raw → físico → agronómico. N/P/K viven en raw como señal nativa (`AgroMetricEval.nativeSignal`: banda `unknown`, peso 0). Nunca suben a la capa agronómica como suficiencia química.
2. **Sin registro manual de fertilización** (corrección de Oscar, 5–6 sep). No existe modelo, pantalla, botón ni API para capturarla. Cualquier "aplicación" es una *firma compatible con fertilización* detectada por el sensor. Razón: maximizar sensor y tendencias y no arriesgar que un error de captura descalibre la app.
3. **Ventana nutricional** = etapa + guía dicen *qué debería ocurrir*. El sensor observa *qué parece haber ocurrido*. El historial del sitio ayuda a comparar magnitudes. Copys oficiales: «Esta etapa necesita nutrición.» → «Estoy observando la respuesta del suelo.» → «Respuesta compatible con fertilización detectada.» / «Esta ventana nutricional no mostró evidencia suficiente de haber sido atendida.»
4. **Penalización solo al cerrar**: una ventana `isCritical` que termina `unattended` (observable, cobertura ≥ 50 %, ≥ 24 lecturas útiles, sin firma ni siquiera «posible») pesa ×0.94 en el factor de temporada, piso 0.85. `inconclusive` y `notComparable` nunca pesan. Nunca «Nraw no subió → no fertilizó»: la urea tiene 4 días de gracia y una firma gradual propia.
5. **Detección multicanal y contextual**: carga iónica normalizada `EC / (VWC/100)` contra baseline robusto (mediana/MAD, 72 h), N/P/K nativos como seguidores, VWC para distinguir riego-solo de fertirriego, historial del sitio para la magnitud habitual. Varios saltos relacionados en 10 días = UNA firma.
6. **Guías curadas visibles solo si están auditadas**. 32 guías `proposed` con fuentes; 0 `audited`. La app abre ventanas (eso sí se ve) y explica que la cifra está pendiente.

## 2. Qué se construyó, por fase

| Fase | Entregable | Archivos clave |
|---|---|---|
| 0 Freeze | tag `legacy-npk-v1` + rama de archivo (en la PC) | — |
| 1 NPK Reset | 26 motores de score sin N/P/K; `alerts_engine` y `event_engine` sin bandas NPK; enum de eventos limpio (`npkReading`, `nutritionUpcomingWindow`, `nutritionResponseDetected`, `nutritionWindowUnattended`, `highSalinity`); sin `NpkCaps`, `NutrientTargetRangeResolver`, `NutrientRecommendationEngine`, `FertilizationPlanner` | `lib/core/agro/*_agro_score_engine.dart`, `alerts_engine.dart`, `event_engine.dart`, `agronomic_event.dart` |
| 2 Auditoría de guías | `NutritionGuide` + tabla `kNutritionGuides` (32 cultivos, `proposed`) + catálogo con alias + documento de auditoría | `lib/core/agro/nutrition/nutrition_guide*.dart`, `docs/AUDITORIA_GUIAS_NUTRICION_2026-09.md` |
| 3 Sensor contract | `SoilSensorSpec.sn3002` (registros, unidades, plausibilidad, canales derivados, warm-up); única conversión µS→mS en la frontera; códec BLE resuelve `probe_id` y descarta lo implausible como ausente | `lib/core/telemetry/soil_sensor_spec.dart`, `biog_ble_codec.dart`, `biog_telemetry.dart` |
| 4 AgroScore limpio | `SoilConditionScore`: media ponderada solo con señales presentes, cobertura «x de 5 señales», penalización crítica una sola vez | `lib/core/agro/soil_condition_score.dart` |
| 5 Readiness V1 | `NutritionReadinessEngine` → `NutritionDecision` (LEARNING → MONITOR → PREPARE → ACTION WINDOW → RESPONSE WINDOW), prioridades por perfil + guía, 3R, condiciones (humedad, suelo frío, CE), recomendación con dosis solo si guía auditada o restitución de frutales | `lib/core/agro/nutrition/nutrition_readiness_engine.dart`, `nutrition_types.dart` |
| 6 UI/UX | Panel (tarjeta NPK = decisión; anillo de suelo con cobertura), pantalla NPK (gauge escalado al sitio, tendencia, nota de dato nativo, hoja de detalle), Historial («N/P/K nativos»), informes rápido y PDF («SEÑALES NATIVAS N/P/K» + «MANEJO NUTRICIONAL»), notificaciones | `dashboard_presenter.dart`, `npk_screen.dart`, `history_presenter.dart`, `quick_report_builder.dart`, `pdf_report_builder.dart` |
| 7 Instalación + memoria | Época de instalación/reubicación (`InstallationEpoch`), 7 días de aprendizaje, baselines por época; `NutritionCoordinator.relocate` (sin UI todavía) | `site_learning.dart`, `nutrition_coordinator.dart`, `nutrition_local_storage.dart` |
| 8 Respuesta | `FertilizationSignatureScanner` (sin anclaje), `NutritionWindowLedger` (open / attendedDetected / unattended / inconclusive / notComparable), `NutritionDecision` publicada por `BioGStore` igual que `IrrigationDecision`; `EventEngine` solo traduce decisiones a eventos | `fertilization_signature_scanner.dart`, `nutrition_window_ledger.dart`, `biog_store.dart`, `crop_event_recorder.dart` |
| Nube | Migración **propuesta y no aplicada** para `nutrition_windows` e `installation_epochs` | `supabase/migrations/20260906_nutrition_windows_and_epochs.sql` |

## 3. Criterios de aceptación §36 (revisión estática; confirmar con la suite)

| Criterio | Estado | Dónde se comprueba |
|---|---|---|
| N/P/K siguen llegando del sensor y se guardan como raw | ✔ | `BioGTelemetry` conserva `n/p/k`; el códec solo descarta implausibles |
| History sigue graficándolos | ✔ | `history_npk_chart_card.dart` («Señal nativa reciente») |
| Dashboard no los clasifica como suficiencia química | ✔ | `dashboard_presenter.dart`: tarjeta NPK = `NutritionDecision` |
| AgroScore no usa N/P/K raw como peso directo | ✔ | `SoilConditionScore` + prueba `soil_condition_score_test.dart` |
| Ningún motor crea «N bajo / P crítico / K alto» desde raw | ✔ | los tipos `nitrogenLow/High`, `phosphorusLow/High`, `potassiumLow/High`, `nutrientImbalance` ya no existen en el enum; solo quedan nombrados en un comentario histórico de `agronomic_event.dart` |
| EventEngine no recomienda fertilización desde bandas NPK | ✔ | `_nutritionEvents(input)` solo lee `NutritionDecision` |
| No existe cálculo de déficit ppm desde raw | ✔ | `NutrientTargetRangeResolver` y `NpkCaps` eliminados |
| No existe dosis derivada de target − raw | ✔ | `FertilizationPlanner` / `NutrientRecommendationEngine` eliminados; dosis solo de guía auditada o restitución |
| Recomendaciones visibles vienen de etapa/guía/3R/contexto | ✔ | `NutritionReadinessEngine._recommendation` |
| Pantalla NPK e informes declaran la naturaleza nativa/tendencial | ✔ | `kNativeSignalNoteEs` en pantalla; la misma nota obligatoria en el PDF («Datos nativos… no equivalen a un análisis de laboratorio»); informe rápido con «Señal nativa» y tendencia |
| Tests de humedad, riego, pH, CE, RT y cultivos siguen pasando | ⏳ | **pendiente de `flutter test`**; se prevén desvíos numéricos en pruebas con puntajes fijos porque N/P/K salieron del denominador |

Reglas §37 aplicadas explícitamente en código: nunca escalar N/P/K al target (2, 1), nunca déficit desde una lectura (3), nunca kg/ha desde raw (4), «compatible» ≠ «absoluto» (5), urea sin pico inmediato no es fallo (6: gracia de 4 días + firma gradual), baseline nunca incluye el evento (8: guarda de 30 min y ventana previa), ausencia nunca es cero ni castigo (9), CE compensada una sola vez (10: `ecTemperatureCompensated` en el contrato), sin calibraciones al agricultor (11), dos ubicaciones nunca comparten baseline (13: épocas).

## 4. Investigación sobre la sonda 7-en-1 (resumen)

- La familia SN-3002/RS-ECTHNPKPH deriva N, P y K de la conductividad y la temperatura con coeficientes de fábrica; estudios independientes (MDPI *Sensors* 2022 sobre sondas NPK de bajo costo; Darmawan et al. 2023; *RSC Advances* 2024) coinciden en que la correlación con laboratorio es débil y en que el canal útil es la CE. Por eso la app los trata como señal de tendencia y la evidencia de fertilización nace de la CE normalizada.
- Lo que sí es defendible con este hardware: (a) detectar cambios de carga iónica en zona radicular, (b) distinguir riego de fertirriego con la humedad, (c) comparar magnitudes dentro del mismo sitio y época, (d) medir persistencia (24 h sostenidas) para no confundir un pulso de riego con un aporte.
- Mejoras propuestas que quedan para banco/hardware (fases 9–13): CE normalizada por textura (§10), warm-up universal (§38), verificación registro por registro de `SoilSensorSpec.sn3002`, y sensor VWC/pH de referencia.

## 5. Pendientes y decisiones para Oscar

1. **Ejecutar la verificación** (§7). Corregir errores de analizador y los desvíos numéricos de pruebas viejas con puntajes fijos.
2. **Auditar guías** cultivo por cultivo y marcar `audited` (ver documento de auditoría §4.6).
3. **Migración de Supabase**: decidir si se aplica (solo cuando la app sincronice ventanas; hoy todo es local).
4. **UI de «Reubicar BIO-G»** (fase 7): el coordinador ya expone `relocate`; falta el botón en Cuenta/Equipo.
5. Archivo huérfano: `lib/core/agro/barley_crop_definition.dart` (no lo importa nadie). Borrar en una limpieza aparte.
6. `StageWeights.npk/n/p/k` siguen declarados en los perfiles: hoy no mueven nada; se pueden retirar en una limpieza aparte.
7. Estatus de auditoría de la restitución de frutales: el planner ya fue auditado en agosto; decidir si sus dosis se muestran desde ya (`usesTreeRestitution` las muestra) o se esperan.

## 6. Lo que NO cambió a propósito

- `IrrigationEngine`, motor de humedad, textura y ventanas hídricas: intactos (Guía §37.14).
- `TreeRestitutionPlanner`: se conserva la extracción/restitución; se retiró el ajuste `soilLevelFor` que dependía de NPK raw.
- Diseño visual: mismas tarjetas, mismos colores; cambian los textos y la fuente del dato.

## 7. Cómo verificar en la PC

```powershell
cd C:\Users\oscar\Documents\bio_g
flutter pub get
flutter analyze
flutter test
```

O con el vigilante para que Claude lea resultados: `powershell -ExecutionPolicy Bypass -File .\tools\claude_test_watcher.ps1` (peticiones en `temp/claude_sync/req/<id>.req`, resultados en `temp/claude_sync/res/`).
