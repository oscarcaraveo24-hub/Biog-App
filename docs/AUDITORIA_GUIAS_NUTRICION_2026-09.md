# Auditoría de guías nutricionales — fase 2 del nuevo motor (septiembre 2026)

Documento de trabajo de la fase 2 de la *Guía oficial del nuevo motor nutricional v0.4* (§5, §9, §10, §34). Inventaría lo que había, lo que se retiró y lo que se propone por cultivo y etapa, con sus fuentes, para que el equipo revise cultivo por cultivo y marque cada guía como `audited` cuando la dé por buena.

Estado al 6 de septiembre de 2026: **32 guías propuestas, 0 auditadas**. El agricultor no ve ningún rango de dosis hasta que una guía pase a `audited`; sí ve las ventanas por etapa, la prioridad y las reglas 3R.

## 1. Qué se auditó y qué se encontró

### 1.1 Inventario previo (motor legado)

- **Rangos de dosis en kg/ha para anuales: no existían.** El motor viejo no tenía plan de temporada por cultivo; las "recomendaciones" de fertilización nacían de comparar la lectura N/P/K de la sonda con bandas por etapa (`StageTargets` con mg/kg objetivo) y de plantillas de texto (`alerts_engine`, `event_engine`) que decían "bajo"/"alto" según esa comparación. Esa comparación es justo lo que la Guía v0.4 prohíbe (§2, §8): la sonda 7-en-1 deriva N/P/K de la CE y no equivale a un análisis.
- **Frutales:** sí existía una base cuantitativa válida: `TreeRestitutionPlanner` (extracción de fruto × cosecha esperada, con coeficientes revisados contra WSU, Cornell, Yara, Haifa, UC ANR). Se conserva y ahora es la única fuente de dosis para los nueve frutales.
- **Unidades:** las pocas cifras que había en comentarios y documentos mezclaban P elemental con P₂O₅ y K con K₂O sin declararlo. La capa nueva obliga a declarar la forma (`NutrientForm`: N, P₂O₅, K₂O) en cada plan y en cada dosis.
- **Copys retirados:** todas las plantillas "N bajo / N alto / desbalance NPK" por lectura cruda (archivadas en `notes/legacy/alerts_engine_nutrient_knowledge.dart.txt` fuera del repo de la app). Se conservó el conocimiento fenológico útil (qué etapa demanda qué) dentro de las reglas por etapa de cada guía.

### 1.2 Diseño de la capa nueva

- `NutritionGuide` (`lib/core/agro/nutrition/nutrition_guide.dart`): fuentes citables, plan de temporada por nutriente (rango, forma, fuente, estatus), reglas por etapa (`StageNutritionRule`: ventana, reparto del plan, `isCritical`, momento, razón, reglas 3R), fuentes comerciales y reglas generales.
- `kNutritionGuides` (`nutrition_guides.dart`): la tabla, 32 cultivos.
- `NutritionGuideCatalog.forCrop` resuelve la clave canónica del catálogo (con o sin `crop_`), alias en español y `CropKey.name`.
- Visibilidad (actualizado 6 sep, noche, decisión de producto de Oscar): `windowDoseFor` devuelve rango con la guía y el plan en `proposed` **o** `audited` (`GuideAuditStatus.canShowDose`); solo `pending` calla. Todo entra `proposed` y se presenta como «dosis orientativa (guía curada, pendiente de revisión final)», con fuente, reparto y nota del plan en la transparencia. El equivalente comercial se calcula por ventana con `FertilizerProducts` (riquezas de etiqueta; primer producto de `sourceOptionsEs` que aporta la forma). Un plan con mínimo 0 se muestra como condición («hasta 60 kg/ha de K₂O, solo si tu análisis de suelo sale bajo en potasio»).
- Autoridad: con guía curada, **solo sus reglas abren ventanas** en el motor; el perfil fenológico heredado aporta matiz de prioridad pero ya no abre por su cuenta (cierra las ventanas falsas de la auditoría de perfiles: K en llenado de cebada, N en espigamiento de trigo/avena, etc.).
- Frutales: `seasonShare` en las reglas de árbol es la fracción de la dosis anual por restitución que toca en cada ventana (caducifolios N 65/35, K 30/70; perennifolios N 50/20/30, K 30/50/20; P 100 %). Reparto orientativo (WSU Tree Fruit, Cornell, Yara/Haifa cítricos) a confirmar.
- Ventanas críticas (`isCritical`): únicamente donde la literatura documenta pérdida de rendimiento por omisión y donde la ventana cae dentro del periodo en que la sonda ya observa (no en fondo/siembra). Una ventana crítica que cierra sin evidencia de fertilización pesa ×0.94 en el factor de temporada (piso 0.85). Mientras está abierta no pesa nada y nadie registra nada.

## 2. Inventario cultivo × etapa (propuesta)

Rangos en kg/ha, riego, rendimiento medio comercial. **Todos `proposed`.** "Crítica" marca la ventana con `isCritical = true`.

| Cultivo | Plan N | Plan P₂O₅ | Plan K₂O | Ventanas (etapas del motor) | Crítica |
|---|---|---|---|---|---|
| Maíz | 160–240 | 40–80 | 0–60 | Fondo (germination, emergence): N 33 %, P 100 %, K 100 % · Segunda (vegEarly, vegMid): N 67 % | V6–V8 (N) |
| Trigo | 180–240 | 40–80 | 0–40 | Siembra (germination…vegEarly): N 35 %, P, K · Amacollamiento (tillering, elongation): N 65 % | Amacollamiento (N) |
| Cebada | 100–160 | 40–60 | 0–40 | Siembra: N 50 %, P, K · Amacollamiento: N 50 % | Amacollamiento (N) |
| Avena | 80–140 | 40–60 | 0–40 | Siembra: N 40 %, P, K · Amacollamiento: N 60 % | Amacollamiento (N) |
| Frijol | 30–60 | 40–60 | 0–40 | Siembra: N 60 %, P, K · Primera escarda (vegEarly, vegAdvanced): N 40 % | — |
| Tomate | 180–240 | 60–100 | 250–330 | Trasplante 15/50/10 · Vegetativo 25/20/15 · Floración-cuajado 35/20/35 · Llenado-cosecha 25/10/40 (N/P/K %) | Floración-cuajado (N,K) · Llenado (K) |
| Chile | 180–240 | 50–90 | 100–200 | Trasplante 25/70/30 · Vegetativo 25/30/20 · Inicio de floración 35/–/30 · Llenado 15/–/20 | Inicio de floración (N,K) |
| Pepino | 120–180 | 40–80 | 150–250 | Fondo 20/60/20 · Guía 30/20/20 · Floración-cuajado 30/20/30 · Cortes 20/–/30 | Floración-cuajado (N,K) |
| Berenjena | 180–260 | 75–100 | 270–335 | Como tomate | Floración-cuajado (N,K) · Llenado (K) |
| Calabaza | 80–150 | 60–90 | 0–120 | Fondo 30/100/50 · Guía 30/–/25 · Floración-cuajado 40/–/25 | Floración-cuajado (N,K) |
| Lechuga | 100–180 | 40–100 | 100–200 | Fondo 20/100/40 · Roseta 35/–/30 · Acogollado 45/–/30 | Acogollado (N,K) |
| Espinaca | 100–150 | 40–60 | 120–200 | Fondo 30/100/40 · Expansión foliar 70/–/60 | Expansión foliar (N,K) |
| Cebolla | 150–220 | 60–120 | 100–200 | Fondo 30/70/40 · Hoja 35/30/20 · Inicio-llenado de bulbo 35/–/40 | Hoja (N) · Bulbo (N,K) |
| Ajo | 120–200 | 60–100 | 100–200 | Plantación 50/100/50 · Desarrollo de hoja 50/–/50 · Bulbo: cerrada | Desarrollo de hoja (N,K) |
| Frutales (9) | restitución | restitución | restitución | Caducifolios: brotación (N), cuajado (K), llenado (K), post-cosecha (N,P). Perennifolios: brotación-floración (N), cuajado (N,K), llenado (K), post-cosecha (N,P,K) | Brotación (N) · Llenado (K) |
| Rosal, girasol, cempasúchil, tulipán | — | — | — | Ventanas por etapa sin plan | — |
| Cactus, suculenta, sábila, agave, nopal | — | — | — | Solo «crecimiento activo» (N ligero) | — |

## 3. Fuentes por cultivo y qué se verificó en línea

Se marca ✔ lo que se leyó directamente en esta sesión y ✎ lo que se cita como referencia regional pendiente de comprobar (el sitio no permitió lectura automática).

- **Maíz:** ✔ Yara México, *Resumen nutricional del maíz* (>200 kg N/ha absorbidos a 7 t/ha; ≈85 kg P₂O₅; ≈200 kg K; V6→floración etapa clave). ✔ MAPA, *Guía práctica de la fertilización racional*, cap. 17 (12 t/ha: 259 N, 120 P₂O₅, 145 K₂O; 1/3 del N en fondo, resto V6–V8 y V10–V12). ✔ CIMMYT/MasAgro, *Menú de tecnologías validadas: maíz de riego en Sinaloa* (304 vs 173 kg N/ha al mismo rendimiento de 19 t/ha). ✎ INIFAP CENID-RASPA, *La fertilización en los cultivos de maíz* (2005).
- **Trigo:** ✔ Rev. Fitotecnia Mexicana 2022 (Bajío: 240-60-00 tradicional 50-50; el 30-70 rindió 8.4 % más; dosis regionales 200–350 kg N/ha). ✔ Terra Latinoamericana 2012 (recomendación regional 280 N – 80 P₂O₅). ✔ Panorama Agropecuario, Sinaloa (180–220 kg N/ha; 60–100 P₂O₅; 2/3 presiembra + 1/3 primer riego ≤45 días). ✔ CDFA-FREP Wheat (150–200 lb N/acre; 60 % del N entre encañe y espigamiento). ✔ MAPA cap. 16.
- **Cebada:** ✔ Agricultura Técnica en México 2009, variedad Alina (120 N – 60 P a la siembra, Bajío). ✔ MAPA cap. 16 (maltera: N tardío sube proteína). ✎ INIFAP, *Cebada maltera de temporal en Valles Altos*.
- **Avena:** ✔ Rev. Mexicana de Ciencias Agrícolas / Redalyc 2018 (200 kg/ha 18-46-00 a siembra + 200 kg/ha urea a los ~50 días ≈ 128 N, 92 P₂O₅). ✎ INIFAP Zacatecas, paquete tecnológico avena forrajera 2024.
- **Frijol:** ✔ Intagri (extracción 53.5 N, 7.8 P, 55.5 K kg/t; siembra + primera escarda). ✔ Panorama Agropecuario (40–60 kg N/ha tras leguminosa; 80–100 tras cereal). ✔ MAPA cap. 18. ✎ INIFAP paquetes 40-40-00 / 60-40-00.
- **Tomate:** ✔ Agroes (campo abierto 55–65 t/ha: 200–240 N, 65–90 P₂O₅, 300–330 K₂O; −15 % N en goteo). ✔ CDFA-FREP Tomato (<30 % del N antes de cuajado; remoción 220–330 lb K₂O/acre; N tras primer fruto rojo se lava). ✎ INIFAP jitomate intensivo.
- **Chile:** ✔ Panorama Agropecuario (trasplante 200-50-50: 50-60-50 / 50-00-00 a 30 d / 100-00-00 a floración; siembra directa 220-80-50). ✔ Rev. Bio Ciencias UAN (2.4–4.0 N, 0.4–1.0 P₂O₅, 3.4–5.29 K₂O kg/t). ✔ Hortalizas.com (≈200 kg N/ha por temporada).
- **Pepino:** ✔ Intagri (extracción por ciclo 140 N, 26 P₂O₅, 180 K₂O kg/ha). ✎ Zamorano, curvas de absorción.
- **Berenjena:** ✔ Intagri (3.5–5.2 N, 1.5–2 P₂O₅, 5.4–6.7 K₂O kg/t).
- **Calabaza:** ✔ Terra Latinoamericana 2011 (recomendaciones regionales 80-60-00 a 130-90-00; probadas 150–330 N y 90–150 K₂O). ✔ Rev. Fitotecnia Mexicana 2012 (absorción ≈180 N, 18 P, 37 K kg/ha, lineal en 80 días).
- **Lechuga:** ✔ CDFA-FREP Lettuce (100–180 lb N/acre; 70–80 % del N entre acogollado y cosecha; sin N con nitratos > 20 ppm; K 70–110 lb K₂O/acre removidos). ✔ Cajamar (extracción a 35 t/ha: 80–100 N, 30–50 P₂O₅, 160–210 K₂O; sin cloruros).
- **Espinaca:** ✔ TecnoAgro (a 25 t/ha: 110–130 N, 38–45 P, 180–220 K kg/ha). ✎ Acta Agronómica (UNAL), dosis y momentos de N.
- **Cebolla:** ✔ Intagri (150–200 kg N/ha; ≤1/3 a siembra; N fuerte tardío retrasa madurez). ✔ CDFA-FREP Onion (150–250 lb N/acre goteo; <20 % del N en la primera mitad; 65–80 % en temporada; remoción 61–98 lb P₂O₅ y 170–225 lb K₂O/acre). ✔ Fertilab (Zacatecas y Morelos: repartos). ✔ Haifa (25–30 % N preplantación; parar N a 2/3 del bulbo).
- **Ajo:** ✔ Biotecnia UNISON (goteo Costa de Hermosillo: óptimo 180 kg N/ha, 22 t/ha). ✔ InfoAgro México (120–240 N, 60–80 P₂O₅; goteo 250-100-265; todo el P y mitad de N y K a plantación, resto a 60 días, nunca tras iniciar bulbo). ✔ Intagri (tres momentos).
- **Frutales:** coeficientes de `TreeRestitutionPlanner` (ya auditados en agosto: WSU, Cornell, Yara, Haifa, UC ANR, IPNI). Las ventanas por etapa son fenológicas, no cuantitativas.
- **Ornamentales y baja demanda:** conocimiento conservado de los motores legados (cempasúchil, girasol, rosal, frutales, nopal); sin plan cuantitativo.

## 4. Decisiones y matices que el equipo debe confirmar

1. **Ventanas críticas.** La lista de la tabla es la propuesta. Si el equipo quiere que una omisión NO pese en el score (por ejemplo frijol o pepino), basta con poner `isCritical: false` en esa regla.
2. **Ventanas de fondo/siembra no críticas.** Suelen ocurrir antes de instalar la sonda o durante los 7 días de aprendizaje; marcarlas críticas generaría penalizaciones falsas. Además, el ledger ya protege: si la ventana no fue observable (`notComparable`) o la cobertura fue insuficiente (`inconclusive`) no hay penalización.
3. **Rendimiento supuesto.** Cada plan declara en `notesEs` el rendimiento para el que vale. Temporal o bajo insumo → tomar el mínimo o menos. La app no escala por rendimiento todavía (fase posterior: meta de rendimiento en la proyección).
4. **P y K en suelos mexicanos.** Muchos suelos agrícolas del centro-norte son ricos en K; el mínimo de K₂O es 0 en cereales a propósito. P siempre por análisis Olsen.
5. **Formas.** Todo está en N, P₂O₅ y K₂O. Cuando una fuente daba P o K elemental (Intagri frijol, TecnoAgro espinaca, Fitotecnia calabacita) se convirtió (×2.29 P→P₂O₅, ×1.2 K→K₂O) o se dejó como extracción de referencia sin usarla como plan.
6. **Cómo marcar una guía como auditada.** En `nutrition_guides.dart`, cambiar `auditStatus: GuideAuditStatus.audited` en la guía **y** `audit: GuideAuditStatus.audited` en cada `SeasonNutrientPlan` (se puede auditar N sin auditar K). Desde el 6 sep los rangos ya se ven en `proposed`; auditar solo cambia el calificativo del copy («guía auditada» en vez de «guía curada, pendiente de revisión final»). La prueba `nutrition_guides_test.dart` ("todas las guías entran como proposed…") se ajusta entonces por cultivo.
7. **Reparto anual en frutales.** Confirmar las fracciones de `seasonShare` de `_deciduousTreeRules` y `_evergreenTreeRules`; suman 1.0 por nutriente y evitan que brotación y post-cosecha muestren las dos la dosis anual completa.

## 5. Pendientes de esta fase

- Leer los PDF de INIFAP marcados ✎ (bloquean lectura automática) y confirmar fórmulas regionales.
- Decidir con el socio agrónomo el estatus de cada guía.
- Meta de rendimiento por parcela para escalar el plan (fase posterior).
- ~~Equivalente comercial por ventana~~ — hecho el 6 sep (`FertilizerProducts.equivalentEs`, redondeo a múltiplos de 5 kg/ha; en g/m² al entero). Falta ampliar la tabla de productos si una guía cita uno que no está (entonces cae al producto por defecto de esa forma: urea / MAP / cloruro de potasio).
