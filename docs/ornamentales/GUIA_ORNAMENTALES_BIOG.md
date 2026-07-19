# Guía de Ornamentales BIO-G

**Versión:** 2.0 · Julio 2026
**Sustituye a:** `Guia_Maestra_Integracion_Ornamentales_BIOG_v1.pdf` (puedes borrarlo: todo lo que valía está aquí)
**Estado:** documento vivo. Es la única fuente de verdad para integrar ornamentales.

---

## Parte 0 — Cómo usar este documento

Este documento hace tres cosas:

1. **Congela el contrato.** Lo que una ornamental NO puede romper. (Parte 3)
2. **Documenta cómo quedó el cactus**, que es la plantilla de referencia. (Parte 4)
3. **Da la receta** para meter la siguiente planta. (Parte 5)

Si vas a integrar una ornamental nueva: lee la **Parte 3** (contrato), copia el cactus
siguiendo la **Parte 5** (receta), y valida con la **Parte 6** (pruebas).

Si algo del contrato te estorba, **el problema es el contrato, no la planta**. Se discute
y se cambia aquí — nunca en el cultivo.

> **Por qué existe este documento.** El PDF original exigía un "Documento 00 — Estándar de
> Ornamentales" que congelara el contrato con el código existente. **Nunca se escribió.** Se
> saltó directo a los documentos del cactus, y sin ese candado la primera integración se
> desvió: inventó unidades propias, sustituyó tarjetas del dashboard, emitió claves de alerta
> que el motor compartido no reconoce (**el cultivo quedó mudo, sin una sola alerta**) y
> filtró jerga interna a la pantalla del agricultor (`N 66 · P 33 · K 86`,
> `Sin baseline comparable`, `Humedad crítico · objetivo 8–30%`).
> No fue mala fe: fue **la ausencia de un contrato**. Esto es ese contrato.

---

## Parte 1 — Qué es una ornamental en BIO-G

### 1.1 El problema

Una planta ornamental no encaja en los motores que ya existen:

- **Como cultivo anual** → generaría un ciclo falso que "termina". Un cactus no termina.
- **Como árbol frutal** → metería floración, cuajado, cosecha y rendimiento donde no hay.

### 1.2 La solución: es un árbol sin cosecha

La ornamental de mantenimiento es, arquitectónicamente, **un árbol al que le quitas la
cosecha**. El árbol ya demostró que un cultivo **no cíclico** cabe en el ecosistema sin
romperlo:

```
Se instala → echa raíz → crece → se mantiene ↔ descansa
                                    ↑
                        aquí se queda. Para siempre.
```

**`maintenance` NUNCA cierra el ciclo.** Puede durar años. Esa es la regla que define todo
lo demás.

### 1.3 Regla #0 — Las ornamentales NO son un ecosistema aparte

Una ornamental es **un cultivo de primera clase de BIO-G**, igual que el frijol. Se lee
igual, se clasifica igual, se alerta igual y se le habla igual al agricultor.

| Puede cambiar (biología) | NO puede cambiar (contrato) |
|---|---|
| Las etapas y sus nombres | Las unidades de los sensores |
| Los rangos objetivo (targets) | Las 4 tarjetas del dashboard |
| Los pesos del AgroScore | El vocabulario de bandas |
| Si tiene o no cosecha/rendimiento | Las claves de alerta |
| Los textos de cuidado | El motor de nutrición compartido |

---

## Parte 2 — El catálogo: 11 plantas, 4 modos de ciclo

### 2.1 Inventario oficial

| Planta | cropId | Subtipo | Modo de ciclo |
|---|---|---|---|
| **Cactus** ✅ | `crop_cactus` | Xerófita / suculenta | `establishment_maintenance` |
| **Suculenta** ✅ | `crop_succulent` | Hoja/tallo carnoso no cactáceo | `establishment_maintenance` |
| Sábila | `crop_aloe` | Suculenta perenne | `establishment_maintenance` |
| Maguey | `crop_agave` | Roseta perenne | `establishment_maintenance` |
| Nopal | `crop_nopal` | Xerófita perenne | `establishment_maintenance` |
| Helecho | `crop_fern` | Follaje | `establishment_maintenance` |
| Palma | `crop_palm` | Follaje perenne | `establishment_maintenance` |
| Rosal | `crop_rose` | Floración recurrente | `recurring_bloom` |
| Girasol | `crop_sunflower` | Anual de flor | `annual_ornamental` |
| Cempasúchil | `crop_marigold` | Anual de flor | `annual_ornamental` |
| Tulipán | `crop_tulip` | Bulbo estacional | `seasonal_bulb` |

✅ = integrada. El **cactus** es la plantilla; la **suculenta** es la primera que la
usó, y al hacerlo obligó a separar el MODO del CULTIVO:
`isEstablishmentMaintenanceCrop()` ya no es un alias de `isCactusCrop()`. Vive en
`lib/core/crops/ornamental/ornamental_crops.dart`, que despacha por planta
(etapas, textos, assets, targets) sin mezclar biología.

### 2.2 Los 4 modos de ciclo

| Modo | Plantas | Esqueleto | Regla clave |
|---|---|---|---|
| **`establishment_maintenance`** | cactus, suculenta, sábila, maguey, nopal, helecho, palma | instalación → raíz → crecimiento → mantenimiento ↔ reposo | El mantenimiento **no cierra** el ciclo |
| `recurring_bloom` | rosal | … → brote → botón → floración → posfloración → rebrote | La floración se repite **sin reinstalar** la planta |
| `annual_ornamental` | girasol, cempasúchil | siembra → … → floración → senescencia → fin | **Sí** tiene final. Puede reusar el reloj anual |
| `seasonal_bulb` | tulipán | bulbo → … → floración → senescencia → dormancia | La dormancia **no borra** el cultivo |

**El usuario elige una planta; BIO-G resuelve el modo.** La categoría "Ornamental" NO es un
motor único que trate igual a un cactus, un rosal y un tulipán. Comparten interfaces y
reglas de seguridad, **no el mismo reloj biológico**.

### 2.3 Capacidades por familia

| Familia | Rendimiento | Floración | Cierra ciclo |
|---|---|---|---|
| Xerófitas y follaje perenne | No | Opcional | **No** |
| Rosal | No | Sí, recurrente | **No** |
| Girasol / cempasúchil | No | Sí, estructural | Sí (senescencia) |
| Tulipán | No | Sí, estructural | No (entra en dormancia) |

**NINGUNA ornamental proyecta rendimiento, cosecha, kg/planta ni t/ha.**

### 2.4 Matriz de prioridades (arquitectónica, no agronómica final)

Sirve para saber **qué pesa** en cada planta. Los números exactos salen de la ficha técnica
de cada una.

| Planta | Agua | EC | NPK |
|---|---|---|---|
| Cactus / Suculenta | **Exceso ≫ déficit** | Alta | Baja-moderada |
| Sábila | Exceso alto; déficit moderado | Alta | Moderada |
| Maguey / Nopal | Exceso alto; sequía tolerada | Alta | Baja-moderada |
| Helecho | **Déficit** y aire seco pesan | Media | Moderada |
| Palma | Estabilidad y establecimiento | Media-alta | Moderada |
| Rosal | Déficit pesa en brote/flor | Media | Moderada-alta |
| Girasol / Cempasúchil | Déficit por etapa | Media | Alta en vegetativo/flor |
| Tulipán | Exceso en bulbo; déficit en crecimiento | Media-alta | Moderada |

> ⚠️ **Compartir esqueleto NO es compartir biología.** El helecho y la palma usan el mismo
> `lifecycle mode` que el cactus, pero **jamás** sus bandas de humedad. Un helecho con los
> targets del cactus se muere de sed.

### 2.5 Convenciones de IDs y prefijos

```
cropId:            crop_cactus
CropKey:           cactus
profilePrefix:     CA
profileId general: ca_skip
profiles:          ca_01_desert_container, ca_02_barrel_biznaga, …
```

| Planta | Prefijo | Planta | Prefijo |
|---|---|---|---|
| Cactus | `CA` | Nopal | `NO` |
| Suculenta | `SU` | Palma | `PA` |
| Sábila | `SA` | Rosal | `RO` |
| Maguey | `MG` | Girasol | `GI` |
| Helecho | `HE` | Cempasúchil | `CE` |
| Tulipán | `TU` | | |

**Un prefijo liberado no se cambia** sin migración y pruebas explícitas.

---

## Parte 3 — EL CONTRATO (congelado)

Esto es lo que la primera integración rompió. **No se negocia por planta.**

### 3.1 Unidades reales

Todas las métricas viajan en las **mismas unidades que los 23 cultivos existentes**.
Referencia viva: `lib/crops/bean/bean_universal_profile.dart` y `lib/models/biog_telemetry.dart`.

| Métrica | Unidad | Referencia (frijol) |
|---|---|---|
| Humedad | **%** (0–100) | 18 – 82 |
| Temperatura de suelo | **°C** | 12 – 32 |
| pH | pH | 5.3 – 7.8 |
| EC | **mS/cm** | 0.4 – 1.8 |
| Resistencia | **MPa** | 0.0 – 2.0 |
| N / P / K | **mg/kg** | según cultivo |

#### PROHIBIDO: los "índices comparables"

El documento original del cactus especificaba `ecComparableIndex`,
`resistanceComparableIndex` y `n/p/kComparableIndex`, todos con *baseline = 100*.

**Descartado.** Y conviene entender por qué, porque el razonamiento del doc **era correcto**:

- La sonda BIO-G no entrega mg/kg de laboratorio. **Cierto.**
- La resistencia medida en tezontle o perlita no significa lo mismo que en un suelo
  arcilloso de parcela. **Cierto.**
- La EC depende del método de medición (PourThru, 1:2, SME, sonda directa). **Cierto.**

**El problema no era la ciencia: era que ese sistema exige una infraestructura que BIO-G no
tiene** (baseline por dispositivo, método declarado, ventanas comparables, historial).

Codex implementó los **targets** de ese sistema sin construir el **sistema**. Los rangos
quedaron en escala de índice (EC 40–160, resistencia 40–190) mientras el sensor mandaba
mS/cm y MPa. Nada podía clasificarse, y hubo que taparlo con `"Sin baseline comparable"`.

> **Regla:** si una métrica no se puede interpretar con **unidades reales y un rango
> absoluto**, **no se muestra**. No se inventa una escala nueva.

### 3.2 UI — Las 4 tarjetas del dashboard son fijas

| Tarjeta | Campo | Unidad |
|---|---|---|
| Humedad | `soilMoisturePct` | % |
| Temp suelo | `soilTempC` | °C |
| pH | `ph` | pH |
| **Resistencia** | `resistance` | **MPa** |

**Ninguna ornamental sustituye una tarjeta por otra.** El cactus reemplazó Resistencia por
"EC" — prohibido. Un agricultor entiende *"suelo apretado"*; **no entiende
electroconductividad**.

La EC **sí se evalúa** (alimenta el AgroScore y las alertas de sales), pero **no ocupa una
tarjeta**. Si algún día se quiere mostrar, se añade una quinta tarjeta **para todos los
cultivos**, no solo para las ornamentales.

### 3.3 Vocabulario de bandas — fijo

Toda métrica se clasifica **solo** con `AgroBand` (`lib/core/agro/agro_types.dart`):

```
Crítico · Bajo · Óptimo · Alto · Ajuste leve
```

**Prohibido inventar etiquetas de estado.** Casos reales de lo que NO se hace:

| ❌ Lo que hizo el cactus | ✅ Lo correcto |
|---|---|
| `Humedad crítico · objetivo 8–30%` | `Crítico` |
| `Sin baseline comparable` | `Óptimo` / `Alto` / … |
| `Lectura orientativa` | la banda que toque |
| `No accionable` | la etiqueta de prioridad del nutriente |

### 3.4 Claves de alerta — canónicas

Las ornamentales emiten **exactamente** las claves que entiende
`AlertsEngine.buildFromSuggestedKeys()` (`lib/core/agro/alerts_engine.dart`):

```
soilMoisture.critical | soilMoisture.low | soilMoisture.high
soilTemp.critical     | soilTemp.low     | soilTemp.high
ph.critical           | ph.low           | ph.high
ec.critical           | ec.low           | ec.high
resistance.critical   | resistance.low
airTemp.frost | airTemp.cold | airTemp.heat | airTemp.extreme_heat
airHumidity.high | airHumidity.critical
npk.{n|p|k}.{action|review|high_priority|medium_priority|possible_excess|review_accumulation}
stage.fallback | stage.unknown
```

> **El bug que esto previene:** el cactus emitía `cactus.maintenance.moisture.critical`. El
> `AlertsEngine` no reconoce esa clave, **la descarta en silencio**, y el cultivo **no generó
> una sola alerta en toda su vida**. No truena: simplemente no avisa. Nadie lo notó.

**Prueba obligatoria:** ninguna clave sugerida puede llevar el prefijo del cultivo.

### 3.5 El motor

El motor de una ornamental es un **espejo estructural** de
`lib/core/agro/bean_agro_score_engine.dart`. Debe:

1. Clasificar las **5** métricas de suelo (humedad, temp, pH, EC, resistencia) con bandas reales.
2. Interpretar N, P y K con `NutrientRecommendationEngine.interpret()`.
3. Emitir **claves canónicas** y construir alertas con `AlertsEngine`.
4. Devolver un `AgroEvalResult` completo (métricas + alertas + score).

`StageTargets` y `StageWeights` por etapa. **Los pesos de cada etapa suman 1.00.**

**Ninguna ornamental escribe su propio constructor de alertas ni su propio generador de
eventos.** Usa el `EventEngine` compartido.

### 3.6 NPK

Orden de interpretación:

```
Humedad → Temperatura → EC → pH → Resistencia → NPK
```

- El agua **manda**. El NPK entra con peso bajo en el `AgroScore`.
- Una lectura baja de N, P o K **no autoriza fertilizar** por sí sola.
- La baja demanda de una ornamental se modela con **caps bajos** (`NpkCaps`) y **pesos
  bajos** (`StageWeights`) — **no** anulando la interpretación ni escribiendo
  *"No accionable"*.
- En establecimiento y reposo el NPK pesa poco. En crecimiento activo, sube.

### 3.7 Mensajes: permitidos y prohibidos

**Permitido**
- *"El sustrato todavía conserva humedad. No riegues por ahora."*
- *"El sustrato está apretado. La raíz batalla y el agua se queda junto al cuello."*
- *"Revisa que el agua salga bien y que el sustrato no se quede empapado."*

**Prohibido**
- ❌ *"Tu cactus tiene pudrición."* → no se diagnostica una enfermedad
- ❌ *"Agrega exactamente 450 ml."* → no se prescriben volúmenes
- ❌ *"Fertiliza porque N está bajo."* si la humedad o la EC invalidan la lectura

#### Jerga PROHIBIDA en la UI

Esta lista sale del post-mortem del cactus. **Ninguna de estas palabras le llega al agricultor:**

```
baseline · objetivo · comparable · índice · confianza 0.25
microciclo · estado ornamental · condición ornamental
electroconductividad · no accionable · orientativa
seguimiento ornamental · etapa fenológica
N 66 · P 33 · K 86   (lecturas crudas como título)
```

Al agricultor se le habla de **agua, sol, frío, sustrato apretado y sales.**

---

## Parte 4 — Cómo quedó integrado el cactus (as-built)

Esta es la plantilla. Cópiala.

### 4.1 Mapa de archivos

```
lib/core/crops/cactus/
├── cactus_catalog.dart            Perfiles, etiquetas humanas, aliases, exclusiones
├── cactus_lifecycle.dart          Etapas, anclas, intenciones del wizard, capacidades
├── cactus_universal_profile.dart  StageTargets + StageWeights (UNIDADES REALES)
├── cactus_agro_score_engine.dart  Motor (espejo del de frijol)
├── cactus_crop_definition.dart    Implementa CropDefinition
├── cactus_stage_resolver.dart     Resuelve la etapa (fuente única, auto-reparable)
├── cactus_assets.dart             Iconos y hero images
└── cactus_risk_catalog.dart       Vocabulario de riesgos

lib/core/plant_health/catalog/cactus_syndromes.dart    Sanidad
lib/core/agro/npk_caps.dart                            Caps: N=60 · P=55 · K=220
lib/core/crops/catalog/crop_catalog.dart               Alta en el catálogo
lib/core/crops/crop_registry.dart                      Alta en el registry
test/core/cactus/cactus_integration_test.dart          Contratos
```

### 4.2 Flujo de datos, de punta a punta

```
Wizard (usuario elige)
    ↓  resolveCactusSetupStage()        ← FUENTE ÚNICA de la etapa
DeviceCropContext (persistido)
    ↓
CropRuntimeResolver
    ↓  CactusStageResolver.resolve()    ← etapa resuelta + días desde plantación
CropStageResult
    ↓  resolveCactusTargetsForProfile() ← StageTargets (unidades reales)
    ↓  CactusAgroScoreEngine.evaluate() ← bandas + NPK + claves canónicas
AgroEvalResult
    ↓
Dashboard · SeedsScreen · NPK · Notificaciones · PDF
```

**Regla de oro de este flujo:** las pantallas **NUNCA** leen `cropContext.ornamentalStageId`
directo. Siempre usan `runtime.stageResult`. Ese fue un bug real: la SeedsScreen leía el
campo crudo y se quedaba clavada en *"Etapa por confirmar"* aunque el usuario hubiera dado
la fecha.

### 4.3 Etapas del cactus — progresión de UNA SOLA PASADA

**Esto es lo que define a una ornamental de maceta.** No es un ciclo: es una vida que
avanza y se estabiliza.

```
Recién plantada → Echando raíz → Creciendo → Estable ──┐
   (0-14 d)        (15-84 d)     (85-365 d)  (>365 d)  │
                                                 ▲      │
                                                 └──────┘
                                          AQUÍ SE QUEDA PARA SIEMPRE
```

| ID | Nombre para el agricultor | Cómo se llega |
|---|---|---|
| `installation_establishment` | **Recién plantada** | fecha futura, o ≤ 14 días (28 si es columnar) |
| `root_establishment` | **Echando raíz** | 15 – 84 días (~12 semanas) |
| `active_growth` | **Creciendo** | 85 – 365 días. **Única etapa donde el NPK pesa de verdad** (wN 0.11) |
| `maintenance` | **Estable** | > 365 días, o "ya está plantada" sin fecha. **Terminal-abierto** |
| `rest` | **En reposo** | estacional (invierno). Solo por confirmación manual |
| `unknown` | Etapa por confirmar | último recurso; se auto-repara |

**Garantías (blindadas con tests):**

- **No hay reinicio.** Ninguna etapa puede volver a `installation_establishment`. Eso sería
  un ciclo, y una planta de maceta no vuelve a nacer.
- **`maintenance` es para siempre.** A 1, 5 o 20 años sigue Estable. No hay siguiente etapa.
- **No hay día terminal.** `expectedDaysToEnd = 0`, `stageProgressPct = null`,
  `windowsNow` vacío, `productiveState = null`.
- `maintenance` **sí** puede volver a `active_growth` o `rest` (una planta estable retoma
  crecimiento en su temporada). **Eso no es un reinicio**: es la misma planta, más vieja.

El sensor **no** decide que la planta "ya enraizó" ni "entró en reposo". Eso lo fija el
usuario o el ancla de fecha.

> ⚠️ **Bug histórico:** `active_growth` existía en el enum, tenía targets, pesos e imagen —
> pero **no había forma de llegar a ella**: la progresión saltaba de "Echando raíz" directo
> a "Estable". Era una etapa muerta. Cuando integres otra ornamental, **verifica que todas
> las etapas que declaras sean alcanzables.**

### 4.4 El wizard: SOLO dos preguntas

```
¿Qué tipo de cactus es?
   1. Cactus de maceta
   2. Biznaga o cactus barril
   3. Cactus columna u órgano
   4. Cactus agrupado o de varios tallos
   5. No sé / cactus general        ← SIEMPRE AL FINAL
```

**El genérico va hasta abajo.** Un menú que abre con "No sé" invita a no elegir. Sigue
siendo el `defaultProfileId`: si no eligen, cae ahí.

```
¿En qué estado está tu cactus?
   1. Lo voy a plantar      → icono ic_aun_no_siembro.png
   2. Ya está plantado      → icono ic_ya_sembrado.png
```

**Solo dos opciones.** Se eliminó "voy a cambiarlo de maceta": un cambio de maceta **no es
una forma de dar de alta una planta**, es mantenimiento de una planta que ya existe.
Producía el mismo contexto y confundía.

**Iconos del wizard, no imágenes de etapa.** El cactus usaba las imágenes fenológicas
(`cactus_stage_*.png`) como si fueran iconos de menú. Usa los mismos que el grano.

### 4.5 Qué ve el usuario

| Pantalla | Qué muestra el cactus |
|---|---|
| **Dashboard** | Humedad · Temp · pH · **Resistencia** · NPK · Riego · Tarjeta de estado · Eventos |
| **SeedsScreen** | Etapa · **Día N desde que la plantaste** · Cuidado · Prioridad · Score |
| **NPK** | N/P/K con bandas y recomendación — **mismo código que frijol, cero special-casing** |
| **Notificaciones** | Alertas reales del `AlertsEngine` compartido |
| **Sanidad** | `cactus_syndromes.dart` |
| **PDF** | Reporte compartido, **sin rendimiento** |
| **Rendimiento** | ❌ No existe. El botón lleva al estado de la planta |

---

## Parte 5 — Receta: cómo integrar la siguiente ornamental

Suponiendo `establishment_maintenance` (suculenta, sábila, maguey, nopal, helecho, palma).
**Deberían ser casi copiar-pegar del cactus. Si no lo son, algo se rompió en el contrato.**

### Paso 1 — Investiga la biología ANTES de tocar código
Necesitas: rangos de humedad, temperatura, pH, EC, resistencia y NPK **en unidades reales**.
⚠️ **No copies los del cactus.** Un helecho no es un cactus.

### Paso 2 — Catálogo (`<crop>_catalog.dart`)
- `cropId`, prefijo, perfiles con **etiquetas humanas** y aliases.
- El perfil general (`<xx>_skip`) va **AL FINAL** de la lista.
- **Nunca** muestres "SKIP" ni el `profileId` al usuario.
- Declara exclusiones (ej.: nopal → `crop_nopal`, no lo metas en cactus).

### Paso 3 — Ciclo de vida (`<crop>_lifecycle.dart`)
- Etapas + nombres **en cristiano** ("Echando raíz", no `root_establishment`).
- `CactusSetupIntentIds` → **dos** intenciones: plantar / ya plantada.
- `resolveCactusSetupStage()` → cópialo: es la **fuente única** de la etapa.
- Capacidades: `supportsYieldProjection = false`, `supportsHarvest = false`.

### Paso 4 — Targets (`<crop>_universal_profile.dart`)
- `StageTargets` en **unidades reales** (%, °C, pH, mS/cm, MPa, mg/kg).
- `StageWeights` por etapa. **Cada fila suma 1.00.**
- Rangos NPK explícitos (`nSoilPpmRange`, etc.).

### Paso 5 — Caps (`NpkCaps`)
Añade el `case` de tu planta. Bajos si es de baja demanda.

### Paso 6 — Motor (`<crop>_agro_score_engine.dart`)
Copia `cactus_agro_score_engine.dart`. Ajusta:
- Los castigos (`criticalPenalty`) según la matriz §2.4.
- Las etapas críticas (`severityBump`).
- Umbrales de aire.
**No toques** las claves de alerta: son canónicas.

### Paso 7 — Definición + registro
`<crop>_crop_definition.dart` → `CropKey` → `CropRegistry` → `CropCatalog`.

### Paso 8 — Resolver de etapa (`<crop>_stage_resolver.dart`)
Copia el del cactus. **Ojo con dos cosas:**
- Un `unknown` guardado **no cuenta** como etapa → se re-estima (auto-reparación).
- Rellena `daySinceSowing` con los días desde la plantación.

### Paso 9 — Assets
`assets/seeds/<crop>/` con las imágenes de etapa. **Declara la carpeta en `pubspec.yaml`**
(Flutter no incluye subcarpetas solo).

### Paso 10 — Wizard
Dos opciones de estado, iconos del wizard, genérico al final.
Conecta `bootstrap_gate.dart` (onboarding) y `configure_seed_wizard_screen.dart` (cuenta).
**Ambos deben usar `resolveCactusSetupStage()`** — si duplicas la lógica, se desincroniza.

### Paso 11 — Sanidad
`plant_health/catalog/<crop>_syndromes.dart` + alta en `PlantHealthRegistry` y
`PlantHealthStageAdapter`.

### Paso 12 — Pantallas
Añade la rama en `dashboard_presenter.dart` y `seeds_screen.dart`.
**Usa `runtime.stageResult`, nunca el campo crudo del contexto.**

### Paso 13 — Tests + `flutter analyze && flutter test`

> **Regla del PDF que sigue vigente:** *"Antes de crear archivos, inspecciona los patrones
> reales del repositorio y reutiliza las abstracciones existentes. No dupliques lo que ya
> existe."* Se ignoró en el cactus y salió caro.

---

## Parte 6 — Pruebas obligatorias

Plantilla viva: `test/core/cactus/cactus_integration_test.dart`.

| # | Prueba | Qué previene |
|---|---|---|
| 1 | EC < 5 (mS/cm), resistencia < 3 (MPa), NPK en mg/kg | Los índices comparables |
| 2 | Cada etapa suma 1.00 en pesos | Scores rotos |
| 3 | Las 5 métricas se clasifican (ninguna `unknown` con dato válido) | Métricas ocultas |
| 4 | Ninguna clave de alerta empieza con el nombre del cultivo | **El cultivo mudo** |
| 5 | Una lectura mala produce `alerts` NO vacío | El cultivo mudo |
| 6 | N, P y K reciben `priorityLabel` no nulo | El NPK anulado |
| 7 | `supportsYieldProjection == false`; `maintenance` no cierra ciclo | Rendimiento falso |
| 8 | Ningún texto de UI contiene la jerga prohibida (§3.7) | La jerga filtrada |
| 9 | Catálogo, registry y aliases resuelven | Identidad rota |
| 10 | El perfil general va **al final** de la lista | Menú que abre con "No sé" |
| 11 | "Ya está plantada" resuelve a una etapa **real**, nunca `unknown` | "Etapa por confirmar" eterna |
| 12 | Un contexto guardado con `unknown` **se auto-repara** | Plantas clavadas para siempre |
| 13 | **Todas** las etapas declaradas son **alcanzables** | Etapas muertas (le pasó a `active_growth`) |
| 14 | Ninguna etapa vuelve a la de instalación | **Reinicio de ciclo** |
| 15 | A 1, 5 y 20 años la planta sigue en `maintenance` | Que "termine" sola |

**Prueba de oro del modo `establishment_maintenance`:**
> Una planta plantada hace **20 años** sigue en `maintenance`, no marca fin de ciclo, no
> reinicia la progresión y no proyecta cosecha.

---

## Parte 7 — Decisiones que tomamos (y por qué divergen del PDF)

El PDF original era bueno. Estas son las cuatro cosas donde **decidimos distinto**, con la
razón, para que nadie las revierta por accidente dentro de tres meses.

### 7.1 Índice comparable (baseline = 100) → **DESCARTADO**
Ver §3.1. Científicamente defendible, pero exige infraestructura que no existe. Se usan
unidades reales con rangos absolutos, como los otros 23 cultivos.

### 7.2 Microciclo hídrico → **DESCARTADO**
El PDF proponía una segunda capa (`recently_watered`, `draining`, `drying`,
`prolonged_wet`…) con un `HydricBaseline` por dispositivo: punto seco/húmedo, tiempo normal
de secado, detección de anomalías.

**Es una buena idea y se descarta a propósito. No reintroducir sin aprobación explícita.**

- Exige **baseline e historial por dispositivo** que hoy no existen.
- En el cactus se persistió el enum **sin construir el motor**: el estado quedaba en
  `unknown` para siempre y la UI mostraba eternamente *"Patrón por aprender · confianza
  baja"*. Una tarjeta muerta.
- Decisión de producto: **todo el ecosistema se comporta igual**. El agua se interpreta con
  la lectura real de humedad contra los targets de la etapa, como en frijol.

**Lo que se pierde, asumido:** BIO-G no dirá *"esta maceta normalmente tarda 4 días en
secarse y ahora tardó 9"*. Sí dirá que la humedad está **Alta** o **Crítica**, que es lo que
dispara la alerta que de verdad importa (pudrición por exceso de agua).

**Si algún día se retoma:** se construye primero el `HydricBaseline` y su motor, se valida
con hardware real, y **sólo entonces** se enciende la UI. **Nunca al revés.**

*(Blindado con un test: si alguien pone `supportsHydricCycle = true`, truena.)*

### 7.3 "Voy a cambiarlo de maceta" → **ELIMINADO**
No es una forma de dar de alta una planta. Es mantenimiento de una planta que ya existe.
Producía el mismo contexto `planted` y confundía al usuario. Los contextos viejos con
`repot` se leen como "ya está plantado".

### 7.4 Fecha antigua → **Estable** (antes: `unknown`)
El doc decía *"la antigüedad no demuestra una etapa biológica"*. Cierto en teoría, pero en
la práctica dejaba al usuario en **"Etapa por confirmar" para siempre**. Si alguien dice
*"ya está plantado"* y lo plantó hace dos años, **está estable**. Eso es justo lo que acaba
de declarar.

---

## Parte 8 — Anti-patrones (post-mortem del cactus)

| Lo que se hizo | Lo que se debió hacer |
|---|---|
| Inventar una escala de índice para EC/resistencia | Usar mS/cm y MPa con rangos propios de la planta |
| Sustituir la tarjeta Resistencia por "EC" | Dejar las 4 tarjetas y evaluar la EC por dentro |
| Emitir claves de alerta `cactus.*` | Emitir claves canónicas |
| Escribir un generador de eventos propio | Usar el `EventEngine` compartido |
| Persistir un microciclo que nadie calcula | No mostrar lo que no se computa |
| Anular el NPK con *"No accionable"* | Interpretarlo con caps y pesos bajos |
| Leer `cropContext.ornamentalStageId` crudo en la UI | Usar `runtime.stageResult` |
| Duplicar la lógica de etapa en dos wizards | Una fuente única (`resolveCactusSetupStage`) |
| Declarar `supportsHydricCycle = true` sin motor | No declarar capacidades que no existen |
| Filtrar jerga interna a la UI | Hablar de agua, sol, frío y sustrato |
| Escribir 5 documentos sin el contrato | Escribir **este** documento primero |

---

## Parte 9 — Riesgos y deuda técnica conocida

| Riesgo | Control |
|---|---|
| Reutilizar el motor anual | Modo de ciclo + resolver ornamental propios |
| **Copiar los targets del cactus a otra planta** | Compartir interfaz, **NO** rangos |
| Forzar rendimiento | `supportsYieldProjection = false` |
| Alertar por un umbral puntual | Valor + banda + etapa |
| Diagnosticar por sensor | Lenguaje de riesgo y confirmación visual |
| Refactor global | Integración **aditiva**, diffs pequeños |

### Deuda técnica abierta

1. **Supabase no tiene columnas ornamentales.** La etapa de las ornamentales sigue viajando
   en `perennial_state_id` / `perennial_anchor_date`. Con la suculenta integrada el puente
   **ya distingue por `crop_id`** (cada planta vuelve a su propio dominio al decodificar),
   así que funciona para las dos. **Sigue pendiente crear columnas ornamentales propias**
   antes de que un perenne futuro choque ahí.
2. **Los targets del cactus son defaults de ingeniería**, no resultado de un ensayo con la
   sonda BIO-G en sustrato real. Son defendibles y coherentes, pero **deben validarse con
   hardware**.
3. **La crítica de fondo del doc original sigue en pie:** la resistencia en mezcla mineral y
   el NPK de una sonda barata no son medidas de laboratorio. Se asume ese error a cambio de
   un sistema coherente que **hoy sí le habla al agricultor**.
4. Validar el sensor de resistencia en perlita, tezontle, pómez y mezclas de maceta.
5. Validar posición y profundidad del sensor en macetas chicas.

---

## Parte 10 — Fuera de alcance (v1)

- Diagnóstico visual automático de plagas o enfermedades.
- Dosis exactas de agua en mililitros o litros.
- Recetas de fertilización por marca o producto.
- Cactus epífitos/tropicales dentro del perfil desértico (van aparte).
- Producción de tuna, penca, fibra o savia en nopal/maguey.
- Rendimiento de flor comercial en rosal, girasol, cempasúchil o tulipán.
- Reescritura del motor de árboles, granos u hortalizas.

> **Criterio de seguridad:** BIO-G prefiere una recomendación **conservadora y explicable**
> antes que una predicción llamativa pero no sustentada.
> **BIO-G no prefiere adivinar a equivocarse.**

---

## Parte 11 — Orden de integración recomendado

```
Cactus ✅  →  Suculenta ✅  →  Sábila  →  Maguey  →  Nopal
              (xerófitas: casi copiar-pegar del cactus)

           →  Helecho  →  Palma
              (follaje: mismo esqueleto, targets MUY distintos)

           →  Rosal
              (recurring_bloom: motor nuevo, floración que se repite)

           →  Girasol  →  Cempasúchil
              (annual_ornamental: pueden reusar el reloj anual)

           →  Tulipán
              (seasonal_bulb: el más distinto, déjalo al final)
```

**Las tres xerófitas siguientes son la prueba del estándar.** Si no salen casi
copiar-pegar, algo está mal **aquí**, no en la planta.

---

## Anexos

- **`PLANTILLA_NUEVA_ORNAMENTAL.md`** — **empieza aquí para meter una planta nueva.** Dice
  qué documentos hay que investigar (son **3**, no 5), con qué formato, y trae el prompt de
  investigación listo para copiar.
- **`05_Nutricion_NPK_y_Targets_Cactus_v2.md`** — los números exactos del cactus (targets,
  pesos, castigos). Úsalo como referencia de formato para la ficha de la siguiente planta.
- **Código de referencia** — `lib/core/crops/cactus/` es la plantilla ejecutable. Cuando
  este documento y el código no coincidan, **gana el código**, y este documento se corrige.

---

*BIO-G — Escuchar a la tierra.*
