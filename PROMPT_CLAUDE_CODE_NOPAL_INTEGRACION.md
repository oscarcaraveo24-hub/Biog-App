# PROMPT PARA CLAUDE CODE — Integración de NOPAL en BIO-G

> Pega este archivo completo como primer mensaje en Claude Code, dentro del repo `bio_g`.

---

## 0. Contexto y regla de oro

Vas a integrar un cultivo ornamental nuevo — **Nopal (`crop_nopal`)** — en la app Flutter BIO-G.

Es la **octava ornamental**. Ya existen siete: cactus, suculenta, sábila, maguey, rosal, tulipán y girasol. Nopal comparte modo de ciclo (`establishment_maintenance`) con cactus, suculenta, sábila y maguey.

**Regla de oro del proyecto:** cuando un documento y el código no coincidan, **gana el código**. Los documentos de especificación se corrigen, nunca al revés. Si algo del contrato te estorba, para y avísame: el problema es el contrato, no la planta.

**El molde a copiar es MAGUEY (`agave`)**, no cactus. Maguey es la ornamental más cercana estructuralmente: mismo modo, ventanas largas, ajustes por perfil (`profileAdjustments` con renormalización de pesos) y catálogo sanitario grande. Cactus no tiene ajustes por perfil.

---

## 1. Qué leer ANTES de escribir una sola línea

En este orden:

1. `docs/ornamentales/GUIA_ORNAMENTALES_BIOG.md` — el contrato. Especial atención a la Parte 3 (lo que una ornamental NO puede romper) y la Parte 5 (la receta).
2. `docs/ornamentales/PLANTILLA_NUEVA_ORNAMENTAL.md` — por qué son 3 documentos y no 5.
3. `temp/nopal/DOCUMENTO_A_NOPAL.txt` — identidad, perfiles, aliases, ciclo de vida.
4. `temp/nopal/DOCUMENTO_B_NOPAL.txt` — targets, pesos, NPK, castigos.
5. `temp/nopal/DOCUMENTO_C_NOPAL.txt` — catálogo sanitario (18 síndromes).
6. El código de referencia de maguey, completo:
   - `lib/core/crops/agave/` (los 8 archivos)
   - `lib/core/plant_health/catalog/agave_syndromes.dart`
   - `test/core/agave/agave_integration_test.dart`

Los documentos son largos (13,293 líneas entre los tres). **No los leas de corrido.** Léelos por sección conforme los vayas necesitando en cada fase.

---

## 2. Correcciones obligatorias a los documentos

Ya audité los tres documentos contra el código. Estas cosas **están mal en los documentos** — respeta el código, no el papel:

### 2.1 Las 12 capacidades de sanidad del Documento C NO EXISTEN. No las implementes.

El Documento C declara estos flags:

```
supportsAutomaticVisualDiagnosis, supportsPathogenConfirmation,
supportsPesticidePrescription, supportsExactTreatmentDose,
supportsLaboratoryConfirmation, supportsEdibilityAssessment,
supportsHarvestDecision, supportsRiskOrganization,
supportsUserConfirmationChecks, supportsSensorContext,
supportsHighConsequenceFlag, supportsManualUseContext
```

**Ninguno existe en `lib/`.** No hay clase, enum ni contrato en `lib/core/plant_health/` que acepte capacidades de sanidad. Cinco de ellos están declarados en `true`, lo que sugeriría infraestructura inexistente. **Son prosa de seguridad, no código.** Ignóralos por completo; el contrato de seguridad ya vive en los textos de `baseActionsEs` y `disclaimerEs`.

### 2.2 Los flags de síndrome: solo existen cuatro

`PlantHealthSyndrome` (`lib/core/plant_health/plant_health_models.dart:78-81`) tiene exactamente:

```dart
final bool favorsHighHumidity;
final bool favorsCoolDewyWindow;
final bool favorsVectorPressure;
final bool favorsRecentStress;
```

El Documento C inventa `favorsOfficialReview`, `favorsMovementRestriction` y `favorsHighConsequence` — **no los crees**. Y nunca usa `favorsVectorPressure`, que sí existe: úsalo en los síndromes con vector (cochinilla, chinches, virus transmitido).

### 2.3 Severidad y urgencia: un solo valor congelado por síndrome

El Documento C escribe cosas como *"Severidad: medium. Subir a high/review24h si crece rápido"* o *"low a medium"*. Hay unos 9 casos así.

**El motor no escala.** `lib/core/plant_health/plant_health_engine.dart:116-117` copia el valor literal:

```dart
severity: best.syndrome.severity,
urgency:  best.syndrome.urgency,
```

Para cada uno de esos casos elige **una** de estas dos salidas y dime cuál elegiste:

- **(a)** Congelar el valor más conservador (el más alto) en un solo síndrome.
- **(b)** Partirlo en dos síndromes con distinto `primarySymptomId` y señales que los separen — por ejemplo "mancha negra estable" vs "mancha negra que avanza".

Prefiere **(a)** salvo que las señales de escalada ya estén bien diferenciadas en el documento, en cuyo caso **(b)** es mejor producto.

Enums reales:

```dart
enum PlantHealthSeverity { low, medium, high, critical }
enum PlantHealthUrgency { monitor72h, review48h, review24h, sameDay, immediate }
```

### 2.4 `organCladode` no existe — hay que darlo de alta

Los órganos reales están en `lib/core/plant_health/plant_health_ids.dart:5-24`. No hay cladodio. Agrega:

```dart
static const String organCladode = 'cladode';
```

y su etiqueta en `organLabelsEs` (~línea 1205): `'cladode': 'Penca'`.

Los demás órganos que usa el Documento C (`organCrown`, `organRoot`, `organStem`, `organFlower`, `organFruit`, `organWholePlant`) ya existen.

### 2.5 `PlantHealthStageBucket` tiene 8 valores, no 7

El documento omite `grainFill`. El enum real:

```dart
enum PlantHealthStageBucket {
  seedling, vegetativeEarly, vegetativeMid, vegetativeLate,
  reproductiveEarly, reproductiveMid, grainFill, lateSeason,
}
```

No afecta a nopal (no se usa `grainFill`), pero no copies la lista incompleta del documento.

### 2.6 No existe ningún campo `cropId` en `crop_definition.dart`

El getter real es `CropKey get cropKey` (`lib/core/crops/crop_definition.dart:9`). El string `crop_nopal` va como constante `kCropNopal` en `nopal_catalog.dart` y se expone vía `CropCatalog.nopalCropId`.

### 2.7 La prioridad de etapa va en el lifecycle, no en el universal_profile

El Documento B propone `nopalStagePriorityEs()` dentro de `_NopalStageProfile`. En el código real la prioridad vive en el lifecycle: `cactusStagePriorityText()` (`cactus_lifecycle.dart:420`), `agaveStagePriorityText()` (`agave_lifecycle.dart:383`), y la consume `ornamentalStagePriorityText()` (`ornamental_crops.dart:187`).

Crea **`nopalStagePriorityText(String? stageId)`** en `nopal_lifecycle.dart`.

---

## 3. La trampa principal: el fallback silencioso a cactus

`lib/core/crops/ornamental/ornamental_crops.dart:105-113`:

```dart
enum _OrnamentalKind { cactus, succulent, aloe, agave }

_OrnamentalKind _kind(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  if (canonical == kCropSucculent) return _OrnamentalKind.succulent;
  if (canonical == kCropAloe)      return _OrnamentalKind.aloe;
  if (canonical == kCropAgave)     return _OrnamentalKind.agave;
  return _OrnamentalKind.cactus;   // ← fallback silencioso
}
```

**Si te olvidas de la rama de nopal, `crop_nopal` heredará targets, assets y textos de cactus sin lanzar ningún error.** Es exactamente el bug que la Guía documenta como el pecado original de la primera integración ornamental.

Al agregar `nopal` al enum `_OrnamentalKind`, Dart te obligará a cubrir **~23 `switch` exhaustivos** en ese mismo archivo (líneas 117, 124, 131, 138, 146, 155, 163, 171, 179, 187, 195, 205, 217, 261, 269, 285, 343, 401, 408, 416, 424, 437, 444, 451, 458, 465, 472, 483, 496, 529, 538). Eso es bueno: el compilador te cubre. El único punto sin red es `_kind()`.

---

## 4. Lo que YA está hecho — no lo generes

Los assets **ya existen en disco**, con los nombres correctos. Verifícalos, no los crees:

```
assets/seeds/nopal/nopal_stage_installation_establishment.png
assets/seeds/nopal/nopal_stage_root_establishment.png
assets/seeds/nopal/nopal_stage_active_growth.png
assets/seeds/nopal/nopal_stage_maintenance.png
assets/seeds/nopal/nopal_stage_rest.png
assets/seeds/nopal/nopal_stage_unknown.png

assets/icons/wizard/ic_nopal.png
assets/icons/wizard/ic_nopal_unknown.png
assets/icons/wizard/ic_nopal_compact_clumping_container.png
assets/icons/wizard/ic_nopal_upright_large_pad_warm.png
assets/icons/wizard/ic_nopal_desert_shrub_spiny_landscape.png
assets/icons/wizard/ic_nopal_low_spreading_cold_hardy.png
```

**PERO:** `assets/seeds/nopal/` **NO está declarada en `pubspec.yaml`**. Flutter no incluye subcarpetas recursivamente. Agrega la línea `- assets/seeds/nopal/` junto a las demás (bloque de líneas 78-106). `assets/icons/wizard/` sí está declarada como carpeta, así que los iconos ya entran.

También ya existen las **redirecciones de alias** hacia `crop_nopal` en `cactus_catalog.dart:167-202`, `agave_catalog.dart:192-256`, `aloe_catalog.dart:200-251` y `succulent_catalog.dart:196-261`. Después de integrar nopal, esas entradas deben **resolver a Nopal**, no devolver `null` ni caer en cactus/maguey. Verifícalo con un test.

---

## 5. Plan de trabajo por fases

Haz una fase a la vez. Al terminar cada una: `flutter analyze` y muéstrame el diff antes de seguir. **No hagas las cinco fases de un tirón.**

### FASE 1 — Identidad y catálogo

Crear:
- `lib/core/crops/nopal/nopal_catalog.dart` — `kCropNopal = 'crop_nopal'`, los 5 `profileId`, `nopalProfileEntries` (SKIP al final), aliases de cultivo y de perfil, `isNopalCrop()`.
- `lib/core/crops/nopal/nopal_lifecycle.dart` — `lifecycleMode = 'establishment_maintenance'`, los 6 stage ids, nombres visibles, los 5 flags `supports*` en `false`, `nopalStagePriorityText()`.
- `lib/core/crops/nopal/nopal_assets.dart`
- `lib/core/crops/nopal/nopal_crop_definition.dart`

Modificar:
- `lib/core/crops/crop_types.dart` → `nopal` en el enum `CropKey`.
- `lib/core/crops/catalog/crop_catalog.dart` → `nopalCropId`, `nopalDefaultProfileId`, entrada de catálogo (~935), aliases (~1911), displayName (~2001).
- `lib/core/crops/crop_registry.dart` → `CropKey.nopal: NopalCropDefinition()` (~64) + resolver de alias (~254).
- `pubspec.yaml` → `- assets/seeds/nopal/`.

**Datos congelados (Documento A):**

```
cropId:            crop_nopal
CropKey:           nopal
prefijo:           NO
categoría:         ornamental
modo:              establishment_maintenance
nombre visible:    Nopal
perfil default:    no_skip
label de alcance:  Nopal ornamental · aprovechamiento manual
subtítulo:         BIO-G cuida la planta; el usuario decide cuándo cortar pencas o tunas

supportsYieldProjection = false
supportsHarvest         = false
supportsRecurringBloom  = false
supportsHydricCycle     = false
supportsStressMemory    = false
```

Perfiles, en este orden exacto en el wizard:

| # | profileId | Etiqueta visible |
|---|---|---|
| 1 | `no_01_compact_clumping_container` | Nopal compacto o agrupado |
| 2 | `no_02_upright_large_pad_warm` | Nopal alto o de penca grande |
| 3 | `no_03_desert_shrub_spiny_landscape` | Nopal arbustivo de paisaje |
| 4 | `no_04_low_spreading_cold_hardy` | Nopal bajo o rastrero |
| 5 | `no_skip` | No sé / nopal general |

Los subtítulos y las listas largas de aliases están en el Documento A §6. **El perfil general va siempre al último y nunca se llama "SKIP" en la interfaz.**

Etapas (los strings coinciden exactos con los de cactus/maguey, no los inventes):

| stageId | Nombre visible |
|---|---|
| `installation_establishment` | Recién plantado |
| `root_establishment` | Echando raíz |
| `active_growth` | Creciendo |
| `maintenance` | Estable |
| `rest` | En reposo |
| `unknown` | Etapa por confirmar |

### FASE 2 — Targets, pesos y motor de score

Crear:
- `lib/core/crops/nopal/nopal_universal_profile.dart`
- `lib/core/crops/nopal/nopal_stage_resolver.dart`
- `lib/core/crops/nopal/nopal_agro_score_engine.dart`

Modificar:
- `lib/core/agro/npk_caps.dart` → 3 `case` (N/P/K).

**NPK caps:** N = 90, P = 60, K = 280 mg/kg.
Aliases (el normalizador solo hace `trim().toLowerCase()`, los espacios están bien):
`nopal`, `crop_nopal`, `nopales`, `opuntia`, `orn_nopal`, `prickly pear`, `cactus pear`.

**StageTargets.** Formato `AgroRange(lowMax, optimalMin, optimalMax, highMin)`:

**Humedad (% escala BIO-G 0-100)**

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | 5 | 12 | 48 | 68 |
| root_establishment | 6 | 14 | 52 | 72 |
| active_growth | 8 | 18 | 60 | 78 |
| maintenance | 5 | 12 | 54 | 72 |
| rest | 3 | 7 | 40 | 62 |
| unknown | 5 | 12 | 52 | 70 |

**Temperatura de suelo (°C)**

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | 6 | 16 | 30 | 38 |
| root_establishment | 7 | 18 | 31 | 39 |
| active_growth | 8 | 20 | 33 | 41 |
| maintenance | 4 | 12 | 32 | 40 |
| rest | -2 | 4 | 18 | 30 |
| unknown | 5 | 12 | 31 | 39 |

**EC (mS/cm)**

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | 0.15 | 0.35 | 1.20 | 2.00 |
| root_establishment | 0.15 | 0.35 | 1.30 | 2.10 |
| active_growth | 0.20 | 0.50 | 1.80 | 2.80 |
| maintenance | 0.15 | 0.35 | 1.50 | 2.50 |
| rest | 0.10 | 0.25 | 1.00 | 1.80 |
| unknown | 0.15 | 0.35 | 1.40 | 2.30 |

**Resistencia (MPa)** — `lowMax = -1` en todas las etapas, a propósito: no se penaliza un medio demasiado suelto.

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | -1 | 0 | 1.0 | 1.6 |
| root_establishment | -1 | 0 | 1.1 | 1.7 |
| active_growth | -1 | 0 | 1.4 | 2.0 |
| maintenance | -1 | 0 | 1.5 | 2.1 |
| rest | -1 | 0 | 1.3 | 1.9 |
| unknown | -1 | 0 | 1.4 | 2.0 |

**Nitrógeno (mg/kg)**

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | 8 | 14 | 32 | 50 |
| root_establishment | 10 | 18 | 38 | 58 |
| active_growth | 15 | 28 | 58 | 85 |
| maintenance | 10 | 18 | 42 | 65 |
| rest | 6 | 10 | 26 | 42 |
| unknown | 10 | 18 | 42 | 65 |

**Fósforo (mg/kg)**

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | 5 | 9 | 20 | 32 |
| root_establishment | 6 | 10 | 24 | 36 |
| active_growth | 8 | 14 | 32 | 48 |
| maintenance | 6 | 10 | 26 | 40 |
| rest | 4 | 7 | 18 | 30 |
| unknown | 6 | 10 | 26 | 40 |

**Potasio (mg/kg)**

| Etapa | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| installation_establishment | 35 | 60 | 140 | 200 |
| root_establishment | 40 | 70 | 155 | 220 |
| active_growth | 55 | 90 | 195 | 270 |
| maintenance | 45 | 75 | 175 | 240 |
| rest | 30 | 50 | 125 | 180 |
| unknown | 45 | 75 | 170 | 235 |

**pH — depende del CONTEXTO, no de la etapa.** El contexto gana siempre; el perfil solo ajusta severidad.

| Contexto | lowMax | optMin | optMax | highMin |
|---|---:|---:|---:|---:|
| `pot` / `nursery` | 4.8 | 5.5 | 7.0 | 7.8 |
| `planter` / `garden_bed` | 5.0 | 5.8 | 7.6 | 8.3 |
| `landscape` / `open_ground` | 5.0 | 6.0 | 8.0 | 8.6 |
| desconocido | 5.0 | 5.7 | 7.7 | 8.4 |

**StageWeights** — el motor admite exactamente 8 métricas (`soilMoisture, soilTemp, resistance, ph, ec, n, p, k`). Cada fila **debe** sumar 1.00 (hay test que lo exige con `closeTo(1.0, 0.0001)`):

| Etapa | Hum | Temp | pH | EC | Resist | N | P | K |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| installation_establishment | 0.33 | 0.13 | 0.07 | 0.12 | 0.15 | 0.06 | 0.06 | 0.08 |
| root_establishment | 0.34 | 0.14 | 0.06 | 0.12 | 0.15 | 0.05 | 0.07 | 0.07 |
| active_growth | 0.27 | 0.12 | 0.07 | 0.12 | 0.10 | 0.13 | 0.09 | 0.10 |
| maintenance | 0.30 | 0.12 | 0.08 | 0.13 | 0.12 | 0.08 | 0.07 | 0.10 |
| rest | 0.34 | 0.20 | 0.06 | 0.13 | 0.11 | 0.04 | 0.04 | 0.08 |
| unknown | 0.32 | 0.14 | 0.07 | 0.12 | 0.13 | 0.07 | 0.06 | 0.09 |

**Ajustes por perfil** (`nopalProfileAdjustments()`, copiando `agave_universal_profile.dart:644-670`, que renormaliza pesos después de aplicar el multiplicador). Detalle completo en el Documento B §15. Resumen:

- **NO-01** (compacto/maceta): humedad `lowMax +1`, `optimalMin +1`, `highMin -4`; EC `optimalMax -0.15`, `highMin -0.25`; severidad EC alta ×1.15; calor de suelo ×1.10; N alto ×1.10; NPK activo ×0.95. **Solo aplica el ajuste de sustrato si `context = pot|nursery`.**
- **NO-02** (alto/penca grande): resistencia alta ×1.10; déficit en `active_growth` ×1.05; frío ×1.15; peso de N y K en `active_growth` ×1.05; `sensorLocalCaution = true`. **No subir rangos de NPK ni humedad óptima por tamaño.**
- **NO-03** (arbustivo de paisaje): `sensorLocalCaution = true`; déficit en `maintenance` ×0.97; calor ×0.95. Sin suavizar EC. No elevar NPK.
- **NO-04** (bajo/rastrero): ajuste de frío del Documento B §6.5 — en `maintenance` `lowMax -2`, `optimalMin 4`; en `rest` `lowMax -8`, `optimalMin -2`, `optimalMax 16`, `highMin 28`. `cold severity ×0.75` **solo si** perfil confirmado + planta estable + stage `maintenance` o `rest` + sin trasplante reciente. Frío + húmedo ×1.15. NPK en `rest` ×0.85. **Nunca aplicar el ajuste de frío en `installation_establishment`, `root_establishment` ni con `no_skip`. `frost` nunca se elimina.**
- **NO-SKIP**: targets base, `limitNpkPriorityToReview = true`, `sensorLocalCaution = true`, sin tolerancia fría ni salina.

**Castigos del AgroScore** (factor menor = castigo mayor):

| Condición | Factor |
|---|---:|
| Humedad crítica por exceso | 0.43 |
| Humedad crítica por sequía | 0.64 |
| Temperatura de suelo crítica | 0.56 |
| pH crítico | 0.64 |
| EC crítica | 0.56 |
| Resistencia crítica | 0.68 |
| N/P/K en acumulación | 0.76 |
| N/P/K crítico bajo durante crecimiento | 0.84 |

Combinaciones: frío + suelo húmedo 0.60 · EC alta + suelo seco 0.72 · EC alta + humedad alta 0.70 · calor + sequía en `active_growth` 0.72 · instalación/raíz + humedad crítica alta 0.82 · NO-01 + EC alta en maceta 0.85 · NO-02 + resistencia crítica 0.90 · NO-04 + frío húmedo 0.85.

**Aplica cada castigo una sola vez y en orden fijo.** El orden completo de 12 pasos está en el Documento B §16.4.

**Severity bumps:** installation 2 · root 2 · active_growth 1 · maintenance 0 · rest 2 (humedad/temperatura) · unknown 1. Frío + húmedo suma +1.

**Umbrales de aire:** frost ≤ 0 °C · cold < 5 °C si no hay `rest` confirmado · heat > 38 °C · extreme heat > 45 °C · humedad ambiental alta > 82 % sostenida · crítica > 92 % sostenida.

**Claves de alerta:** usa **solo** las canónicas. Todas existen ya en `lib/core/agro/alerts_engine.dart`:

```
soilMoisture.{critical,low,high}   soilTemp.{critical,low,high}
ph.{critical,low,high}             ec.{critical,low,high}
resistance.{critical,low}          airTemp.{frost,cold,heat,extreme_heat}
airHumidity.{high,critical}        npk.{n,p,k}.*
stage.{fallback,unknown}
```

**Nunca emitas `nopal.*`, `opuntia.*` ni ninguna clave propia.** `AlertsEngine` las descarta en silencio y el cultivo se queda mudo, sin una sola alerta. Ese fue exactamente el bug del cactus.

### FASE 3 — Despacho ornamental

Modificar `lib/core/crops/ornamental/ornamental_crops.dart`:

1. 5 imports nuevos (`nopal_assets`, `nopal_catalog`, `nopal_lifecycle`, `nopal_stage_resolver`, `nopal_universal_profile`).
2. `kCropNopal` al set `kEstablishmentMaintenanceCropIds` (~línea 45).
3. `isNopalCrop()` al `||` de `isEstablishmentMaintenanceCrop()` (~línea 58).
4. `nopal` al enum `_OrnamentalKind` (~línea 105).
5. **La rama en `_kind()`** (~línea 107) — este es el punto crítico, ver §3.
6. Los ~23 `switch` que el compilador te va a marcar.

Modificar también:
- `lib/core/crops/crop_presentation_resolver.dart` (~línea 811) — tiene un `case CropCatalog.agaveCropId:` explícito para `ornamentalProfileIcon()`. **Sin rama de nopal el icono de perfil no resuelve.** Este archivo NO está en la lista del Documento A.
- `lib/screens/onboarding/onboarding_wizard_screen.dart` (~línea 1358) — `case CropCatalog.agaveCropId: return AgaveAssets.cropIcon;`. Tampoco está en la lista del documento.
- `lib/widgets/account/wizard/configure_seed_wizard_screen.dart` (~línea 2138) — ahí el `case` es agrupado, solo agrega el cropId.

El onboarding no tiene lista hardcodeada de cultivos: sale de `CropCatalog`, así que nopal entra solo una vez registrado.

### FASE 4 — Sanidad

Crear:
- `lib/core/crops/nopal/nopal_risk_catalog.dart`
- `lib/core/plant_health/catalog/nopal_syndromes.dart` — los 18 síndromes del Documento C.

Modificar:
- `lib/core/plant_health/plant_health_ids.dart` — `organCladode` + su label; los 18 `symptomNopal*` y sus labels en `symptomLabelsEs` (~1227); las señales `signalNopal*` y sus labels en `signalLabelsEs` (~1459).
- `lib/core/plant_health/plant_health_registry.dart` — import + `case nopalCropId` (~línea 56).
- `lib/core/plant_health/plant_health_stage_adapter.dart` — agrega `case CropCatalog.nopalCropId:` al grupo existente de líneas 62-70. El mapeo que ya hace `_fromEstablishmentMaintenance()` es exactamente el que pide el documento, no escribas uno nuevo.

**Sobre el volumen de señales:** el Documento C define ~196 señales `signalNopal*` propias. Para comparar: cactus tiene 14, maguey 51. Con 18 síndromes salen ~11 señales por síndrome, cuando los reales manejan 3-8. **Antes de darlas todas de alta, propón una poda** quedándote con las que de verdad discriminan entre diagnósticos dentro de cada síndrome, y muéstrame la lista podada. Demasiadas señales diluyen el score.

Estructura real de `PlantHealthSyndrome` (los nombres son sin sufijo `Ids`):

```
id, cropId, labelEs, stages, organIds, primarySymptomId,
strongSignals, weakSignals, conflictingSignals,
probableDiagnoses, confirmationChecksEs, severity, urgency,
baseActionsEs, disclaimerEs, varietyModifiers,
favorsHighHumidity, favorsCoolDewyWindow, favorsVectorPressure, favorsRecentStress
```

`PlantHealthDiagnosis` sí lleva sufijo: `id, labelEs, scientificName, type, summaryEs, confirmatorySignalIds, contradictorySignalIds`.

Las 19 señales compartidas que el documento reutiliza **ya existen** — úsalas, no las dupliques con prefijo nopal: `signalHumidWindow`, `signalCoolDewyWindow`, `signalActiveChewing`, `signalFrassPresent`, `signalVectorPresent`, `signalStickyHoneydew`, `signalSootyMold`, `signalWhitePowderGrowth`, `signalBronzedLeafSurface`, `signalMitesWebbing`, `signalWaterlogging`, `signalRootsDarkRot`, `signalHeatStress`, `signalDryHotWindow`, `signalSalinityLoad`, `signalFeedingHoles`, `signalDenseWetCanopy`, `signalColdExposure`, `signalRecentStress`.

### FASE 5 — Pruebas

Crear `test/core/nopal/nopal_integration_test.dart`, copiando `test/core/agave/agave_integration_test.dart`. Debe cubrir como mínimo:

1. `CropRegistry` resuelve `CropKey.nopal` a `NopalCropDefinition`.
2. Los 6 stage ids existen y `unknown` tiene targets propios.
3. Cada fila de `StageWeights` suma 1.00 (`closeTo(1.0, 0.0001)`).
4. **Nopal NO hereda los caps de cactus, suculenta ni sábila.** Ojo: N(nopal)=90 coincide con N(maguey)=90, así que compara contra maguey por P (60 vs 55) o por K, no por N.
5. Los aliases `nopal`, `opuntia`, `penca de nopal` resuelven a `crop_nopal` y **no** a cactus ni a maguey.
6. `_kind()` no cae en cactus: pide assets, textos y targets de nopal y verifica que no sean los de cactus.
7. Una lectura de humedad de 60 % da **Óptimo** en `active_growth` y **Alto/ajuste, no Crítico** en las otras cinco etapas. (Regresión obligatoria del Documento B §5.7.)
8. Una lectura de 82 % da Crítico alto en todas las etapas y bloquea recomendación fuerte de NPK.
9. `PlantHealthRegistry.catalogForCrop('crop_nopal')` devuelve los 18 síndromes.
10. El adapter mapea las 6 etapas a los buckets correctos.

---

## 6. Criterios de aceptación

Antes de decir que terminaste:

```bash
flutter analyze          # 0 errores, 0 warnings nuevos
flutter test             # toda la suite en verde, no solo la de nopal
```

Y estas verificaciones manuales:

- `grep -rn "nopal\." lib/ | grep -v "nopal_"` no devuelve ninguna clave de alerta propia.
- Nopal aparece en el wizard de onboarding con sus 5 perfiles, el general al final.
- Las 6 imágenes de etapa cargan (si `pubspec.yaml` no se tocó, salen en blanco).
- El icono de perfil resuelve en `crop_presentation_resolver.dart`.

---

## 7. Prohibiciones

- No inventes claves de alerta.
- No crees unidades nuevas. Humedad en % 0-100 de la escala BIO-G, temperatura en °C, pH en unidades de pH, EC en mS/cm, resistencia en MPa, NPK en mg/kg.
- No cambies las 4 tarjetas del dashboard (Humedad, Temperatura de suelo, pH, Resistencia). La EC se evalúa internamente y en alertas, y **no sustituye a Resistencia**.
- No filtres jerga a la pantalla del usuario: nada de `baseline`, `microciclo`, `índice comparable`, `confianza 0.25`, `objetivo 18–60`, `etapa fenológica`, `no accionable`. El vocabulario de bandas es: Crítico, Bajo, Óptimo, Alto, Ajuste leve.
- No declares ninguna capacidad productiva. Nopal no proyecta rendimiento, no cosecha, no estima tunas. Cortar una penca o retirar una tuna **no** cambia el stageId ni activa `harvest`.
- No hagas que BIO-G diagnostique. El lenguaje de sanidad es "condición compatible con…", "posible…", "revisa…", "confirma si…". Nunca "tu nopal tiene X".
- No toques los cultivos ya integrados. La integración es aditiva: no debe alterar granos, hortalizas, árboles ni las otras siete ornamentales.

---

## 8. Cómo quiero que trabajes

- Una fase a la vez. Al terminar cada una, `flutter analyze` y me muestras el diff.
- Si un dato del documento no te cuadra contra el código, **para y pregunta**. No lo resuelvas inventando.
- Cuando decidas algo que el documento dejó ambiguo (sobre todo las severidades condicionales de §2.3 y la poda de señales de la Fase 4), anótalo en un archivo `temp/nopal/DECISIONES_INTEGRACION.md` con la razón. Ese archivo lo reviso yo después.
