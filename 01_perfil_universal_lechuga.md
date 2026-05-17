# PERFIL UNIVERSAL BIO-G — LECHUGA

**Versión:** v2 — Mayo 2026
**Cultivo madre:** `crop_lettuce` / `CropKey.lettuce`
**Alcance:** Campo abierto y protegido en suelo. Hidroponía NFT/DWC queda fuera de v1 (nota futura).
**Objetivo del documento:** Definir cuándo la lechuga está en riesgo. No define cómo producirla. Es el esqueleto biológico que alimenta Dashboard, Crop Care, Notifications, History, motor NPK y estimación de cosecha.

---

## 1. Identidad del cultivo — UNIVERSAL

| Campo | Valor |
|---|---|
| ID interno sugerido | `crop_lettuce` |
| Código corto | LE |
| Nombre común | Lechuga |
| Nombre científico | *Lactuca sativa* L. |
| Familia botánica | Asteraceae |
| Tipo de planta | Hortaliza de hoja |
| Metabolismo | C3 (estación fresca) |
| Ciclo de vida | Anual de ciclo corto-medio |
| Órgano objetivo | **HOJA / ROSETA / CABEZA** (según tipo) |
| Uso principal | Consumo fresco (sub-uso, no perfil) |
| Variedad / híbrido | Solo alias dentro de un tipo. No define perfil. |
| Floración | NO es objetivo productivo. Se modela como **evento de falla** (espigado/bolting). |

**Varía (no aquí, sí en perfiles por tipo):** arquitectura (cabecea vs no cabecea), velocidad de cierre de cabeza, tolerancia varietal a calor/espigado, densidad de siembra, sistema típico (campo vs protegido en suelo).

> Nota BIO-G: El órgano objetivo (hoja) define toda la lógica. No se modela cuajado, llenado de fruto ni cosecha progresiva. Calidad de hoja, turgencia, tamaño de roseta/cabeza, color, textura, sanidad foliar y uniformidad son los KPI reales.

---

## 2. Estructura fenológica (esqueleto BIO-G) — UNIVERSAL

8 etapas. La floración aparece **solo como evento de riesgo (espigado)** dentro de la etapa de Sobre-madurez; no es etapa productiva en sí.

| # | Etapa | Nombre interno sugerido | Duración orientativa | Objetivo fisiológico |
|---|---|---|---|---|
| 1 | Germinación | `germination` | 3–10 días | Emerger, romper testa, salir cotiledones |
| 2 | Emergencia / establecimiento | `establishment` | 5–15 días desde emergencia (o trasplante = inicio directo aquí) | Instalar raíz superficial, primeras hojas verdaderas |
| 3 | Desarrollo vegetativo inicial | `vegetative_early` | 10–25 días | Crecimiento foliar acelerado, base de la roseta |
| 4 | Formación de roseta | `rosette_formation` | 15–30 días | Acumular masa foliar, definir tamaño potencial |
| 5 | Expansión comercial / cierre de cabeza | `head_formation` *(solo si tipo cabecea)* / `commercial_expansion` *(si no cabecea)* | 10–20 días | Compactar cabeza (iceberg, romana, butterhead) o alcanzar tamaño comercial (looseleaf, baby leaf) |
| 6 | Madurez comercial / ventana de cosecha | `commercial_maturity` | 3–14 días | Mantener calidad lista para corte |
| 7 | Sobre-madurez / riesgo de espigado | `over_maturity_bolting_risk` | Variable (7–30 días si no se cosecha) | Etapa de **deterioro**. Aparece tallo central elongado, sabor amargo, hojas duras, látex abundante. |
| 8 | Fin de ciclo / retiro | `end_of_cycle` | — | Retiro del lote. Sanitización obligatoria por *Sclerotinia* y *Pythium*. |

**Etapa crítica BIO-G:** Etapas 4 + 5 (formación de roseta + cierre de cabeza). Aquí pesa más el índice del cultivo. Un evento de estrés en estas etapas pesa el doble que en vegetativo inicial.

**Etapa de segunda mayor sensibilidad:** Etapa 6 (madurez comercial / ventana de cosecha). La calidad cae rápido por calor, exceso de humedad o sanidad.

---

## 3. Tiempo y calendario base — UNIVERSAL

- **Día 0:** siembra directa o trasplante (declarado por el usuario).
- **Tiempo desde siembra:** `today - sowing_date`.
- **Duración total estimada:** depende del perfil por tipo, no de la variedad. Banda universal de referencia: **55–95 días desde siembra**; **40–75 días desde trasplante**.
- **Ajuste por estrés:** el estrés acumulado **mueve el calendario** (atrasa madurez si hubo frío o estrés hídrico moderado; acelera espigado y deterioro si hubo calor). **El estrés no cambia la biología**, solo el cuándo.
- **Recomendación futura (no v1):** modelo GDD con `T_base = 4°C` (referencia clásica para Lactuca), con techo térmico funcional alrededor de 24°C (por encima la planta deja de "ganar" desarrollo útil y empieza a acumular riesgo).

---

## 4. Rangos fisiológicos MEDIBLES — UNIVERSAL

Esta sección entrega rangos **listos para serializar como JSON** por el motor BIO-G. Cada variable trae: óptimo, observación, estrés y crítico, con dirección y peso sugerido.

### 4.1 Temperatura ambiente (°C)

| Banda | Valor | Etapa donde más castiga |
|---|---|---|
| Óptimo desarrollo foliar | 15–20 °C | Todas |
| Óptimo germinación | 15–22 °C | 1 |
| Aceptable | 7–24 °C | 2–4 |
| Observación (estrés moderado) | 24–27 °C | 4–6 |
| Estrés fuerte | 27–30 °C sostenido (>4 h/día por ≥3 días) | 4–6 |
| Crítico (espigado / amargor / tipburn) | >30 °C sostenido o varios días >28 °C en cierre | 4–6 |
| Termoinhibición de germinación | T suelo >27 °C | 1 |
| Daño por frío | <2 °C continuado en trasplante joven; <0 °C riesgo de helada |  2 |

Peso sugerido en sub-índice de temperatura: **0.30** en etapas 1–3, **0.45** en etapas 4–5, **0.40** en etapa 6.

### 4.2 Temperatura del suelo (°C)

| Banda | Valor |
|---|---|
| Óptimo germinación | 15–22 °C |
| Aceptable | 10–24 °C |
| Inhibición térmica de germinación | >27 °C (típica en variedades iceberg; iceberg es más sensible) |
| Riesgo de daño por frío | <5 °C en plántula |

### 4.3 Humedad del suelo (% Agua Disponible — AW)

| Banda | Valor | Lectura |
|---|---|---|
| Óptimo operativo | 60–95 % AW | Riego correcto |
| Observación | 50–60 % AW | Acercándose a déficit |
| Estrés (déficit) | <50 % AW (depleción >50 %) | Riesgo de amargor + pre-espigado |
| Crítico (déficit) | <30 % AW sostenido | Pérdida estructural |
| Exceso (saturación corta) | 95–100 % AW por <24 h | Tolerable |
| Crítico (saturación prolongada) | 100 % por >48 h | Anoxia radicular, *Pythium*, *Rhizoctonia*, base podrida |

Peso sugerido en sub-índice de agua: **0.35** en todas las etapas; sube a **0.45** en etapas 4–6.

### 4.4 Humedad relativa ambiental (HR %)

En v1 se usa como **factor de riesgo, no umbral duro**, porque el efecto depende de temperatura y de duración.

| Combinación | Riesgo principal |
|---|---|
| HR >90 % sostenida (>12 h) + 10–17 °C | Mildiu velloso (*Bremia lactucae*) — riesgo alto |
| HR >85 % + tejido senescente o herido | Botrytis (moho gris) |
| HR alta + suelo saturado + temperatura tibia (15–22 °C) | *Sclerotinia* / lettuce drop |
| HR baja (<40 %) + calor (>25 °C) + EC alta | Tipburn, amargor, frutos/cabezas deformes |
| HR oscilante + ventilación deficiente en protegido | Foco compuesto: Botrytis + mildiu |

### 4.5 pH del suelo

| Banda | Valor |
|---|---|
| Óptimo | 6.0–6.8 |
| Aceptable | 5.8–7.2 |
| Observación | 5.5–5.8 ó 7.2–7.5 |
| Alerta (Fe/Mn/Zn poco disponibles) | >7.5 |
| Alerta (Mn fitotóxico potencial) | <5.5 |

### 4.6 Salinidad — ECe del extracto de saturación (dS/m)

Lechuga es **moderadamente sensible** a salinidad. Referencia clásica Maas-Hoffman: umbral 1.3 dS/m, pendiente ~13 % de pérdida por cada dS/m sobre umbral.

| Banda | Valor (ECe) | Lectura BIO-G |
|---|---|---|
| Sin impacto | <1.3 dS/m | OK |
| Observación / pérdida marginal | 1.3–2.0 dS/m | "Salinidad subiendo" |
| Alerta (pérdida ~10–15 %) | 2.0–2.5 dS/m | "Salinidad elevada" |
| Crítico (pérdida ~20–30 %+) | >2.5 dS/m | "Salinidad crítica para lechuga" |

> Si el sensor reporta EC del bulbo húmedo (no ECe), aplicar factor de conversión local; mientras no haya calibración, el motor debe marcar el dato con `confidence = media` y mostrar mensaje conservador.

### 4.7 Compactación / resistencia a la penetración (MPa)

| Banda | Valor |
|---|---|
| OK | <1.0 MPa |
| Observación | 1.0–1.5 MPa |
| Alerta | 1.5–2.0 MPa |
| Crítico (raíz superficial limitada) | >2.0 MPa |

> Lechuga tiene sistema radicular superficial (mayoría en 0–20 cm). La compactación pega más temprano que en hortalizas de raíz profunda.

### 4.8 NPK — nivel relativo por etapa (NO dosis; dosis = doc Fertilización)

Esta tabla es la capa fisiológica que alimenta `nPriority/pPriority/kPriority` en el motor. Escala 0–3.

| Etapa | N | P | K | Comentario |
|---|---|---|---|---|
| 1 Germinación | 0 | 1 | 0 | Reserva de semilla, no se fertiliza |
| 2 Establecimiento | 1 | 2 | 1 | P crítico para raíz |
| 3 Vegetativo inicial | 2 | 1 | 1 | N empieza a pesar |
| 4 Formación de roseta | 3 | 1 | 2 | N pico controlado |
| 5 Cierre / expansión comercial | **2** | 1 | **3** | **Bajar N para evitar tipburn**; K manda |
| 6 Madurez / ventana cosecha | 1 | 1 | 2 | Suspender o reducir N |
| 7 Sobre-madurez | 0 | 0 | 0 | No se fertiliza |
| 8 Fin de ciclo | 0 | 0 | 0 | No aplica |

---

## 5. Sensibilidad por etapa — MATRIZ UNIVERSAL (numérica)

Escala 0–1 (0 = no sensible, 1 = letal). Para usar como pesos relativos dentro del cálculo de cada sub-índice.

| Variable / Etapa | 1 Germ | 2 Estab | 3 Veget | 4 Roseta | 5 Cierre | 6 Cosecha | 7 Sobre-mad |
|---|---|---|---|---|---|---|---|
| Déficit hídrico | 0.7 | 0.7 | 0.6 | 0.85 | **0.95** | 0.7 | 0.4 |
| Exceso humedad / anoxia | 0.8 | 0.8 | 0.5 | 0.75 | 0.85 | 0.8 | 0.5 |
| Calor (>27°C sostenido) | 0.9* | 0.5 | 0.6 | 0.85 | **1.0** | **0.95** | 0.8 |
| Frío (<2°C) | 0.4 | 0.6 | 0.4 | 0.4 | 0.4 | 0.3 | 0.2 |
| Salinidad (EC) | 0.6 | 0.6 | 0.7 | 0.85 | **0.9** | 0.7 | 0.4 |
| Compactación | 0.8 | 0.8 | 0.5 | 0.5 | 0.4 | 0.3 | 0.2 |
| pH fuera de rango | 0.5 | 0.5 | 0.5 | 0.5 | 0.5 | 0.3 | 0.2 |
| HR alta sostenida (sanidad foliar) | 0.3 | 0.3 | 0.5 | 0.7 | **0.9** | **0.9** | 0.6 |
| Desbalance N (exceso) | 0.0 | 0.2 | 0.3 | 0.6 | **0.9** | 0.7 | 0.2 |
| Desbalance N (déficit) | 0.0 | 0.3 | 0.6 | 0.8 | 0.5 | 0.3 | 0.1 |
| Desbalance K (déficit) | 0.0 | 0.2 | 0.4 | 0.6 | 0.85 | 0.6 | 0.2 |

\* En germinación el calor actúa vía termoinhibición de la semilla.

**Etapas críticas marcadas (≥0.9):** las celdas en negrita son las que disparan alerta fuerte (no observación). El motor las debe ponderar al doble en el índice global.

---

## 6. Ventanas fisiológicas activas — UNIVERSAL

- **Ventana crítica principal (calidad/peso):** etapa 4 → etapa 5. Aquí se decide tamaño comercial, firmeza y susceptibilidad a tipburn.
- **Ventana de cosecha:** corta (3–14 días). La calidad cae rápido si se pasa: amargor, espigado, deterioro foliar.
- **Ventana de riego:** continua desde establecimiento. Estabilidad > volumen. Lechuga castiga oscilaciones.
- **Ventana de revisión sanitaria intensa:** 7–10 días previos a cosecha (revisar mildiu, Botrytis, podredumbre basal, foco de áfidos).
- **Ventana de mayor riesgo de espigado:** etapas 5–7 con calor sostenido. En verano puede aparecer en etapa 4 en variedades sensibles.

---

## 7. Estado del cultivo — OUTPUT BIO-G

### 7.1 Índice general (0–100)

```
indice_global = round(
  w_water    * sub_indice_agua
 + w_temp    * sub_indice_temperatura
 + w_soil    * sub_indice_suelo
 + w_nutri   * sub_indice_nutricion
 + w_health  * sub_indice_sanidad
)
```

**Pesos por etapa:**

| Etapa | w_water | w_temp | w_soil | w_nutri | w_health |
|---|---|---|---|---|---|
| 1 Germinación | 0.30 | 0.35 | 0.25 | 0.05 | 0.05 |
| 2 Establecimiento | 0.30 | 0.25 | 0.25 | 0.10 | 0.10 |
| 3 Vegetativo inicial | 0.25 | 0.25 | 0.15 | 0.20 | 0.15 |
| 4 Formación de roseta | 0.25 | 0.30 | 0.10 | 0.20 | 0.15 |
| 5 Cierre / expansión | 0.25 | **0.35** | 0.05 | 0.15 | **0.20** |
| 6 Madurez / cosecha | 0.20 | 0.30 | 0.05 | 0.10 | **0.35** |
| 7 Sobre-madurez | 0.20 | 0.30 | 0.10 | 0.10 | 0.30 |

### 7.2 Categorías de estado

| Categoría | Banda |
|---|---|
| Óptimo | 80–100 |
| Observación | 60–79 |
| Alerta | 40–59 |
| Alerta crítica | <40 |

### 7.3 Tendencia

Comparación del índice global vs el promedio móvil de los últimos 7 días:
- Mejorando: `+3` o más puntos.
- Estable: dentro de ±3.
- Deteriorando: `-3` o más puntos.

---

## 8. Alertas posibles (lenguaje humano, listas para app)

| Código sugerido | Texto al agricultor | Etapa principal | Severidad base |
|---|---|---|---|
| `alert_thermo_inhibition_seed` | "El calor del suelo puede dificultar la germinación. Considere sembrar más temprano o más profundo, o sombrear el semillero." | 1 | Media |
| `alert_heat_stress_critical_stage` | "Temperatura alta en cierre de cabeza: riesgo de tipburn, amargor y cabezas blandas." | 4–5 | Alta |
| `alert_bolting_risk_accumulated` | "Riesgo de espigado por calor acumulado. La cosecha podría adelantarse o perder calidad." | 5–7 | Alta |
| `alert_water_deficit_critical` | "Déficit hídrico en etapa crítica de la lechuga. Riesgo de amargor y pérdida de turgencia." | 4–6 | Alta |
| `alert_water_excess_anoxia` | "Suelo saturado: riesgo de pudrición de raíz y base." | 1–6 | Alta |
| `alert_salinity_rising` | "La salinidad está subiendo y la lechuga es sensible." | 3–6 | Media |
| `alert_salinity_critical` | "Salinidad crítica para lechuga: se esperan pérdidas de rendimiento y calidad." | 3–6 | Alta |
| `alert_compaction` | "Suelo compactado: la raíz superficial de la lechuga puede limitarse." | 2–4 | Media |
| `alert_humid_sanitary_risk` | "Humedad alta sostenida: revise foco de mildiu, Botrytis o pudrición basal." | 3–6 | Media-Alta |
| `alert_pH_out_of_range` | "El pH del suelo está fuera del rango óptimo para lechuga (6.0–6.8)." | Todas | Media |

> Todas las alertas tienen `cooldown_min` y `cooldown_max` definidos en Notifications (doc 4) para evitar spam.

---

## 9. Contexto climático reciente — UNIVERSAL

El motor mantiene en buffer los últimos 7 y 14 días de:
- Tendencia térmica (máximas y mínimas diarias).
- Tendencia humedad de suelo.
- Tendencia HR ambiental.
- Tendencia ECe.
- Evento extremo binario (helada / ola de calor / lluvia >25 mm en 24 h).
- Impacto esperado según etapa (peso × severidad).

---

## 10. Memoria del cultivo — UNIVERSAL

Estructura mínima persistida por evento de estrés (alimenta History):

```
{
  "event_id": "uuid",
  "stress_type": "heat|water_deficit|water_excess|salinity|cold|compaction|sanitary|nutrient_imbalance",
  "severity": 0.0..1.0,
  "duration_hours": int,
  "stage_when_occurred": "rosette_formation",
  "calendar_shift_days": int,        // + retraso, - adelanto
  "index_impact": -X,                // delta sobre indice_global
  "resolved": bool,
  "resolved_at": timestamp
}
```

**Regla:** la memoria **nunca se borra** al migrar de SKIP a un perfil específico. Los eventos cambian solo de contexto, no de existencia.

---

## 11. Confiabilidad del dato — UNIVERSAL

| Nivel | Cuándo se asigna |
|---|---|
| Alta | Sensor reciente (<6 h), validado contra rango plausible |
| Media | Modelo o estimación; sensor con dato 6–24 h; o sensor calibrado pendiente |
| Baja | Dato >24 h, fuera de rango plausible, o derivado con muchos supuestos |

**Regla de fallback (datos faltantes):**
- Sin temperatura ambiente → usar última conocida con `confidence = baja` por máx 24 h; después, motor entra en `degraded_mode = true` y muestra al agricultor: "Estamos sin datos recientes de tu campo. Las alertas pueden no reflejar lo que está pasando ahora."
- Sin humedad de suelo → no calcular sub-índice de agua; mostrar tile en gris.
- Sin pH ni EC → no bloquear el cultivo, asumir valores del perfil SKIP con `confidence = baja`.

---

## 12. Metadatos BIO-G — UNIVERSAL

| Campo | Valor |
|---|---|
| `crop_profile_version` | "lettuce.universal.v2" |
| `last_validated_at` | 2026-05-10 |
| `source_evidence_level` | "university_extension + classic_handbook" |
| `compatible_sensors` | T_air, T_soil, soil_moisture (VWC%), pH_soil, EC_soil, soil_resistance |
| `ready_for_expansion` | GDD, VPD, bolting model, leaf wetness, DLI |

---

## 13. Tipos / perfiles UX y alias — UNIVERSAL

> Regla BIO-G activa: **Tipo = UX**, **Perfil = reloj biológico**, **Variedad = alias (no perfil)**. Una variedad puede aparecer en más de un tipo si el manejo lo permite. Siempre existe "Otra variedad".

### LE-01 — Lechuga romana (incluye corazones / mini romana / Little Gem)
- **Sistema:** campo abierto y protegido en suelo.
- **Arquitectura:** erecta, nervadura marcada.
- **Inicio compactación útil:** 35–55 días desde siembra (mini/corazones: 30–45).
- **Inicio cosecha:** 55–80 días (mini/corazones: 45–70).
- **Tipo cosecha:** 1 corte.
- **Sensibilidad crítica:** calor acumulado → espigado, tipburn en cierre, exceso humedad → sanidad.
- **Alias visibles (UX):** Romana, Cos, Corazones, Mini romana, Little Gem.
- **Variedades comerciales (alias, validar lista contra tu portafolio):** SV4896LC, MAXIMUS RZ, SAMPEDRO RZ, Blondeos, Caitlin, Mayoral, Scala, Vicious, ACTINA, CARDAINE RZ, LIRINA, ALMARAL, Themes, Otra variedad (romana).

### LE-02 — Lechuga bola / iceberg / crisphead ("Salinas")
- **Sistema:** principalmente campo abierto; admite protegido en suelo.
- **Arquitectura:** cabeza compacta tipo bola.
- **Inicio formación cabeza:** 35–55 días.
- **Inicio cosecha:** 60–95 días.
- **Tipo cosecha:** 1 corte.
- **Sensibilidad crítica:** calor sostenido → tipburn / cabezas blandas / no cierra; exceso humedad / lluvia → sanidad; salinidad (sensible); termoinhibición de germinación >27°C en suelo.
- **Alias UX:** Bola, Iceberg, Crisphead, Salinas.
- **Variedades (alias, validar):** SURE SHOT, SV7735LD, Palmarda, RHODENAS RZ, PAULONAS RZ, TOSCANAS RZ, Aspirata, Mestiza, Olmeca, Otra variedad (iceberg/bola).

### LE-03 — Lechuga mantequilla / butterhead (Boston / Bibb)
- **Sistema:** protegido en suelo y campo abierto en zonas frescas.
- **Arquitectura:** cabeza blanda, hoja tierna.
- **Inicio compactación:** 30–50 días.
- **Inicio cosecha:** 45–75 días.
- **Tipo cosecha:** 1 corte.
- **Sensibilidad crítica:** calor → pérdida de textura y espigado; HR alta → Botrytis; balance agua-N → calidad (la hoja blanda es muy susceptible a N alto + calor).
- **Alias UX:** Mantequilla, Butterhead, Boston, Bibb.
- **Variedades (alias, validar):** Fairly, Cuervo, Buttercrunch, Otra variedad (mantequilla/butterhead).

> Cambio respecto a v1: **se retira "Hidropónico" como sistema principal**. v1 = suelo y protegido en suelo. Si el usuario tiene hidroponía, queda como nota futura.

### LE-04 — Lechuga orejona / hoja suelta (looseleaf / oak leaf / lollo)
- **Sistema:** campo y protegido en suelo.
- **Arquitectura:** roseta abierta, no cabecea.
- **Inicio cosecha:** 30–60 días.
- **Tipo cosecha:** 1 corte (planta completa) o cortes parciales según manejo.
- **Sensibilidad crítica:** calor → espigado y amargor; HR alta → mildiu, Botrytis; salinidad.
- **Alias UX:** Orejona, Hoja suelta, Looseleaf, Oak leaf, Lollo.
- **Variedades (alias, validar):** Ancona, Bergam's Green, Celinet, Clearwater, Claudita, Crispita, Lollo Rossa, Red Salad Bowl, Otra variedad (hoja suelta).

### LE-05 — Baby leaf / mezclas tiernas
- **Sistema:** campo y protegido en suelo (alta densidad).
- **Arquitectura:** no cabecea. Cosecha tierna.
- **Inicio cosecha:** 25–45 días.
- **Densidad:** 1,500,000–3,000,000 pl/ha.
- **Tipo cosecha:** 1 corte de bandas o cortes parciales repetidos según manejo.
- **Sensibilidad crítica:** calor (acelera espigado), HR alta (sanidad), salinidad (afecta calidad y color).
- **Alias UX:** Baby leaf, Mezcla baby, Tierna.
- **Variedades:** según mezcla del usuario; alias libre + "Otra variedad (baby leaf)".

### LE-GEN — Perfil genérico SKIP
- Ver documento 2 (Perfil SKIP).

---

## 14. Reglas para Dashboard, Crop Care, Notifications, History (resumen ejecutivo)

> El detalle por documento queda en cada uno de los 5 documentos. Aquí solo se listan las reglas que dependen del Perfil Universal.

**Dashboard**
- Tile principal: estado del cultivo (índice global 0–100 + categoría + tendencia).
- Sub-tiles: agua, temperatura, suelo, nutrición, sanidad. Cada uno con su sub-índice y un mensaje corto.
- Banner si etapa actual es crítica (4 o 5).
- Banner si hay alerta crítica activa.

**Crop Care**
- Carta principal: la alerta activa de mayor severidad.
- Cartas secundarias: hasta 3 acciones recomendadas seguras (revisar riego, revisar HR, revisar foco sanitario), priorizadas por etapa.
- Carta de cosecha estimada (`estimated_harvest_window`): aparece desde etapa 5 en adelante.

**Notifications**
- Push obligatorio: alertas críticas (severidad ≥0.9) en etapas 4–6.
- Push opcional: alertas de severidad media (0.5–0.8).
- Cooldown por código de alerta: ver documento 4 (Riesgos).
- Una sola notificación por evento; los eventos repetidos consolidan.

**History**
- Persistir cada evento de estrés según el esquema de la sección 10.
- Persistir cambios de etapa con timestamp.
- Persistir cambios de perfil (SKIP → tipo específico) sin borrar memoria.
- Persistir cosecha real cuando el usuario la marque (alimenta el modelo de rendimiento real).

---

## 15. Supuestos y datos que requieren validación local

- Rangos de temperatura, HR y EC: tomados de literatura clásica de Lactuca (Maas-Hoffman para EC; manuales de extensión UC, UF/IFAS, UMN, Cornell, INIFAP). Pueden afinarse con datos locales de tu zona de operación.
- Duraciones de etapas: rangos amplios. Variedades específicas pueden caer fuera; el motor debe ajustar por estrés acumulado pero la banda inicial es válida para tipo.
- Termoinhibición a >27°C: bien documentada pero varía por cultivar (iceberg más sensible que romana, romana más que looseleaf). Si tu base de datos tiene la cultivar específica, el umbral puede personalizarse.
- Lista de variedades comerciales: la del v1 más complementos. Debe validarse contra tu portafolio real antes de cerrar UX.

---

## 16. Notas de implementación (sugeridas, validar contra código real BIO-G)

- `CropKey.lettuce` como única entrada al cultivo madre.
- `LettuceTypeAlias` enum sugerido: `romaine | iceberg | butterhead | looseleaf | baby_leaf | generic`.
- `LettuceStage` enum sugerido: `germination | establishment | vegetative_early | rosette_formation | head_formation | commercial_maturity | over_maturity_bolting_risk | end_of_cycle`.
- `CropProfile.lettuce.universal` carga los rangos de la sección 4 y los pesos de la sección 7.
- Cada tipo (LE-01..LE-05) sobreescribe `duration_ranges`, `sensitivity_overrides` y `harvest_yield_anchor`.
- El SKIP usa los rangos del Universal con `conservative_buffer = 0.9` aplicado a los thresholds de "estrés" (los acerca al óptimo en un 10 %) — ver doc 2.

---

## 17. Cierre BIO-G — Lechuga

Este perfil define **cuándo la lechuga está en riesgo**, no cómo producirla. Cubre los 5 tipos UX más comunes y el SKIP, mantiene el cultivo como madre único (`crop_lettuce`), trata el espigado como evento de falla y no como etapa, prioriza calidad de hoja sobre rendimiento bruto, y deja el reloj biológico estable mientras el calendario se ajusta por estrés acumulado.

**Estado del perfil:** CERRADO para v2 BIO-G. Listo para alimentar Dashboard, Crop Care, Notifications, History y motor NPK.
