# Verificación adversarial — guías de fertilización de HORTALIZAS (BIO-G)

Fecha: 2026-09-17. Alcance: tomate, chile, pepino, berenjena, calabaza, lechuga, espinaca, cebolla, ajo.
Método: 46 consultas web (43 útiles, 3 fallidas: INIFAP gob.mx jitomate → 403; CDFA Spinach → 404 (esa guía no existe); geisseler.ucdavis.edu → bloqueo TLS). Todas las cifras de este informe se leyeron en la fuente citada; conversión 1 lb/acre = 1.121 kg/ha; 1 short ton/acre = 2.24 t/ha.

Convenciones de veredicto: **se sostiene** (sin ≥3 fuentes en contra) · **se sostiene con matiz** (cifra correcta, pero la nota o el rango merece ajuste no obligatorio) · **CAMBIAR** (≥3 fuentes independientes lo contradicen o hay inconsistencia interna).

---

## 0. Hallazgos transversales (leer primero)

**H1. «Dos veces» NO debe estar prohibido en tomate, chile, pepino, berenjena, calabaza, cebolla ni ajo.** Hay ≥3 fuentes primarias e independientes en las que un plan de DOS aplicaciones es la práctica normal o el mejor tratamiento del ensayo, sobre todo con riego rodado / suelo pesado:
- UC IPM Tomate (riego rodado): «a single sidedress application of 100 to 120 lb nitrogen per acre is normally sufficient to finish the crop» (más el arranque) → 2 pasadas [F2].
- UC ANR Bell Pepper Production in California: «N and K are applied preplant and in one or more sidedressings» → 2 pasadas es el caso base en riego convencional [F21].
- UF/IFAS calabacita, Csizinszky 1985: el MEJOR tratamiento fue DOS aplicaciones («twice (50% preplant and 50% at mid-growth, resulting in 785 bushels/acre)») contra una sola (335 bu/ac). El ensayo que la guía cita para exigir ≥3 pasadas demuestra la ventaja de 2, no de 3 [F11].
- UF/IFAS pepino, ensayo 1963: rindió más con N repartido «80% preplant and 20% side-dressed» (2 pasadas) que todo a la siembra [F12].
- UF/IFAS berenjena: los ensayos usaron «two or three equal applications» [F10].
- PNW 546 cebolla: «Where leaching losses are high, split applications usually are more effective than a single side-dress application» → donde la lixiviación es baja (suelo pesado, rodado) una sola cobertera es aceptable [F16]; INIFAP Chihuahua prescribe 4 fracciones, pero Fertilab/INIFAP Zacatecas (fuente ya en la guía) da 2 (mitad antes del trasplante + resto a 50 días).
- Ajo: InfoAgro (fuente ya en la guía) da 2 momentos (plantación + 60 días); Hermosillo usó 5 fracciones en goteo [F19].

Propuesta: mantener `splitRequired` (una sola pasada sigue prohibida: Csizinszky −57 %, CDFA tomate <30 % de la absorción antes del cuaje) pero bajar `minNitrogenPasses` a **2** en tomate, chile, pepino, berenjena, calabaza, cebolla y ajo, con `minNitrogenPassesCoarse: 3` (cebolla 4) para arena/goteo. Lechuga y espinaca ya están en 2.

**H2. Inconsistencia interna con el tope de 45 kg N/ha (lechuga/espinaca).** Con el reparto actual, el tope se viola en cuanto la dosis pasa de ~100 kg N/ha: lechuga 180 × 0.45 = 81 kg en acogollado; espinaca 150 × 0.40 = 60 kg en expansión foliar; con dos pasadas peor (lechuga 180 × 0.56 ≈ 101). El motor tiene que o (a) subdividir automáticamente la pasada, o (b) aplicar el tope solo al fondo/arranque (que es de donde sale la cifra: CDFA «20–40 lbs/acre just before or at planting»; «ammonium-N exceeding 50–60 lbs/acre may damage seedlings») y usar otro tope para cobertera. Ver §6.B y §7.B.

**H3. Cifras de extracción ≠ dosis.** Los 250–330 kg K₂O/ha de tomate son remoción a 45 short ton/acre ≈ 100 t/ha (CDFA) o extracción total (Agroes); a 55–65 t/ha la fruta se lleva 132–234 kg K₂O/ha y las guías de campo (UC IPM, CDFA) recomiendan 112–224 según análisis. 120–180 se sostiene para México. Igual para K en berenjena (270–335 = extracción de invernadero) y para el 180–220 kg K/ha de espinaca de TecnoAgro.

**H4. La prioridad de ventanas (A) y la criticidad (D) son conceptos distintos.** La ventana crítica es la que más pesa si se OMITE; la primera de la lista de prioridad es dónde va la ÚNICA pasada de un plan concentrado. En lechuga, espinaca y calabaza no coinciden, y es correcto que no coincidan (ver cada cultivo).

---

## 1. Tomate

### A. Prioridad de ventanas y mínimo de pasadas
`nitrogenPassPriority: [floracion, vegetativo, llenado, germinacion]`
- **floracion** (35 %) primero: CDFA «Tomato plants take up less than 30% of their N before fruit set. Most of the seasonal growth and N uptake occurs between early fruit set and the early red fruit stage» [F1]; la cobertera única de UC IPM (100–120 lb N/ac) va justo antes de ese pico [F2].
- **vegetativo** (27 %) segundo: es la cobertera de «primera escarda» de la práctica mexicana y del esquema UC de arranque + cobertera.
- **llenado** (25 %) tercero: CDFA «The amount of N taken up after the early red fruit stage is minimal» → solo vale para saladette de cosecha escalonada; en industrial casi no cuenta.
- **germinacion** (13 %) último como pasada de N independiente: está topada (CDFA: preplante «max. 30 lbs/acre» = 34 kg/ha; arranque comercial 5–15 lb/ac [F1]) y normalmente viaja con el fósforo de fondo sin contar como pasada.
- Mínimo de pasadas: **2 es defendible** en rodado/suelo pesado (UC IPM: arranque + una cobertera de 112–134 kg N/ha «normally sufficient to finish the crop» [F2]). Plan de 2: vegetativo + floracion (o arranque-con-P + floracion, que es el esquema UC). Recomendación: `minNitrogenPasses: 2`, `minNitrogenPassesCoarse: 3`.

### B. Topes por pasada
- Preplante/arranque: **34 kg N/ha** (CDFA «max. 30 lbs/acre») — ya está en la guía (33). Se sostiene.
- Cobertera: no existe tope explícito en la literatura de tomate. La pasada única más alta documentada como práctica normal es 100–120 lb N/ac = **112–134 kg N/ha** (UC IPM rodado [F2]). Si se quiere un `maxSinglePassKgN`, 112 (100 lb/ac, el único tope explícito hallado, PNW 546 y CDFA cebolla) o 134 son las cifras defendibles; por debajo de eso no hay respaldo.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes (cifra exacta) |
|---|---|---|---|
| N | 180–240 | **Se sostiene** | UC IPM: rodado «about 150 lb per acre [168 kg/ha] is nearly always adequate»; goteo «as high as 200 lb per acre [224]» [F2]. Agroes 200–240 (ya en guía). CDFA no fija dosis; umbral 16 ppm NO₃-N ≈ 115 lb N/ac. El mínimo podría bajar a 150–168 en rodado industrial, pero solo UC lo apoya → sin cambio. |
| P₂O₅ | 60–100 | **Se sostiene** | CDFA: Olsen <10 ppm «60–100 lbs P2O5/acre» [67–112]; 10–20 ppm «50–80»; >20 ppm sin respuesta; remoción 25–35 lb P/ac a 50 t/ac [F1]. UC IPM: bajo (<15 ppm) «up to 150 lb P2O5», medio «75 lb» [F2]. |
| K₂O | 120–180 | **Se sostiene (para México)** | CDFA: «Economic returns on the current crop may be highest with some 100 lbs K2O/acre» [112]; Zhang: sin aumento arriba de «175 lbs/acre (210 lbs K2O)» [235] a >50 t/ac; umbrales 135 ppm (rodado) / 200 ppm (goteo) / 270 ppm (color) [F1]. UC IPM: K <130 ppm «up to 200 lb K2O» [224]; 130–250 ppm «100 lb K2O» [112]; >250 ppm nada [F2]. Hartz & Hanson 2009 vía [F3]: «A general recommendation is 100 pounds K2O per acre»; respuesta probable con K <200 mg/kg. Remoción: 4–6 lb K/short ton → 2.4–3.6 kg K₂O/t → a 55–65 t/ha 132–234 kg/ha. Los 250–330 de Agroes/CDFA corresponden a ~100 t/ha (45 short ton/ac). La nota actual («sube a 220 solo si <130 ppm») es exactamente lo que dicen UC IPM/CDFA. |

Reparto 13/27/35/25: coherente con «<30 % antes del cuaje» (13+27 = 40 %, algo alto, pero incluye la cobertera vegetativa que se absorbe ya en cuaje). Se sostiene.

### D. Criticidad
- floracion crítica: **se sostiene** (CDFA, pico de absorción cuaje → primer fruto rojo).
- llenado crítica (nutriente de ventana = K): **se sostiene con matiz**: para N no es crítica (CDFA: absorción mínima tras primer fruto rojo); como ventana de K en saladette de cosecha escalonada sí (UC IPM: fertirriego de N y K «concentrated during bloom through first red fruit stage»). Si el motor penaliza omisión de N ahí, revisar; si penaliza K, correcto.

---

## 2. Chile

### A. Prioridad y mínimo
`nitrogenPassPriority: [floracion, vegetativo, llenado, germinacion]`
- **floracion** primero: NMSU H-257 «The optimal application window for nitrogen begins when plants reach the reproductive period (first bloom) and continues through early fruit development» [F9]; Panorama (ya en guía) pone la aplicación grande (100-00-00) a inicio de floración.
- **vegetativo** (30 días, 50-00-00 regional) segundo; **llenado** tercero (solo jalapeño/serrano de 4–8 cortes; NMSU corta el N a mediados de agosto para chile rojo); **germinacion** último (N corto a propósito; viaja con el 50-60-50 de trasplante).
- Mínimo: **2 defendible**. UC ANR: «N and K are applied preplant and in one or more sidedressings; a late season water-run application can also be used» [F21]. Recomendación: `minNitrogenPasses: 2`, coarse 3. Plan de 2: vegetativo (30 d) + floracion, dejando el N de trasplante con el fósforo.

### B. Topes
- Sin tope explícito en la literatura de chile. Práctica documentada máxima en una pasada: 100 kg N/ha a floración (Panorama, ya en guía). Preplante en zona árida 11–45 kg (nota actual). Mismo criterio que tomate: si se pone tope, 112 kg N/ha.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 180–240 | **Se sostiene** | UC ANR pimiento: «180 to 240 pounds per acre (201 to 268 kg/ha) of N is normally sufficient to produce maximum marketable yield»; «many growers using more than 250 pounds per acre (336 kg/ha)» [F21]. NMSU: «Approximately 200 lb/ac [224] of nitrogen are used by a chile crop over the course of the season» [F9]. UNISON 2024 (testigo químico en Hermosillo, serrano): 290 N – 75 P – 250 K kg/ha [F20]. El rango de la app queda en la parte baja de UC (201–268 kg/ha); a 30–45 t/ha de jalapeño es correcto. |
| P₂O₅ | 50–90 | **Se sostiene** | NMSU: «Approximately 50 to 100 lb/ac of P2O5 [56–112] are incorporated, depending on existing levels» preplante [F9]. UC ANR: «80 to 200 pounds per acre (90 to 224 kg/ha) of P2O5 is common» (California, suelos fijadores) [F21]. |
| K₂O | 100–200 | **Se sostiene con matiz** | UC ANR: solo con K «less than 150 ppm»; «50 to 150 pounds per acre (56 to 168 kg/ha) of K2O» [F21]. Bio Ciencias 3.4–5.3 kg K₂O/t (ya en guía) × 30–45 t = 102–238. Matiz: el mínimo 100 debería poder ser 0–50 con análisis >150 ppm (UC ANR; Panorama «50 K en suelos ricos»). No llega a 3 fuentes → no obligatorio. |

### D. Criticidad
- floracion crítica: **se sostiene** (NMSU, ventana óptima desde primera flor).

---

## 3. Pepino

### A. Prioridad y mínimo
`nitrogenPassPriority: [floracion, vegetativo, llenado, germinacion]`
- **floracion** primero (pico de absorción con el cuaje; ensayos UF/IFAS con goteo/acolchado óptimo 120–160 lb N [F12]).
- **vegetativo** («guía», 2–3 hojas verdaderas) segundo: en un plan de 2 pasadas cubre el arranque.
- **llenado** (cortes) tercero: solo pepino de 6–8 semanas de cortes; **germinacion** último (arranque con el P).
- Mínimo: **2 defendible**: UF/IFAS 1963 «yield increased through 120 lb/acre N when fertilizer was split (80% preplant and 20% side-dressed) but did not increase with N when all of the fertilizer was applied at planting» [F12]. Recomendación: 2, coarse 3.

### B. Topes
- Sin tope específico. Mismo criterio (112). La nota de la guía sobre arena (analogía con calabaza) es correcta.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 120–180 | **Se sostiene** | UF/IFAS: «recommends a target of 150 lb/acre N [168]»; ensayos: óptimo «130 lb/acre N [146]», «160 lb/acre N (735 bushels/acre)» temporada húmeda, «120 lb/acre [134]» seca; «leveling off at 125 lb/acre N [140]» [F12]. Intagri 140 extraídos (ya en guía). |
| P₂O₅ | 40–80 | **Se sostiene** | UF/IFAS: 120 lb [134] solo con P muy bajo; «0 to 60 lb/acre P2O5 (172 bushels/acre, 97% RY)» en 1971; «no P fertilizer application where soils test more than 31 ppm» [F12]. |
| K₂O | 120–180 | **Se sostiene con matiz** | UF/IFAS: 120 lb K₂O [134] solo con K muy bajo; «Side-dress K applications from 50 to 150 lb/acre K2O [56–168] were shown to hold soil K»; «Research with K fertilization of cucumber plants has not been reported» [F12]. Matiz: mínimo 0 con análisis alto (como calabaza). |

### D. Criticidad
- floracion crítica: **se sostiene** (analogía cucurbitácea, UF/IFAS; sin curva mexicana leída — Zamorano sigue ✎).

---

## 4. Berenjena

### A. Prioridad y mínimo
`nitrogenPassPriority: [floracion, vegetativo, llenado, germinacion]`
- Igual que tomate; **llenado** sube a segundo lugar si la cosecha dura >8 semanas: UF/IFAS «A supplemental N application of 30 lb/acre N [34] was recommended for extended harvest seasons» y ensayos con «four equal fertilizer applications at one-month intervals» [F10].
- Mínimo: **2 defendible** (UF/IFAS «two or three equal applications» [F10]). Recomendación: 2, coarse 3.

### B. Topes
- Sin tope específico; mismo criterio (112).

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 180–220 | **Se sostiene** | UF/IFAS: objetivo «200 lb/acre N [224]»; «yields generally reached a plateau at 200 lb/acre N in most experiments» y bajan arriba de 250 lb [280]; Live Oak: meseta a 60 lb (1988) y 120 lb (1989–90) [F10]. |
| P₂O₅ | 75–100 | **Se sostiene con matiz** | UF/IFAS: «160 lb/acre P2O5 [179]… only when soil concentrations of phosphorus (P) or potassium (K) are very low»; «Response to P was maximized between 150 and 200 lb/acre P2O5 [168–224]» en suelos bajos; «Very little research has been conducted on P fertilization of eggplant» [F10]. Intagri 1.5–2 kg/t × 50 t = 75–100 (ya en guía). Matiz: con Olsen bajo el máximo podría llegar a ~170; 2 fuentes → sin cambio. |
| K₂O | 120–180 | **Se sostiene** | UF/IFAS: «yields optimized at or near 160 lb/acre K2O [179] in all experiments where M-1 soil testing was performed»; en varios «100 lb/acre K2O [112] was sufficient» [F10]. La nota de la guía (270–335 = extracción de invernadero) es correcta. |

### D. Criticidad
- floracion y llenado críticas: **se sostienen** (cosecha extendida con refuerzos mensuales, UF/IFAS).

---

## 5. Calabaza (calabacita)

### A. Prioridad y mínimo
`nitrogenPassPriority: [vegetativo, floracion, germinacion, llenado]`
- Aquí la primera de la lista NO es la crítica: en un ciclo de 80 días con absorción lineal (Fitotecnia 2012, ya en guía) la pasada única va a la **guía (3–4 semanas)**, justo antes de la flor; es el «mid-growth» del mejor tratamiento de Csizinszky («50% preplant and 50% at mid-growth» = 785 bu/ac) [F11].
- **floracion** segunda; **germinacion** (fondo con todo el P) tercera; **llenado** (cortes) última.
- Mínimo: **2 defendible y es lo que el propio ensayo demuestra** [F11]. Recomendación: `minNitrogenPasses: 2` (fondo + guía, o guía + floración), coarse 3. Reescribir `splitNotesEs`: hoy dice que el fraccionado fue «785» sin aclarar que fueron DOS aplicaciones.

### B. Topes
- Sin tope específico. Dosis pequeñas (UF/IFAS 50–100 lb suficientes), el tope no es operativo.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 80–150 | **Se sostiene** | UF/IFAS objetivo «150 lb/acre N [168]»; Sutton 1965 «100 lb/acre N, 93% RY, and 150 lb/acre, 100% RY»; Hochmuth 1992 pico a «80 lb/acre N [90]»; butternut «50 lb/acre N [56]»; Santos 2006 «between 50 and 100 lb N/acre [56–112] could be sufficient» [F11]. Terra 2011 regional 80–130 (ya en guía). |
| P₂O₅ | 60–90 | **Se sostiene** | UF/IFAS 120 lb [134] solo muy bajo; Sutton «yield leveled off after 100 lb/acre P2O5 [112]» [F11]. Terra 60–90. |
| K₂O | 0–120 | **Se sostiene** | UF/IFAS 120 lb [134] solo muy bajo; Sutton «Yield leveled off after 100 lb/acre of potassium (K2O) [112]» [F11]. Mínimo 0 correcto (solo con K muy bajo). |

### D. Criticidad
- floracion crítica: **se sostiene con matiz**. Lo que el ensayo penaliza es no tener una segunda pasada a mitad de ciclo (3–5 semanas); si el productor la hace en «guía», omitir «floracion» no debería penalizar tanto. Sugerencia: marcar crítica la segunda pasada del plan (vegetativo o floracion, la que quede), no la etiqueta.

---

## 6. Lechuga

### A. Prioridad y dos pasadas
`nitrogenPassPriority: [desarrolloVegetativo, formacionCabeza, germinacion]`
- CDFA/UC Davis: «the first sidedress N application is done after thinning at the two- to four-leaf-stage. If the residual nitrate-N concentration drops below 20 ppm, a second application is done 2–4 weeks later at the cupping stage» [F14]. La primera cobertera es incondicional; la segunda, condicional → prioridad post-aclareo > acogollado.
- Con **dos pasadas: desarrolloVegetativo + formacionCabeza**, reparto ≈ **45 / 55** (renormalizando 35/45), y el N de fondo se reduce a arranque ≤22 kg/ha con el fósforo (CDFA «about 20 lbs N/acre are applied at planting») o cero si el nitrato residual >20 ppm.
- Pasada única (no recomendada): post-aclareo, no acogollado (llegaría tarde; la app misma dice «se pone ANTES»).
- `splitRecommended`, mín 2, 3 en arena: **se sostiene**.

### B. Topes
- **45 kg N/ha se sostiene SOLO para fondo/arranque**: CDFA «a small application of 20–40 lbs/acre [22–45] just before or at planting is sufficient»; «pre-plant or starter ammonium-N application exceeding 50–60 lbs/acre may damage seedlings» [F13].
- Para cobertera no hay fuente que respalde 45: CDFA reparte 150–180 lb (invierno) en arranque 20 + dos coberteras → 55–80 lb (62–90 kg) cada una; VRIC: aplicaciones típicas 100–220 lb N/ac en 2–3 eventos [F15]. **CAMBIAR** (por inconsistencia interna H2 + 2 fuentes): tope de fondo 45; tope de cobertera **90 kg N/ha** (80 lb/ac), o dejar que el motor subdivida.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 100–180 | **Se sostiene** | CDFA: «should not exceed 150–180 lbs/acre [168–202] for winter and spring production and 100–140 lbs/acre [112–157] for summer and fall» [F13]. VRIC: absorción 120–160 lb, remoción 60–90 lb, aplicación típica 100–220 lb [F15]. Cajamar 80–100 extraídos (ya en guía). |
| P₂O₅ | 40–100 | **Se sostiene** | CDFA: «Up to 90 lbs P/acre (200 lbs P2O5/acre) [224] … below 10 ppm»; 30–40 ppm «not more than 45 lbs P/acre (100 lbs P2O5/acre) [112]»; 40–60 ppm arranque 20 lb P₂O₅; >60 ppm sin respuesta [F13]. |
| K₂O | 80–120 | **Se sostiene** | CDFA: remoción «70–110 lbs K2O/acre [78–123]» a 350–400 cwt/ac (39–45 t/ha); «above 150 ppm, K fertilization is not required»; 100–150 ppm respuesta posible [F13]. |

Reparto 20/35/45: coherente con «<20 % del N el primer mes» y «70–80 % entre acogollado y cosecha» [F13]. Se sostiene.

### D. Criticidad
- formacionCabeza crítica: **se sostiene** («Between heading and harvest, N demand of lettuce is high, reaching 3–4 lbs N/acre per day»; «70–80% of total N is taken up» ahí [F13]). Es compatible con que la prioridad de pasada única sea post-aclareo (H4).

---

## 7. Espinaca

### A. Prioridad y dos pasadas
`nitrogenPassPriority: [vegetativoTemprano, expansionFoliar, germinacion]`
- Acta Agronómica (UNAL): dosis 0–150 kg N/ha × momentos «planting (PT), 15, 30, and 45 days after planting»; el mejor fue **90 kg N/ha a los 15 días** [F18] → la pasada temprana es la de mayor prioridad para un plan concentrado.
- VRIC: absorción rápida 5–7 lb N/ac/día [5.6–7.8 kg] [F15] → la segunda pasada (expansión foliar) sostiene ese pico.
- **Dos pasadas: vegetativoTemprano + expansionFoliar**, reparto ≈ **45 / 55** (de 30/40); fondo solo si el suelo sale bajo (nota Arizona ~15 lb, ya en guía).
- `splitRecommended`, mín 2 (3 en arena): **se sostiene**; en arena/goteo la práctica californiana es 4–5 fertirriegos (nota YCEDA de la guía; VRIC 160–200 lb en baby leaf).

### B. Topes
- 45 kg N/ha: **se sostiene para fondo y para fertirriego** (4–5 eventos de ≤150 lb → 34–42 kg cada uno, nota Arizona de la guía). Para cobertera en rodado con 2–3 pasadas a 100–150 totales el reparto lo viola (H2). Proponer tope de cobertera **60 kg N/ha** (una semana de absorción máxima según VRIC = 5.6–7.8 kg/día × 7–10 días) o subdivisión automática. Solo 2 fuentes directas → dejarlo como propuesta.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 100–150 | **Se sostiene** | VRIC: absorción «100–130 lb N/acre [112–146]», remoción 70–90 lb, aplicación típica «160–200» lb [179–224] en baby leaf de varios cortes [F15]. Acta Agronómica: óptimo 90 kg/ha; los autores dicen que en su suelo se puede prescindir de cobertera [F18]. TecnoAgro 110–130 (ya en guía). |
| P₂O₅ | 40–60 | **Se sostiene, VERIFICAR UNIDADES** | TecnoAgro (no releído) reporta 38–45 kg **P**/ha extraídos; si es P elemental, equivalen a 87–103 kg P₂O₅. La dosis 40–60 sigue siendo defendible (el suelo aporta; CDFA lechuga no pasa de 112 con Olsen 30–40 ppm), pero el `sourceEs` no debe decir «38–45 kg P/ha» como si fuera P₂O₅. |
| K₂O | 80–110 | **Se sostiene** | UF/IFAS 100 lb K₂O [112] con análisis bajo (nota actual); CDFA lechuga (cultivo análogo) sin K >150 ppm [F13]. Los 180–220 kg K/ha de TecnoAgro son extracción, no dosis (H3). |

### D. Criticidad
- expansionFoliar crítica: **se sostiene con matiz**: el pico de absorción (VRIC) está ahí, pero el único ensayo de momentos leído [F18] favorece la aplicación a 15 días (vegetativoTemprano). Mantener crítica expansionFoliar; no marcar crítica la temprana pero sí primera en prioridad (H4).

---

## 8. Cebolla

### A. Prioridad y mínimo
`nitrogenPassPriority: [induccionBulbificacion, vegetativo, germinacion]`
- CDFA: «onions take up less than 20% of their total N requirement in the first half of the growing season»; «fertigated throughout the season, starting at bulb initiation, when rapid N uptake begins»; «65–80% of the total rate should be applied in-season» [F17]. PNW 546: aplicar «during bulb initiation (growth stage 4)»; «Minimize preplant N fertilizer application» [F16]. INIFAP Chihuahua: tercera fracción «En marzo, al inicio del crecimiento del bulbo» [F7].
- Mínimo: **2 defendible en suelo pesado/rodado**: PNW «Where leaching losses are high, split applications usually are more effective than a single side-dress application» [F16]; Fertilab/INIFAP Zacatecas (fuente de la guía): mitad antes del trasplante + resto a 50 días. Pero INIFAP Chihuahua prescribe 4 fracciones iguales (camelloneo, mediados de febrero, marzo, mediados de abril; 25–45 kg N cada una) [F7] y CDFA limita el preplante a 1/3. Recomendación: `minNitrogenPasses: 2` (vegetativo + inducción, con ≤1/3 en fondo si el productor lo pide), `minNitrogenPassesCoarse: 4` se sostiene.

### B. Topes
- **112 kg N/ha se sostiene** con dos fuentes primarias coincidentes: PNW 546 «The amount of N applied at one time should not exceed 100 lb N per acre»; «Typical side-dress N application rates are 40 to 80 lb N per acre per application» [45–90] [F16]. CDFA: «Individual applications should not exceed 100 lbs N/acre»; «30 lbs N/acre may be a safer threshold in high organic matter soils» [F17]. INIFAP Chihuahua: fracciones de 25–45 kg [F7]. Consistencia interna: 200 × 0.35 = 70 < 112 ✔; con 2 pasadas 100 < 112 ✔.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 150–200 | **Se sostiene con matiz** | CDFA: goteo fresco «150–200 lbs N/acre [168–224]» para 50–70 t/ac; rodado industrial «100–150 lbs N/acre [112–168]»; «no more than 1/3 … at planting» [F17]. INIFAP Chihuahua: «100 a 180 kilogramos por hectárea (kg/ha) de nitrógeno en riego por cintilla y gravedad, respectivamente» (36.5 t/ha) [F7]. PNW: 40–160 lb N total contando el N del suelo [F16]. Matiz: con cintilla INIFAP baja a 100; 2 fuentes (CDFA rodado, INIFAP cintilla) sugieren mínimo 100–120 para rendimientos <50 t/ha → sin cambio obligatorio, pero la nota podría decirlo. |
| P₂O₅ | 60–120 | **Se sostiene** | INIFAP Chihuahua «80 kg/ha de fósforo (P2O5)» todo al camelloneo [F7]. CDFA: «up to 200 lbs P2O5/acre [224]» con Olsen bajo; «greater than 30 ppm, no more than 50 lbs/acre P2O5»; banda ≤70 lb; remoción «61–98 lbs P2O5 [68–110]» [F17]. |
| K₂O | 0–150 | **Se sostiene** | PNW tabla: 0 ppm «240 lb K2O per acre [269]»; 50 ppm «120 lb K2O [134]»; >100 ppm «0» [F16]. CDFA: «less than 100 ppm … up to 150 lbs K2O/acre [168]»; remoción «170–225 lbs K2O [191–252]» [F17]. Nota: la frase de la guía «Entre 0 y 50 ppm sí van los 150» subestima PNW (269 a 0 ppm); el máximo 150 es conservador pero defendible con CDFA (168). |

### D. Criticidad
- induccionBulbificacion crítica: **se sostiene** (CDFA/PNW: arranque de la absorción rápida; Machado & Bryla −47 %, ya en guía).
- vegetativo (3–4 hojas) crítica: **se sostiene con matiz**: <20 % de la absorción en la primera mitad (CDFA) → su omisión pesa menos que la de inducción; INIFAP Chihuahua sí pone una fracción ahí (mediados de febrero). Mantener, pero si el motor pondera criticidad por igual, considerar bajarla.

---

## 9. Ajo

### A. Prioridad y mínimo
`nitrogenPassPriority: [vegetativeLeafDevelopment, bulbDifferentiation, clovePlanting]`
- Hermosillo (Huez López et al. 2010, Biotecnia/Redalyc): 180 kg N/ha óptimo (22.03 t/ha) aplicado en **5 fracciones** del 1 oct al 15 feb (plantación → ~día 137, es decir hasta la diferenciación del bulbo) [F19] → la ventana de hoja concentra la mayoría de las fracciones.
- Cal Ag 1988: «Nitrogen applications of 100 pounds per acre or more … increased garlic yields in all but one of the ten experiments» [F22] (sin momentos).
- Mínimo: **2 defendible** (InfoAgro, ya en guía: plantación + 60 días; Cárdenas 2019 usa 3). Recomendación: `minNitrogenPasses: 2` (hoja + diferenciación; el 20–25 % de plantación con el P), coarse 3.
- Conflicto a documentar: InfoAgro dice «nunca tras iniciar bulbo», mientras la guía pone 35 % en bulbDifferentiation. Hermosillo (última fracción 15 feb ≈ 10 semanas antes de cosecha) y el calendario INIFAP Zacatecas (nota de la guía) respaldan a la guía: N durante la diferenciación sí, cortando 4–6 semanas antes de cosecha.

### B. Topes
- 112 kg N/ha: **se sostiene por extensión** de cebolla (PNW 546, CDFA cebolla) — no hay tope explícito para ajo. Hermosillo: 180/5 = 36 kg por fracción. Consistencia: 200 × 0.40 = 80 ✔.

### C. Dosis
| Nutriente | Actual | Veredicto | Fuentes |
|---|---|---|---|
| N | 120–200 | **Se sostiene** | Redalyc/Biotecnia: «30, 120, 180, 240 and 300 kg N ha-1» → 15.78 / 19.39 / **22.03** / 20.88 / 21.86 t/ha; óptimo 180 [F19]. Cal Ag: «The addition 100 to 200 pounds of nitrogen per acre [112–224] should be sufficient for garlic»; libre de virus «as much as 300 pounds [336]» [F22]. InfoAgro 120–240 (ya en guía). |
| P₂O₅ | 60–100 | **Se sostiene con matiz** | Cal Ag: «Despite very low concentrations of available phosphorus in seven soils … there was no significant yield response to phosphorus»; «Phosphorus and zinc fertilizers are rarely required» [F22]. InfoAgro 60–80 (100 goteo). Una sola fuente en contra → sin cambio, pero permitir 0–30 con Olsen alto. |
| K₂O | 100–200 | **CAMBIAR el mínimo a 0 (por análisis)** | Cal Ag: «Potassium application had little or no effect on garlic yield»; los 10 campos tenían «more than 100 parts per million (ppm) exchangeable soil potassium» [F22]. PNW 546 (Allium): K₂O = 0 con >100 ppm [F16]. CDFA cebolla: K solo «less than 100 ppm» [F17]. Tres fuentes independientes (una de ajo, dos de cebolla) y coherencia con el criterio que la guía ya usa en cebolla (mín 0). Máximo 200 se sostiene (InfoAgro extracción 70–170 kg K = 84–204 K₂O). |

### D. Criticidad
- vegetativeLeafDevelopment crítica: **se sostiene** (Hermosillo, 4 de 5 fracciones en esa etapa; guía «cada hoja es un diente»).
- bulbDifferentiation crítica: **se sostiene con matiz** (respaldo: Hermosillo y calendario INIFAP Zacatecas; en contra: InfoAgro «nunca tras iniciar bulbo»). Mantener, con la regla de corte 4–6 semanas antes de cosecha.

---

## 10. Resumen de cambios propuestos

| # | Cultivo | Campo | Actual | Propuesta | Respaldo |
|---|---|---|---|---|---|
| 1 | Tomate, chile, pepino, berenjena, calabaza, cebolla, ajo | `minNitrogenPasses` | 3 | **2** (`splitRequired` se mantiene; coarse 3, cebolla 4) | H1: F2, F21, F11, F12, F10, F16 + Fertilab Zacatecas e InfoAgro (ya en guía) |
| 2 | Todos | `nitrogenPassPriority` | — | listas de la sección A de cada cultivo | A de cada cultivo |
| 3 | Lechuga, espinaca | `maxSinglePassKgN` | 45 (todas las pasadas) | 45 solo fondo/arranque; cobertera 90 (lechuga) / 60 (espinaca), o subdivisión automática | H2, F13, F14, F15 |
| 4 | Ajo | K₂O mín | 100 | **0** (por análisis; >100 ppm nada) | F22, F16, F17 |
| 5 | Calabaza | `splitNotesEs` | «fraccionado 785» | aclarar que fueron DOS aplicaciones (50 % fondo + 50 % mitad de ciclo) | F11 |
| 6 | Espinaca | `sourceEs` P₂O₅ | «38–45 kg P/ha» | verificar si TecnoAgro da P o P₂O₅; si es P, la extracción es 87–103 P₂O₅ | H3 |
| 7 | Tomate/chile/pepino/berenjena | `maxSinglePassKgN` | ninguno | opcional: 112 (100 lb/ac, único tope explícito en la literatura) y preplante 34 en tomate | F1, F2, F16, F17 |

Sin cambio (se sostienen): todas las dosis N/P₂O₅/K₂O de los 9 cultivos salvo K₂O mín de ajo; K₂O 120–180 en tomate (los 250–330 son remoción a ~100 t/ha); K₂O mín 0 en cebolla y calabaza; P₂O₅ 75–100 en berenjena; tope 112 en cebolla/ajo; todas las ventanas críticas (con los matices anotados en cada D).

---

## E. Fuentes consultadas

| # | URL | Institución / año | Qué dice (cifras usadas) | Lectura |
|---|---|---|---|---|
| F1 | https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Tomato.html | CDFA-FREP / UC Davis (Geisseler), guía 2016–2023 | Preplante «max. 30 lbs/acre»; arranque 5–15 lb; «<30% of their N before fruit set»; uptake máximo entre cuaje temprano y primer fruto rojo; Olsen-P <10 ppm 60–100 lb P₂O₅, 10–20 ppm 50–80; K 135 ppm rodado / 200 goteo / 270 color; remoción 220–330 lb K₂O/ac a 45 t/ac; «some 100 lbs K2O/acre»; Zhang sin respuesta >210 lb K₂O | Completa (extracto por fetch) |
| F2 | https://ipm.ucanr.edu/agriculture/tomato/fertilization/ | UC IPM / UC ANR | Rodado: 150 lb N/ac temporada; «a single sidedress application of 100 to 120 lb nitrogen per acre is normally sufficient»; NO₃-N >15 ppm ≤50 lb; goteo hasta 200 lb; P/K: bajo hasta 150 P₂O₅ y 200 K₂O, medio 75/100; K <130 / 130–250 / >250 ppm | Completa |
| F3 | https://www.progressivecrop.com/2025/09/11/management-of-potassium-in-processing-tomato/ | Progressive Crop Consultant, 2025 (secundaria; cita Hartz & Hanson 2009 y CTRI) | 50-ton crop remueve 200–300 lb K/ac (4–6 lb/ton); «general recommendation is 100 pounds K2O per acre»; respuesta probable <200 mg/kg | Completa |
| F4 | https://vun.inifap.gob.mx/VUN_MEDIA/BibliotecaWeb/_media/_agendas/4142_4839_Agenda_T%C3%A9cnica_Sinaloa_2017.pdf | INIFAP, Agenda Técnica Sinaloa 2017 | No cubre hortalizas (solo cártamo, frijol, garbanzo, maíz, sorgo, soya, trigo, praderas, mijo, alfalfa) | Completa (negativo) |
| F5 | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S1870-04622011000200012 | SciELO México (Jalisco, sistemas de producción de tomate), 2011 | Campo abierto 35–70 t/ha; sin dosis | Completa (negativo) |
| F6 | https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792024000100302 | Terra Latinoamericana, 2024 (saladette a 2 racimos, invernadero) | 0.78 N, 0.12 P, 1.74 K kg/t; no aplicable a campo | Completa (no usada en veredictos) |
| F7 | https://vun.inifap.gob.mx/VUN_MEDIA/BibliotecaWeb/_media/_agendas/4124_4821_Agenda_T%C3%A9cnica_Chihuahua_2017.pdf | INIFAP, Agenda Técnica Chihuahua 2017 | Cebolla: «100 a 180 kg/ha de nitrógeno en riego por cintilla y gravedad, respectivamente»; «80 kg/ha de fósforo (P2O5)»; 4 fracciones: camelloneo (todo el P + 1/4 N, 25–45 kg), mediados de febrero, marzo «al inicio del crecimiento del bulbo», mediados de abril; 36.5 t/ha. Chile jalapeño: solo solución para almácigo | Completa (secciones cebolla y chile) |
| F8 | https://vun.inifap.gob.mx/VUN_MEDIA/BibliotecaWeb/_media/_agendas/4134_4831_Agenda_T%C3%A9cnica_Morelos_2017.pdf | INIFAP, Agenda Técnica Morelos 2017 | El fetch solo alcanzó aguacate, amaranto y arroz; hortalizas no verificadas | Parcial (truncado) |
| F9 | https://pubs.nmsu.edu/_h/H257/ | NMSU Extension, Guide H-257 Red Chile and Paprika | «Approximately 200 lb/ac of nitrogen are used»; ventana óptima «begins … first bloom … through early fruit development»; corte a mediados de agosto; P «50 to 100 lb/ac of P2O5» preplante; sin K | Completa |
| F10 | https://ask.ifas.ufl.edu/publication/CV228 | UF/IFAS SL 330 (Hochmuth & Hanlon), berenjena | Objetivo 200-160-160; meseta a 200 lb N, baja >250; Live Oak meseta 60 (1988) y 120 lb (1989–90); ensayos con 2–3 aplicaciones iguales o 4 mensuales; +30 lb N cosecha extendida; K óptimo 160 lb, 100 suficiente en varios; P 150–200 lb en suelos bajos, poca investigación | Completa |
| F11 | https://ask.ifas.ufl.edu/publication/CV227 | UF/IFAS SL 343, calabaza | Objetivo 150-120-120; Sutton 1965 100 lb 93 % RY / 150 lb 100 %; Hochmuth 1992 80 lb; butternut 50 lb; Santos 2006 50–100 lb; Csizinszky 1985 «twice (50% preplant and 50% at mid-growth, resulting in 785 bushels/acre)» vs «once … 335»; P y K meseta a 100 lb | Completa |
| F12 | https://ask.ifas.ufl.edu/publication/CV226 | UF/IFAS SL 335, pepino | Objetivo 150-120-120; óptimos 120–160 lb N; 1963 «split (80% preplant and 20% side-dressed)» > todo a la siembra; P 60 lb 97 % RY, nada >31 ppm; K cobertera 50–150 lb mantiene el suelo; sin investigación de K | Completa |
| F13 | https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Lettuce.html | CDFA-FREP / UC Davis | N ≤150–180 lb invierno-primavera, 100–140 verano-otoño; preplante 20–40 lb; arranque 20 lb; amonio >50–60 lb daña plántula; <20 % primer mes; 3–4 lb/día; 70–80 % entre acogollado y cosecha; umbral 20 ppm; P hasta 200 lb P₂O₅ (<10 ppm), ≤100 (30–40 ppm), 20 (40–60); K remoción 70–110 lb K₂O, nada >150 ppm | Completa |
| F14 | http://geisseler.ucdavis.edu/Guidelines/Lettuce.html | UC Davis Geisseler Lab (misma guía) | Primera cobertera tras aclareo (2–4 hojas); segunda 2–4 semanas después en «cupping» si NO₃ <20 ppm; opcional 10–15 lb 7–10 d antes de cosecha | Completa (sección momentos) |
| F15 | https://vric.ucdavis.edu/pdf/fertilization/fertilization_EfficientNitrogenManagementforCoolSeasonvegetable2017.pdf | UC ANR VRIC (Smith, Cahn, Hartz), 2017 | Lechuga: absorción 120–160 lb, remoción 60–90, 3–4 lb/día, aplicación típica 100–220 lb; baby 60–70 / 160–190; espinaca: absorción 100–130 lb, remoción 70–90, 5–7 lb/día, aplicación típica 160–200 lb; >20 ppm posponer | Completa (tablas 1–2) |
| F16 | https://extension.oregonstate.edu/sites/extd8/files/documents/pnw546.pdf | OSU/UI/WSU, PNW 546 | 40–160 lb N total (suelo + fertilizante); «side-dress … 40 to 80 lb N per acre per application»; «should not exceed 100 lb N per acre»; split mejor donde hay lixiviación; aplicar en inicio de bulbo; 2–3 lb N/día; K₂O 240 / 120 / 0 lb a 0 / 50 / >100 ppm; remoción 110–160 lb K; S 30–40 lb si <5 ppm | Completa |
| F17 | https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Onion.html | CDFA-FREP / UC Davis | Goteo 150–200 lb N (50–70 t/ac), hasta 250; rodado industrial 100–150; ≤1/3 al plantar; <20 % primera mitad; 1.5–3.5 lb/día; «Individual applications should not exceed 100 lbs N/acre», 30 lb en suelos con mucha MO; 65–80 % en temporada desde inicio de bulbo; P hasta 200 lb, ≤50 si >30 ppm, banda ≤70; remoción P₂O₅ 61–98; K hasta 150 lb si <100 ppm, banda ≤30; remoción K₂O 170–225 | Completa |
| F18 | https://revistas.unal.edu.co/index.php/acta_agronomica/article/view/100895 | Acta Agronómica (UNAL) | Espinaca: 0–150 kg N/ha × momentos (plantación, 15, 30, 45 d); mejor 90 kg a 15 d; autores: posible sin cobertera | Resumen/metadatos |
| F19 | https://www.redalyc.org/pdf/6729/672971159003.pdf | Biotecnia (UNISON) vía Redalyc, Huez López et al. 2010 | Ajo goteo Costa de Hermosillo: 30/120/180/240/300 kg N → 15.78/19.39/22.03/20.88/21.86 t/ha; 5 fracciones 1 oct–15 feb; óptimo 180 | Completa |
| F20 | https://www.redalyc.org/journal/813/81381932004/81381932004.pdf | UNISON vía Redalyc, 2024 (serrano, calidad) | Testigo químico 290 N – 75 P – 250 K – 70 Ca – 45 Mg kg/ha, Hermosillo; sin optimización de dosis | Completa |
| F21 | https://ucanr.edu/sites/default/files/2018-11/294695.pdf | UC ANR Vegetable Production Series, Bell Pepper Production in California | «180 to 240 pounds per acre (201 to 268 kg/ha) of N is normally sufficient»; muchos >250 lb; «N and K are applied preplant and in one or more sidedressings»; goteo fertirriegos pequeños; P 80–200 lb P₂O₅ preplante; K solo <150 ppm, 50–150 lb K₂O; 16.5–20 t/ac | Completa |
| F22 | https://calag.ucanr.edu/download_pdf.cfm?article=ca.v042n02p28 | California Agriculture 42(2), 1988, «Diagnosing nutrient needs of garlic» | N ≥100 lb subió rendimiento en 9 de 10 ensayos; «100 to 200 pounds of nitrogen per acre should be sufficient»; libre de virus hasta 300; sin respuesta a P ni Zn aun con P muy bajo; K sin efecto (todos >100 ppm) | Completa |
| F23 | https://www.lgseeds.es/media/guia-practica-fertilizacion-cultivos-ii.pdf | MAPA, Guía práctica de la fertilización racional, Parte II (espejo) | El fetch solo alcanzó caps. 16–20 (cereales, leguminosas, patata, industriales); hortalizas no verificadas | Parcial (no usada) |
| — | https://www.gob.mx/inifap/es/articulos/manejo-eficiente-del-agua-y-nutricion-de-jitomate-solanum-lycopersicum-l-en-sistemas-intensivos | INIFAP | 403: sigue ✎ | Fallida |
| — | https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Spinach.html | CDFA | 404: no existe guía CDFA de espinaca; no citarla | Fallida |
| — | http://geisseler.ucdavis.edu/Guidelines/Spinach.html | UC Davis | Bloqueo TLS/robots | Fallida |

Fuentes de la guía NO releídas en esta sesión (se citan por su etiqueta en la guía, sin verificar): Agroes, Panorama Agropecuario, Bio Ciencias UAN, Hortalizas.com, Intagri (pepino, berenjena, cebolla, ajo), Zamorano, Terra 2011 y Fitotecnia 2012 (calabacita), Cajamar, TecnoAgro, Fertilab, NC State, InfoAgro, Machado & Bryla 2016, Cárdenas 2019, Arizona/YCEDA.
