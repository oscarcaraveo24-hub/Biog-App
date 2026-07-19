# Documento 05 — Nutrición NPK, StageTargets y StageWeights · CACTUS

**Versión:** 2.0 · Julio 2026 · **Sustituye a** `05_Guia_Nutricion_NPK_Targets_BioG_Cactus_v1_1_reforzado.txt`
**Depende de:** `GUIA_ORNAMENTALES_BIOG.md` (obligatorio leerla antes)
**Estado:** implementado en `lib/core/crops/cactus/cactus_universal_profile.dart`

---

## 0. Qué cambió respecto a la v1.1, y por qué

La v1.1 era un documento serio y bien investigado. Su problema no fue la agronomía: fue que
**especificaba un sistema que BIO-G no tiene**.

### 0.1 Lo que la v1.1 pedía

La v1.1 §3 definía todas las variables como **índices comparables contra un baseline = 100**:

```
ecComparableIndex          = 100 * currentComparableEc / baselineComparableEc
resistanceComparableIndex  // baseline = 100
n/p/kComparableIndex       = 100 * median(currentValidWindow) / healthyBaselineMedian
```

Y condicionaba el NPK a una ventana de validez estricta (humedad 18–48, `hydricStage` en
{draining, drying}, 2–36 h desde el pico de riego, temperatura 14–34 °C, 3 lecturas
comparables, método de EC declarado…).

### 0.2 Por qué el razonamiento era correcto

- La sonda BIO-G **no** entrega mg/kg de laboratorio. Es cierto y está documentado.
- La resistencia medida en una mezcla de **tezontle, pómez, perlita o arena** no significa
  lo mismo que en un suelo arcilloso de parcela. También es cierto.
- La EC depende del **método** (PourThru, 1:2, SME, sonda directa) y de la humedad al
  momento de medir. Comparar dS/m entre métodos distintos es inválido.

**Todo esto sigue siendo verdad.** No se está diciendo que el documento estuviera equivocado.

### 0.3 Por qué aun así se descarta

El sistema de índices exige infraestructura que **no existe en BIO-G**:

- baseline de EC/NPK por dispositivo,
- `ecMethodId` / `phMethodId` declarados por el usuario,
- historial y ventanas comparables,
- máquina de estados del microciclo hídrico (`hydricStage`), que además quedó
  **descartada** en la Guía §7.2.

La integración original implementó los **targets** de ese sistema (rangos en escala de
índice: EC 40–160, resistencia 40–190) **sin construir el sistema**. El sensor seguía
mandando mS/cm y MPa. Resultado: nada podía clasificarse, y hubo que taparlo con
`"Sin baseline comparable"`, `"No accionable"` y una tarjeta de EC que sustituyó a la de
Resistencia.

> **Lección, ya congelada en la Guía §3.1:** si una métrica no se puede interpretar con
> unidades reales y un rango absoluto, **no se muestra**. No se inventa una escala nueva.

### 0.4 Qué se conserva de la v1.1

- Toda la agronomía: baja demanda, K > P > N, el agua manda, el exceso de N es dañino.
- Las puertas conceptuales (§14 de la Guía): seco extremo, saturación, EC alta, frío y
  reposo **bajan el peso** del NPK.
- Las bandas de EC por método (§8.3), que **sí** venían en dS/m reales y se usaron para
  calibrar los rangos de este documento.
- Las exclusiones de alcance (§0.2): epífitos, nopal/Opuntia, pitahaya.

---

## 1. Alcance

Aplica a cactus **xerófitos / desérticos**:

```
ca_skip · ca_01_desert_container · ca_02_barrel_biznaga
ca_03_columnar_landscape · ca_04_clustered_desert
```

**No aplica a:** cactus epífitos/tropicales (navidad, *Schlumbergera*, *Rhipsalis*),
nopal/*Opuntia* (reservado a `crop_nopal`), pitahaya productiva, semilleros, injertos
especializados.

## 2. Capacidades congeladas

```
supportsYieldProjection = false
supportsHarvest         = false
supportsRecurringBloom  = false
supportsHydricCycle     = false   // descartado — Guía §7.2
supportsStressMemory    = false   // no se computa; no se persiste
```

## 3. Regla maestra

```
Humedad → Temperatura → EC → pH → Resistencia → NPK
```

Primero se valida el agua y la zona radicular; después se interpreta la nutrición.
Una lectura baja de N, P o K **no autoriza fertilizar** por sí sola.

En cactus, **el exceso de agua sostenido es el riesgo #1**: pudre raíz y cuello. Pesa más
en el score que la sequía.

---

## 4. Unidades oficiales

Las **mismas** que frijol, hortalizas, granos y árboles (Guía §3.1).

| Variable | Campo | Unidad |
|---|---|---|
| Humedad | `soilMoisturePct` | % (0–100) |
| Temperatura de sustrato | `soilTempC` | °C |
| pH | `ph` | pH |
| EC | `ec` | **mS/cm** |
| Resistencia | `resistance` | **MPa** |
| N / P / K | `n` `p` `k` | **mg/kg** |

---

## 5. StageTargets

Implementado en `resolveCactusTargets(stageId)`.

### 5.1 Humedad (%)

Rangos **bajos**: el cactus vive seco y se pudre mojado.

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Recién plantada | 4 | 10 – 30 | 48 |
| Echando raíz | 4 | 12 – 34 | 52 |
| Creciendo | 6 | 15 – 40 | 58 |
| Estable | 4 | 10 – 34 | 52 |
| En reposo | 3 | 7 – 25 | 42 |
| Por confirmar | 4 | 10 – 34 | 52 |

### 5.2 Temperatura de sustrato (°C)

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Recién plantada | 6 | 16 – 30 | 38 |
| Echando raíz | 6 | 16 – 30 | 38 |
| Creciendo | 8 | 18 – 32 | 40 |
| Estable | 5 | 12 – 32 | 40 |
| En reposo | 2 | 6 – 20 | 32 |
| Por confirmar | 5 | 12 – 30 | 38 |

### 5.3 pH — por contexto de cultivo

| Contexto | lowMax | óptimo | highMin |
|---|---|---|---|
| Base (desconocido) | 4.8 | 5.5 – 7.2 | 8.0 |
| Maceta / vivero | 4.6 | 5.2 – 6.8 | 7.4 |
| Jardinera / cama | 4.8 | 5.5 – 7.2 | 8.0 |
| Paisaje / suelo abierto | 5.0 | 5.8 – 7.8 | 8.4 |

`ca_01` (maceta) usa el rango de maceta; `ca_03` (columnar de paisaje) el de paisaje.
`ca_02` y `ca_04` admiten ambos contextos → conservan el rango base hasta que el usuario
lo precise.

### 5.4 EC (mS/cm)

Calibrado desde las bandas por método de la v1.1 §8.3, llevadas a la escala de sonda
directa que usa el resto del ecosistema. El cactus es **sensible a la acumulación de
sales**, sobre todo en maceta.

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Establecimiento (plantada / raíz) | 0.2 | 0.4 – 1.0 | 1.5 |
| Creciendo | 0.3 | 0.5 – 1.2 | 1.8 |
| Estable / por confirmar | 0.2 | 0.4 – 1.1 | 1.6 |
| En reposo | 0.2 | 0.3 – 0.9 | 1.4 |

> **Nota v1.1 conservada:** una EC "muy baja" **no** es deficiencia en mantenimiento ni en
> reposo. Por eso el `lowMax` es bajo y no dispara alarma fuerte.

### 5.5 Resistencia (MPa)

El cactus exige sustrato **suelto y drenante**. La compactación asfixia la raíz **y retiene
agua junto al cuello**, que es como se pudre. Umbral más estricto que frijol (2.0).

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Establecimiento | −1.0 | 0.0 – 1.0 | **1.6** |
| Resto | −1.0 | 0.0 – 1.2 | **1.8** |

`lowMax = −1.0` significa que **no se castiga por "muy suelto"**: para un cactus, suelto es
bueno.

### 5.6 NPK (mg/kg)

Rangos **explícitos** de suficiencia de suelo. Planta de **baja demanda**.
**K > P > N** en importancia.

**Nitrógeno** — el exceso produce tejido blando y aguado que se pudre.

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Establecimiento | 6 | 12 – 28 | 45 |
| Creciendo | 10 | 18 – 40 | 60 |
| Estable / por confirmar | 8 | 14 – 32 | 50 |
| En reposo | 5 | 10 – 24 | 40 |

**Fósforo** — raíz y espinas.

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Recién plantada | 5 | 10 – 26 | 40 |
| Raíz / creciendo | 6 | 12 – 30 | 45 |
| Estable / por confirmar | 5 | 10 – 26 | 40 |
| En reposo | 4 | 8 – 22 | 36 |

**Potasio** — el que **sí** importa: turgencia, pared celular, espinas, aguante a calor y frío.

| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Establecimiento | 35 | 60 – 130 | 185 |
| Creciendo | 45 | 75 – 150 | 205 |
| Estable / por confirmar | 40 | 65 – 140 | 195 |
| En reposo | 30 | 55 – 120 | 175 |

### 5.7 Caps (`NpkCaps`)

Normalizan la lectura cruda al gauge. **No son dosis.**

```
cactus → N = 60 · P = 55 · K = 220 mg/kg
```

`K > N` a propósito: en cactus el potasio manda. El cap de N es **bajo** (60) para que una
lectura de 40–50 mg/kg ya se lea como **alta** — que es lo correcto, porque en un cactus eso
ya es demasiado nitrógeno.

---

## 6. StageWeights

`resolveCactusStageWeights(stageId)`. **Cada fila suma 1.00.**

| Etapa | Humedad | Temp | pH | EC | Resist. | N | P | K |
|---|---|---|---|---|---|---|---|---|
| Recién plantada | 0.34 | 0.13 | 0.07 | 0.12 | 0.14 | 0.06 | 0.06 | 0.08 |
| Echando raíz | 0.34 | 0.14 | 0.06 | 0.12 | 0.14 | 0.05 | 0.07 | 0.08 |
| **Creciendo** | 0.28 | 0.12 | 0.08 | 0.12 | 0.11 | **0.11** | 0.08 | 0.10 |
| Estable | 0.30 | 0.12 | 0.08 | 0.13 | 0.12 | 0.08 | 0.07 | 0.10 |
| En reposo | 0.34 | **0.18** | 0.06 | 0.13 | 0.11 | 0.05 | 0.05 | 0.08 |
| Por confirmar | 0.32 | 0.14 | 0.07 | 0.12 | 0.13 | 0.07 | 0.06 | 0.09 |

Lectura de la tabla:

- **El agua domina siempre** (0.28 – 0.34).
- El **NPK sólo pesa de verdad en `Creciendo`** (N sube a 0.11). Es la única etapa donde la
  planta responde a nutrición. Esto sustituye a la "puerta de accionabilidad" de la v1.1:
  se logra el mismo efecto con pesos, sin apagar la interpretación.
- En **reposo**, la temperatura sube (0.18): el frío es el peligro.
- En **establecimiento**, la resistencia sube (0.14): el sustrato apretado impide arraigar.

---

## 7. Castigos del AgroScore

En `cactus_agro_score_engine.dart`:

| Condición | Factor |
|---|---|
| Humedad crítica **por exceso** | **× 0.40** |
| Humedad crítica por sequía | × 0.60 |
| **Frío + sustrato húmedo** | **× 0.65** (extra) |
| Temperatura crítica | × 0.55 |
| pH crítico | × 0.60 |
| EC crítica | × 0.60 |
| Resistencia crítica | × 0.70 |
| N/P/K en acumulación | × 0.78 |

El **exceso de agua se castiga más que la sequía** (0.40 vs 0.60). Un cactus aguanta semanas
seco; no aguanta días encharcado.

**Frío + húmedo** lleva castigo aparte: es la combinación que pudre la raíz.

---

## 8. Alertas

Claves **canónicas** del `AlertsEngine` (Guía §3.4). El cactus **no** define claves propias.

Particularidades:

- **La humedad ALTA avisa en cualquier etapa** (no sólo en las críticas). Es el riesgo que
  de verdad mata la planta.
- Umbrales de aire más tolerantes que un cultivo anual: calor > 40 °C, calor extremo > 45 °C.
- Humedad ambiental alta (> 80 / > 90 %) sí avisa: favorece hongos y pudrición.
- Etapas críticas (`severityBump = 2`): **recién plantada** y **echando raíz**.
  Semicrítica: **reposo**.

---

## 9. Lo que este documento NO hace

- **No** prescribe marcas, dosis, mililitros, gramos por maceta ni frecuencia de riego.
- **No** sustituye un análisis de laboratorio de sustrato o agua.
- **No** diagnostica enfermedades.
- **No** proyecta rendimiento ni cosecha.

---

## 10. Limitaciones honestas de la v2

1. **Los targets son defaults de ingeniería**, no resultado de un ensayo con la sonda BIO-G
   en sustrato de cactus. Son agronómicamente defendibles y coherentes con el ecosistema,
   pero **deben validarse con hardware real**.
2. **La crítica de fondo de la v1.1 sigue en pie:** la resistencia en una mezcla mineral y
   el NPK de una sonda barata no son medidas de laboratorio. Se asume ese error a cambio de
   un sistema coherente que **hoy sí le habla al agricultor**.
3. Cuando exista baseline por dispositivo, **conviene revisitar** el enfoque de la v1.1 —
   pero construyendo primero el motor y encendiendo la UI después. Nunca al revés.
