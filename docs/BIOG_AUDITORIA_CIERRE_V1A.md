# BIO-G · Auditoría de cierre V1-A

**Consolidación de arquitectura previa al hardware.** 10 de agosto de 2026.

> Este documento existe para una segunda auditoría. Cada sección dice qué se
> encontró, qué se cambió, qué **no** se cambió y por qué. Lo que quedó fuera
> está en §16 y §17, no escondido en el texto.

---

## 1 · Resumen ejecutivo

Se recorrió el árbol de trabajo real (no `HEAD`: incluye lo no commiteado) desde
ocho frentes independientes, se contrastó cada sospecha contra el código, y
después se pasaron **dos rondas adversariales** —una de compilación y otra de
regresiones— sobre el diff completo. Las dos rondas encontraron fallos reales en
mi propio trabajo; están corregidos y documentados aquí.

**24 archivos de `lib/` modificados, 3 de pruebas (1 actualizado, 2 nuevos). Cero
archivos borrados. Cero cambios de estética. Cero features nuevas. Cero cultivos
nuevos. Básico/Pro sigue sin cablear.**

### Lo que de verdad estaba mal

| # | Hallazgo | ¿Era cierto? |
|---|---|---|
| 1 | Historial reconstruye desde la última lectura e ignora la persistencia | **Sí**, y además pintaba las horas en UTC |
| 2 | Campana y Notificaciones no comparten fuente | **Sí**, y la campana estaba encendida permanentemente por diseño accidental |
| 3 | `EventEngine` decide riego por su cuenta | **Sí**, y contradecía al motor en Historial, campana e informe PDF |
| 4 | `RecommendationRecorder` ignora el `bool` de `save()` | **Sí**, más dos fallos peores que nadie había visto |
| 5 | `FertilizationPlanner` asume campo abierto | **Sí**, pero el wizard **sí** pregunta la escala; el nulo viene de otro sitio |
| 6 | NPK dice "lectura real" | **Sí**, 12 cadenas en un solo archivo |
| 7 | Borrado de cuenta olvida `RecommendationStore` | **Sí**, y otros 9 almacenes |
| 8 | Básico/Pro interfiere | **No.** Módulo inerte, verificado |
| 9 | Los adaptadores tragan errores y la cola pierde datos | **Sí**, demostrado, y el propio repo lo documentaba |
| 10 | Existe un respaldo a Los Mochis | **Sí**, y uno peor a CDMX que sí llegaba al motor |
| 11 | Telemetría | **Correcta.** No se tocó |
| 12 | Dos motores de agua compitiendo | **No.** Uno vivo y una capa preparada sin cablear |

### Estado después de la intervención

Cada dato tiene una fuente. El Historial tiene memoria. La campana representa
solo lo que BIO-G decidió comunicar. El riego tiene una autoridad única. Las
recomendaciones no se dan por auditadas sin estarlo. La app ya no inventa
ubicación. Los datos offline no desaparecen en silencio. NPK habla de
estimación sin dejar de ser útil.

**Lo que NO puedo afirmar: que compile y que las pruebas pasen.** Ver §15.

---

## 2 · Historial

### Problema

Los eventos aparecían todos con la misma hora (`11:52 PM` repetido).

### Causa raíz — dos causas, no una

**(a) Historial no leía el historial.** `HistoryScreenPresenter.buildAgronomicEvents`
tomaba `runtime.live.timestamp` como referencia y reconstruía la lista entera con
`EventEngine`. `EventEngine.build` fija `final now = input.timestamp` y estampa
ese mismo valor en las ~33 construcciones de evento del archivo. Resultado:
*"qué eventos existirían con el estado actual"*, no *"qué ocurrió"*.

Mientras tanto, `CropEventLocalStorage` llevaba tiempo guardando cada evento con
su hora, su dispositivo y su dueño — y **`load()` no tenía un solo llamador**.
Memoria de escritura pura.

**(b) Las horas se pintaban en UTC.** `history_events_list.dart` y
`notifications_screen.dart` formateaban `event.timestamp` sin `.toLocal()`. Las
gráficas de esa misma pantalla sí convertían, así que el eje de tiempo y la lista
de eventos iban desfasados seis horas.

### Solución

- `widgets/history/history_events_list.dart` y `screens/notifications_screen.dart`: `.toLocal()`.
- `screens/history_screen.dart`: `_loadPersistedEvents()` lee de `CropEventLocalStorage`
  con guarda por `deviceId|userId`, filtra por la ventana de rango elegida,
  deduplica por `dedupKey` contra el lote vivo y ordena descendente.
- `services/biog/events/crop_event_recorder.dart`: `store.currentUserId` entra en
  la firma de estado. Antes, la primera lectura podía guardarse bajo un dueño
  provisional y `load(userId:)` no la encontraba nunca.

### Cómo queda el flujo

```
lectura → CropEventRecorder → EventEngine → CropEventLocalStorage (hora real)
                                          ↘ NotificationDispatcher (política)

Historial = lote vivo (estado actual)  +  persistido (lo ya ocurrido)
```

El lote vivo va primero, así que **las tres tarjetas visibles no cambian**. Lo
persistido aparece en "Ver más".

### Hasta dónde llega el arreglo — dicho sin adornos

`EventEngine` sigue estampando **un solo timestamp a todo el lote**. Lo persistido
conserva la hora de la lectura que lo generó, con granularidad de una hora por
`tipo+métrica+etapa` (así es el `dedupKey`). Es decir: **memoria real entre
lecturas, no dentro de una lectura**. Dos eventos nacidos de la misma lectura
comparten hora, y eso es correcto — nacieron a la vez.

Lo que ya no ocurre es que eventos de días distintos aparezcan con la hora de
ahora. Reescribir `EventEngine` para que cada regla lleve el punto de historial
que la dispara es un cambio grande y **no se hizo**: queda en §17.

---

## 3 · Eventos y notificaciones

### Fuente de verdad anterior — había tres

| # | Origen | Consumidor |
|---|---|---|
| 1 | `NotificationDispatcher._outbox` (persistido, con política) | solo `unreadCount` del Panel |
| 2 | `HistoryScreenPresenter.buildAgronomicEvents` con telemetría | Historial |
| 3 | `_buildDashboardEvents` **sin** telemetría | campana, `NotificationsScreen`, Recomendaciones |

2 y 3 competían: mismo motor, entradas distintas. La 1 —la única legítima para la
campana— estaba prácticamente desconectada.

**El síntoma exacto:** `hasNotifications: unreadCount > 0 || viewData.events.isNotEmpty`.
`EventEngine` **siempre** emite un evento de contexto (`genericMode` o
`cropActivated`), así que la segunda mitad era verdadera casi siempre y la campana
vibraba sin parar. Y esos eventos son `severity: info`, justo los que el umbral
por defecto (`cautionAndAbove`) nunca deja entrar a la bandeja. **La campana se
encendía precisamente por avisos que tenían garantizado no existir.**

Además, `markRead` / `markAllRead` / `dismiss` existían y **no los llamaba nadie**:
`unreadCount` solo podía crecer.

### Fuente de verdad nueva

**`NotificationDispatcher` es la única fuente de la campana.** `NotificationsScreen`
tiene ahora dos entradas explícitas:

- `NotificationsScreen(dispatcher:)` — la campana. Panel y bandeja, misma fuente.
- `NotificationsScreen.events(events:)` — el "Ver más" del Historial, que muestra
  **eventos**, porque el Historial solo pinta tres y necesita una vía para verlos
  todos.

Comparten render; difieren en criterio de inclusión. Eso es exactamente la
distinción del Fundacional.

### AgronomicEvent vs BiogNotification

| | Evento | Notificación |
|---|---|---|
| Qué es | algo ocurrió | BIO-G decidió avisar |
| Dónde vive | `CropEventLocalStorage` | `biog_notification_outbox_v1` |
| Quién filtra | nadie | `NotificationPreferences.shouldDeliver` |
| Identidad | `dedupKey` | `deviceId\|dedupKey` |

**Historial ⊇ campana, por diseño.** *"El suelo regresó al rango óptimo"* es
evento y no notificación. Eso ya funcionaba en el core; lo que faltaba era que la
UI lo respetara.

**Trazabilidad notificación → evento: ya existía y no hubo que inventarla.**
`BiogNotification.id = '${deviceId}|${event.dedupKey}'` es la misma llave con la
que el evento queda archivado. No se tocaron los modelos.

### unreadCount, markRead, persistencia

- `unreadCount` = notificaciones con `state != read && != dismissed`.
- Visitar la bandeja la marca leída: `hydrate()` y luego `markAllRead()` en `initState`.
- Persistencia en `SharedPreferences`, rehidratada al enlazar usuario, purgada al salir.

**Dos fallos que introduje aquí y corregí tras la revisión:**

1. `hydrate()` ponía `_hydrated = true` **antes** de su primer `await`, así que no
   servía como barrera: `markAllRead()` podía correr sobre una bandeja vacía y
   `_persist()` escribía `[]` encima del archivo. **Se perdía la bandeja entera.**
   Corregido cacheando el futuro (`_hydration ??= _hydrateOnce()`) y añadiendo un
   early-return en `markAllRead()` cuando no hay nada que marcar.
2. El "Ver más" del Historial apuntaba a la bandeja, que tiene menos elementos.
   Como el Historial solo pinta tres, **toda la rehidratación quedaba invisible**.
   Corregido con el constructor `.events`.

---

## 4 · Riego

### Dónde había decisiones duplicadas

`EventEngine._shouldRecommendIrrigation` era literalmente:

```dart
return moistureBand == AgroBand.low || moistureBand == AgroBand.critical;
```

Y era **estructuralmente incapaz** de saber otra cosa: `EventEngineInput` no tenía
ni un campo de clima, pronóstico, lluvia, vigencia ni confianza. No es que
ignorara la lluvia: no podía verla.

**La contradicción, reproducible.** Maíz vegetativo, humedad 18 % (objetivo 25–40),
pronóstico 80 % y 9 mm en 24 h:

- `IrrigationEngine` → veto por lluvia → `esperar` → *"Espera: se espera lluvia"*.
- `EventEngine`, misma lectura → banda `low` → *"Riego recomendado"*, `caution`,
  que pasa el umbral por defecto y **entra a la campana y al Historial**.

Tercera superficie: `AlertsEngine` alimentaba el informe rápido con *"Se recomienda
riego inmediato"* y *"Considera programar riego en las próximas 24 horas"* — en el
mismo PDF donde el motor decía esperar.

El Panel y Recomendaciones ya estaban limpios (`engineDrivesCard`, filtro `_isWater`).
Lo roto era todo lo demás.

### Qué motor quedó como autoridad

**`IrrigationEngine`, sin tocarlo.** Se preservan íntegros el orden de vetos, la
degradación `regar→revisar` bajo confianza mínima, `datosInsuficientes` como
no-recomendación, `validUntil` y la evidencia.

### Cómo consume EventEngine la decisión

`EventEngineInput` recibe un `IrrigationDecision?` opcional:

```dart
if (input.isGenericMode) return false;
final decision = input.irrigationDecision;
if (decision == null) return false;          // callar, no deducir
return decision.action == IrrigationAction.regar;
```

- **Severidad desde `decision.urgency`**, no desde la banda. Una banda crítica con
  lluvia encima no es una urgencia crítica.
- `metadata` guarda `decisionAction`, `decisionUrgency` y `engineVersion`.
- `AlertsEngine`: los dos textos describen el riesgo y remiten al Panel; ya no
  ordenan ni ponen plazo.
- `event_engine.dart` humedad baja: *"Conviene revisar la retención de humedad
  del suelo"* en lugar de *"revisar riego"*.

### El puente al registro en segundo plano

El coordinador vive en el estado del Panel; el registro corre con cada lectura sin
pantalla de por medio. `BioGStore` hace de puente:

- `publishIrrigationDecision(d)` — la llama el Panel en su `build`.
- `irrigationDecisionAt(now)` — **la única regla de vigencia**, usada por el
  Historial y por el registro. Si cada uno aplicara la suya, volveríamos a tener
  dos verdades.
- Se limpia en `unbindUser()`: la decisión es del usuario que sale.

**Tres carreras reales que la revisión encontró y están corregidas:**

1. `decisionFor` **recalcula en cada build** con `decidedAt = now`. Disparar el
   registro comparando por hora habría hecho un **bucle infinito**
   (registro → la bandeja notifica → el Panel repinta → hora nueva → registro…).
   Se compara por `BioGStore.irrigationDecisionKey` = `action|urgency`: contenido,
   no hora.
2. El orden real es lectura → registro **ya** → Panel repinta en el frame
   siguiente. La primera lectura se procesaba sin decisión y se daba por hecha.
   Ahora la llave entra en la firma de estado y `publishIrrigationDecision`
   relanza el registro cuando el contenido cambia.
3. El cerrojo `_running` descartaba en silencio justo esa segunda llamada. Ahora
   se anota en `_pendingRerun` y se atiende al terminar.

El relanzamiento va en `scheduleMicrotask`: `recordFromStore` hace trabajo
síncrono antes de su primer `await` y no debe entrar en la ruta de pintado.

---

## 5 · NPK

Todo el absolutismo vivía en **un solo archivo**. Ni el Panel, ni el PDF, ni el
historial, ni los motores decían "real" sobre nutrientes.

| Antes | Después |
|---|---|
| `Lectura real de N disponible.` | `Nitrógeno disponible estimado por sensor.` |
| `Lectura real de N en pre-siembra.` | `Nitrógeno disponible estimado en pre-siembra.` |
| ídem P y K | ídem |
| `Lectura real de nitrógeno del suelo. Asigna un cultivo para convertirla…` | `Nitrógeno disponible estimado por sensor. Asigna un cultivo para convertirlo…` |
| `Lectura actual de nitrógeno del suelo.` (rama sembrada) | `Nitrógeno disponible estimado por sensor.` |
| `'Lectura real'` ×3 (chip del gauge) | `'Estimado'` ×3 |

**Archivo:** `lib/screens/npk/npk_screen.dart`.

**Cero lenguaje prohibido**, ni antes ni ahora: no hay "pendiente de validación",
"confirme en laboratorio" ni "no confiable" en la ruta de nutrientes. Los ~30
aciertos de "laboratorio" del repo están en `plant_health/catalog/*`, que es
diagnóstico de enfermedades — contexto legítimo y distinto.

El chip pasa de 12 a 8 caracteres, así que no hay riesgo de desbordar el pill.

**Bug colateral corregido en el mismo archivo:** `_resolveRuntimeWeights(dynamic runtime)`
llamaba a `runtime.weights`, miembro que `CropRuntimeSnapshot` no tiene. El
`catch (_) {}` se tragaba un `NoSuchMethodError` **en cada build** y `weights`
llegaba siempre nulo. Sustituido por `const StageWeights? weights = null` con la
deuda declarada. Runtime idéntico; desaparece la excepción por frame.

---

## 6 · Auditoría de recomendaciones

### Cómo se guardan

`IrrigationCoordinator.sync` → `RecommendationRecorder.recordIrrigation` →
`RecommendationRecord.fromIrrigationDecision` → `RecommendationStore.save`
(SQLite `biog_recommendations.db`, `INSERT OR IGNORE`).

### Qué ocurre si falla SQLite — tres fallos, no uno

**F1 (el denunciado).** `await _store.save(record); _lastRecordedId = record.id;`
El `bool` se descartaba. SQLite falla → se marca igual → la siguiente llamada sale
por el dedup → **nunca se reintenta**.

**F1b (peor, y nadie lo había visto).** `save()` devolvía `return inserted > 0`, y
con `INSERT OR IGNORE` un duplicado legítimo también da 0. La corrección ingenua
(`if (ok) _lastRecordedId = ...`) habría **desactivado el dedup para siempre**.
Había que arreglar la semántica, no el sitio de la llamada.

**F2 (amplificador).** `static Future<Database>? _dbFuture` cacheaba un futuro
**rechazado** para toda la vida del proceso. Combinado con F1: toda la sesión
marcada como auditada, sin una sola fila, sin una señal.

### Correcciones

- `save()` significa ahora **"la fila está presente"**: si `inserted == 0`,
  consulta por `id` y devuelve `true` si ya existía. `false` solo cuando de verdad
  no está.
- `_db` descarta el futuro fallido y `rethrow`, con `identical()` para no anular
  una reapertura válida en vuelo.
- `_lastRecordedId = saved ? record.id : null;`

**El reintento sale gratis:** al no marcar el id, el siguiente `sync` lo reintenta.
El coordinador sincroniza en cada cambio de estado y al menos cada 15 minutos por
su `timeBucket`. No hizo falta cola, backoff ni máquina de reintentos.

### Qué evidencia se conserva

`id`, `readingId`, `kind`, `issuedAt`, `deviceId`, `userId`, `headlineEs`,
`detailEs`, `action`, `urgency`, `confidence01`, `validUntil`,
`requiresConfirmation`, `requiresHumanReview`, `stageKey`, `stageLabel`, `cropId`,
`cropLabel`, `varietyId`, `varietyAlias`, `catalogVersion`, `metrics`
(solo `soilMoisture`), `weather`, `reasons`, `limitations`, `engineVersion`,
`schemaVersion`, `extra['evidence']`.

**Huecos declarados:** `userResponse` y `respondedAt` **siempre** vacíos (nadie
llama a `respond()`); `parcelLat/Lon` pueden llegar nulos en los primeros
registros; `metrics` solo lleva humedad.

### Cobertura

Solo riego. Nutrición, sanidad y rendimiento **no** se auditan. La infraestructura
existe (`RecommendationKind.fertilization` está definido, `BioGEngineVersions.fertilization`
también y sin usar) y basta con una fábrica análoga — pero **no es parte de esta
intervención**: primero había que hacer confiable lo que ya existe. Queda en §17.

---

## 7 · Offline / sincronización

### El bug

El propio repositorio lo documentaba en `telemetry_ingest_service.dart:17-21`:
*"evita el defecto que ya existe en la cola de contexto de cultivo, donde los
adaptadores tragan el error con `catch (_) {}` y la operación se descarta al
primer intento, dejando el backoff como código inalcanzable."* Verificado: exacto.

El contrato de la cola es **la ausencia de excepción**:

```dart
try { await _handler(op); }              // éxito: la operación sale
catch (e) { remaining.add(op.reschedule(...)); }
```

Y los cuatro métodos que la cola invoca eran `Future<void>` con `catch (_) { /* best-effort */ }`.
Un `SocketException` se tragaba, la cola lo leía como éxito y **borraba la
operación**. `attempts` nunca pasaba de 0 y las cinco duraciones de backoff eran
inalcanzables.

Tres fallos más, todos demostrados:

- **Sesión sin resolver = "éxito"**: `if (userId == null) return;` antes de intentar nada.
- **Carrera `enqueue`/`drain`**: `_draining` era un *skip*, no un lock. El
  `_write(remaining)` del drenado en vuelo pisaba la operación recién encolada.
- **Un solo disparador**: `drain()` solo se llamaba al cambiar de usuario.
  `ConnectivityBanner` detectaba la vuelta de la red y **no se lo decía a nadie**.

### Cómo funciona ahora

- Los cuatro métodos propagan. `userId == null` lanza `StateError`.
- `drain()`, `enqueue()` y `clear()` van por una cadena de futuros. Encadenar solo
  `drain()` no habría bastado: el `load→add→write` de `enqueue` corría fuera.
- Disparadores nuevos: `ConnectivityBanner.onBackOnline` (Panel y Entorno) y el
  `AppLifecycleState.resumed` de Entorno, que está registrado siempre.
- `_wasOfflineWhenDisabled` / `_pendingRecoveryProbe`: el banner se apagaba al
  perder el foco y `_offline` volvía a false, así que una recuperación ocurrida
  con la pestaña apagada **no se detectaba jamás**. Ahora se recuerda. Y no se
  falsea el estado visible: la primera versión de este arreglo pintaba el aviso de
  "sin conexión" al volver a la pestaña aunque hubiera señal perfecta.

### Manejo de errores

No se crearon enums de resultado: el contrato "lanza = reintenta" ya existía y
funciona. **No se distingue reintentable de permanente** (§17): un 401 o un
rechazo por RLS reintentará cada 6 h. Una operación inmortal es preferible a una
perdida, y no descartar es política deliberada de la cola.

---

## 8 · Clima y ubicación

### Qué servicios existían

```
EnvironmentService (const, sin estado)
  ├─ WeatherRepository ── caché por coordenada, dedup en vuelo, TTL
  │    └─ IrrigationCoordinator → IrrigationAdvisor → IrrigationEngine
  └─ llamadas DIRECTAS, fuera del repositorio:
       ├─ environment_screen        (estado propio, TTL propio)
       ├─ environment_forecast_screen
       └─ environment_forecast_24h_screen
```

`WeatherRepository` está bien diseñado como punto común y **solo lo usa el motor**.
El Dashboard no pinta clima propio, así que no añade una tercera fuente.

### Las coordenadas inventadas

| Dónde | Valor | ¿Llegaba al usuario? | ¿Al motor? |
|---|---|---|---|
| `environment_screen.dart:57-58` | 25.7913 / −108.9859 (Los Mochis) | **Sí**, todo Entorno | No |
| `environment_screen.dart:265` | `'Los Mochis, Sinaloa (predeterminada)'` | **Sí** | No |
| `environment_screen.dart:271` | `'Bio-G Field #001'` | **Sí, siempre** | No |
| `location_screen.dart:34,83` | 19.4326 / −99.1332 (CDMX) | **Sí** | **Sí** |
| `onboarding_wizard_screen.dart:414` | `?? 19.4326 / ?? -99.1332` | vía etiqueta | **Sí** |

**Lo grave no era Los Mochis.** Esa ruta se cortaba sola: Entorno nunca escribe en
preferencias y nunca toca la caché del repositorio, y `ParcelLocationResolver`
devolvía `null`, así que el motor recibía `AgronomicWeatherSnapshot.unavailable`.
El efecto era una contradicción visible —Entorno anunciaba el clima de Sinaloa
mientras el Panel decía "no hay pronóstico para esta parcela"— pero no una
recomendación envenenada.

**Lo grave era CDMX.** `LocationScreen._save()` no comprobaba si el usuario había
movido el mapa: escribía el encuadre por defecto en `profile_location_lat/lng`, de
ahí pasaba a `DeviceCropContext.geoLat`, a la nube, y **el motor razonaba sobre la
lluvia de Ciudad de México** y lo grababa en la trazabilidad.

### Qué se consolidó

- Fuera el respaldo de Los Mochis. Sin ubicación no se pinta clima.
- `'Bio-G Field #001'` → etiqueta real de la parcela, o `'Tu parcela'`.
- `_hasExplicitPick` en el mapa: no se guarda sin elección deliberada. Quien ya
  tenía ubicación guardada sigue pudiendo confirmar sin mover nada.
- Fuera los `?? 19.4326`, con **nulos explícitos** en la otra rama: `copyWith` usa
  centinela y omitir el campo conservaba las coordenadas viejas junto a la
  etiqueta nueva — dato falso más difícil de detectar que el anterior.
- Entorno resuelve con `ParcelLocationResolver.resolve(cropContext)`, la **cadena
  completa** que usa el motor. Quedarse en `fromProfilePreferences()` reabría la
  discrepancia: un contexto bajado de la nube desde otro teléfono trae `geo_lat`
  con las preferencias locales vacías.

### Sin ubicación

```
Ubicación desconocida.
Configura tu ubicación en Cuenta para consultar el clima de tu parcela.
```

Se reutiliza la rama `BioGErrorState` que ya existía. **Cero cambios de layout.**

`IrrigationEngine` ya distinguía correctamente `weatherUnavailable` de
`weatherStale`, marcaba la limitación y penalizaba la confianza. **No requirió
ningún cambio.**

---

## 9 · Borrado de cuenta

### Antes

Purgaba 4 de al menos 12 almacenes: eventos de cultivo, telemetría, clima y la
cola de subidas. El mensaje al usuario decía *"Borramos todos los datos de este
teléfono"* — era falso.

### Ahora

| Añadido | Por qué |
|---|---|
| `RecommendationStore.deleteForUser` + la ranura `__guest__` | El almacén devolvía las filas de invitado al siguiente usuario con sesión |
| Claves globales de `ProfileLocalService` (6) | Teléfono y avatar del usuario A visibles para B |
| `ParcelLocationKeys` (3) | Ubicación de parcela filtrada entre cuentas |
| `biog_notif_*` por prefijo + `biog_notification_outbox_v1` | Preferencias y bandeja sin namespace |
| Contexto de cultivo, proyección, equipo activo, caché de identidad | Por API pública de cada almacén |
| Cola de sincronización | Vía `PendingSyncQueue.clear()` inyectado desde `BioGStore` |

Sobre la cola: **no** se borra la clave a mano. `clear()` pasa por la cadena
interna, y saltársela reabre la carrera que la cadena existe para evitar — un
drenado en vuelo resucitaría en disco las operaciones de la cuenta recién
eliminada.

`LocalPurgeReport` se extendió con `recommendationsCleared`,
`profilePreferencesCleared` y `deviceScopedPreferencesCleared`.

### Logout — analizado y NO tocado

`unbindUser` está **al revés** de lo correcto: **borra de disco** el historial
agronómico (irreversible, se pierde al reentrar en la misma cuenta) y **conserva**
perfil, ubicación y recomendaciones, que son justo lo que filtra entre cuentas.

No lo cambié: es decisión de producto, no de ingeniería. El dato que hacía falta
para decidirlo: **`profile_location_lat/lng` es solo local**, nunca sube a
Supabase. Borrarlo en un logout sería pérdida irrecuperable de un dato capturado a
mano, salvo que el usuario lo tenga duplicado en el contexto de cultivo (que sí
sincroniza como `geo_lat`/`geo_lng`). Recomendación en §17.

---

## 10 · Escala de cultivo y hardware

### NO se agregó ninguna pregunta al wizard

Ni al onboarding, ni al segundo wizard, ni a ninguna pantalla. Confirmado.

### Y no hacía falta: el wizard YA la pregunta

`OnboardingStep.cultivationScale` es el paso 2 y es **obligatorio**: `canAdvance`
devuelve false sin él. La premisa de la auditoría previa era incorrecta en este
punto.

### De dónde viene el nulo

De los **ornamentales**, que lo anulan deliberadamente en cinco sitios
(`bootstrap_gate.dart:217,315`, `biog_store.dart:1257`,
`configure_seed_wizard_screen.dart:1849`, `wizard_crop_context_resolver.dart:170`),
con el motivo escrito en el código: *"El flujo ornamental no pregunta
ubicación/maceta/jardín"*.

### El fallback

`fertilization_planner.dart:1525` y `:1559`:

```dart
final form = _resolveDoseForm(scaleId) ?? _DoseForm.field;
```

El TODO adyacente ya reconoce el problema y cita el Fundacional 2.1 §9.3.

**Impacto real, medido.** La aritmética interna es coherente (campo: 2 400 000 kg
de suelo/ha; maceta: 15 kg), así que **no es una sobredosis de 1000×**. El daño es
de accionabilidad: la app le dice *"~48 kg/ha de urea"* al dueño de un cactus en
maceta. Si el usuario escala por superficie de maceta obtiene ~0.15 g contra los
~0.3 g correctos: error de ~2×, y de ~3× si el caso real era `plant`.

### Por qué NO se cambió

Suprimir la dosis para ornamentales es un cambio de comportamiento con
implicaciones de producto, no una corrección técnica. **Deuda explícita de
hardware.**

### Cómo debe resolverse en V1-B

La pieza ya existe: `defaultScaleForModel(BioGDeviceModel)` en `cultivation_scale.dart:32`,
y `deviceModelId` ya se persiste y se lee desde la columna `hardware_model`.

```
QR / vinculación → device identity → hardware_model
                                  → defaultScaleForModel()
                                  → cultivationScaleId
                                  → unidades y dosis del motor
```

Regla propuesta: `contexto.cultivationScaleId ?? defaultScaleForModel(device.deviceModelId)`,
y si sigue siendo nulo, **no emitir número** — que es lo que pide §9.3. Los equipos
sin `hardware_model` (todos los anteriores a que la app empezara a escribirlo)
quedan fuera hasta que se registren.

**Esto no bloquea el cierre de V1-A.**

---

## 11 · Básico / Pro

**NO se implementó ni se cableó nada.** Verificado y sin cambios.

`lib/core/billing/biog_plan.dart` (543 líneas) tiene **un solo importador en todo
el repositorio: su propio test**. Ninguna pantalla, presenter, servicio o
repositorio lo toca. Ninguna de las 11 banderas de entitlement aparece fuera del
archivo. **Cero gates activos, cero límites aplicados**, incluido el de equipos.

`subscriptionStatus` sigue siendo bandera muerta: se almacena y se copia, y ningún
`if` la evalúa.

Hay dos *orígenes* (`profiles.subscription_status` y `public.subscriptions`), pero
la precedencia ya está resuelta en `BiogSubscription.resolve`, que además tiene un
test fijando *"sin fila de suscripción se comporta EXACTAMENTE como antes"*. Como
nada en producción lo consume, esos 25 tests protegen el módulo pero no verifican
comportamiento visible.

El módulo es lógica pura, `@immutable`, sin I/O y sin registrarse en ningún scope.
**Está inerte por construcción.**

---

## 12 · Código legacy y huérfano

**No se borró ni un archivo.**

### Los dos motores de agua: NO compiten

Hay **un motor vivo** y **una capa de objetivos escrita para alimentarlo que nunca
se cableó**. Categoría (D), no (C).

`MoistureTargetResolver.resolve()` devuelve `AgroRange` **y** `SoilContext` —
exactamente los dos tipos que consume `IrrigationInput`. Su encabezado dice que se
enchufa "en dos puntos de llamada". Pero `irrigation_advisor.dart:72` sigue leyendo
`runtime.targets?.moistureRaw`, los rangos escritos a mano.

Consecuencia medible: `irrigation_advisor.dart:38,96` pasan `SoilContext.unknown`,
así que `supportsWaterBalance` **nunca** es true y la rama de balance hídrico del
motor es código muerto en runtime.

Y el propio `soil_water_scale.dart` documenta el daño del camino vivo: los rangos
manuales piden 60–80 % VWC mientras un suelo mineral a capacidad de campo lee
~28 %. **Eso sigue en producción y no lo toqué**: cablearlo cambia las bandas de
los 85 cultivos de golpe y requiere el prototipo en campo. Es el mismo bloqueador
A1/A2 de la auditoría del 9 de agosto.

`moisture_trend.dart` **sí está vivo**. No agruparlo con los otros tres.

### Clasificación

| Ruta | Cat. | Evidencia | Recomendación |
|---|---|---|---|
| `core/agro/water/{crop_water_policy,moisture_target_resolver,soil_water_scale}` | **D** | Cero imports de producción; tipos calzan con `IrrigationInput` | Conectar tras el prototipo. Máximo valor del repo |
| `core/agro/water/moisture_trend.dart` | vivo | `recommendations_screen.dart:365,492` | Dejar |
| `auth_gate.dart` + `screens/auth/sign_in_screen.dart` | **E** | Sustituto vivo: `bootstrap_gate.dart` | Documentar |
| `screens/onboarding/steps/{crop_category,crop_details,crop_stage,crop_date}_step.dart` | **E** | El wizard NO los importa; usa páginas inline | **4 steps muertos** confirmados |
| `core/crops/maize/crop_catalog.dart` (725 líneas) | **A** | Cero referencias. Sustituto: `catalog/crop_catalog.dart` | Candidato a borrado |
| `core/agro/barley_crop_definition.dart` | **E** | El registro importa el de `core/crops/barley/` | Documentar |
| `features/reporting/report_export_service.dart` | **A** | Cero referencias. El resto del módulo sí vive | Documentar |
| Los 9 `*_risk_catalog.dart` | **E** | Referenciados solo desde comentarios | **No borrar**: vocabulario de ids estable |
| `core/billing/biog_plan.dart` | **B** | Solo su test | Dejar |
| `lib/crops/` vs `lib/core/crops/` | **no dup.** | Las 14 hortalizas de `lib/crops/` las importan los `*_crop_definition` | Capa fea, no duplicación |
| `RecommendationStore.load/loadPending/respond` | **D** | Sin llamantes | SQLite crece sin lector |
| `SensorSimulator` + alertas | **D** | `kEnableSensorSimulator = false` → `watchAlerts` emite lista vacía siempre | **Ninguna pantalla depende del simulador**: sospecha descartada |
| `uploadAll`/`downloadAll` de los sync | **A** | Cero llamantes | Documentar |

### Otros hallazgos de interconexión

- **DESCARTADO — servicios duplicados.** Todos los constructores en capa UI son
  `const`: Dart los canonicaliza. `IrrigationCoordinator` es `late final`.
- **DESCARTADO — dependencia del simulador.** Ninguna pantalla lo alcanza.
- **MITIGADO — IDs.** `supabase_device_identity_repository.dart:460` sí lee
  `row['telemetry_device_id']`, columna que no existe. Pero la escritura la omite
  a propósito y `_keepingIdentityOf` protege el override contra el null remoto.
  **Es una defensa documentada, no un bug abierto.** No tocar.
- **ABIERTO — timestamps mixtos** en `biog_store.dart`, `offline_first_telemetry_source.dart`
  y `environment_service.dart`. Los del Historial están corregidos; el resto
  requiere revisión caso por caso. §17.

---

## 13 · Archivos modificados

**24 en `lib/`.** Ninguno borrado.

### Riego — autoridad única
| Archivo | Cambio |
|---|---|
| `core/agro/event_engine.dart` | `EventEngineInput.irrigationDecision`; `_shouldRecommendIrrigation` consume en vez de deducir; severidad desde la urgencia; rastro en `metadata`; texto de humedad baja sin orden de riego |
| `core/agro/agro_event_input_factory.dart` | Propaga la decisión |
| `core/agro/alerts_engine.dart` | Los dos textos de humedad describen el riesgo y remiten al Panel |
| `screens/history/history_presenter.dart` | Parámetro opcional de decisión |
| `screens/dashboard/dashboard_presenter.dart` | Baja la decisión hasta el motor de eventos |

### Historial y notificaciones
| Archivo | Cambio |
|---|---|
| `screens/history_screen.dart` | Rehidrata eventos persistidos; usa `irrigationDecisionAt`; "Ver más" abre la lista de eventos |
| `screens/notifications_screen.dart` | Dos constructores; fuente = despachador; `hydrate` + `markAllRead`; `.toLocal()` |
| `widgets/history/history_events_list.dart` | `.toLocal()` |
| `screens/dashboard_screen.dart` | Campana solo desde `unreadCount`; publica la decisión; `onBackOnline` |
| `core/notifications/notification_dispatcher.dart` | `hydrate()` esperable; `markAllRead` no persiste sobre vacío |
| `services/biog/events/crop_event_recorder.dart` | `userId` y llave de decisión en la firma; consume la decisión vigente; `_pendingRerun` |
| `services/biog/biog_store.dart` | Puente de la decisión, `irrigationDecisionAt`, `irrigationDecisionKey`, `drainPendingSync`, `clearPendingSync`, limpieza en `unbindUser` |

### Trazabilidad y borrado
| Archivo | Cambio |
|---|---|
| `core/agro/traceability/recommendation_store.dart` | `save()` = "la fila está presente"; futuro de BD fallido no se cachea |
| `core/agro/traceability/recommendation_recorder.dart` | Honra el resultado de `save()` |
| `core/account/account_deletion_service.dart` | Purga recomendaciones, claves globales, claves con namespace y la cola |
| `widgets/account/edit_profile_screen.dart` | Inyecta `clearPendingSync` |

### Offline
| Archivo | Cambio |
|---|---|
| `services/biog/storage/crop_context_supabase_sync.dart` | Las escrituras propagan; sin sesión lanza |
| `services/biog/storage/yield_projection_supabase_sync.dart` | Ídem |
| `services/biog/sync/pending_sync_queue.dart` | `drain`/`enqueue`/`clear` serializados |
| `widgets/shared/connectivity_banner.dart` | `onBackOnline`; recuerda la caída ocurrida con la pestaña apagada |

### Clima, ubicación y NPK
| Archivo | Cambio |
|---|---|
| `screens/environment/environment_screen.dart` | Sin respaldo de Los Mochis; resolutor completo; etiqueta real; drena al reanudar |
| `widgets/account/location_screen.dart` | `_hasExplicitPick` |
| `screens/onboarding/onboarding_wizard_screen.dart` | Sin CDMX; nulos explícitos |
| `screens/npk/npk_screen.dart` | 15 cadenas a lenguaje de estimación; `weights` explícito |

---

## 14 · Archivos nuevos

| Archivo | Propósito |
|---|---|
| `test/core/agro/traceability/recommendation_store_test.dart` | 9 pruebas: semántica de `save()` (nueva, duplicada, fallo), y que el recorder reintente cuando no se persistió y deduplique cuando sí |
| `test/services/biog/sync/pending_sync_queue_test.dart` | 4 pruebas: la operación sobrevive al fallo con `attempts == 1`, desaparece al confirmar, la carrera `enqueue`/`drain` no la pierde, y `collapseKey` sigue colapsando |
| `docs/BIOG_AUDITORIA_CIERRE_V1A.md` | Este documento |

Ningún archivo de `lib/` es nuevo. La consolidación se hizo con las piezas que ya
existían.

---

## 15 · Pruebas y validación

### Resultado en la máquina del dueño — EJECUTADO

**No hay SDK de Dart ni de Flutter en el entorno donde se escribió este trabajo**
(`pub.dev` y `storage.googleapis.com` bloqueados por el proxy; `github.com`
devuelve 403), así que la corrida la hizo el dueño.

```
flutter analyze  →  391 issues · 0 ERRORES  (129 s)
flutter test     →  1597 pasan · 4 fallan
```

**`analyze`: cero errores.** Los 391 son `warning` e `info`, y **ninguno lo
introdujo esta intervención** — comprobado uno por uno contra el árbol previo:

| Aviso | Veredicto |
|---|---|
| 241 `unnecessary_const` en `yield_reference_catalog.dart` | preexistente |
| `dart:ui` innecesario en `environment_screen.dart` | ya sobraba antes |
| `kMaterialIconScale` sin usar | ya estaba sin usar |
| `use_build_context_synchronously` en `location_screen.dart:328,362` | del buscador de direcciones, preexistente |
| 9 `unnecessary_brace_in_string_interps` en `event_engine.dart` | 9 antes, 9 ahora |

**`test`: los 4 fallos eran preexistentes**, y los tres archivos implicados están
byte a byte idénticos al árbol previo a la intervención:

| Fallo | Causa | Estado |
|---|---|---|
| `ring keeps the requested label` — esperaba 46, obtuvo 50 | `soil_health_ring.dart:333` dice `fontSize: 50`; la prueba se quedó con la cifra vieja | **corregido** en la prueba |
| `background pauses when inactive` — clave no encontrada | `dashboard-nature-particles` no existe en `lib/`: se perdió al unificar los fondos | **corregido** devolviendo la `Key` al widget |
| `recommendations · narrow phone` | `RecommendationsScreen.didChangeDependencies` resuelve `BioGScope.of` y la prueba no lo envolvía | **corregido** con envoltura de scope |
| `recommendations · optimal band` | idéntica causa | **corregido** |

Las 13 pruebas nuevas **pasaron**, y también `absent_sensor_events_test`
reescrito para el contrato nuevo de riego. De los 18 fallos preexistentes que
documentaba `CIERRE_SESION_BIOG.md` ya no queda ninguno.

Tras estas cuatro correcciones la suite debería quedar en verde. **Confírmalo
con una segunda corrida antes de congelar.**

### Lo que sí se hizo

**1. Verificación sintáctica real de los 574 archivos.** Se montó un analizador con
`tree-sitter-dart` (`/home/claude/dartcheck.py`) que parsea cada `.dart` y reporta
nodos `ERROR` o faltantes. Baseline antes de tocar nada: 0 errores. Después de
todos los cambios: **0 errores en 574 archivos**. Cubre sintaxis, **no tipos**.

**2. Dos rondas adversariales sobre el diff completo.**

*Ronda de compilación* — recorrió los 10 modos de fallo más probables (símbolos sin
importar, parámetros con nombre inexistentes, tipos incompatibles, null safety,
firmas rotas, alcance de variables, `const`, ciclos, `@override`, pruebas rotas)
abriendo cada definición. **Cero bloqueantes.** Cinco hallazgos "probables", los
cinco corregidos: la decisión sin limpiar en `unbindUser`, la vigencia aplicada de
dos formas distintas, el borrado de la cola saltándose su API, el centinela de
`copyWith` en el onboarding, y la relectura de eventos persistidos.

*Ronda de regresiones* — verificó los 9 escenarios y buscó bucles de
reconstrucción, `setState` tras `dispose` y pérdidas de funcionalidad. Encontró
seis regresiones reales. Las seis corregidas, incluidas las dos peores:
`markAllRead` sobre una bandeja sin hidratar **borraba la bandeja entera**, y el
"Ver más" del Historial dejaba de mostrar eventos.

*Segunda pasada sobre mis propias correcciones* — cuatro fallos más: `hydrate()`
no era una barrera de sincronización real, el banner falseaba el estado visible,
el cerrojo `_running` se tragaba el rerun necesario, y el motor de eventos entraba
en la ruta de pintado. Los cuatro corregidos.

**3. El bucle infinito que casi entra.** `IrrigationCoordinator.decisionFor`
recalcula en cada `build` con `decidedAt = now`. Mi primera versión del disparador
comparaba por `decidedAt`, lo que habría hecho: registro → la bandeja notifica →
el Panel repinta → hora nueva → registro… Se detectó antes de cerrar y se cambió a
comparar por `action|urgency`. Está documentado en el código para que nadie lo
revierta.

### Los 9 escenarios

| # | Escenario | Estado | Nota |
|---|---|---|---|
| 1 | Historial con memoria real | **Parcial** | Persiste y rehidrata con hora local; varios eventos de la misma lectura comparten hora (§2) |
| 2 | Notificaciones coherentes | **Sí** | Una sola fuente; en instalación limpia la campana arranca apagada, que es lo correcto |
| 3 | Riego con lluvia próxima | **Sí** | Ninguna superficie recomienda regar con `esperar` |
| 4 | Riego crítico sin lluvia | **Sí** | Tras cerrar las tres carreras del puente |
| 5 | NPK sin lenguaje absoluto | **Sí** | Barrido completo de `lib/` |
| 6 | Sin ubicación | **Sí** | Ni Los Mochis ni CDMX; Entorno usa la cadena completa |
| 7 | Offline | **Sí** | Sobrevive y se reintenta; sin clasificar permanente vs reintentable |
| 8 | Fallo de persistencia | **Sí** | No se da por auditada; reintenta al siguiente `sync` |
| 9 | Borrado de cuenta | **Sí** | 12 almacenes; la cola por su propia API |

**Escenarios 1 a 9 verificados por lectura de código, no por ejecución.** Los tests
nuevos fijan 3, 4, 7 y 8; el resto necesita la corrida en tu máquina.

### Cobertura previa: prácticamente nula en esta zona

Antes de esta intervención **no existía ni un test** de `CropEventLocalStorage`,
`CropEventRecorder`, `NotificationDispatcher`, `PendingSyncQueue`,
`RecommendationStore`, `RecommendationRecorder`, `AccountDeletionService`,
`EnvironmentScreen` ni `WeatherRepository`. Ese vacío es un hallazgo por sí mismo.

### Un test actualizado, a propósito

`test/core/agro/absent_sensor_events_test.dart` — `'humedad crítica real SÍ produce
riego recomendado'` fijaba el contrato viejo (la banda decide). Se reescribió y se
añadieron cuatro casos que fijan el nuevo: sin decisión no hay consejo, con
`esperar` no hay consejo, la severidad la gradúa el motor, y el aviso deja rastro
de la decisión.

### Los 18 fallos preexistentes

Los que documenta `CIERRE_SESION_BIOG.md` (copy de catálogos de árbol, umbrales de
`SucculentStageResolver`, tests del simulador desactivado) **no se tocaron** y
siguen ahí. No tienen relación con esta intervención.

---

## 16 · Pendientes para hardware / V1-B

| Pendiente | Necesita |
|---|---|
| **Escala desde identidad de hardware** — `?? _DoseForm.field` en `fertilization_planner.dart:1525,1559` | QR / vinculación que rellene `hardware_model`. La pieza (`defaultScaleForModel`) ya existe (§10) |
| **Cablear `MoistureTargetResolver`** — hoy `SoilContext.unknown` permanente y balance hídrico inalcanzable | Prototipo en campo. Cambia las bandas de los 85 cultivos de golpe |
| **Contrato de escala de humedad** — 60–80 % VWC pedido contra ~28 % reales | Decidir con el firmware si el aparato entrega índice relativo o VWC |
| **Ingesta real** — la telemetría viene del simulador | ESP32 + BLE |
| **Lámina de riego** — `IrrigationDepthEstimate` existe y no se calcula | Perfil de suelo real y validación |
| **`serial_number` como identidad** | Hardware con serie grabada |
| **Trazabilidad de nutrición/sanidad/rendimiento** | Nada de hardware: solo una fábrica análoga a `fromIrrigationDecision` |
| **Consumidor de lectura del `RecommendationStore`** | Decisión de producto: hoy escribe y nadie lee, y `userResponse` nunca se llena |
| **Clasificar fallos de sync** permanente vs reintentable | Nada. Trabajo pendiente |
| **Compartir un `WeatherRepository`** entre Panel y Entorno | Elevarlo por encima del `State` del Panel |
| **Timestamps mixtos** en 3 archivos de servicios | Revisión caso por caso |
| **`user_id` en `biog_telemetry.db`** | Migración de esquema local |
| **Semántica del logout** (§9) | Decisión de producto |
| **Notificaciones push, BLE, deep links, pagos** | Las 6 fases de dependencias pendientes |

---

## 17 · Riesgos restantes

**1. ~~Nada de esto está compilado.~~ RESUELTO.** `flutter analyze` da cero
errores y la suite pasa 1597. Los 4 fallos eran anteriores a esta intervención y
quedaron corregidos; falta una segunda corrida que lo confirme en verde.

**2. El Historial no tiene hora por evento, sino por lectura.** Defendible y
honesto, pero no lo vendas como *"cada evento con su hora exacta"*. Arreglarlo de
verdad es reescribir `EventEngine`.

**3. El agricultor recibirá menos avisos de riego que antes, y eso es correcto.**
Sin decisión vigente del motor no hay consejo. Es pérdida de cobertura a cambio de
que no haya contradicción. Si en campo se nota demasiado silencio, la respuesta es
publicar la decisión desde más sitios, **no** devolverle a `EventEngine` la
capacidad de deducirla.

**4. La campana arrancará apagada** en instalación limpia y hasta el primer evento
`caution` o superior. Antes vibraba permanentemente. **Se va a reportar como "dejó
de funcionar"** y es justo lo contrario: avisa a QA.

**5. El horario silencioso descarta, no difiere.** Un `caution` a las 23:00 se
pierde para esa lectura. La condición reaparece por la mañana con un `dedupKey`
nuevo, así que no se pierde el problema, solo ese aviso. Ahora que la campana
depende solo de la bandeja, esto pesa más que antes.

**6. No hay forma de descartar avisos desde la interfaz.** `dismiss()` existe y no
lo llama nadie. La bandeja crece hasta 200 y se recorta sola.

**7. Una operación de sync rechazada por RLS reintentará cada 6 h para siempre.**
Coste: una petición fallida cada 6 h por dispositivo. Preferible a perderla, pero
hay que clasificar los errores antes de tener tráfico real.

**8. `_hasExplicitPick` va a generar tickets.** Quien abría el mapa y tocaba
Guardar sin mover ahora recibe un aviso. Es exactamente el caso que había que
bloquear.

**9. Los textos de alerta son menos imperativos.** La crítica ya no dice "riego
inmediato": describe el riesgo y remite al Panel. Quien solo leyera el informe
rápido recibe menos instrucción directa. Es el precio de no contradecir al motor.

**10. Sigue vivo el bloqueador A1/A2 de la auditoría del 9 de agosto**: la escala
de humedad. Los rangos manuales piden 60–80 % VWC donde un suelo mineral a
capacidad de campo lee ~28 %, y el umbral de encharcamiento a 90 % es físicamente
inalcanzable. **Esta intervención no lo tocó** y es, con diferencia, lo que más
afecta a la calidad del consejo en campo.

---

## Veredicto

La parte de BIO-G independiente del hardware tiene ahora una arquitectura
coherente. Cada dato tiene una fuente clara. El Historial recuerda. Las
notificaciones representan solo lo que BIO-G decidió comunicar. El riego tiene una
única autoridad. Las recomendaciones pueden auditarse y no se dan por auditadas
sin estarlo. La aplicación no inventa ubicación. Los datos offline no desaparecen
en silencio. NPK se comunica como estimación sin dejar de ser útil.

El siguiente paso puede ser conectar ESP32 + BLE + identidad de hardware **sin
rehacer la lógica**: las costuras están escritas y documentadas.

Con una condición: **corre `flutter analyze` y `flutter test` antes de congelar.**
Es lo único de este trabajo que no pude verificar yo.
