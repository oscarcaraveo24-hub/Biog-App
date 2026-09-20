# Ornamentales y plantas de baja demanda: ¿hay plan cuantitativo defendible?

Informe de investigación para BIO-G · 2026-09-17 · Alcance: `_rose`, `_annualOrnamentalRules` (girasol, cempasúchil), `_tulip`, `_lowDemandRules` (cactus, suculenta, sábila, agave, nopal) en `nutrition_guides.dart` líneas 3014–3249.

Criterio del dueño: una cifra solo se acepta con **≥3 fuentes primarias e independientes** (institutos, universidades, revistas indexadas, extensión oficial). Intagri/Yara/ICL/viveros = secundarias, no cuentan.

Método: 18 búsquedas web + 32 lecturas (WebFetch). Limitación importante: varios PDF clave de INIFAP/gob.mx/ICAMEX/Chapingo no se pudieron abrir (robots.txt con timeout, 429 en ResearchGate, redirecciones en revistas). Se listan al final como «no accesibles» para que el equipo los consulte a mano; **ninguna cifra de este informe proviene de una fuente que no se haya leído**.

---

## Resumen ejecutivo

| Cultivo | Fuentes primarias con cifra leídas | Veredicto | Ventana única de N (clave de etapa) |
|---|---|---|---|
| Girasol (campo, grano) | 3 (Colpos 2021, Terra Lat. 2012, INIFAP 2025) | **N defendible: 60–120 kg N/ha**; P₂O₅ parcial (0–52); K₂O sin plan | `sowing` (presiembra/siembra en banda) |
| Nopal verdura (campo) | 2 recomendaciones (Colpos 1991, UANL 2006) citadas en RMCA/INIFAP 2023 + 1 ensayo Colpos 2016 | **Provisional (2 fuentes): 120–150 N / 100 P₂O₅ / 0–50 K₂O kg/ha/año, en 3 fracciones** | `active_growth` |
| Tulipán (producción de bulbo) | 2 (LBO 1998 y PPO 2004; mismo instituto WUR) | **Sin plan defendible por 1 fuente independiente**: 134–176 kg N/ha/temporada; NBS 80 kg N/ha a la emergencia | `shoot_emergence` |
| Rosal (jardín/cama) | 1 (UF/IFAS 2017) + 1 diagnóstico (Colpos 2017) | **Sin plan defendible** | `vegetative_flush` |
| Cempasúchil | 1 indirecta (UAM-X 2021 citando Valdez et al. 2015, maceta) | **Sin plan defendible** | `early_vegetative_growth` |
| Cactus | 1 (UC ANR MG Fresno) + 1 boletín gremial 1953 | **Sin plan defendible** (consenso cualitativo: ¼–½ de etiqueta, mensual, solo en crecimiento) | `active_growth` |
| Suculenta | idem cactus | **Sin plan defendible** | `active_growth` |
| Sábila | 1 (UACh/INIFAP 2016, solo biofertilizantes) | **Sin plan defendible** | `active_growth` |
| Agave | 1 ensayo (INIFAP/Colpos/IPN 2018) + 1 ensayo A. angustifolia (IPN 2022) | **Sin plan defendible** | `active_growth` (inicio de lluvias; práctica regional no verificada en primaria) |

Conclusión: **solo girasol cumple el umbral de 3 fuentes para N**. Nopal queda a una fuente de cumplir (y las dos recomendaciones se leyeron a través de una cita, no del original). Tulipán tiene dos documentos sólidos pero del mismo instituto. El resto se queda en «según etiqueta», con orientación cualitativa respaldada.

---

## Fórmulas de conversión usadas

- kg/ha ÷ 10 = g/m².
- g/planta = kg/ha × 1000 ÷ (plantas/ha).
- Fertirriego: g N por planta y riego = (mg N/L ÷ 1000) × litros aplicados por planta.
- lb por 100 ft² → g/m²: × 453.6 ÷ 9.29 = × 48.8.
- «¼ de la etiqueta»: si la etiqueta dice X g/L de un 20‑20‑20, usar X/4 g/L; N (mg/L) = (X/4) × 20 × 10.

---

## 1. Girasol — DEFENDIBLE para N (60–120 kg N/ha)

| Nutriente | Rango propuesto | Reparto por etapa (claves de la guía) | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| N | **60–120 kg N/ha** por ciclo (6–12 g/m²; a 70 000–85 000 pl/ha ≈ 0.8–1.7 g N/planta). Perfil ornamental/corte: usar el extremo bajo (60). | 50 % en `sowing` (fondo, en banda) + 50 % en `early_vegetative_growth` (~30 DDS) [Colpos 2021]; alternativa 100 % presiembra [INIFAP 2025]. Cero N desde `bud_formation`. | 3 | Defendible |
| P₂O₅ | **0–52 kg/ha**, 100 % en `sowing` | Todo al fondo | 2 (contradictorias: Terra 2012 = 0 significativo; INIFAP 2025 aplica 52) | Parcial: «según análisis de suelo; si no hay análisis, 40–50 al fondo» |
| K₂O | Ninguna de las 3 fuentes aplicó K | — | 0 | Sin plan (según análisis de suelo) |

Cifras exactas:
- Colpos (Arenas‑Julio et al., Biotecnia 23(1):45‑51, 2021): «dos niveles de nitrógeno de 0 (N0) y 100 kg ha‑1 (N100), los cuales se aplicaron de forma fraccionada, la mitad al momento de la siembra y el resto a los 30 días»; máxima producción con «la aplicación de nitrógeno a 100 kg ha‑1 y la inoculación del biofertilizante» (+42 % biomasa, +28 % rendimiento de grano vs. cero). Fuente: urea 46 %. No aplicaron P ni K.
- ITSON/ITVY/Colpos (Moreno et al., Terra Latinoamericana 30(1):89, 2012): «cuatro dosis de N: 0, 60, 120 y 180 kg de N ha‑1»; óptimo económico «54 kg ha‑1» de N para DO‑730 (77 000 pl/ha) y 0 para Madero‑91; «cuatro dosis de fósforo: 0, 30, 60 y 90 kg de P₂O₅ ha‑1», no significativo → recomiendan 0 P.
- INIFAP CE Norman E. Borlaug (Cantúa‑Ayala et al., Rev. Mex. Cienc. Agríc. 16(7), 2025): «Se fertilizó en pre siembra con la fórmula 149‑52‑00 (N‑P‑K), aplicando 300 kg ha⁻¹ de Urea (46 % de N) y 100 kg ha⁻¹ de MAP (11‑52‑00)»; según el resumen del texto, los autores citan estudios que sugieren 80–120 kg N/ha (frase resumida por la herramienta, no verbatim).

Advertencias: (a) las tres fuentes son de girasol de grano/aceite, no ornamental; la extrapolación al ornamental es del informe, no de la literatura; (b) la respuesta a N depende del genotipo y del N residual (Terra 2012 encontró 0 óptimo en un genotipo). Propuesta de texto para la guía: «60–120 kg N/ha; mitad a la siembra y mitad a los 30 días; corta el N al botón».

Ventana única de N: `sowing` (presiembra/siembra en banda, nunca en contacto con la semilla). INIFAP aplicó el 100 % presiembra y Colpos el 50 %; es la etapa con más respaldo.

---

## 2. Cempasúchil — SIN PLAN DEFENDIBLE

| Nutriente | Rango disponible | Reparto | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| N | Maceta (fertirriego): **175 mg N/L los primeros 30 días tras trasplante, 225 mg N/L del día 31 al 60**; bajar N en etapa reproductiva | `early_vegetative_growth` → `active_vegetative_growth`; reducir en `bud_formation` | 1 (UAM‑X 2021, que cita Valdez et al. 2015, no verificado) | Sin plan defendible |
| P₂O₅ / K₂O | Solo una fórmula de solución (Sonklien et al. 2020, citada): N 106.5, P 107.3, K 98.1 mg/kg | — | 1 indirecta | Sin plan defendible |
| Campo (kg/ha) | **No se pudo leer ninguna fuente primaria con cifra** (ICAMEX, INIFAP, artículo organomineral bloqueados) | — | 0 | Sin plan defendible |

Cifra exacta: UAM‑Xochimilco (Rosas Loera, 2021, manual de producción en maceta cv. Marvel): «Se sugiere llevar una fertilización al sustrato con alguna fuente de nitrógeno que suministre 175 mg L⁻¹ de N durante los primeros 30 días posteriores al trasplante y aumentar la dosis a 225 mg L⁻¹ desde el día 31 hasta el 60» (atribuido a Valdéz et al., 2015). Conversión: 175 mg/L × 0.2 L por riego = 0.035 g N por planta y riego.

Lo que se descartó: Serrato‑Cruz et al. 2008 (RFM 31(3)) es de carotenoides, no de nutrición; RFM 38(3) 8a (2015) resultó ser de nochebuena. Existe literatura india de N×K en Tagetes erecta (ResearchGate/AGRIS) pero no se leyó ni se cuenta.

Ventana única de N: `early_vegetative_growth` (primeros 30–60 días tras trasplante; toda la fuente disponible concentra el N ahí y lo baja al botón).

---

## 3. Tulipán — SIN PLAN DEFENDIBLE (falta 1 fuente independiente)

| Nutriente | Rango disponible | Reparto (calendario holandés → claves de la guía) | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| N | **134–176 kg N/ha/temporada** (13–18 g/m²) de fertilizante mineral; absorción total al óptimo **146 kg N/ha** | `bulb_planting`/`rooting_chilling` (otoño): 0 N. `shoot_emergence` (emergencia, feb): **80 kg N/ha** en arena/franco/arcilla (o 2×40 en duna). `vegetative_growth`–`stem_elongation` (fin mar/abr): hasta 65 kg N/ha menos N del suelo. `bud_formation`–`flowering` (fin abr/may): hasta 70 menos N del suelo. `bulb_recharge` (fin may): hasta 45 menos N del suelo. | 2 (LBO 1998, PPO 2004; ambos hoy WUR) | Sin plan defendible por la regla de independencia |
| P₂O₅ / K₂O | «bajo suficiencia… solo una indicación» | — | 0 | Sin plan |

Cifras exactas:
- Laboratorium voor Bloembollenonderzoek, Lisse, Rapport 101, ene‑1998 (p. 17): «Startgift: op dekzand‑, zavel‑ en kleigronden bij opkomst 80 kg N/ha; op gescheurd grasland 40 kg N/ha; op duin/zeezandgronden medio februari 40 kg N/ha»; «Vlak voor spreiden op duin‑/zeezandgronden 40 kg N/ha»; «Eind maart/begin april na N‑meting 65 – Nvoorraad»; «Eind april/begin mei na N‑meting 70 – Nvoorraad»; «Eind mei na N‑meting 45 – Nvoorraad»; (p. 15) «de totale N‑opname (bij Noptimum) 146 kg N per ha».
- PPO Bloembollen, infoblad «Efficiënte stikstofbemesting bij tulp», abr‑2004: «twee startgiften gegeven van 40 kg N per ha, half februari en begin maart»; «totale kunstmest N‑aanvoer voor plantmaat 8‑9 van 134 tot 176 kg N per ha».

Implicación para la guía actual: el programa holandés **sí fertiliza durante brote y floración** (la mayor dosis fija va a la emergencia), porque lo que se llena es el bulbo del año siguiente; la regla «brote y flor: ventana cerrada» de `_tulip` contradice estas dos fuentes. Para jardín (bulbo que se deja en tierra) el objetivo es el mismo: reparto 40–80 kg N/ha (4–8 g/m²) a la emergencia + el resto tras la flor.

Tercera fuente candidata (no leída): Handboek bodem en bemesting (CBAV) o normas de uso de N de RVO para bloembollen; extensión de Cornell/NC State para bulbos de jardín.

Ventana única de N: `shoot_emergence` (la «startgift» de 80 kg N/ha es la única dosis fija del sistema; las demás dependen de la medición de N).

---

## 4. Rosal — SIN PLAN DEFENDIBLE

| Nutriente | Rango disponible (jardín, cama) | Reparto | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| N‑P₂O₅‑K₂O (10‑10‑10) | **2–3 lb/100 ft² en dos aplicaciones al inicio de primavera** = 98–147 g/m² de 10‑10‑10 = **9.8–14.7 g N/m²**; luego **1–2 lb/100 ft² cada 4 semanas desde el botón hasta mediados de agosto** = 4.9–9.8 g N/m² por aplicación | `vegetative_flush` (tras la poda): 2 dosis; `bud_formation`/`post_bloom_recovery`: 1 dosis cada 4 semanas; parar a mitad de verano (`rest` antes de heladas) | 1 (UF/IFAS Nassau 2017) | Sin plan defendible |
| Corte (invernadero) | Diagnóstico Colpos 2017: productores aplican «por arriba de 7000 kg ha‑1 anuales» de N, «excesivo»; parcela experimental recibió 150 kg N; hoja <2 % N = deficiente | — | 0 recomendaciones | Sin plan defendible |

Cifras exactas: UF/IFAS Extension Nassau Co. (21‑jun‑2017): «2 to 3 pounds per 100 square feet between two feedings in early spring (March – April)»; «apply an additional 1 to 2 pounds of balanced fertilizer per 100 square feet once buds form and continue every four weeks until mid‑August»; «the amounts listed above are NOT per rose plant but instead for a whole bed of roses». Colpos (Cortés Jiménez et al., Terra Latinoamericana 35(3), 2017): «La fertilización nitrogenada en rosa de corte presenta aplicaciones de nitrógeno elemental por arriba de 7000 kg ha‑1 anuales, lo que se considerada como excesivo»; «el aporte de este elemento a la parcela muestreada fue 150 kg».

Callejón sin salida: Texas A&M EHT‑070 resultó ser de hortalizas, no de rosal. Faltan 2 fuentes (UC ANR Pest Notes/Master Gardener rosas, Cornell, UACh/Colpos fertirriego de corte).

Ventana única de N: `vegetative_flush` (brotación tras la poda de primavera: es donde UF/IFAS concentra la dosis mayor y la guía ya lo tiene como ventana de N).

---

## 5 y 6. Cactus y suculentas — SIN PLAN DEFENDIBLE (consenso cualitativo)

| Nutriente | Orientación disponible | Reparto | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| NPK soluble | **¼ de la dosis de etiqueta, una vez al mes, solo en temporada de crecimiento** (UC ANR); «media dosis… en temporada de crecimiento; es mejor quedarse corto» (boletín NY 1953). Ejemplo de conversión: etiqueta 1 g/L de 20‑20‑20 → ¼ = 0.25 g/L = 50 mg N/L; ½ = 0.5 g/L = 100 mg N/L. Granulado de liberación lenta (Osmocote): «alimenta 3 o 4 meses». | `active_growth`: mensual; `maintenance`/`rest`: nada | 1 (UC ANR Master Gardeners Fresno) + 1 gremial | Sin plan defendible; la redacción actual de `_rulesLowDemand` («mitad de la etiqueta y solo con la planta creciendo») es coherente con ambas fuentes |

Cifras exactas: UC ANR MG Fresno («Under the spell of succulents», sin fecha): «If you use a powdered fertilizer like Miracle Gro, mix it to 1/4 strength»; «Fertilize once a month during the growing season»; «Add pellet fertilizer like Osmocote to your soil, it will feed your plants for 3 or 4 months». NY State Flower Industries Bull. 157 (Huttar, 1953; archivo NCSU): «Fertilize with half strength house plant food during the growing season. It is better to underfertilize than to overdo».

Ventana única de N: `active_growth` (primera dosis al arrancar el crecimiento, primavera o, en cactus de crecimiento estival, inicio de lluvias).

---

## 7. Sábila — SIN PLAN DEFENDIBLE

| Nutriente | Orientación disponible | Reparto | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| Orgánico | **Lombricomposta 10 t/ha en una aplicación al inicio del año** fue el mejor tratamiento (grosor de hoja, calidad de gel); ácidos húmicos 54–108 L/ha en 4 aplicaciones/año | `active_growth` | 1 (UACh‑URUZA/INIFAP 2016) | Sin plan defendible |
| N‑P‑K mineral | Ninguna fuente primaria leída da dosis mineral | — | 0 | Sin plan defendible |

Cifra exacta: Aba Guevara et al., Investigación y Ciencia (UAA) 24(67), 2016: ácidos húmicos «0, 54 y 108 l ha⁻¹» (cuatro veces al año); lombricomposta «0, 5 y 10 t ha⁻¹» en aplicación única; mejor «10 t ha⁻¹ de lombricomposta». Cosecha óptima octubre–diciembre.

No accesibles: «Efecto del acolchado plástico, fertilización nitrogenada y composta orgánica en… sábila con riego por goteo» y «Manejo agronómico de la sábila en zonas áridas» (ResearchGate 429); Agro Productividad 912 (redirección); Ciencia UANL (no leído).

Ventana única de N: `active_growth` (primavera–verano, con el sustrato húmedo; la única fuente aplica al inicio del ciclo).

---

## 8. Agave — SIN PLAN DEFENDIBLE

| Nutriente | Orientación disponible | Reparto | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| N‑P‑K | Ensayo de fertirriego (INIFAP/Colpos/IPN, Tamaulipas 2018): base **«162‑150‑250 kg ha⁻¹ de N, P y K»** + 1 t/ha de orgánico + 5 kg/ha MgSO₄; fertirriego acumulado por planta en el ciclo «315.3 g de N; 179.9 g de P₂O₅; 353.4 g de K₂O; 111 g de CaO y 89.1 g de MgO» (348 riegos). Es un **tratamiento experimental, no una recomendación**. | — | 1 ensayo | Sin plan defendible |
| Liberación lenta (A. angustifolia, IPN‑CIIDIR 2022) | «19 g por planta» de Osmocote 15‑9‑12 o Basacote 16‑8‑12 (= 2.5 kg/m³ de suelo, vivero); los autores advierten: «Los productos evaluados no incluyen dosis ni periodos de aplicación para agave». | `installation_establishment` (vivero) | 1 ensayo | Sin plan defendible |

Conversión ilustrativa: 315 g N/planta en el ciclo a 3 000 pl/ha = 945 kg N/ha acumulados en ~6 años ≈ 160 kg N/ha/año (coincide con la base de 162), pero es un dato de ensayo bajo riego, no extrapolable al temporal de Jalisco. Las recomendaciones de INIFAP‑Jalisco/CRT/CIATEJ por edad de planta no se pudieron leer en fuente primaria; ICL, Hydroenv, Agroproductores, Gor Green son comerciales (no cuentan).

Ventana única de N: `active_growth` al inicio de las lluvias (junio–julio). Es la práctica regional descrita por fuentes secundarias; **no quedó verificada en primaria** en esta sesión.

---

## 9. Nopal verdura — PROVISIONAL (2 recomendaciones + 1 ensayo; a una fuente del umbral)

| Nutriente | Rango propuesto | Reparto por etapa | Nº fuentes primarias | Veredicto |
|---|---|---|---|---|
| N | **120–150 kg N/ha/año** (12–15 g/m²) | 3 fracciones iguales: `active_growth` al arrancar la brotación de primavera (tras la poda/limpieza), inicio de lluvias y mitad de verano; nada en `rest` (invierno) | 2 recomendaciones (Colegio de Postgraduados 1991: 120‑100‑00; UANL 2006: 150‑100‑50), leídas vía cita en RMCA 2023 | Provisional |
| P₂O₅ | **100 kg/ha/año** | 100 % en la primera fracción | 2 (mismas) | Provisional |
| K₂O | **0–50 kg/ha/año** | Con la primera fracción | 2 (0 en Colpos 1991; 50 en UANL 2006) | Provisional |
| Estiércol | Sin dosis defendible; los productores aplican 137–187 t/ha (excesivo según los autores); Colpos 2016 ensayó **5 kg de estiércol + 80 g de triple 17 por planta y año** (= 13.6 g N/planta/año) | `active_growth` | 1 ensayo + 1 diagnóstico | Sin plan (indicar «estiércol descompuesto según disponibilidad») |

Cifras exactas: Reyes‑Terrazas et al., Rev. Mex. Cienc. Agríc. 14(2):211–, 2023 (Otumba, Edomex): «en el G1 a dosis de N‑P‑K (kg ha⁻¹) promedio es de 355‑65‑50, mientras que en G2 la dosis es de 347‑50‑55, en ambos casos la aplicación es fraccionada en tres partes. Las dosis de fertilización mineral aplicadas son diferentes a las recomendaciones técnicas: 120‑100‑00, 150‑100‑50» (p. 218), citando García V. A. G. y Grajeda J. E. G. 1991, «Cultivo nopal para verdura», Colegio de Postgraduados, y Vázquez‑Alvarado R. E. et al. 2006, Acta Hortic. 728:151‑158. Estiércol: G1 «dosis que varían de 1 a 200 t ha‑1 (137 t ha‑1, promedio)»; G2 «1 a 500 t ha‑1 (187 t ha‑1, en promedio)». Santiago‑Lorenzo et al., Rev. Fitotec. Mex. 39(4):403, 2016 (Colpos): tratamiento «5 kg de estiércol de bovino y 80 g de fertilizante triple 17 por planta».

Conversión por planta: g N/planta/año = kg N/ha × 1000 ÷ plantas/ha (ej. 120 kg N/ha a 40 000 pl/ha = 3 g N/planta/año; el tratamiento Colpos 2016 de 13.6 g N/planta equivale, a esa densidad, a 544 kg N/ha, cerca de la práctica de Otumba).

Para llegar a 3: leer el original de Vázquez‑Alvarado 2006 (UANL) o el Manual INIFAP CENID‑RASPA 2000 (no accesible hoy), o el paquete de nopal de la Agenda Técnica INIFAP Morelos 2017 (pp. 151–157; el visor no devolvió esa parte).

Ventana única de N: `active_growth` (primera fracción al arrancar la brotación de primavera, tras la limpieza de invierno; los productores fraccionan en tres y la guía ya coloca el N ahí).

---

## Recomendación de implementación (sin tocar código)

1. **Girasol**: pasar de «sin plan en kg/ha» a 60–120 N / 0–50 P₂O₅ / K según suelo, con reparto 50/50 siembra–30 DDS y auditStatus «proposed → auditado (3 fuentes)». Nota de extrapolación a ornamental.
2. **Nopal**: 120–150 N / 100 P₂O₅ / 0–50 K₂O en tres fracciones, marcado «provisional: 2 fuentes»; pendiente leer un original.
3. **Tulipán**: corregir la regla «brote y flor sin fertilizar»: el programa holandés pone la dosis principal (40–80 kg N/ha) a la emergencia; mantener cifras como «provisional: 2 fuentes del mismo instituto».
4. **Rosal, cempasúchil, cactus, suculenta, sábila, agave**: mantener «según etiqueta» y añadir la orientación cualitativa respaldada (¼–½ de etiqueta mensual en crecimiento; rosal: dosis mayor tras la poda; cempasúchil en maceta: 175→225 mg N/L los primeros 60 días).

---

## Sección de fuentes (todas las consultadas)

Leyenda: **[completa]** = texto leído por la herramienta; **[parcial]** = el visor solo devolvió parte; **[solo metadatos]**; **[no accesible]**.

### Primarias con cifra
1. Arenas‑Julio Y. R. et al. «Rentabilidad y rendimiento de girasol en función del tipo de suelo, nitrógeno y biofertilizante». Biotecnia (Unison) 23(1):45‑51, 2021. Colegio de Postgraduados. https://www.redalyc.org/journal/6729/672971078006/html/ — 0 vs 100 kg N/ha fraccionado 50 % siembra / 50 % 30 DDS; máximo con 100 N. **[completa]**
2. Moreno R. O. H., Cruz Medina I. R., Herrera Andrade H., Turrent Fernández A. «Optimización de seis factores productivos para el girasol». Terra Latinoamericana 30(1):89‑, 2012. ITVY/ITSON/Colpos. https://www.scielo.org.mx/scielo.php?script=sci_arttext_plus&pid=S0187-57792012000100089&lng=es&tlng=es&nrm=iso — N 0/60/120/180; óptimo económico 54 kg N/ha (DO‑730) y 0 (Madero‑91); P₂O₅ 0/30/60/90 no significativo. **[completa]**
3. Cantúa‑Ayala J. A., Borbón‑Gracia A., Marroquín‑Morales J. Á., Castillo‑Torres N. «Evaluación de rendimiento de híbridos de girasol en el sur de Sonora». Rev. Mex. Cienc. Agríc. 16(7), 2025. INIFAP CE Norman E. Borlaug. https://www.scielo.org.mx/scielo.php?script=sci_arttext_plus&pid=S2007-09342025000700301&lng=es&tlng=es&nrm=iso — fertilización 149‑52‑00 en presiembra (300 kg urea + 100 kg MAP); cita 80–120 kg N/ha. **[completa]**
4. Reyes‑Terrazas et al. «Características y retos del sistema de cultivo nopal verdura en Cuautlacingo, Otumba». Rev. Mex. Cienc. Agríc. 14(2):211‑, 2023 (INIFAP). https://dialnet.unirioja.es/descarga/articulo/8882793.pdf (también https://cienciasagricolas.inifap.gob.mx/index.php/agricolas/article/download/3079/5757?inline=1 y https://classic.scielo.org.mx/pdf/remexca/v14n2/2007-0934-remexca-14-02-211.pdf) — práctica 355‑65‑50 / 347‑50‑55 en 3 partes; recomendaciones técnicas 120‑100‑00 (Colpos 1991) y 150‑100‑50 (UANL 2006); estiércol 137–187 t/ha. **[completa]**
5. Santiago‑Lorenzo M. R. et al. «Composición nutrimental del nopal verdura producido con fertilización mineral y orgánica». Rev. Fitotec. Mex. 39(4):403‑, 2016. Colpos Montecillo. https://www.scielo.org.mx/pdf/rfm/v39n4/0187-7380-rfm-39-04-00403.pdf — 5 kg estiércol + 80 g triple 17 por planta; compost 5 kg/planta + micorriza; mezcla mineral; testigo. **[completa]**
6. Laboratorium voor Bloembollenonderzoek (LBO, hoy WUR). «Stikstofbemesting en nutriëntenonderzoek bij diverse gewassen». Rapport bloembollenonderzoek nr. 101, Lisse, enero 1998. https://edepot.wur.nl/273573 — NBS tulp: 80 kg N/ha a la emergencia; 65/70/45 – N del suelo; absorción total 146 kg N/ha. **[completa]**
7. PPO Bloembollen (WUR). Infoblad «Efficiënte stikstofbemesting bij tulp», Mest‑ en mineralenprogramma's, abril 2004. https://edepot.wur.nl/33149 — 2×40 kg N/ha de arranque; total 134–176 kg N/ha (plantmaat 8‑9). **[completa]**
8. UF/IFAS Extension Nassau County. «I purchased 10‑10‑10 fertilizer for my roses. How much do I use?», 21‑jun‑2017. https://blogs.ifas.ufl.edu/nassauco/2017/06/21/purchased-10-10-10-fertilizer-roses-much-use — 2–3 lb/100 ft² en dos dosis (mar–abr); 1–2 lb/100 ft² cada 4 semanas desde el botón hasta mediados de agosto. **[completa]**
9. Cortés Jiménez S., Etchevers Barra J. D., Hidalgo Moreno C. M. I., Navarro Garza H. «Estado nutrimental del agroecosistema rosa (Rosa spp.) en la ladera este del Iztaccíhuatl». Terra Latinoamericana 35(3):237‑, 2017. Colpos. https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792017000300237 — >7000 kg N/ha/año aplicados (excesivo); 150 kg N en parcela; hoja <2 % N deficiente. Diagnóstico, no recomendación. **[completa]**
10. UC ANR Master Gardeners of Fresno County. «Under the Spell of Succulents» (s. f.). https://ucanr.edu/site/mgfresno/under-spell-succulents — ¼ de dosis de etiqueta, mensual en crecimiento; Osmocote 3–4 meses. **[completa]**
11. Aba Guevara C. G., Pedroza Sandoval A., Trejo Calzada R., Sánchez Cohen I., Samaniego Gaxiola J. A., Chávez Rivero J. A. «Uso de biofertilizantes en la producción de sábila Aloe vera (L.) L. N. Burm y calidad de gel». Investigación y Ciencia (UAA) 24(67), 2016. UACh‑URUZA/INIFAP. https://www.redalyc.org/pdf/674/67446178004.pdf — ácidos húmicos 0/54/108 L/ha (4 veces/año); lombricomposta 0/5/10 t/ha; mejor 10 t/ha. **[completa]**
12. Zúñiga‑Estrada L., Rosales Robles E., Yáñez‑Morales M. J., Jacques‑Hernández C. «Características y productividad de una planta MAC, Agave tequilana desarrollada con fertigación en Tamaulipas, México». Rev. Mex. Cienc. Agríc. 9(3), 2018. INIFAP/Colpos/IPN‑CBG. https://www.redalyc.org/journal/2631/263158442005/263158442005.pdf — base 162‑150‑250 kg/ha + 1 t/ha orgánico + 5 kg/ha MgSO₄; fertirriego 315.3 g N, 179.9 g P₂O₅, 353.4 g K₂O, 111 g CaO, 89.1 g MgO por planta en 348 riegos. **[completa]**
13. Sánchez‑Mendoza S., Bautista‑Cruz A. «Efecto de fertilizantes de liberación lenta y fitohormonas en el crecimiento de Agave angustifolia Haw.». Entreciencias 10(24), 2022. IPN‑CIIDIR Oaxaca. https://www.redalyc.org/journal/4576/457669807027/html/ — 19 g/planta (2.5 kg/m³) Osmocote 15‑9‑12 / Basacote 16‑8‑12; «no incluyen dosis ni periodos de aplicación para agave». **[completa]**
14. Rosas Loera M. F. «Manual para la producción de cempasúchil (Tagetes erecta L. cv Marvel) ornamental en maceta». UAM‑Xochimilco, 2021. https://repositorio.xoc.uam.mx/jspui/retrieve/e83c1df5-a39e-4dc7-a2f1-33c44e1a2b28/250427.pdf — 175 mg N/L (0–30 DDT) → 225 mg N/L (31–60 DDT) citando Valdéz et al. 2015; fórmula Sonklien et al. 2020 (N 106.5, P 107.3, K 98.1 mg/kg); bajar N en reproductiva. **[completa]** (la cita original Valdez 2015 no se verificó).

### Secundarias o sin cifra útil (leídas)
15. Huttar K. «Cacti and Succulents: Old Plants for Modern Living». New York State Flower Industries Bull. 157, nov‑dic 1953 (archivo NC State hortscans). https://hortscans.ces.ncsu.edu/file/../uploads/c/a/cacti_an_520a9965b53e8.pdf — «half strength house plant food during the growing season». Boletín gremial: no cuenta como primaria. **[completa]**
16. Serrato Cruz M. Á. et al. «Carotenoides y características morfológicas en cabezuelas de muestras mexicanas de Tagetes erecta L.». Rev. Fitotec. Mex. 31(3), 2008. https://www.redalyc.org/pdf/610/61009713.pdf — sin datos de fertilización. **[completa]**
17. Rev. Fitotec. Mex. 38(3):305‑312, 2015 (https://revistafitotecniamexicana.org/documentos/38-3/8a.pdf) — resultó ser de nochebuena (Euphorbia pulcherrima); sin cempasúchil. **[completa]**
18. Mandujano‑Bueno et al. «Algoritmo simplificado para aplicación racional de nitrógeno en trigos harineros en el Bajío». Rev. Fitotec. Mex. 46(3):255‑262, 2023. https://www.scielo.org.mx/pdf/rfm/v46n3/0187-7380-rfm-46-03-255.pdf — es de trigo, no agave. **[completa]**
19. Masabni J., Lillard P. «Easy Gardening: Fertilizing» (EHT‑070). Texas A&M AgriLife, 2014. https://aggie-horticulture.tamu.edu/wp-content/uploads/sites/10/2013/09/EHT-070.pdf — hortalizas; sin rosal. **[completa]**
20. INIFAP. «Agenda Técnica Morelos 2017». https://vun.inifap.gob.mx/VUN_MEDIA/BibliotecaWeb/_media/_agendas/4134_4831_Agenda_T%C3%A9cnica_Morelos_2017.pdf — el índice lista nopal verdura (pp. 151‑157), girasol y nochebuena, pero el visor solo devolvió aguacate/amaranto/arroz. **[parcial]** Pendiente de lectura manual.
21. Redalyc 263121473005 (Rev. Mex. Cienc. Agríc.) — es de amaranto. **[completa]**
22. DICEA‑Chapingo «Memoria Mesa 3» 2019 — sin cempasúchil. **[completa]**
23. «Fertilización organomineral en cultivo de cempasúchil (Tagetes erecta L.)», ojsincaing.com.mx. https://ojsincaing.com.mx/index.php/ediciones/article/view/257/fertiizacion — **[solo metadatos]**; el PDF no se abrió. Candidata a fuente primaria de campo.

### No accesibles en esta sesión (para lectura manual)
24. ICAMEX (Edomex). «Cultivo de Cempoalxóchitl». http://icamex.edomex.gob.mx/cempoalxochitl — robots/timeout.
25. INIFAP. «Usos y beneficios del cempasúchil en el sector agropecuario». https://www.gob.mx/inifap/es/articulos/usos-y-beneficios-del-cempasuchil-en-el-sector-agropecuario-inifap — no abierto.
26. INIFAP Norte‑Centro. «Agenda Tecnológica Durango 2017» (girasol). http://inifap-nortecentro.gob.mx/nodos/agendas_tecnologicas/Agenda_Tecnol%C3%B3gica_Durango_2017.pdf — robots/timeout y host fuera de la lista de egreso.
27. UACh Preparatoria Agrícola, manual Matadamas. https://areadeagronomia.mx/wp-content/uploads/2024/12/MANUALMATADAMAS-pdf.pdf — 403 del proxy.
28. INIFAP CENID‑RASPA. «Manual para el establecimiento y manejo del nopal verdura» (2000). http://cenid-raspa.inifap.gob.mx/demo/modulo/Manual/2000/Manual%20para%20establecimiento%20y%20manejo%20de%20nopal%20verdura.pdf — robots.
29. INIFAP RMCA art. 2216 (agave, mismo que #12) https://cienciasagricolas.inifap.gob.mx/index.php/agricolas/en/article/download/2216/3519?inline=1 — redirecciones; se leyó vía Redalyc.
30. ResearchGate: «Efecto del acolchado plástico, fertilización nitrogenada y composta orgánica en el crecimiento y desarrollo de sábila…» https://www.researchgate.net/publication/265976199 y «Manejo agronómico de la sábila en zonas áridas» https://www.researchgate.net/publication/275832605 — 429.
31. Agro Productividad art. 912 (sábila). https://www.revista-agroproductividad.org/index.php/agroproductividad/en/article/download/912/773/ — redirecciones.
32. Ciencia UANL «Sábila (Aloe vera): propiedades, usos y problemas». https://cienciauanl.uanl.mx/sabila-aloe-vera-propiedades-usos-y-problemas/ — no leído (sin presupuesto).
33. Vázquez‑Alvarado R. E. et al. 2006, Acta Hortic. 728:151‑158 (UANL) y García & Grajeda 1991 (Colpos) — originales de las recomendaciones de nopal; no leídos (citados en #4).
34. Handboek bodem en bemesting (CBAV) — bloembollen; RVO gebruiksnormen — no leídos; candidatos a tercera fuente de tulipán.

### Comerciales encontradas y descartadas por regla
ICL (agave), Hydroenv (cempasúchil, agave), Agroproductores (agave), Gor Green (agave), Cambiagro (cempasúchil), InfoAgronomo, Intagri, Fertilizar.org.ar, Engormix (girasol), nutrinorm.nl (tulipán).
