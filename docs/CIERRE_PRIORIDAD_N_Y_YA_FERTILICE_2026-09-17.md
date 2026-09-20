# Cierre · Plegado por prioridad agronómica, «Ya fertilicé» y línea de tiempo honesta — 17 sep 2026

Sesión sobre el motor nutricional (Guía v0.4) a partir de la prueba de Oscar con maíz: al elegir «una sola vez» la línea de tiempo seguía pintando tres fertilizaciones y la pestaña de nitrógeno, en vegetativa avanzada, no daba dosis. Investigación en paralelo, cultivo por cultivo, de *dónde* conviene concentrar el nitrógeno y de si las dosis en kg/ha se sostienen.

## 0. Estado en una frase

Con k pasadas declaradas el nitrógeno cae en las **k mejores ventanas de la guía** (prioridad agronómica investigada con fuentes primarias; maíz «una sola vez» → V6–V8, no la siembra), las ventanas plegadas **ya no se pintan** como fertilización, la línea sale **en gris** hasta que el productor contesta la pregunta de NPK, existe la cuarta tarjeta **«Ya fertilicé»**, y cinco dosis/guardarraíles cambiaron con ≥3 fuentes independientes cada uno. **Verificación: pendiente del vigilante** (`027_analyze`, `028_test_nutricion`, `029_test_all` en cola; ver §7).

## 1. Diagnóstico (lo que pasaba en maíz)

- El resolver plegaba «una sola vez» en la **primera** ventana de N de la guía (fondo, germinación). Estando en vegetativa avanzada, el fondo ya había pasado: NPK no tenía nada que dosificar.
- La línea de tiempo pintaba las ventanas plegadas como «orientativas» con la insignia «N»: se leían como tres fertilizaciones.
- En aguacate «se veía bien» porque las ventanas plegadas seguían abriendo fósforo/potasio y la insignia cambiaba a «P K»; el número de «N» sí coincidía con lo elegido.
- La pestaña de nitrógeno en una etapa plegada decía «la guía de Maíz no reparte fertilizante», que no era cierto: era el plan del productor.

## 2. Decisiones de producto (Oscar, 17 sep)

1. **«Toda la temporada, como la guía»**: la declaración describe la temporada (no se re-ancla al «hoy»), pero la guía decide **cuáles** ventanas son las mejores para 1, 2 o 3 pasadas, con investigación por cultivo.
2. **Cuarta tarjeta «Ya fertilicé»** en la pregunta de NPK, con las cuatro tarjetas en dos filas de dos.
3. **Dosis**: se corrigen solo con **mínimo 3 fuentes confiables e independientes**; el resto se reporta.
4. Línea de tiempo: si no se ha elegido el plan en NPK, se ve **en gris**; con plan, se ven exactamente las pasadas elegidas.

## 3. Qué se construyó

| Pieza | Qué hace | Archivos |
|---|---|---|
| Prioridad por guía | `NutritionGuide.nitrogenPassPriority` (claves de etapa de la más a la menos importante) + `nitrogenRulesByPriority`; `singlePassStageKey` queda de respaldo | `nutrition_guide.dart`, `nutrition_guides.dart` (23 guías comestibles) |
| Resolver | Conserva las k primeras de la prioridad (en orden fenológico). El N de cada ventana plegada va a la conservada más cercana **antes** de ella; si no hay, a la primera después. Nuevos campos `keptStageKeys`, `keptWindowLabelsEs`, `planNoteEs`, `isAlreadyDone`. `canDeclare` cuenta solo opciones de número (la cuarta no obliga a preguntar) | `nutrition_plan_resolver.dart` |
| «Ya fertilicé» | `NitrogenPassPlan.alreadyDone` (id `already_done`, 0 pasadas): todas las ventanas de N se pliegan (siguen abiertas para P/K), sin ⚠ ni score; NPK: «Nitrógeno ya aplicado» | `nutrition_season_declaration.dart`, resolver, `nutrition_plan_gate.dart`, `npk_tab_copy.dart` |
| Motor | `NutritionDecision.planNoteEs` / `isNitrogenAlreadyDone`; `_closedWindowNoteEs` distingue «plegada por tu plan» de «la guía no reparte»; versión 1.2.0 | `nutrition_readiness_engine.dart`, `nutrition_types.dart`, `engine_versions.dart` |
| Pestaña N | Etapa plegada → «Sin nitrógeno en esta etapa» + «Según tu plan (una sola vez), el nitrógeno de Maíz va en «Segunda fertilización (V6–V8)». Si eso cambió, ajusta tu plan con el icono de ajustes»; P/K conservan su nota de etapa | `npk_tab_copy.dart` |
| Línea de tiempo | VM: ventana plegada del todo → **sin marcador**; `awaitingDeclaration` (sin respuesta y con algo que contestar, o memoria del sitio sin leer) → sin marcadores; `isAlreadyDone`. Widget: en gris (desaturado, 62 % de opacidad, sin pulso), leyenda «Elige cómo vas a fertilizar en NPK…», cabecera «Plan sin elegir»; en la pantalla de cultivo tocarla abre NPK y se pide `sync` si la memoria no se ha leído | `nutrition_timeline_vm.dart`, `nutrition_timeline.dart`, `seeds_screen.dart` |
| Pregunta NPK | Cuatro tarjetas (2 × 2, 188 px), «Ya fertilicé» con esfera + palomita, explicación propia; ayuda de «una sola vez» y «dos veces» ya nombra las ventanas de la prioridad | `nutrition_plan_gate.dart` |
| Pruebas | Resolver (prioridad, plegado por cultivo, cuarta opción, cebolla/cítricos con mínimo 2, invariantes de prioridad), VM (gris, un solo marcador, «ya fertilicé»), declaración (JSON), copy NPK (etapa plegada, ya fertilicé), guías y motor actualizados a los planes nuevos | `test/core/agro/nutrition/*`, `test/screens/npk/*` |

### 3.1 Aritmética del plegado (congelada en pruebas)

| Cultivo | Declaración | Ventanas de N que quedan | Reparto |
|---|---|---|---|
| Maíz (arcilla) | una sola vez | V6–V8 | 100 % (160–240 kg N/ha ≈ 350–520 de urea) |
| Maíz | dos veces | fondo + V6–V8 | 33 / 67 |
| Tomate | dos veces | vegetativo + floración | 40 / 60 |
| Nogal | dos veces | brotación (marzo) + cuajado (junio) | 55 / 45 |
| Pistache | dos veces | crecimiento del fruto + llenado | 50 / 50 |
| Mango | dos veces | cuajado + post-cosecha | 35 / 65 |
| Cebolla | dos veces | desarrollo de hoja + inicio de bulbo | 65 / 35 |
| Cebada | una sola vez | siembra | 100 % |
| Cualquiera | ya fertilicé | ninguna | — |

## 4. Investigación: prioridad de ventanas por cultivo

Cinco informes adversariales (intentar refutar lo escrito) con fuentes primarias; están completos, con URL y grado de lectura, en `docs/investigacion_prioridad_N_2026-09-17/`.

| Cultivo | `nitrogenPassPriority` | Evidencia principal |
|---|---|---|
| Maíz | vegEarly › germination › vegAdvanced | Purdue (más eficiente justo antes de V6), Nebraska EC117 (V8; en arena ≥67 % en temporada), Wisconsin/Bundy (136 sitios: presiembra = cobertera en franco/arcilloso; en arena +30 bu/ac y 79 % vs 45 % de recuperación), Clark 2020, Missouri/Scharf (hasta V11 rinde completo), INIFAP Chihuahua/Zacatecas (mitad siembra + mitad primer auxilio) |
| Trigo | tillering › germination (riego) | Fitotecnia 2022 ¹⁵N Celaya (todo al encañe 4,850 ≈ todo a la siembra 4,786; 30/70 = 6,822), CIMMYT Yaqui (30 % del N presiembra se pierde; primer riego etapa crítica), K-State. Temporal se invierte (NDSU) — pendiente de la fase de riego |
| Cebada | germination › tillering | NDSU (todo presiembra, nada tras 5 hojas), INIFAP Alina (120-60 a la siembra), CINVESTAV/INIFAP ¹⁵N (todo a la siembra), MAPA |
| Avena | germination › tillering | INIFAP Zacatecas (100-60-00 presiembra), INIFAP Chihuahua (60-40-00 a la siembra + 20–40 opcional), NDSU |
| Frijol | vegEarly › germination (riego) | Henson & Bliss 1991 (1 ensayo), Frontiers 2020 (N a la siembra baja Ndfa 45 → 20 %); en temporal INIFAP fertiliza a la siembra — evidencia limitada, se mantiene |
| Tomate, chile, pepino, berenjena | floracion › vegetativo › llenado › germinacion | CDFA (<30 % del N antes del cuaje), UC IPM (una cobertera de 112–134 kg N/ha), NMSU H-257 (ventana óptima desde primera flor), UF/IFAS (pepino 80/20; berenjena 2–3 aplicaciones) |
| Calabaza | vegetativo › floracion › germinacion › llenado | UF/IFAS Csizinszky 1985 (785 bu/ac con DOS aplicaciones: 50 % fondo + 50 % mitad de ciclo) |
| Lechuga | desarrolloVegetativo › formacionCabeza › germinacion | CDFA/UC Davis (primera cobertera post-aclareo incondicional; segunda condicional a NO₃ < 20 ppm), UC ANR VRIC |
| Espinaca | vegetativoTemprano › expansionFoliar › germinacion | Acta Agronómica UNAL (mejor: 90 kg N/ha a 15 días), UC ANR VRIC (pico 5–7 lb/ac/día) |
| Cebolla | induccionBulbificacion › vegetativo › germinacion | CDFA (<20 % en la primera mitad; fertirriego desde inicio de bulbo), PNW 546, INIFAP Chihuahua |
| Ajo | vegetativeLeafDevelopment › bulbDifferentiation › clovePlanting | Biotecnia/UNISON Hermosillo (5 fracciones 1 oct–15 feb), Cal Ag 1988 |
| Manzano, peral, durazno | budbreak › post_harvest | Wisconsin (antes de la caída de pétalo), Cornell 2023, NMSU H-319, Havis 1956 vía Penn State (otoño solo rinde peor), CDFA durazno |
| Nogal | budbreak › fruit_set › fruit_fill | Cruz-Álvarez 2020 (Jiménez), INIFAP PT-0008 (110 en marzo + 110 en mayo), NMSU H-602, UGA B1304, Tarango-INIFAP (agosto ≥ ⅓ de primavera) |
| Pistache | fruit_set › fruit_fill › budbreak › harvest_maturity | CDFA/Siddiqui & Brown (mínimo dos eventos; año «off» mitad antes del endurecimiento + resto julio-agosto; 20/30/30/20) |
| Naranjo, limonero | budbreak › fruit_set › post_harvest › harvest_maturity | CDFA (⅔ entre brote de primavera y amarre; Tulare: 2 aplicaciones = 1 en rendimiento, menos lixiviación), UF/IFAS CG091, UC ANR/Roccuzzo, Fitotecnia Veracruz 2021 (2 aplicaciones) |
| Mango | post_harvest › fruit_set › budbreak | AMIA (60–70 % post-cosecha), National Mango Board, INIFAP Ataulfo (julio y septiembre), UF/IFAS |
| Aguacate | budbreak (bloque flor → cuajado) › post_harvest › fruit_set | Lovatt/UCR 2013 (abril y noviembre), CDFA (justo después de plena floración), UC ANR, INIFAP Nayarit |

Nota de implementación: la prioridad es una sola lista por cultivo. La dimensión **riego rodado / temporal / fertirriego** (trigo, frijol, maíz en arena) cambia el orden en algunos casos y queda para la fase 2 (paso «¿Cómo riegas?» del onboarding).

## 5. Dosis y guardarraíles: qué cambió y qué se sostuvo

### 5.1 Cambios aplicados (≥3 fuentes independientes cada uno)

| Guía | Campo | Antes | Ahora | Fuentes |
|---|---|---|---|---|
| Nogal | N anual | 100–150 | **100–200** | NMSU H-602 (168–224), INIFAP PT-0008 (110 + 110 = 220), Tarango-INIFAP Delicias (220–240), Sánchez 2009 Terra (óptimo 160), UGA/TAMU/MSU (10 lb N por 100 lb de nuez). Mínimo 100 lo sostiene Cruz-Álvarez (41 % arcilla) |
| Durazno | N anual | 90–112 | **60–112** | CDFA-FREP (25–75 lb/acre fresco = 28–84; 6 t/acre → 71), Penn State/Marini (50–100 lb = 56–112; el autor aplica 67), INIFAP Zacatecas (55-55-55) |
| Manzano | N anual | 100–140 | **70–140** | WSU (por demanda 75–132), Wisconsin (45–67 mantener; 56–90 bajo), Cornell 2023 (22–56 al suelo con foliar bajo); techo sostenido por UACH 138 y NMSU |
| Ajo | K₂O mínimo | 100 | **0** (por análisis) | Cal Ag 1988 (10 ensayos: sin respuesta a K con > 100 ppm), PNW 546 (Allium: 0 con > 100 ppm), CDFA cebolla (solo < 100 ppm) |
| Tomate, chile, pepino, berenjena, calabaza, cebolla, ajo | mínimo de pasadas | 3 | **2** (3 en arena) | UC IPM tomate (arranque + una cobertera «normalmente basta»), UC ANR pimiento («presiembra y una o más coberteras»), UF/IFAS calabacita (el mejor tratamiento fueron DOS aplicaciones), UF/IFAS pepino (80/20 > todo a la siembra), UF/IFAS berenjena (2–3 aplicaciones iguales), PNW 546 cebolla (una cobertera basta donde la lixiviación es baja); la única sigue prohibida |
| Naranjo, limonero | clasificación / mínimo | splitRequired, 3 | **splitRecommended, 2 (3 en arena), ★ en 3** | CDFA (Tulare: 2 aplicaciones = 1 en rendimiento), Fitotecnia Veracruz 2021 (2 al suelo), UF/IFAS (3–4 solo para fertilizante seco en arena de Florida) |
| Aguacate | `timingEs` del bloque de floración | «Antes y durante la floración principal» | **«De la plena floración al cuajado temprano… no lo adelantes a enero-febrero»** | CDFA («justo después de plena floración»), Lovatt (abril; enero-febrero lo más lixiviable), UC ANR |
| Textos | citas inexactas | — | Maíz: «76–84 %» → «< 15 % de los casos» (Clark), «68 bu/ac / A3634» → «+30 bu/ac, 79 % vs 45 %» (Wisconsin/Bundy). Trigo: «FAO-Yaqui» → CIMMYT. Calabaza: aclarado que fueron DOS aplicaciones. WSU: ya no dice «50–100 lb/acre» (calcula por demanda). UF/IFAS cítricos: 125–240 lb/acre (no 120–200) | informes |

### 5.2 Se sostienen (verificado, sin cambio)

N, P₂O₅ y K₂O de maíz (160–240 / 50–80 / 0–60), trigo, cebada (100–130 con reserva: el Bajío rinde óptimo a 180 pero sin medir proteína), avena, frijol (40–100), tomate (K₂O 120–180: los 250–330 son remoción a ~100 t/ha), chile, pepino, berenjena, calabaza, lechuga, espinaca, cebolla, ajo (N y P), peral, pistache, cítricos, mango (con nota: UF/IFAS «poco o nada» en adulto), aguacate 150–220 (con reserva: CDFA 53–100 y Lovatt 112 van por debajo; falta tercera fuente), P₂O₅ mínimo 0 en todos los frutales, topes 112 (cebolla/ajo) y 120 (nogal).

### 5.3 Reportado, sin aplicar (menos de 3 fuentes o decisión de producto)

- **Cebada y avena: amacollamiento como ventana crítica no se sostiene con una sola pasada** (NDSU, INIFAP Alina, CINVESTAV; INIFAP Zacatecas/Chihuahua). Con la prioridad nueva, quien declara «una sola vez» pliega amacollamiento (deja de pesar), así que el riesgo real es solo para quien no contesta; se deja como está y se anota.
- **Maíz V10–V12 crítica solo condicional**: ninguna fuente documenta pérdida por omitir una tercera pasada cuando siembra + V6–V8 fueron suficientes. Con «dos veces» se pliega y no pesa; solo pesa en el plan de 3.
- **Lechuga/espinaca, tope 45 kg N/ha**: solo vale para fondo/arranque (CDFA 20–40 lb); el reparto lo rebasa en cobertera (180 × 0.45 = 81). Propuesta (2 fuentes): tope de cobertera 90 / 60. Hoy el tope solo afecta a la opción «una sola vez», que ya está deshabilitada por el mínimo 2: sin efecto práctico.
- **Nogal**: la fracción de agosto (20 %) queda corta frente a Tarango (≥ ⅓ de lo de primavera ≈ 30 %); cambio de reparto pendiente de una segunda fuente.
- **Aguacate N mínimo 150**: dos líneas de evidencia (CDFA 53–100; Lovatt 112) por debajo; falta una tercera (p. ej. Salazar-García/INIFAP).
- **Espinaca P₂O₅**: verificar si TecnoAgro reporta P o P₂O₅ (38–45 kg P = 87–103 P₂O₅).
- **Elote y maíz forrajero**: sin fuente primaria propia (forrajero: INIFAP Chihuahua 180-90-00 cae dentro del rango; K en forraje pendiente).
- **Ornamentales («que en todos diga»)**: con la regla de 3 fuentes solo **girasol** tiene plan defendible para N (60–120 kg N/ha: Colpos 2021, Terra 2012, INIFAP 2025), pero las tres son de girasol de **grano/aceite** y los perfiles de la app son ornamentales (jardín, maceta, corte): no se aplicó; decisión de Oscar. Nopal verdura: 2 recomendaciones (Colpos 1991 120-100-00; UANL 2006 150-100-50) leídas vía cita, a una fuente del umbral. Tulipán: 2 documentos del mismo instituto (WUR: 80 kg N/ha a la emergencia; total 134–176) que además contradicen la regla «brote y flor sin fertilizar». Rosal, cempasúchil, cactus, suculenta, sábila, agave: sin plan defendible (1 fuente o ninguna con cifra); se mantiene «según etiqueta» con la orientación cualitativa (¼–½ de etiqueta, mensual en crecimiento). PDF bloqueados para lectura manual: ICAMEX cempasúchil, INIFAP Morelos (nopal), CENID-RASPA (nopal, maíz), INIFAP Durango (girasol).

## 6. Riesgos y notas de diseño

- Con «toda la temporada como guía», un productor que instala el Bio-G en V10 y declara «una sola vez» verá que su única pasada (V6–V8) ya pasó: NPK le dice dónde iba y que cambie el plan si no la hizo. Para el que ya fertilizó existe ahora «Ya fertilicé». Para el que va a hacer su única pasada *ahora*, la salida es «tres o más» (o cambiar el plan al pasar la ventana); la variante «las que faltan desde hoy» se descartó a propósito.
- La línea en gris también aparece mientras la memoria del sitio no se ha leído (primer cuadro): es breve y evita enseñar un plan que quizá no es el del productor.
- Antiguas declaraciones guardadas siguen valiendo; `already_done` es un id nuevo (una app vieja lo leería como «sin declaración»).
- Las pruebas del 13–14 sep nunca corrieron (el vigilante estaba apagado): dos aserciones desfasadas se corrigieron de paso (`nextWindowRuleAfterAny('vegMid')` con tres ventanas; cebolla `minNitrogenPassesCoarse` mayor que sus ventanas).

## 7. Verificación

- Revisión estática propia de todos los diffs; sin compilador en esta sesión (el contenedor no alcanza storage.googleapis.com/pub.dev).
- Peticiones al vigilante en cola: `027_analyze`, `028_test_nutricion` (`test/core/agro/nutrition` + `test/screens/npk`), `029_test_all`. Las peticiones viejas 019–026 se movieron a `temp/claude_sync/_stale_req/`.
- Pendiente: probar en el teléfono maíz con «una sola vez» (marcador único en V6–V8; en V10–V12 la pestaña de N explica el plan), la línea en gris antes de contestar, la cuarta tarjeta, y aguacate/nogal con «dos veces».
