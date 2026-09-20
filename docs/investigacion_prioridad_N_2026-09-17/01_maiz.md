# Verificación adversarial — guía de fertilización de MAÍZ (BIO-G)

Fecha: 17 sep 2026. Alcance: `_maize` en `nutrition_guides.dart` (plan N 160–240, P₂O₅ 50–80, K₂O 0–60; ventanas fondo 33 % / V6–V8 40 % / V10–V12 27 %; `splitRecommended`, mínimo 2 pasadas, 3 en arenoso, 1 en arcilloso, sin tope por pasada). Solo investigación; no se tocó el repositorio.

Método: 10 búsquedas + 16 lecturas (26 llamadas). Las lecturas se hicieron por extracto automático de la página/PDF (no lectura humana de página completa); en la sección E se marca qué se pudo leer y qué quedó en resumen. Sin cifras ni URL inventadas: lo que no se encontró se dice.

---

## A. Veredicto de prioridad de ventanas de nitrógeno

### A.1 Qué dice la evidencia (resumen)

1. **En suelo franco/arcilloso, una sola pasada al sembrar rinde igual que una sola pasada en cobertera.** Universidad de Wisconsin (Bundy, 136 sitios IA/MN/WI 1987–1992): entre los sitios con respuesta, presiembra = cobertera en 48 casos, presiembra > cobertera en 15, cobertera > presiembra en solo 10 (casi todos en suelos gruesos de Minnesota). Clark et al. 2020 (49 sitio-años, 8 estados): fraccionar frente a aplicar todo a la siembra cambió el rendimiento «<15 % de las veces»; la única resultó **mejor** en suelos con más arcilla (>24–37 %), más limo, más CIC y más N total.
2. **En suelo arenoso, la cobertera gana con claridad.** Wisconsin (Hancock, arena con riego, 2003–04): con 100 lb N/ac, cobertera fraccionada (4 y 7 semanas tras siembra) 175 bu/ac frente a 145 presiembra (+30 bu/ac ≈ +1.9 t/ha); recuperación del N 79 % frente a 45 %. Nebraska EC117: en suelos muy arenosos «67 % o más del N debe aplicarse en temporada»; «hasta 33 %» pre/siembra. Florida IFAS: ≥7 fracciones en arenas. Clark 2020: la fraccionada fue mejor en suelo grueso y con lluvia regular alrededor de la cobertera.
3. **La ventana más eficiente para la pasada grande es justo antes del arranque de absorción rápida (V6–V8).** Purdue: «the most efficient N application method and timing for minimizing N loss is to inject N prior to the beginning of rapid crop N uptake at roughly growth stage V6»; los momentos menos eficientes (presiembra temprana) «typically result in higher optimum fertilizer N rates». Nebraska EC117: «Fertilizer N is most efficiently used when most is applied near the beginning of rapid N uptake or about the eighth leaf stage (V8)».
4. **Retrasar toda la dosis hasta V10–V12 casi no cuesta; más allá sí.** Missouri (Scharf, 37 experimentos): con el N puesto antes de V11 «you have a good chance to make full yield»; retrasado a V12–V16, −3 % de potencial en promedio; retrasado a floración, −15 % (3 experimentos). Purdue (2010): cobertera en V13 rindió 64 bu/ac más que el testigo con solo arrancador, pero 18 bu/ac (≈1.1 t/ha) menos que la cobertera en V3. Nebraska: rentable hasta R2, no recomendado después de R3.
5. **Práctica y recomendación oficial mexicana: dos pasadas, siembra + primer riego de auxilio/escarda.** INIFAP–Fundación Produce Chihuahua (maíz forrajero, 180-90-00): «la mitad del nitrógeno (90 kg) y todo el fósforo (90 kg) en presiembra o bien al momento de la siembra» y «el resto del nitrógeno deberá aplicarse en el primer riego de auxilio»; con fertilizantes líquidos 15 % siembra (0–30 d) / 40 % crecimiento rápido (30–50 d) / 30 % floración (50–75 d) / 15 % llenado (75–100 d). INIFAP Zacatecas (temporal, 100-40-00): «todo el fósforo y la mitad del nitrógeno al momento de la siembra», los otros 50 kg N «durante la escarda»; en zonas de potencial bajo-medio (40-40-00) «aplicándose todo al momento de la siembra». Terra Latinoamericana 2021 (Veracruz, forrajero): 50 % N a 15 dds (V2) + 50 % a 35 dds (V4). Rev. Fitotecnia Mexicana 2024 (temporal, Tlaxcala/Edo. de México): en los ensayos el N se aplicó en una sola dosis a los 21–39 dds en banda (escarda). MAPA cap. 17 (auditoría previa): 1/3 en fondo y el resto en V6–V8 y V10–V12.

Conclusión: **la evidencia no dice que la ventana única deba ser la siembra**; dice que en franco/arcilloso da igual y en arenoso es peor. La cobertera V6–V8 es la única ventana que (a) nunca pierde frente a la siembra en ningún suelo, (b) gana en arenoso, (c) es la más eficiente según Purdue y Nebraska, y (d) coincide con el «primer riego de auxilio» de la práctica INIFAP. V10–V12 es una buena segunda cobertera (pico de absorción, 7.8 lb N/ac/día ≈ 8.7 kg/ha/día entre V10 y V14 según Bender et al. 2013) pero, como pasada única, ya roza el límite de Scharf (V11) y perdió 18 bu/ac frente a V3 en Purdue: no debe ir por delante de V6–V8.

### A.2 Tabla de veredicto

| Pasadas declaradas | Etapas (clave) | Reparto recomendado | Base |
|---|---|---|---|
| k = 1 | `vegEarly` (V6–V8, antes del primer riego de auxilio) | 100 % | Purdue, Nebraska, Wisconsin, Clark 2020, Scharf/Missouri (≥3 independientes) |
| k = 2 (franco / arcilloso, riego) | `germination` + `vegEarly` | 1/3 + 2/3 (INIFAP local: 1/2 + 1/2 también válido) | MAPA, Nebraska (≤33 % a la siembra), Clark (45 vs 90 kg N a la siembra: igual 93–98 % de las veces), INIFAP Chihuahua/Zacatecas 50/50 |
| k = 2 (arenoso, o pivote/fertirriego) | `vegEarly` + `vegAdvanced` | 60 % + 40 % (el N del MAP/DAP de fondo hace de arrancador) | Wisconsin Hancock (4 y 7 semanas), Nebraska (≥67 % en temporada), Florida IFAS |
| k = 2 (temporal) | `germination` + `vegEarly` (escarda con lluvias establecidas) | 1/2 + 1/2 | INIFAP Zacatecas; Terra/RFM temporal |
| k = 3 | `germination` + `vegEarly` + `vegAdvanced` | **33 / 40 / 27 se sostiene** para franco; arenoso: bajar fondo a 15–25 % (p. ej. 20 / 45 / 35) | MAPA; Nebraska ≤33 % siembra; INIFAP Chihuahua líquido 15 % siembra |
| k ≥ 4 solo con fertirriego/pivote | + `tasseling` | p. ej. 15 / 40 / 30 / 15 | INIFAP Chihuahua (fertilizantes líquidos), Florida (5–8 aplicaciones hasta VT) |

Matices:
- **Textura.** Arcilloso (>25–35 % arcilla) e incorporación: la única a la siembra es defendible (Clark 2020, Wisconsin) y no debe penalizarse; pero sigue sin ser *mejor* que V6–V8, así que la prioridad no cambia, solo la tolerancia. Arenoso: nunca una sola pasada; si el productor insiste en k=1, la app debe advertir (Nebraska: ≥67 % en temporada; Wisconsin: recuperación 45 % presiembra).
- **Sistema.** Riego rodado: V6–V8 = «antes del primer riego de auxilio» (INIFAP), operativamente natural. Pivote/fertirriego: mover peso de la siembra a las coberteras (Chihuahua líquido 15 % siembra; Florida 30 lb/ac de arranque) y admitir refuerzo en floración. Temporal: la ventana V6–V8 solo vale con lluvia establecida; si la dosis es baja (≤60 kg N) y el suelo pesado, todo a la siembra es la recomendación INIFAP (40-40-00).
- **Tipo.** No se encontró literatura que ordene distinto las ventanas para grano, forraje o elote. Forrajero (Chihuahua): mismo esquema mitad/mitad. Elote: sin fuente primaria; por ciclo corto (cosecha R3) la última pasada útil es V10–V12, lo que ya cumple la lista.

### A.3 Lista para el motor

```
nitrogenPassPriority: [vegEarly, germination, vegAdvanced]          // franco/arcilloso, riego rodado, temporal
nitrogenPassPriorityCoarseOrFertigation: [vegEarly, vegAdvanced, germination]   // arenoso, pivote, goteo
```

Sugerencia de implementación: k=1 → primera clave; k=2 → dos primeras con reparto 1/3–2/3 (o 60/40 en la variante gruesa); k=3 → 33/40/27 (20/45/35 en gruesa).

Correcciones al `splitNotesEs` actual (dos cifras no verificadas):
- «sin diferencia … en 76–84 % de los sitios» → el resumen de Clark 2020 dice que la fraccionada cambió rendimiento «<15 % de las veces» (≥85 % sin diferencia). El 76–84 % no aparece en el resumen leído; puede venir del cuerpo del artículo (no accesible: Wiley 403). Redactar como «en ≈85 % de los sitio-años».
- «hasta 68 bu/ac más y recuperó el doble del N (Wisconsin A3634)» → lo verificado en el documento de Wisconsin (Bundy) es +30 bu/ac (175 vs 145 a 100 lb N/ac) y recuperación 79 % vs 45 % (×1.8). El «68 bu/ac» y la cita a A3634 no se pudieron confirmar.

---

## B. Tope por pasada (`maxSinglePassKgN`)

**Veredicto: NO hay evidencia de un tope universal en kg N/ha por aplicación; SÍ la hay de un tope condicionado a textura gruesa.**

- En franco/arcilloso, la literatura acepta toda la dosis en una sola pasada: Clark 2020 (única a la siembra igual o mejor en suelos arcillosos/limosos), Wisconsin (preplant ≥ sidedress en 63 de 73 comparaciones con respuesta), CIMMYT-Sinaloa (auditoría previa: 304 kg N/ha convencionales en presiembra). Ninguna de las fuentes leídas fija «no más de X kg N/ha por aplicación» para estos suelos. La pérdida por volatilización de urea es proporcional (%), no un umbral de dosis; la regla ya presente («incorpora o riega en 24 h») es la mitigación correcta.
- En arenoso sí hay tres fuentes independientes que limitan la pasada:
  1. Nebraska EC117: «Up to 33 percent of the planned N may be applied pre- or at planting»; «67 percent or more of N should be applied in-season such as with multiple fertigation applications after corn is 1 foot tall».
  2. Florida IFAS (BMP maíz en arenas): 30 lb N/ac (≈34 kg/ha) a la siembra, 30 lb/ac en cobertera a 30–38 cm y el resto «divided into 5-8 applications, with all N applied by tassel emergence (VT)» → ≈35–50 kg N/ha por aplicación.
  3. Wisconsin (Hancock, arena): presiembra recuperó 45 % del N frente a 79 % fraccionado; +30 bu/ac.
  (Clark 2020 lo respalda: fraccionar fue mejor con arena y lluvia regular.)
- Si la única pasada lleva 160–240 kg N/ha: en arcilloso/franco con incorporación es defendible (Clark, Wisconsin, práctica Sinaloa), con eficiencia menor (Purdue: dosis óptima más alta). En arenoso la evidencia dice que se pierde entre un tercio y la mitad del N (Wisconsin 45 % recuperado) y el rendimiento cae: no debe permitirse sin advertencia.

Propuesta: no introducir `maxSinglePassKgN` global. Introducir un tope **solo para textura gruesa**: ≤ 1/3 del plan a la siembra (≈ ≤ 80 kg N/ha) y ≈ ≤ 50 kg N/ha por aplicación en fertirriego, citando Nebraska, Florida y Wisconsin. El límite de contacto con la semilla (arrancador en surco) es distinto y no se verificó en esta sesión con fuente primaria.

---

## C. Dosis del plan

Rendimiento supuesto: grano de riego 8–12 t/ha. Conversiones: 1 bu/ac = 62.77 kg/ha; 1 lb/ac = 1.12 kg/ha.

| Nutriente | Valor actual | Veredicto | Fuentes (cifra citada) |
|---|---|---|---|
| N | 160–240 kg/ha | **Se sostiene** (sin ≥3 fuentes en contra; el techo queda algo corto para 12 t/ha en suelos pobres en N residual, como ya avisa `notesEs`) | MAPA cap. 17 (auditoría previa): 259 kg N/ha para 12 t/ha. CIMMYT/MasAgro Sinaloa (auditoría previa): 173–304 kg N/ha validados. Yara MX (auditoría previa): >200 kg N/ha absorbidos a 7 t/ha. Florida IFAS: «1.37 lb of N per bushel» → 8 t/ha ≈ 196, 12 t/ha ≈ 293 kg N/ha (arenas con lixiviación). Purdue: regla antigua «1 lb of N per bushel» → 143–214 kg N/ha. INIFAP Chihuahua forrajero: 180 N para 13 t MS/ha. |
| P₂O₅ | 50–80 kg/ha | **Se sostiene** (solo 2 fuentes por encima: MAPA 120 e INIFAP Chihuahua 90; no llega a 3 → no cambiar; anotar que en suelos calcáreos de Chihuahua INIFAP usa 90) | INIFAP–Produce Chihuahua: «180-90-00». Terra Latinoamericana 2021 (Veracruz): 69 P₂O₅. INIFAP Zacatecas temporal: 40. MAPA (auditoría previa): 120 para 12 t/ha. CIMMYT Sinaloa (auditoría previa): 48 K₂O y P según análisis. |
| K₂O | 0–60 kg/ha | **Se sostiene** | INIFAP Chihuahua: 180-90-**00**. INIFAP Zacatecas: 100-40-**00**. Terra 2021 Veracruz: 60. CIMMYT Sinaloa: 48. |

**Forrajero (MZF).** N: INIFAP Chihuahua recomienda 180 kg N/ha para hasta 13 t MS/ha (dentro del rango); Veracruz (Terra 2021) obtuvo +15 % de forraje verde con 253 frente a 207 kg N/ha. No hay ≥3 fuentes que exijan otro rango de N: **mantener 160–240**. P: Chihuahua usa 90 (ver arriba). K: el forraje se lleva la planta entera y la extracción de K es mayor que en grano, pero en esta sesión no se leyó una fuente primaria con el coeficiente; la ICL «Guía nutricional de maíz forrajero» apareció en búsqueda y no se leyó (secundaria). **No se propone cambio; pendiente de verificar K en forraje con fuente primaria.**

**Elote (MZE).** No se encontró en esta sesión ninguna fuente primaria mexicana ni de extensión (CDFA sweet corn no consultada por presupuesto de llamadas). **Sin base para cambiar**; queda como pendiente explícito. Lo único defendible es que la ventana `tasseling` no aplica (cosecha en R3) y la última pasada útil es V10–V12.

---

## D. Criticidad de ventanas

- **V6–V8 (`vegEarly`) crítica: se sostiene.** Purdue sitúa el arranque de absorción rápida en ~V6 y Nebraska en ~V8; Wisconsin documenta +30 bu/ac y recuperación 79 % vs 45 % en arena al mover el N a 4–7 semanas; Scharf: retrasar todo el N más allá de V11 ya cuesta (3 % en V12–V16, 15 % en floración); Purdue 2010: V13 rindió 18 bu/ac menos que V3. Omitir esta ventana sin haber puesto N antes es la omisión mejor documentada.
- **V10–V12 (`vegAdvanced`) crítica: se sostiene solo de forma condicional.** Es el pico de absorción (Bender et al. 2013: 7.8 lb N/ac/día ≈ 8.7 kg/ha/día en V10–V14; la guía dice «cerca de 8», aceptable) y N aplicado hasta V11 todavía da rendimiento completo (Scharf). Pero ninguna fuente documenta pérdida por omitir una *tercera* pasada cuando el N ya fue suficiente en siembra + V6–V8 (Clark 2020: fraccionar más no cambió rendimiento en ≥85 % de los sitios; Wisconsin: idem). Recomendación: `isCritical` en V10–V12 solo cuando el plan del productor reserva N para esa ventana (k ≥ 3, o k = 2 en la variante arenoso/fertirriego); si el productor declaró k = 2 franco/arcilloso, no penalizar su omisión.
- **Fondo (`germination`) no crítica: se sostiene agronómicamente**, no solo por la razón operativa (sonda sin instalar). Scharf: sin N hasta V11 se logra rendimiento completo si se aplica entonces; Wisconsin: cobertera = presiembra en suelos medios/finos; Purdue: la única más eficiente es V6. La excepción (arenas o suelos fríos con poco N residual, arrancador) no reúne 3 fuentes leídas en esta sesión y además Nebraska la trata como «hasta 33 %», opcional.
- Afirmación de `rationaleEs` «de las 6 hojas a la floración el maíz toma más de la mitad del N»: no se pudo verificar el porcentaje exacto en esta sesión (la página de Illinois solo dio el pico diario y «hasta 50 lb N/ac» a grano en llenado); es coherente con la curva de Bender pero queda **sin cita textual**.

---

## E. Fuentes

Leyenda: ✔ leída (extracto automático de la página/PDF completo) · ◐ solo resumen/abstract · ✘ no accesible en esta sesión · ⟲ ya usada en la auditoría previa, no releída.

1. ◐ Clark, J.D. et al. 2020, *Weather and soil in the US Midwest influence the effectiveness of single- and split-nitrogen applications in corn production*, Agronomy Journal 112. Resumen vía UNL Digital Commons: https://digitalcommons.unl.edu/agronomyfacpub/1387 — «49 site-year study across eight U.S. Midwestern states»; única a la siembra vs 45 o 90 kg N/ha a la siembra + resto en V9; «changed … plant N uptake and grain yield <15% of the time»; fraccionada mejor con «uniform precipitation around the sidedress timing» y suelo grueso; única mejor con N total >2.1–2.4 g/kg, CIC >27–31 cmolc/kg, limo >66–74 % o arcilla >24–37 %. Texto completo en Wiley (https://acsess.onlinelibrary.wiley.com/doi/full/10.1002/agj2.20446): ✘ 403.
2. ✔ Universidad de Missouri, IPM, 2008, *Rescue Nitrogen Applications on Corn Can Still be Profitable* (Scharf): https://ipm.missouri.edu/cropPest/2008/7/Rescue-Nitrogen-Applications-on-Corn-Can-Still-be-Profitable — «If you can get the needed N to the corn by growth stage V11, you have a good chance to make full yield» (37 experimentos); V12–V16 «only 3 percent reduction»; en floración «15 percent».
3. ✔ Purdue University, Camberato & Nielsen, *Corn Response to Late-Season Nitrogen Application*: https://agry.purdue.edu/ext/corn/news/timeless/CornRespLateSeasonN.html — «sidedress-applied at growth stage V13 increased yield 64 bu/acre compared to the starter-only control, but yield was 18 bu/acre less than an earlier V3 sidedress treatment».
4. ✔ Purdue University, *Nitrogen Management Guidelines for Corn in Indiana*: https://www.agry.purdue.edu/ext/corn/news/timeless/nitrogenmgmt.pdf — «most efficient … inject N prior to the beginning of rapid crop N uptake at roughly growth stage V6»; «Less efficient N application timings … typically result in higher optimum fertilizer N rates».
5. ✔ University of Nebraska–Lincoln Extension, EC117 *Fertilizer Suggestions for Corn*: https://extensionpubs.unl.edu/publication/ec117/na/pdf/view — «most efficiently used when most is applied near … about the eighth leaf stage (V8)»; «On very sandy soils, 67 percent or more of N should be applied in-season»; «Up to 33 percent … pre- or at planting»; rentable hasta R2, «applying N after R3 is not recommended».
6. ✔ University of Wisconsin, Bundy, *Nitrogen timing* (documento del Dept. de Suelos): https://extension.soils.wisc.edu/wp-content/uploads/sites/68/2016/07/Bundy1-4.pdf — 136 sitios IA/MN/WI 1987–92: presiembra = cobertera 48, presiembra > 15, cobertera > 10; «Only when soils with relatively coarse texture were considered did sidedress applications provide a benefit»; Hancock 2003–04 a 100 lb N/ac: 175 vs 145 bu/ac, recuperación 79 % vs 45 %.
7. ✔ University of Florida IFAS, BMP *Corn* recommendations: https://bmp.ifas.ufl.edu/crop-recommendations/corn/ — «1.37 lb of N per bushel»; «equal to or more than 7 splits total»; 30 lb N/ac a la siembra, 30 lb/ac a 12–15 in, resto «5-8 applications, with all N applied by tassel emergence (VT)».
8. ✔ INIFAP – Fundación Produce Chihuahua, *Paquete tecnológico para la producción de maíz forrajero* (PT-0012): https://www.producechihuahua.org/paqs/PT-0012MaizForrajero.pdf — «180 kg de nitrógeno + 90 kg de fósforo (180-90-00)» para «hasta 13 toneladas de materia seca por hectárea»; «la mitad del nitrógeno (90 kg) y todo el fósforo (90 kg) en presiembra o bien al momento de la siembra»; «el resto del nitrógeno deberá aplicarse en el primer riego de auxilio»; líquidos: 15 / 40 / 30 / 15 % (0–30, 30–50, 50–75, 75–100 d).
9. ✔ INIFAP Zacatecas, *Tecnología para la producción de maíz* (FP46): http://zacatecas.inifap.gob.mx/publicaciones/FP46%20RSan.pdf — potencial alto 100-40-00: «todo el fósforo y la mitad del nitrógeno al momento de la siembra», 50 kg N «durante la escarda»; potencial bajo-medio 40-40-00 «aplicándose todo al momento de la siembra».
10. ✔ Revista Fitotecnia Mexicana 47(2), 2024, *Aporte de nitrógeno por el suelo y eficiencia de aprovechamiento del nitrógeno aplicado en maíz de temporal* (Tlaxcala, Edo. de México): https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-73802024000200099 — N en una sola dosis «a los 21 días después de la siembra … 22 dds … 39 dds» en banda; dosis 70–120 kg N/ha; rendimientos 2.3–4.9 t/ha; eficiencia 0–37.5 %.
11. ✔ Terra Latinoamericana 39, 2021, *Productividad de forraje en maíces híbridos bajo diferentes densidades de población y dosis de fertilización* (Cotaxtla, Veracruz): https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792021000100117 — 253-69-60 vs 207-69-60; 50 % N + todo P y K a 15 dds (V2), 50 % N a 35 dds (V4); «253-69-60, incrementó el rendimiento de forraje verde, un 15.06 %».
12. ✔ Revista Fitotecnia Mexicana 44(2), 2021, *Nitrógeno en fertirriego para producir semilla de líneas progenitoras y cruzas simples de maíz* (Chapingo): https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-73802021000200191 — 150 kg N/ha mejor que 225 y 300 (−4.2 % y −9.5 %); fertirriego semanal «a partir de la quinta semana después de la siembra». Relevancia marginal (producción de semilla).
13. ◐ University of Illinois, Crop Physiology Lab, *Corn Nutrient Uptake and Partitioning* (resumen de Bender et al. 2013, Agron. J.): https://cropphysiology.cropsci.illinois.edu/nutrient-uptake-and-partitioning/ — «peak needs of 7.8 lb N/day from V10-V14»; «as much of 50 lb N/acre is accumulated and partitioned directly into the developing seeds during grain fill». Porcentajes por etapa no disponibles en la página.
14. ✘ INIFAP CENID-RASPA 2005, *La fertilización en los cultivos de maíz*: http://cenid-raspa.inifap.gob.mx/demo/modulo/Folletos%20tecnicos/2005/La%20Fertilizaci%C3%B3n%20en%20los%20cultivos%20de%20ma%C3%ADz.pdf — sigue sin poder leerse (robots/timeout). Mantener como «referencia regional, verificar».
15. ⟲ Yara México, *Resumen nutricional del maíz*; MAPA, *Guía práctica de la fertilización racional*, cap. 17; CIMMYT/MasAgro, *Menú de tecnologías validadas: maíz de riego en Sinaloa* — cifras tomadas de la auditoría previa (259 N para 12 t; 1/3 fondo + V6–V8 + V10–V12; 173–304 kg N/ha; >200 kg N absorbidos a 7 t).

Aparecieron en búsqueda y **no se leyeron** (candidatas para la siguiente pasada): Rev. Fitotecnia Mexicana 46(3), *Algoritmo simplificado para aplicación racional de nitrógeno* (https://www.scielo.org.mx/pdf/rfm/v46n3/0187-7380-rfm-46-03-255.pdf); Rev. Mex. Ciencias Agrícolas, *Inhibidor de la nitrificación DMPP … maíz forrajero en la Comarca Lagunera* (https://cienciasagricolas.inifap.gob.mx/index.php/agricolas/article/view/2079) y *Fertilización nitrogenada y emisión de N₂O … maíz en la Comarca Lagunera* (https://cienciasagricolas.inifap.gob.mx/index.php/agricolas/article/view/2608); PLOS ONE 2020, *Timing and rate of nitrogen fertilization influence maize yield and nitrogen use efficiency* (https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0233674); Michigan State, Steinke, *Pre-plant and in-season corn N* (https://www.canr.msu.edu/soilfertility/Files/Articles/Corn/Steinke%20Pre%20plant%20and%20In%20season%20Corn%20N.pdf); ICL *Guía nutricional de maíz forrajero* (secundaria).

Huecos honestos: sin fuente para elote; sin coeficiente primario de extracción de K en forraje; porcentajes de absorción por etapa de Bender no verificados; el «76–84 %» y el «68 bu/ac» del `splitNotesEs` no confirmados.
