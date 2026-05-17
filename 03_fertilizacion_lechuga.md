# GUÍA DE FERTILIZACIÓN BIO-G — LECHUGA

**Versión:** v2 — Mayo 2026
**Alcance:** Campo abierto y protegido en suelo. No incluye hidroponía NFT/DWC ni sustratos inertes como sistema principal de v1 (nota futura).
**Cultivo madre:** `crop_lettuce`
**Capa activa en v1:** **N, P, K**. Calcio, magnesio, azufre y micronutrientes quedan como **notas agronómicas y banderas futuras**, no como lógica activa del motor.
**Objetivo del documento:** Base técnica conservadora para que BIO-G interprete demanda nutricional por etapa, escenarios de desbalance, y entregue mensajes seguros al agricultor sin caer en recetas químicas universales ni en dosis peligrosas.

---

## 1. Metodología y regla de lectura

Esta guía se construye con tres capas claramente separadas para que el motor no confunda fisiología con receta:

| Capa | Qué es | Cómo la usa BIO-G |
|---|---|---|
| **Capa fisiológica** | Demanda relativa de N, P, K por etapa (0–3). | Mueve `nPriority/pPriority/kPriority` y prioriza alertas. |
| **Capa analítica (referencia)** | Bandas de dosis y de tejido publicadas por extensiones universitarias y manuales técnicos. | Se muestra al usuario como referencia, **siempre con advertencia** de ajustar con análisis de suelo, agua y asesoría local. |
| **Capa correctiva (acción segura)** | Reglas para sugerir revisión cuando hay desbalance evidente (N excesivo + calor, K bajo + cierre, EC alta, etc.). | Genera mensajes amigables, nunca dosis específicas. |

> **Regla maestra:** BIO-G no entrega recetas. Entrega **interpretación + recomendación de revisión + mensaje al agricultor**. La dosis final siempre depende de análisis local de suelo, agua y asesoría agronómica.

---

## 2. Hallazgos firmes para lechuga (criterio agronómico de fondo)

Estos son los hallazgos respaldados por literatura universitaria, extensiones y manuales técnicos hortícolas. Forman el sustrato del documento.

1. **La lechuga es un cultivo de demanda nutricional moderada**, no alta como cucurbitáceas o solanáceas. Las dosis típicas de N en campo abierto rondan 100–180 kg N/ha por ciclo (no por mes). Pasarse de 200 kg N/ha rara vez beneficia y suele empeorar calidad.
2. **El exceso de nitrógeno es uno de los principales factores de pérdida de calidad** en lechuga: induce tipburn, hojas blandas, acumulación de nitratos en hoja, mayor susceptibilidad a *Botrytis* y *Sclerotinia*, demora la madurez fisiológica, y combinado con calor puede inducir amargor.
3. **El potasio gana peso hacia el cierre de cabeza y la madurez comercial**: sostiene turgencia, firmeza de hoja, color y resistencia general al estrés. K bajo se asocia con hojas marginales necróticas, cabezas blandas y mayor sensibilidad a salinidad.
4. **El fósforo es crítico en establecimiento y raíz temprana** (etapas 1–2). Después se vuelve mantenimiento. Si el suelo está bien provisto, no hay que insistir en P.
5. **La lechuga castiga el desequilibrio más que la deficiencia absoluta.** Un exceso de N en cierre o un K bajo en formación pesan más que un déficit moderado en vegetativo temprano.
6. **El calcio importa fisiológicamente** (tipburn es desorden Ca-relacionado), pero su problema casi nunca es Ca bajo en suelo, sino Ca no traslocado a la hoja interior por desbalance transpiración / EC / humedad / temperatura. Por eso v1 BIO-G **no convierte Ca en lógica activa**; lo trata indirectamente vía control de calor, HR, EC y exceso de N.
7. **El N nítrico es preferible al amoniacal** en lechuga: el amonio en exceso favorece tipburn, deprime la absorción de K y altera el balance catiónico.
8. **El programa debe partir de análisis** de suelo y de agua. Sin análisis, el motor solo sugiere bandas conservadoras y siempre con advertencia.

---

## 3. Reglas maestras BIO-G para fertilización de lechuga

- **Separar prioridad fisiológica (capa UX) de meta analítica (laboratorio).** La etapa dice qué nutriente pesa más; el laboratorio dice cuánto hay realmente.
- **No usar N amoniacal alto como base del programa**, especialmente desde formación de roseta en adelante.
- **No leer P y K como valores fijos universales.** Si el suelo es alto, el programa cambia.
- **Bajar N a partir del cierre de cabeza.** Mantener K firme. Suspender N en la ventana de cosecha.
- **No empujar N cuando se pronostica calor.** El binomio N alto + calor es la receta clásica del tipburn.
- **Foliar y fertirriego correctivo afinan, no reemplazan el manejo de fondo ni el riego.**
- **La calidad del agua importa:** si la EC del agua de riego ya está alta, el programa debe ajustar dosis y considerar lavados.
- **Lechuga es sensible a salinidad.** Cualquier desbalance que suba EC del bulbo húmedo se traduce en pérdida de rendimiento y calidad.

---

## 4. Capa fisiológica — demanda relativa de NPK por etapa

Esta es la tabla **principal del motor**. Define cómo se mueve `nPriority/pPriority/kPriority` (0–3) en cada etapa fenológica BIO-G.

| Etapa | N | P | K | Foco operativo |
|---|---|---|---|---|
| 1 Germinación | 0 | 1 | 0 | No se fertiliza; reserva de semilla. |
| 2 Establecimiento | 1 | **2** | 1 | P crítico para raíz temprana. |
| 3 Vegetativo inicial | 2 | 1 | 1 | N empieza a pesar para construir hoja. |
| 4 Formación de roseta | **3** | 1 | 2 | N pico **controlado**; K acompaña. |
| 5 Cierre / expansión comercial | **2** | 1 | **3** | **Bajar N**; **K manda**: firmeza, calidad, anti-tipburn. |
| 6 Madurez comercial / cosecha | 1 | 1 | 2 | Suspender o reducir N; mantener K. |
| 7 Sobre-madurez | 0 | 0 | 0 | No se fertiliza. |
| 8 Fin de ciclo | 0 | 0 | 0 | Retiro. |

**Lectura BIO-G:**
- Si la etapa actual es 4 o 5 y el motor detecta N excesivo + temperatura >25 °C en buffer de 3 días → alerta `alert_n_excess_with_heat` (alta severidad).
- Si la etapa actual es 5 o 6 y K disponible aparece bajo → alerta `alert_k_low_at_close` (alta severidad).
- Si la etapa es 2 y P aparece bajo → alerta `alert_p_low_establishment` (media severidad).

---

## 5. Capa analítica — referencia de dosis para campo abierto

> Todos los rangos siguientes son **referencia conservadora**. La dosis final debe ajustarse con análisis de suelo, agua, sistema productivo y asesoría local. BIO-G nunca debe entregar estos números como instrucción cerrada al agricultor.

### 5.1 Nitrógeno total estacional (kg N/ha por ciclo, campo abierto)

| Bucket de suelo (N residual, MO) | Banda referencial | Lectura |
|---|---|---|
| Suelo bajo / arenoso / baja MO | 130–180 kg N/ha | Fraccionar en 3–4 aplicaciones; mayor riesgo de lixiviación. |
| Suelo medio | 100–150 kg N/ha | Fraccionar en 2–3 aplicaciones. |
| Suelo alto / alta MO / con leguminosa previa | 60–100 kg N/ha | Cuidado con exceso; vigilar tipburn. |

**Reglas duras:**
- No superar **180 kg N/ha** por ciclo en lechuga sin razón muy específica respaldada por laboratorio.
- No aplicar N en la semana previa a cosecha (ventana de 7 días antes de corte).
- Preferir fuente nítrica sobre amoniacal, especialmente desde etapa 4.

### 5.2 Fósforo (P₂O₅) por buckets de suelo

| Nivel de P en suelo (Bray-1, Mehlich-1 u Olsen, según laboratorio) | Banda referencial P₂O₅ (kg/ha) |
|---|---|
| Muy bajo | 100–140 |
| Bajo | 60–100 |
| Medio | 30–60 |
| Alto | 0–30 |
| Muy alto | 0 |

**Lectura BIO-G:** el motor mantiene buckets simbólicos (`p_soil_level = low|medium|high`) y mueve la prioridad `pPriority` y los mensajes de revisión. **No entrega dosis directa al agricultor.**

### 5.3 Potasio (K₂O) por buckets de suelo

| Nivel de K en suelo | Banda referencial K₂O (kg/ha) |
|---|---|
| Muy bajo | 150–200 |
| Bajo | 100–150 |
| Medio | 60–100 |
| Alto | 30–60 |
| Muy alto | 0–30 |

**Reglas duras:**
- En lechuga de cabeza (LE-01, LE-02, LE-03), K en cierre debe estar bien provisto.
- Si el suelo es alto en K pero hay EC alta, no insistir en K: el problema es de balance osmótico, no de aporte.

### 5.4 Azufre, calcio, magnesio, micronutrientes

| Elemento | BIO-G v1 |
|---|---|
| Azufre (S) | Mantener en el plan si el laboratorio lo recomienda. No es lógica activa v1. |
| Calcio (Ca) | **Fisiológicamente importante** (tipburn), pero su manejo se hace vía control de calor + HR + EC + N, no vía dosis. **No lógica activa v1.** |
| Magnesio (Mg) | Vigilar cuando hay K alto o N amoniacal alto. **No lógica activa v1.** |
| Hierro, manganeso, zinc, boro | Por análisis. **No lógica activa v1.** |

> **Nota futura BIO-G v2+:** considerar añadir Ca como variable de riesgo activa cuando se incorpore monitoreo de transpiración / VPD.

---

## 6. Capa analítica — referencia para protegido en suelo (fertirriego)

En protegido en suelo, el manejo cambia: fertirriego por goteo, calidad de agua, EC del bulbo húmedo, pH del bulbo. La banda referencial **en mg/L (ppm) de la solución aplicada**, para lechuga en protegido en suelo:

| Etapa | N total (ppm) | P (ppm) | K (ppm) |
|---|---|---|---|
| Establecimiento (semana 1–2) | 70–100 | 30–50 | 100–150 |
| Vegetativo inicial (semana 2–4) | 100–140 | 30–50 | 130–180 |
| Formación de roseta (semana 4–6) | 120–150 | 30–50 | 150–200 |
| Cierre / expansión (semana 6–8) | **80–120** | 25–40 | **180–230** |
| Madurez / ventana cosecha | 60–80 | 20–40 | 150–200 |

> Las bandas son referenciales y deben ajustarse según calidad del agua de riego (EC base, pH del agua), análisis del suelo del invernadero y respuesta del cultivo. **BIO-G nunca entrega estas cifras como receta cerrada al agricultor.**

**Reglas operativas para protegido en suelo:**
- Mantener EC del bulbo húmedo entre 1.0 y 2.0 dS/m. Por encima de 2.5, lavar y reducir aporte.
- pH del bulbo entre 6.0 y 6.8.
- En cierre de cabeza, **bajar la relación N/K**: pasar de aproximadamente 1:1 en vegetativo a 1:1.5–1:2 en cierre, manteniendo N en valores moderados y K alto.

---

## 7. Capa correctiva — escenarios típicos y mensajes para agricultor

Esta es la capa que dispara las alertas amigables en la app. Cada escenario describe disparadores, lectura BIO-G y mensaje sugerido.

### 7.1 N excesivo + calor en formación o cierre

- **Disparadores:** etapa 4 o 5 + N estimado alto (vía calendario de aplicaciones o vía conductividad/lectura de tejido) + temperatura aire >25 °C en buffer de 3 días.
- **Riesgo:** tipburn, hojas blandas, susceptibilidad a Botrytis, amargor.
- **Mensaje al agricultor:** "Su lechuga está en cierre con N alto y calor. Esto sube mucho el riesgo de tipburn y hojas blandas. Considere pausar aplicaciones de N y revisar riego/temperatura."
- **Acción base segura:** suspender o reducir aplicaciones de N hasta que pase la ola de calor; mantener humedad de suelo estable; revisar EC.

### 7.2 N bajo en formación de roseta

- **Disparadores:** etapa 3 o 4 + síntomas (color pálido en hoja externa, crecimiento lento) + N estimado bajo.
- **Riesgo:** tamaño comercial menor, peor uniformidad.
- **Mensaje:** "Su lechuga puede estar baja en nitrógeno justo cuando más lo necesita. Revise su programa y considere muestreo foliar."
- **Acción:** revisar programa, considerar aplicación moderada de N nítrico fraccionada.

### 7.3 K bajo en cierre de cabeza

- **Disparadores:** etapa 5 + K disponible bajo + síntomas (clorosis y quemado marginal en hojas viejas, marchitez fácil).
- **Riesgo:** cabezas blandas, menor firmeza, menor calidad post-cosecha.
- **Mensaje:** "El potasio puede estar bajo justo en el cierre, que es la etapa donde más lo necesita la lechuga para firmeza."
- **Acción:** revisar programa de K, considerar refuerzo vía fertirriego en suelo con sulfato o nitrato de potasio según situación.

### 7.4 P bajo en establecimiento

- **Disparadores:** etapa 2 + P bajo en análisis de suelo.
- **Riesgo:** raíz débil, plantas pequeñas, ciclo más largo.
- **Mensaje:** "El fósforo puede estar bajo en el establecimiento. Es la etapa más importante para la raíz."
- **Acción:** banda de P en pre-trasplante; corrección difícil después.

### 7.5 EC alta + humedad de suelo baja

- **Disparadores:** ECe >2.0 dS/m + AW <60 %.
- **Riesgo:** estrés osmótico, deformación, tipburn, amargor.
- **Mensaje:** "La salinidad está subiendo y el suelo está seco. La lechuga lo va a sentir rápido."
- **Acción:** lavado controlado de sales, reforzar riego, revisar calidad del agua.

### 7.6 Humedad alta sostenida + N alto

- **Disparadores:** HR ambiental >85 % por >12 h/día durante 3 días + N alto.
- **Riesgo:** Botrytis, Sclerotinia, podredumbre basal.
- **Mensaje:** "Humedad alta y N alto suben mucho el riesgo sanitario en lechuga. Revise ventilación y manejo de aplicaciones."
- **Acción:** mejorar ventilación si protegido, reducir aplicaciones de N, revisar focos sanitarios.

### 7.7 Estrés acumulado en cierre + programa rígido

- **Disparadores:** suma de eventos de calor + déficit hídrico + EC alta en etapas 4–5.
- **Riesgo:** acumulación de daños, espigado prematuro, ventana de cosecha estrecha.
- **Mensaje:** "Su lechuga ha acumulado varios eventos de estrés. Considere adelantar la revisión de cosecha y aliviar lo que se pueda."
- **Acción:** revisar ventana de cosecha estimada, no aplicar más N, mantener riego estable.

---

## 8. Antagonismos y desequilibrios que BIO-G debe vigilar

| Antagonismo | Efecto | Lectura BIO-G v1 |
|---|---|---|
| NH₄ alto → reduce absorción de K | Cabezas blandas, tipburn | Aviso de "preferir fuente nítrica desde formación" |
| K alto → puede inducir deficiencia de Mg | Clorosis intervenal en hojas viejas | Nota agronómica; no lógica activa v1 |
| K alto / N alto → empeoran disponibilidad fisiológica de Ca en hoja | Tipburn | Aviso vía calor + N alto + EC alta |
| pH alto (>7.5) → baja disponibilidad de P, Fe, Zn, Mn | Síntomas micros | Alerta `alert_pH_out_of_range` |
| pH muy bajo (<5.5) → toxicidad potencial Mn | Manchas necróticas en hoja | Alerta `alert_pH_out_of_range` |
| EC alta + riego irregular | Deformación, amargor, mal cierre | Combinado con HR genera alerta dura |

---

## 9. Tejido foliar — referencia (capa de verificación, no obligatoria v1)

Si el agricultor o el motor reciben un análisis foliar de lechuga, las bandas de referencia (hoja recientemente madura, momento de cierre o pre-cosecha) son aproximadamente:

| Nutriente | Banda referencial (hoja madura) |
|---|---|
| N | 3.5–5.5 % |
| P | 0.3–0.6 % |
| K | 4.0–6.0 % |
| Ca | 1.0–2.0 % |
| Mg | 0.3–0.6 % |
| S | 0.2–0.4 % |

> Estos valores son referencia comercial común. Cada laboratorio reporta su propia banda de suficiencia; BIO-G debe mostrar siempre que los rangos varían por laboratorio y por momento de muestreo. El análisis foliar **verifica**, no reemplaza el manejo de fondo.

---

## 10. Mensajes amigables listos para app (catálogo cerrado v1)

| Código | Mensaje |
|---|---|
| `msg_fert_n_high_heat` | "Su lechuga está entrando al cierre con N alto y calor. Considere pausar aplicaciones de N para reducir riesgo de tipburn." |
| `msg_fert_n_low_growth` | "El nitrógeno puede estar bajo justo cuando la lechuga está expandiendo hoja. Revise su programa." |
| `msg_fert_k_low_close` | "El potasio puede estar bajo en el cierre. K mantiene la firmeza y la calidad de la cabeza." |
| `msg_fert_p_low_establishment` | "El fósforo puede estar bajo en el establecimiento. Es lo que más sostiene la raíz nueva." |
| `msg_fert_ec_high_water_low` | "Salinidad subiendo con poco agua: la lechuga lo siente rápido. Revise riego y EC." |
| `msg_fert_humid_n_high` | "Humedad alta sostenida + mucho N suben el riesgo sanitario. Considere ventilar y moderar dosis." |
| `msg_fert_no_n_pre_harvest` | "Estamos a una semana de cosecha. No conviene aplicar más N." |
| `msg_fert_general_review` | "Su lechuga lleva varios eventos de estrés. Sería buen momento para revisar el programa con su asesor." |

> Todos los mensajes están escritos para no asustar y no inducir acciones imprudentes. Ninguno entrega dosis específica.

---

## 11. Reglas para Dashboard, Crop Care, Notifications, History (fertilización)

**Dashboard**
- Tile de nutrición: muestra `n_status`, `p_status`, `k_status` (OK / Observación / Alerta) según la combinación de etapa, prioridad fisiológica y nivel estimado.
- Banner si hay alerta de fertilización activa.

**Crop Care**
- Carta principal por escenario activo (sección 7). Una sola carta de fertilización a la vez para no abrumar.
- Sub-carta "Próxima revisión" indica cuándo se sugiere muestrear suelo o tejido.
- Las cartas de fertilización **nunca llevan dosis específica**. Solo dirección (revisar, pausar, reforzar, lavar).

**Notifications**
- Push para escenarios 7.1, 7.3, 7.5 (alta severidad).
- Cooldown 48 h por escenario activo (no spamear).

**History**
- Persistir cada cambio de status nutricional con timestamp.
- Persistir cuándo el agricultor declara aplicación (si la app captura este dato a futuro).
- Persistir análisis foliares introducidos manualmente.

---

## 12. Advertencias y limitaciones de la guía

- **BIO-G v1 no calcula dosis.** Calcula prioridad fisiológica, identifica desbalance, sugiere revisión y entrega mensajes seguros.
- Las bandas referenciales de dosis y de tejido **son de literatura técnica**, no instrucción al agricultor.
- **Calcio, magnesio, azufre y micronutrientes no entran a lógica activa v1.** Aparecen como notas agronómicas. Se evita el riesgo de inducir decisiones complejas con datos insuficientes.
- **Hidroponía y sustratos inertes no son v1.** El usuario que opera hidroponía obtiene un aviso suave: "BIO-G v1 está calibrado para suelo y protegido en suelo. Las recomendaciones pueden no aplicar a NFT/DWC/hidroponía."
- **La calidad del agua es crítica.** Si la EC del agua de riego ya está >0.8–1.0 dS/m, el agricultor parte con desventaja en lechuga.
- **Sin análisis de suelo y agua, las recomendaciones son siempre conservadoras** y siempre llevan advertencia.

---

## 13. Supuestos y datos que requieren validación local

- Las bandas referenciales de N total (100–180 kg N/ha) y de NPK por etapa son síntesis conservadora de literatura clásica. Calibrar con datos de tu zona.
- Las bandas de fertirriego en protegido (ppm por etapa) son referencias comerciales típicas; deben ajustarse a la calidad de agua local.
- Los umbrales de EC y pH se alinean con el documento Universal (sección 4).
- Las bandas de tejido foliar son referencia comercial común; cada laboratorio puede usar bandas levemente distintas.

---

## 14. Tipo de fuentes consultadas

- Manuales y boletines de extensión universitaria sobre lechuga comercial (USA: Mid-Atlantic Commercial Vegetable Production Recommendations; UF/IFAS; UC Davis / UC ANR; Cornell; University of Florida; Oregon State; University of Hawaii CTAHR).
- INIFAP México (hortalizas en casa malla).
- Manuales técnicos comerciales (Universidad Jorge Tadeo Lozano y otros).
- Literatura clásica sobre tolerancia a salinidad (Maas-Hoffman).
- Literatura sobre tipburn y desórdenes fisiológicos de lechuga (universidades de California, Florida y Cornell).
- Manuales de fertilización en hortalizas de hoja (publicaciones de extensión).

> Todas las cifras finales en este documento son síntesis conservadora; ninguna es copia literal de una sola fuente.

---

## 15. Cierre BIO-G — Fertilización Lechuga

Lechuga necesita una guía **honesta y conservadora**: prioridad fisiológica por etapa, referencia analítica con advertencias, acción correctiva siempre segura. El programa real lo arma el agricultor con su asesor y su laboratorio. BIO-G **acompaña, interpreta, alerta y educa**.

**Reglas vivas para v1:**
- N no se empuja con calor o cerca de cosecha.
- K manda en cierre.
- P pesa en raíz temprana.
- Ca, Mg, S y micros son notas, no lógica activa.
- Sin análisis, todas las recomendaciones son conservadoras y nunca dosis.

**Estado:** CERRADO para v2 BIO-G.
