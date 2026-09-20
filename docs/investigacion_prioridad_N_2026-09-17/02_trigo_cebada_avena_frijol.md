# Verificación adversarial: trigo, cebada, avena y frijol (BIO-G, 17-sep-2026)

Alcance: guías `_wheat`, `_barley`, `_oat`, `_bean` de `nutrition_guides.dart`. Se intentó **refutar** la prioridad de ventanas, el tope por pasada, las dosis y la criticidad con fuentes primarias (INIFAP, CINVESTAV, Colpos, CIMMYT, NDSU, K-State, Saskatchewan Agriculture, SciELO/Redalyc/Terra Latinoamericana). Conversión usada: 1 lb/acre = 1.12 kg/ha. Lo no leído hoy se marca como tal en §E. No se modificó ningún archivo del repositorio.

Claves de ventana: cereales `germination` (siembra) | `tillering` (amacollamiento–inicio de encañe); frijol `germination` (siembra) | `vegEarly` (primera escarda).

Resumen de veredictos:

| Cultivo | k=1 (una sola pasada de N) | k=2 | Tope por pasada | Dosis | Criticidad actual |
|---|---|---|---|---|---|
| Trigo | Riego: `tillering` > `germination` (diferencia marginal: 4,850 vs 4,786 kg/ha; ambas ≈ −29 % vs 30/70). Temporal: `germination` > `tillering`. **splitRequired se sostiene.** | 30/70 se sostiene | Solo si el N va en contacto con la semilla | N, P, K se sostienen | Encañe crítico: se sostiene |
| Cebada | `germination` > `tillering` (maltera; 4 fuentes) | 50/50 se sostiene (práctica Bajío), 2.ª pasada antes de 5 hojas | ídem | N 100–130 se sostiene **con reserva** (Bajío rinde óptimo a 180); P, K se sostienen | **Amacollamiento crítico NO se sostiene** para maltera: la ventana prioritaria es la siembra |
| Avena | `germination` > `tillering` (INIFAP Zacatecas y Chihuahua) | 40/60 se sostiene en riego; temporal ≈ 60/40 (1 fuente, no cambiar) | ídem | N, P, K se sostienen | **Amacollamiento crítico NO se sostiene** para k=1 (INIFAP lo trata como opcional) |
| Frijol | Riego: `vegEarly` > `germination` (Henson & Bliss; 1 sola fuente experimental). Temporal: `germination` > `vegEarly` | 60/40: sin fuente exacta; 50/50 (Colpos) igual de defendible | ídem; la semilla de leguminosa es más sensible | N 40–100 se sostiene; P, K se sostienen | Sin ventana crítica: se sostiene |

---

## TRIGO (`_wheat`)

### A. Prioridad de ventanas

**k=1.** Ninguna fuente primaria recomienda una sola pasada de N en trigo de riego; la guía ya lo impide (`splitRequired`, mínimo 2), y eso **se sostiene**. Para el orden de reserva (`nitrogenPassPriority`):

- Rev. Fitotecnia Mexicana 2022 (INIFAP Celaya, riego, 240 kg N/ha, tres variedades): todo a la siembra (100-00-00) = **4,786 kg/ha, EUN 19.68 %**; todo al encañe (00-100-00) = **4,850 kg/ha, EUN 22.05 %**; mejor tratamiento 30-70-00 = **6,822 kg/ha, EUN 41.14 %**; práctica regional 50-50-00 = 6,296. Es decir, la pasada única cuesta ≈ 29–30 % del rendimiento **sin importar dónde se ponga**; la diferencia siembra vs encañe (64 kg/ha) es marginal. Punto adversarial: la nota `splitNotesEs` ("todo el N a la siembra rindió 30 % menos") es cierta, pero también es cierto para todo el N al encañe; la lección del ensayo es el fraccionamiento, no la ventana.
- CIMMYT Hub Pacífico Norte (Valle del Yaqui): "30 % de lo aplicado en presiembra ya se perdió al momento de la siembra"; práctica convencional 55 % de ≈ 275 kg N/ha en presiembra; recomendación **30 % siembra / 55 % primer riego (etapa crítica) / 15 % cerca de floración**; eliminar la presiembra no bajó rendimiento en dosis de 75–300 kg N/ha y la eficiencia subió hasta 50 %.
- K-State (vía Kansas Wheat): el N de cobertera debe estar en la zona radical **antes del encañe**, cuando se define el número de espiguillas; "normalmente se necesita alguna combinación de N presiembra o a la siembra y/o cobertera temprana".
- NDSU (trigo de primavera, temporal): la aplicación de otoño/presiembra de amoniaco es el método preferido; el único N en temporada que documenta es 30 lb N/acre (34 kg) post-antesis para +0.5 % de proteína.

Lista ordenada propuesta:
- Riego (Bajío, Sonora, Sinaloa): `['tillering', 'germination']` — 3 fuentes (Fitotecnia 2022: leve ventaja y mayor EUN del encañe; CIMMYT: pérdida de 30 % del N presiembra y primer riego como etapa crítica; K-State: N necesario antes del encañe). Advertir en la app que la pasada única cuesta ≈ 30 %.
- Temporal (sin riego que baje la cobertera): `['germination', 'tillering']` — NDSU y K-State (la cobertera depende de lluvia para entrar a la raíz); solo 2 fuentes, marcar como criterio provisional.
- Textura gruesa: la guía ya exige 2 pasadas (`minNitrogenPassesCoarse: 2`); el orden de riego aplica.

**k=2: 30/70 (siembra / fin de amacollamiento–encañe) se sostiene.** Fitotecnia 2022 (30-70-00 máximo, +8.4 % sobre 50-50); CIMMYT 30/55/15 (≈ 30/70 si el 15 % de floración se funde con la ventana de encañe); CDFA-FREP (60 % del N entre encañe y espigamiento, según la auditoría de sep). Matiz: la fuente mexicana aplicó el 70 % en **encañe (Z3)**, no en amacollamiento temprano; el `label` actual ("fin de amacollamiento e inicio de encañe") es correcto. La regla "adelantarlo al amacollamiento temprano rinde menos" **no** fue probada en ese ensayo (no hubo tratamiento en amacollamiento temprano); K-State pide que el N ya esté en la raíz antes del encañe, así que con riego aplicar con el primer auxilio (~40–50 d) es compatible con ambas fuentes. Sugerencia: suavizar esa regla a "no lo retrases más allá del inicio del encañe ni lo adelantes tanto que se pierda antes del amacollamiento".

### B. Tope por pasada
Ver §"Tope por pasada (común)" al final: solo hay evidencia de tope para N **en contacto con la semilla**. Fitotecnia 2022 aplicó 168 kg N/ha (70 % de 240) en una sola pasada al encañe, con riego, sin reportar daño: en cobertera con riego no hay tope agronómico documentado.

### C. Dosis

| Nutriente | Actual | Veredicto | Fuentes y cifra exacta |
|---|---|---|---|
| N | 150–240 | **Se sostiene** | Fitotecnia 2022: "240-60-00 recomendada 30 años en el Bajío"; CIMMYT Yaqui: convencional ≈ 275 kg N/ha, ensayos 75–300 sin pérdida al quitar presiembra; Terra 2012 (auditoría): 280 N regional; Panorama Sinaloa: 180–220; CDFA-FREP: 150–200 lb N/acre = 168–224 kg/ha. |
| P₂O₅ | 40–80 | **Se sostiene** (por análisis) | Fitotecnia 2022: 60; Terra 2012: 80; Panorama Sinaloa: 60–100; NDSU: 15–90 lb/acre (17–101 kg/ha) según Olsen, −1/3 si va en banda. Sinaloa llega a 100, pero es 1 fuente; no cambiar. |
| K₂O | 0–40 | **Se sostiene** | NDSU: 25 lb K₂O/acre (28 kg/ha) solo con K ≤ 100–150 ppm; CDFA-FREP: sin respuesta con K > 60 ppm (auditoría sep). |
| Reparto | 30/70 | **Se sostiene** | Fitotecnia 2022 (6,822 vs 6,296 kg/ha); CIMMYT 30/55/15. |

Nota sobre la atribución "FAO-Yaqui" en `splitNotesEs`: no se localizó esa fuente; lo verificable es la nota de CIMMYT (Yaqui). Se recomienda cambiar la atribución.

### D. Criticidad
**Se sostiene** que la ventana de fin de amacollamiento–encañe sea crítica: Fitotecnia 2022 (70 % ahí = máximo rendimiento y EUN), CIMMYT (primer riego = "etapa crítica", 55 %), K-State (N antes del encañe define espiguillas), CDFA-FREP (60 % entre encañe y espigamiento).

---

## CEBADA (`_barley`)

### A. Prioridad de ventanas

**k=1 → `germination` (siembra), no amacollamiento.** Cuatro fuentes independientes:
- NDSU *Fertilizing Malting and Feed Barley*: "todo el N destinado a la cebada debe aplicarse en presiembra"; "la cobertera después del establecimiento se desaconseja porque aporta más a la proteína que al rendimiento"; "no aplicar N después de 5 hojas".
- INIFAP, Agricultura Técnica en México 2009 (variedad Alina, Bajío riego): 120 N – 60 P₂O₅ **a la siembra** (ya en la guía).
- Vera-Núñez, Grageda, Vuelvas y Peña-Cabriales (CINVESTAV-Irapuato / INIFAP-CAEB Celaya), ¹⁵N en cebada de riego: 120, 180 y 240 kg N/ha como sulfato de amonio **todo a la siembra**; máximo 7,514 kg/ha (240 N + 4 riegos) ≈ 180 N + 3 riegos; recuperación final del ¹⁵N 15.9–21.7 %; máxima tasa de asimilación (< 40 %) entre 52 y 66 dds. Muestra que la práctica experimental del Bajío es todo a la siembra y que la absorción fuerte cae en encañe-floración (argumento a favor de una 2.ª pasada temprana cuando k=2, no de mover la única).
- MAPA cap. 16 (auditoría sep): en maltera el N tardío sube la proteína.

Fuente que matiza (práctica regional Bajío): Rev. Mex. Cienc. Agríc. 2012 (siembra directa de cebada maltera, Guanajuato): "se adicionó la mitad de nitrógeno (urea) y todo el fósforo a la siembra y un mes después el resto"; 180-60-00 es "dosis media regional".

Lista ordenada propuesta (maltera y forrajera): `['germination', 'tillering']`. Para forrajera no hay restricción de proteína y la 2.ª pasada en amacollamiento es aceptable, pero ninguna fuente la coloca como primera opción; se mantiene el mismo orden.

**k=2: 50/50 se sostiene** como práctica del Bajío (siembra + ~30 días), con la condición NDSU de que la 2.ª pasada entre antes de 5 hojas / antes del encañe (la regla ya está en `rulesEs`).

### B. Tope por pasada
Ver sección común. NDSU cebada, tabla 7: N + K₂O con la semilla 15–30 lb/acre con disco doble (17–34 kg/ha), 20–58 con zapata, 20–100 con sembradora neumática.

### C. Dosis

| Nutriente | Actual | Veredicto | Fuentes y cifra exacta |
|---|---|---|---|
| N | 100–130 (techo de calidad) | **Se sostiene con reserva** | A favor del rango: INIFAP Alina 120; NDSU 2 hileras económico ≈ 80–154 lb/acre (90–172 kg) y "6 hileras debe ir ligeramente deficiente en N para lograr proteína maltera". En contra del techo 130 **para rendimiento**: Vera-Núñez (óptimo "dos riegos y 180 kg N/ha"; 7,514 kg/ha con 240); RMCA 2012 (180-60-00 "dosis media regional", mejor costo-beneficio; 8 t/ha en siembra directa). Son 2 fuentes del Bajío (ambas con INIFAP-CAEB) y ninguna midió la proteína contra la norma maltera → no se alcanza el umbral de 3 independientes; **no cambiar**, pero documentar que el 130 es techo de proteína y que a 5–8 t/ha el Bajío usa 180. Forrajera 160–180 (ya en la nota) es coherente con esas cifras. |
| P₂O₅ | 40–60 | **Se sostiene** | Alina 60; RMCA 2012 60; NDSU 0–78 lb/acre (0–87 kg) según análisis, −1/3 en banda. |
| K₂O | 0–40 | **Se sostiene** | NDSU 0–90 lb K₂O/acre (0–101 kg) según análisis; fórmulas mexicanas -00. |
| Reparto | 50/50 | **Se sostiene** (práctica Bajío) | RMCA 2012 mitad/mitad; NDSU y Alina 100/0. |

### D. Criticidad
**No se sostiene** que amacollamiento sea la ventana crítica de la cebada maltera: NDSU, INIFAP Alina y Vera-Núñez ponen todo el N a la siembra y NDSU desaconseja la cobertera. Propuesta: `isCritical: true` en la regla de siembra (o ninguna crítica) y dejar el amacollamiento como pasada opcional "antes de 5 hojas"; conservar la nota de que con k=2 el reparto es 50/50. Si la app mantiene amacollamiento como crítica, penalizará al productor que sigue la recomendación INIFAP/NDSU de una sola pasada a la siembra.

---

## AVENA (`_oat`)

### A. Prioridad de ventanas

**k=1 → `germination` (siembra).**
- INIFAP Zacatecas (Medina et al. 2003, Zonas potenciales para avena forrajera de riego): "Incorporar con rastra antes de la siembra la fórmula 100-60-00, si se da un segundo corte, aplicar la fórmula 50-00-00"; 4.5–5.5 t MS/ha.
- INIFAP Chihuahua, Agenda Técnica 2017 (temporal): "La fertilización en temporal se realiza al momento de la siembra con la fórmula 60-40-00" (87 kg DAP + 100 kg urea o 200 kg sulfato de amonio), "de 20 a 40 kg/ha de nitrógeno en la etapa de amacollamiento" como complemento, 30-40-00 con poca lluvia, y "la dosis total de nitrógeno debe aplicarse fraccionadamente y con la humedad adecuada en el suelo".
- Analogía de grano pequeño: NDSU (cebada) todo presiembra; K-State (trigo) siembra + cobertera temprana. No se encontró un ensayo mexicano única-vs-fraccionada en avena (coincide con la nota actual de la guía).

Lista ordenada propuesta: `['germination', 'tillering']`. La guía actual (40 % siembra / 60 % amacollamiento, amacollamiento crítica) invierte esa prioridad para k=1 y contradice los dos paquetes INIFAP.

**k=2.** Fuentes divergen: INIFAP Chihuahua ≈ 60–75 % siembra / 25–40 % amacollamiento (temporal); Redalyc 2018 (guía) 36 N (DAP) a la siembra + 92 N (urea) a los ~50 d = 28/72 (riego); Terra Latinoamericana 2014 (INIFAP La Laguna, riego): "20, 40, 30 y 10 % de la dosis en el riego de siembra y en los siguientes tres riegos" = 20/80 después de la siembra; INIFAP Zacatecas 100/0 (+50 tras el 1.er corte). **40/60 se sostiene para riego** (queda entre 20/80 y 100/0 y ya es conservador hacia la siembra). Para temporal solo 1 fuente sugiere ≈ 60/40 → no cambiar cifra; anotar.

### B. Tope por pasada
Ver sección común. Las dosis de avena por pasada (≤ 100 kg N/ha) están lejos de cualquier riesgo salvo en contacto con semilla en arena.

### C. Dosis

| Nutriente | Actual | Veredicto | Fuentes y cifra exacta |
|---|---|---|---|
| N | 80–140 (temporal 40–60) | **Se sostiene** | INIFAP Zacatecas riego 100 (+50 por 2.º corte); INIFAP Chihuahua temporal 60 + 20–40 (30 con poca lluvia); Terra 2014 La Laguna: requerimiento 144 kg N/ha para 9 Mg MS/ha, dosis 63/95/126, MS 5.5 (0 N) → 6.3–7.1 (químico) → 7.6–8.9 (biosólidos); Redalyc 2018 ≈ 128. Temporal 40–60 podría abrirse a 30–100 según lluvia (Chihuahua), sin urgencia. |
| P₂O₅ | 40–60 | **Se sostiene** | Chihuahua 40; Zacatecas 60; Redalyc 92 (1 fuente, alta). |
| K₂O | 0–40 | **Se sostiene** | Todas las fórmulas INIFAP del norte terminan en -00. |
| Reparto | 40/60 | **Se sostiene en riego**; temporal ≈ 60/40 (1 fuente) | Ver A. |

### D. Criticidad
**No se sostiene** amacollamiento como crítica cuando k=1: INIFAP Zacatecas pone todo presiembra e INIFAP Chihuahua trata el N de amacollamiento como complemento de 20–40 kg. En riego con dosis altas y varios cortes la mayor parte del N sí va después de la siembra (La Laguna 80 %, Redalyc 72 %), así que la ventana importa con k≥2. Propuesta: siembra crítica (o ninguna) y amacollamiento crítica solo cuando el productor declara ≥2 pasadas o multicorte.

---

## FRIJOL (`_bean`)

### A. Prioridad de ventanas

**k=1.** Evidencia experimental directa: una sola fuente.
- Henson & Bliss 1991 (Fertilizer Research, Springer; UC Davis; 3 líneas × 3 años): 50–60 kg N/ha a la siembra, vegetativo, floración, llenado o fraccionado; "el N aplicado en etapa vegetativa produjo mayor rendimiento de semilla que a la siembra, floración, llenado o fraccionado"; redujo nodulación pero el crecimiento lo compensó; "el mejor sistema fue una aplicación en crecimiento vegetativo".
- Frontiers in Plant Science 2020: 100 kg N/ha de urea a la siembra subió el rendimiento de 2,566 a 3,004 kg/ha pero bajó el %Ndfa de 45.5 a 20.4 % (el N a la siembra apaga la fijación; argumento fisiológico para retrasarlo).
- Colpos Montecillo (Morales y Escalante, Terra Latinoamericana; asociación girasol–frijol): 0–160 kg N, "mitad al momento de siembra y mitad en primera escarda"; máximo con 80 kg N (504 kg/ha del sistema, temporal de Valles Altos).
- Práctica INIFAP: temporal Chihuahua 30-50-00 (Pinto Saltillo; el artículo no explicita el momento); riego SLP testigo regional 40-60-00 (gravedad, 2,530 kg/ha); Intagri y Panorama: siembra + primera escarda.

Lista ordenada propuesta:
- Riego: `['vegEarly', 'germination']` — se sostiene la elección actual (`singlePassStageKey: 'vegEarly'`) pero con **1 fuente experimental** (Henson & Bliss) + 1 fisiológica (Frontiers) + práctica de 2 pasadas (Colpos, Intagri). No cumple el umbral de 3 ensayos independientes; mantener y marcar como "evidencia limitada".
- Temporal: `['germination', 'vegEarly']` — los paquetes INIFAP de temporal fertilizan a la siembra con el fósforo (Chihuahua 30-50-00) y la escarda depende de lluvia; criterio de práctica, no de ensayo.

**k=2: 60/40 (siembra/escarda).** Ninguna fuente da exactamente 60/40; Colpos usa 50/50; Henson & Bliss encontró que el fraccionado rindió menos que la única en vegetativo. **Se sostiene** como aproximación (no hay 3 fuentes que lo contradigan); 50/50 sería igual de defendible.

### B. Tope por pasada
Ver sección común. Saskatchewan: para canola/lino los límites en contacto con semilla bajan a 0–50 lb N/acre; para leguminosas de grano NDSU/Saskatchewan no dan tabla específica en lo leído; regla práctica: no poner urea en contacto con la semilla de frijol.

### C. Dosis

| Nutriente | Actual | Veredicto | Fuentes y cifra exacta |
|---|---|---|---|
| N | 40–100 | **Se sostiene** | INIFAP Chihuahua temporal 30-50-00 (+18.74 %: 2,036 vs 1,655 kg/ha); INIFAP SLP riego 40-60-00 regional (2,530 kg/ha; con fertirriego 100-100-50 suficiente, 5,113 máx con 200-100-50); Colpos óptimo 80; Panorama 40–60 tras leguminosa / 80–100 tras cereal; Henson & Bliss 50–60; Frontiers 100 (+17 % rendimiento, −55 % Ndfa). INIFAP recomienda menos (30–40) en temporal y riego rodado de bajo rendimiento; 80–100 solo tras cereal o en fertirriego de alto rendimiento. El mínimo 40 es correcto para riego; para temporal el piso real es 30 (1 fuente → no cambiar, anotar). |
| P₂O₅ | 40–60 | **Se sostiene** | INIFAP Chihuahua 50; INIFAP SLP 60; MAPA 40–70 (auditoría). |
| K₂O | 0–40 | **Se sostiene** | Fórmulas INIFAP -00; fertirriego SLP 50 sin diferencia frente a 100. |
| Reparto | 60/40 | **Se sostiene** (aprox.) | Colpos 50/50; Intagri siembra + escarda. |

### D. Criticidad
**Se sostiene** que no haya ventana crítica: es leguminosa (Ndfa ≈ 45 % sin N, Frontiers), la respuesta al N es modesta (+17–19 % en Chihuahua y Frontiers) y la fuente experimental principal (Henson & Bliss) muestra que el momento cambia el rendimiento pero no lo hunde.

---

## Tope por pasada (común a los cuatro cultivos)

Pregunta: ¿hay evidencia (≥3 fuentes) de un máximo de kg N/ha por aplicación? **Sí, pero solo para N colocado en contacto con la semilla** (misma banda/surco). Para N al voleo incorporado, en banda separada o en cobertera con riego, ninguna fuente leída fija un tope agronómico; las pérdidas son de eficiencia (CIMMYT: 30 % del N presiembra perdido antes de la siembra; volatilización media en México 18 %), no de daño.

Fuentes de tope en contacto con semilla:
1. NDSU, *Fertilizer Application With Small-grain Seed at Planting*, tabla 2 (lb N/acre según textura y utilización del lecho de siembra): arena francosa 5 (disco doble) / 10–20 (zapata) / 25–40 (neumática); franco 20 / 25–35 / 40–55; arcilla 40 / 45–55 / 60–100. En kg/ha: 5.6 → 112. "La toxicidad por amoniaco es el mayor factor de daño a la semilla", sobre todo con urea; "ser conservador… especialmente con urea".
2. NDSU, *Fertilizing Malting and Feed Barley*, tabla 7 (N + K₂O con la semilla): disco doble 15–30 lb/acre; zapata 20–58; neumática 20–100.
3. Saskatchewan Ministry of Agriculture, *Guidelines for Safe Rates of Fertilizer Placed With the Seed* (urea con semilla de trigo/cebada/avena, lb N/acre): suelos ligeros 15–40; medios 20–50; pesados 30–60 según ancho de banda (17–67 kg/ha); "la toxicidad por amonio es el mecanismo principal de daño cuando la urea es la fuente colocada con la semilla"; canola/lino 0–50.

Las dos primeras son de la misma institución, así que la independencia es parcial (2 instituciones). Recomendación para la app: no imponer un tope global de kg N/ha por pasada; añadir una regla de colocación: "si el N va en el surco con la semilla, máximo ≈ 20–25 kg N/ha de urea en suelo arenoso y ≈ 40–55 en arcilloso; el resto en banda separada o en cobertera". La guía de textura gruesa (2 pasadas obligatorias) ya cubre el riesgo de lixiviación.

---

## E. Fuentes (todas)

| # | Fuente (institución, año) | URL | Qué dice (cifra) | Lectura |
|---|---|---|---|---|
| 1 | Rev. Fitotecnia Mexicana 2022, INIFAP Celaya, ¹⁵N en trigo de riego | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-73802022000400437 | 240 N; 100-00-00 4,786 kg/ha (EUN 19.68); 00-100-00 4,850 (22.05); 70-30-00 5,924; 50-50-00 6,296 (34.88); 30-70-00 6,822 (41.14); 33-33-33 6,469; 00-30-70 5,339; 00-70-30 5,568; 00-50-50 5,197; "240-60-00 recomendada 30 años, fraccionamiento 50-50" | Completa (dos extracciones) |
| 2 | CIMMYT, Hub Pacífico Norte (M. E. Cárdenas), Valle del Yaqui, s/f | https://www.cimmyt.org/es/noticias/los-beneficios-de-eliminar-las-aplicaciones-de-nitrogeno-durante-la-presiembra/ | 55 % de ≈ 275 kg N/ha en presiembra; 30 % perdido antes de sembrar; recomienda 30 % siembra / 55 % primer riego / 15 % floración; eficiencia México 31 %, volatilización 18 %; ensayos 75–300 kg N/ha sin pérdida de rendimiento | Completa |
| 3 | K-State Agronomy eUpdate vía Kansas Wheat, *Topdressing wheat with nitrogen* | https://kswheat.com/news/topdressing-wheat-with-nitrogen-timing-application-methods-sources-and-rates | N de cobertera en zona radical antes del encañe; combinación siembra + cobertera temprana | Extracto (la nota enlaza al artículo completo, no leído) |
| 4 | NDSU, *Fertilizing Hard Red Spring Wheat and Durum* | https://www.ndsu.edu/agriculture/extension/publications/fertilizing-hard-red-spring-wheat-and-durum | Presiembra/otoño preferido; 30 lb N post-antesis → +0.5 % proteína; P 15–90 lb P₂O₅/acre; K 25 lb K₂O si K ≤ 100–150 ppm; NBPT inactiva ureasa ~10 días | Completa |
| 5 | NDSU, *Fertilizer Application With Small-grain Seed at Planting* | https://www.ndsu.edu/agriculture/extension/publications/fertilizer-application-small-grain-seed-planting | Tabla 2 de N máximo con semilla por textura (5–100 lb N/acre); amoniaco = mayor factor de daño; urea la más riesgosa tras amoniaco anhidro | Completa |
| 6 | NDSU, *Fertilizing Malting and Feed Barley* (SF723) | https://www.ndsu.edu/agriculture/extension/publications/fertilizing-malting-and-feed-barley | Todo el N presiembra; cobertera desaconsejada (proteína); nada tras 5 hojas; 150 lb N/acre labranza convencional, 120 cero labranza; 2 hileras ≈ 80–154 lb; P 0–78 lb; K 0–90 lb; tabla 7 N+K₂O con semilla 15–100 lb | Completa |
| 7 | Saskatchewan Ministry of Agriculture, *Guidelines for Safe Rates of Fertilizer Placed With the Seed* | https://pubsaskdev.blob.core.windows.net/pubsask-prod/84100/guidelines_for_safe_rates_of_fertilizer.pdf | Urea con semilla de cereal: ligeros 15–40, medios 20–50, pesados 30–60 lb N/acre; canola/lino 0–50; toxicidad por amonio y salinidad | Completa |
| 8 | Vera-Núñez, Grageda, Vuelvas, Peña-Cabriales (CINVESTAV-Irapuato / INIFAP-CAEB), ¹⁵N en cebada, Bajío (Redalyc 57320110; revista y año no confirmados en la extracción) | https://www.redalyc.org/pdf/573/57320110.pdf | 120/180/240 N todo a la siembra; máximo 7,514 kg/ha; recuperación ¹⁵N 15.9–21.7 %; asimilación máxima 52–66 dds; óptimo "dos riegos y 180 kg N/ha" | Completa |
| 9 | Rev. Mex. Cienc. Agríc. 2012, siembra directa de cebada maltera, Guanajuato | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S2007-09342012000800003 | 90/180/270-60-00; mitad N + todo P a la siembra, resto un mes después; 180 = dosis media regional y mejor costo-beneficio; SD hasta 8 t/ha vs LC ≈ 5 | Completa |
| 10 | INIFAP / Agricultura Técnica en México 2009, variedad Alina | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0568-25172009000400012 | 120 N – 60 P a la siembra (Bajío riego) | Ya en la guía; no releída hoy |
| 11 | INIFAP, Agenda Técnica Agrícola de Chihuahua 2017 | https://vun.inifap.gob.mx/VUN_MEDIA/BibliotecaWeb/_media/_agendas/4124_4821_Agenda_T%C3%A9cnica_Chihuahua_2017.pdf | Avena temporal: 60-40-00 a la siembra (87 kg DAP + 100 kg urea o 200 kg sulfato de amonio); 20–40 kg N/ha en amacollamiento; 30-40-00 con poca lluvia; "dosis total de N fraccionada y con humedad" | Parcial (solo sección avena; frijol y trigo no aparecieron en la extracción) |
| 12 | INIFAP Zacatecas (Medina et al. 2003), *Zonas potenciales para avena forrajera de riego* | http://zacatecas.inifap.gob.mx/PotForr/AvenaFR.pdf | 100-60-00 incorporado con rastra antes de la siembra; 50-00-00 si hay 2.º corte; 4.5–5.5 t MS/ha | Completa |
| 13 | Terra Latinoamericana 2014, INIFAP La Laguna (Matamoros, Coah.), avena forrajera con biosólidos | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792014000200099 | Requerimiento 144 kg N/ha para 9 Mg/ha; dosis 63/95/126; fraccionado 20/40/30/10 % en riego de siembra + 3 riegos; MS 5.5 → 6.3–7.1 (químico) → 7.6–8.9 (biosólidos) | Completa |
| 14 | Rev. Mex. Cienc. Agríc. / Redalyc 2018, avena forrajera fuentes químicas y orgánicas | https://www.redalyc.org/jatsRepo/610/61050549007/html/index.html | 200 kg DAP a la siembra + 200 kg urea a los ~50 d (≈ 36 + 92 N; 92 P₂O₅) | Ya en la guía; no releída hoy |
| 15 | Henson & Bliss 1991, Fertilizer Research (Springer), UC Davis | https://link.springer.com/article/10.1007/BF01048951 | 50–60 kg N/ha; vegetativo > siembra, floración, llenado y fraccionado; 3 líneas × 3 años | Solo resumen (abstract) |
| 16 | Morales Rosales y Escalante Estrada, Colpos Montecillo, Terra Latinoamericana (girasol–frijol) | https://terralatinoamericana.org.mx/index.php/terra/en/article/download/1391/1586/12840 | 0–160 N, mitad siembra + mitad primera escarda; máximo con 80 (504 kg/ha del sistema) | Completa |
| 17 | Rev. Mex. Cienc. Agríc. 2013, INIFAP, frijol Pinto Saltillo temporal Chihuahua | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S2007-09342013000100009 | 30-50-00 vs 00-00-00: 2,036 vs 1,655 kg/ha (+18.74 %); momento no explicitado | Completa |
| 18 | Rev. Mex. Cienc. Agríc. 2012, INIFAP San Luis Potosí, frijol Flor de Mayo M-38 fertirriego | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S2007-09342012000800006 | Testigo regional 40-60-00 (gravedad 2,530; goteo 3,995 kg/ha); 100-100-50 suficiente; máximo 5,113 con 200-100-50 | Completa |
| 19 | Frontiers in Plant Science 2020, *Effects of Nitrogen Application on Nitrogen Fixation in Common Bean Production* | https://www.frontiersin.org/journals/plant-science/articles/10.3389/fpls.2020.01172/full | 100 kg N/ha urea a la siembra: rendimiento 2,566 → 3,004 kg/ha; %Ndfa 45.5 → 20.4 | Completa |
| 20 | Panorama Agropecuario, guía de frijol | https://panorama-agro.com/?page_id=134 | 40–60 N tras leguminosa/hortaliza; 80–100 tras cereal | Ya en la guía; no releída hoy |
| 21 | Panorama Agropecuario, guía de trigo (Sinaloa) | https://panorama-agro.com/?page_id=872 | 180–220 N; 60–100 P₂O₅; 2/3 presiembra + 1/3 primer riego | Ya en la guía; no releída hoy |
| 22 | Terra Latinoamericana 2012, fertilizantes de solubilidad controlada en trigo, Bajío | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792012000200121 | Recomendación regional 280 N – 80 P₂O₅ | Ya en la guía; no releída hoy |
| 23 | INIFAP, *Cebada maltera de temporal en Valles Altos* | https://www.gob.mx/inifap/articulos/cebada-maltera-de-temporal-en-valles-altos-de-mexico | — | No leída (403 hoy) |
| 24 | INIFAP, Agenda Técnica San Luis Potosí 2017 | https://vun.inifap.gob.mx/VUN_MEDIA/BibliotecaWeb/_media/_agendas/4141_4838_Agenda_T%C3%A9cnica_San_Luis_Potos%C3%AD_2017.pdf | Solo se extrajo avena temporal (micorriza 1–1.5 kg/ha; 10.1–13.5 t/ha); frijol, cebada y trigo no salieron en la extracción | Parcial, sin cifras útiles |
| 25 | Manitoba Agriculture, *Guidelines for Safely Applying Fertilizer with Seed* | https://www.gov.mb.ca/agriculture/crops/soil-fertility/guidelines-for-safely-applying-fertilizer-with-seed.html | — | Solo resultado de búsqueda; no leída |

Fallos de lectura: INIFAP Valles Altos (403), Acta Universitaria UGTO frijol (redirecciones), K-State eUpdate original (redirige al índice).
