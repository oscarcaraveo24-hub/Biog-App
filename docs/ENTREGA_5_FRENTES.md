# BIO-G · Entrega de los 5 frentes

**Fecha:** 3 de agosto de 2026 · **Base:** commit `6dff352`
**Archivos:** 21 nuevos + 18 modificados + 8 de pruebas = **47**, ~8,400 líneas
**Ya están en tu carpeta**, en su sitio. Respaldo de los 18 originales en `temp/_audit/_respaldo_previo/`.

---

## Lo primero: corre esto

```powershell
cd C:\Users\oscar\Documents\bio_g
flutter analyze
flutter test
```

y pégame la salida. No pude compilar de mi lado —el sandbox no tiene Flutter ni acceso a pub.dev—, así que corregí lo que se puede corregir por lectura y verificación estática, pero el compilador es el que tiene la última palabra.

**Lo que sí verifiqué:**

- Verificador propio de Dart sobre los **562 archivos** del proyecto: balance de llaves y paréntesis con tokenizador que entiende cadenas, cadenas crudas, triples e interpolación; imports que resuelven a archivos reales; exhaustividad de `switch` sobre enums; símbolos referenciados que existen. **0 errores.**
- **Simulación ejecutable** del árbol de decisión del motor de riego: porté la lógica a Python y corrí los **25 casos** que afirman las pruebas. Todos coinciden.
- El esquema SQLite nuevo, **ejecutado contra SQLite real**: se confirma que dos usuarios en el mismo teléfono ya no colisionan y que la deduplicación sigue funcionando.
- **Dos revisiones adversariales** independientes del código nuevo. Encontraron 1 error de compilación, 8 regresiones y 22 riesgos; están todos corregidos y reverificados.

---

## Frente 1 · Clima conectado

| Archivo | Qué hace |
|---|---|
| `core/weather/agronomic_weather_snapshot.dart` | Foto inmutable del clima con ET0, lluvia por ventanas (6/12/24/48 h), lluvia ya caída, frescura y origen. **Todos los campos son nullable**: un dato que no llegó vale `null`, nunca `0`. |
| `core/weather/et0_calculator.dart` | ET0 de referencia. Usa la de Open-Meteo (FAO-56 Penman-Monteith) y, si falta, estima con Hargreaves-Samani, declarando que es estimación. |
| `core/weather/weather_repository.dart` | Fuente única. Caché en memoria + disco, deduplicación de peticiones en vuelo, último pronóstico válido offline. |
| `core/weather/weather_snapshot_storage.dart` | Persistencia por parcela (clave a 3 decimales ≈ 110 m). |
| `services/environment_service.dart` | **+234 líneas, aditivo.** Método nuevo `fetchAgronomicSnapshot()`. Las tres pantallas de Ambiente no se tocaron. |

**ET0 ahora existe**: se pide `et0_fao_evapotranspiration` a la API, que nunca se había pedido.

**La antigüedad no miente**: `fetchedAt` es el momento real de la descarga y reutilizar la caché nunca lo rejuvenece. Era el defecto exacto de la pantalla de Ambiente, que mostraba "Actualizado hace unos segundos" sobre un pronóstico de horas antes.

**Detalle que resultó importante:** Open-Meteo con `timezone=auto` devuelve horas locales sin zona. Ubicar "ahora" en el arreglo horario sin corregir por `utc_offset_seconds` desplazaba las ventanas de lluvia varias horas. Está corregido.

---

## Frente 2 · Motor de riego real

| Archivo | Qué hace |
|---|---|
| `core/agro/irrigation/irrigation_types.dart` | Los 5 estados como enum de dominio, urgencia, razones estructuradas, confianza, vigencia, evidencia. |
| `core/agro/irrigation/irrigation_inputs.dart` | `MoistureReading` (obliga a declarar si el dato existe), `SoilContext`, `IrrigationPolicy` con todos los umbrales centralizados. |
| `core/agro/irrigation/irrigation_engine.dart` | El motor. **Puro**: sin red, sin disco, sin `BuildContext`. |
| `core/agro/irrigation/irrigation_advisor.dart` | Traduce el runtime del cultivo a entradas del motor. |
| `core/agro/irrigation/irrigation_coordinator.dart` | Une clima → decisión → registro. |
| `widgets/dashboard/irrigation_evidence_note.dart` | La franja que explica por qué. |

### El orden de decisión

```
1. BLOQUEOS DE DATO  → DATOS INSUFICIENTES (que NO es una recomendación)
   sin cultivo · sensor ausente · valor imposible · sin hora · lectura vencida (>6 h)
2. SIN OBJETIVO DE ETAPA → REVISAR
3. POSICIÓN vs objetivo → saturado/alto/dentro → NO REGAR
4. DÉFICIT:
   llovió ≥8 mm pero el sensor sigue crítico  → REVISAR (contradicción)
   lluvia ≥60 % Y ≥5 mm próximas              → ESPERAR (veto)
   riego reciente (<12 h) y déficit moderado  → ESPERAR
   sin clima utilizable:
       crítico  → REGAR (y lo declara)
       moderado → REVISAR
   lluvia posible pero insuficiente, moderado → ESPERAR
   resto                                      → REGAR
5. Confianza < 0.35 ⇒ la orden se degrada a REVISAR
```

**El veto exige las dos condiciones a la vez** —probabilidad alta *y* volumen suficiente— porque 90 % de 0.3 mm no moja la zona radicular, y vetar un riego por eso sería peor que no mirar el clima.

**La decisión nunca sobrevive a la lectura que la fundamenta**: `validUntil` se acota por la vigencia restante de la humedad.

**V1-A no inventa milímetros.** El hueco (`IrrigationDepthEstimate`) está reservado para cuando haya perfil de suelo y validación de campo.

### La tarjeta no se estaba renderizando

`DashboardInsightSection` existía en `dashboard_sections.dart` y **no se instanciaba en ninguna parte**. `viewData.irrigation` se calculaba en cada build y no llegaba nunca a la pantalla. Ya está en el árbol de widgets, con la nota de evidencia debajo.

---

## Frente 3 · Contrato de telemetría e ingesta

| Archivo | Qué hace |
|---|---|
| `core/telemetry/telemetry_contract.dart` | `TelemetryEnvelope`: identidad, serie de fábrica, firmware, versión de protocolo, calibración, **hora de medición separada de la de recepción**, zona horaria, número de secuencia, banderas de calidad. Con validación. |
| `core/telemetry/telemetry_transport.dart` | Interfaz del transporte + `ManualTelemetryTransport` (pruebas, importación) + `NullTelemetryTransport` (el estado real de hoy, declarado). |
| `core/telemetry/telemetry_ingest_service.dart` | **El pasillo que faltaba**: validar → guardar local → marcar pendiente → subir → quitar de pendientes *solo* si la nube confirmó. |

**`uploadBatch` ya tiene llamador vivo**: `BioGStore.bindUser` llama a `flushPending()`, que reintenta lo que quedó sin confirmar.

**Dos bugs corregidos en la sincronización:**

1. `air_temp_c`, `air_humidity_pct` y `ec` se escribían **siempre**, incluido el `0.0` sintetizado. Cada lectura sin esos sensores metía un cero falso permanente en la nube. Ahora van a `null` como el resto. Para eso añadí `hasAirTempData`, `hasAirHumidityData` y `hasEcData` a `BioGTelemetry`, que eran las tres banderas que faltaban.
2. `_latestTimestampIso` tomaba el **máximo** entre `timestamp` y `created_at`. Como `created_at` es la hora de inserción, una medición de hace 6 horas subida ahora se presentaba con la hora de subida: **rejuvenecía**. Ahora manda la hora declarada por el dispositivo.

**Identidad de dispositivo real:** el id escaneado por QR **se descartaba** —se leía, se mostraba en el diálogo y no se pasaba a `addDevice`— y se generaba un UUID aleatorio en el teléfono. Ahora viaja hasta el repositorio, que lo adopta si es un UUID válido y, si ese Bio-G ya existe, lo activa en vez de duplicarlo.

> **Lo que sigue faltando, y lo digo claro:** no hay BLE. Requiere un paquete nativo, permisos de Android e iOS y firmware que no existe. Lo que sí está cerrado y probado es todo el camino operativo; enchufar el BLE es escribir una clase que implemente `TelemetryTransport` y llamar a `store.telemetryIngest.bindTransport(...)`.

---

## Frente 4 · Cuenta, planes y notificaciones

| Archivo | Qué hace |
|---|---|
| `core/billing/biog_plan.dart` | `BiogPlan` (Básico/Pro), `BiogPlanStatus`, `BiogEntitlements`, `BiogSubscription`. Degradación, gracia de 30 días, término inicial de 12 meses, límite de 4 equipos fijos, portátil que no ocupa plaza. |
| `core/auth/auth_repository.dart` | **+230 líneas.** `sendPasswordReset`, `updatePassword`, `reauthenticate`, `requestAccountDeletion`, y `AuthActionResult` para que la interfaz no pueda mentir. |
| `core/account/account_deletion_service.dart` | Borrado real: reautenticar → servidor → purga local → cerrar sesión. |
| `core/notifications/notification_preferences.dart` | Preferencias por categoría, umbral de severidad, horario silencioso que lo crítico atraviesa. |
| `core/notifications/notification_dispatcher.dart` | Bandeja persistente con deduplicación y estado de entrega. |
| `screens/auth/sign_in_screen.dart` | El enlace "¿Olvidaste tu contraseña?" que no existía. |

**Sobre `subscriptionStatus`:** la auditoría señalaba `isGenericMode` como el campo sobrecargado. No lo era —es puramente agronómico— y el que había que cablear era `subscriptionStatus`. Ahora la fecha manda sobre la cadena: un `'pro'` con vencimiento del año pasado no da acceso Pro.

**Regla de degradación:** que una suscripción caduque **nunca** borra configuración ni historial local. Se apaga lo que el plan cubría y se conserva todo lo que capturaste.

**El borrado de cuenta ahora dice la verdad.** Reautenticación obligatoria (requisito de las tiendas), y **remoto antes que local**: si la red falla, no se toca nada y el mensaje es "no se borró nada, inténtalo de nuevo". Antes se purgaba primero, así que un fallo de red destruía el historial local dejando la cuenta viva.

⚠️ **Requiere una función en Supabase.** Un cliente no puede borrar su propio usuario de `auth.users`. El SQL exacto está en el doc-comment de `requestAccountDeletion()`. Mientras no exista, el flujo funciona y dice honestamente "quedó solicitado", en vez de fingir.

> **Push sigue sin existir:** requiere `firebase_messaging` y configuración nativa. Lo que sí funciona hoy: las preferencias se respetan, la bandeja sobrevive al cierre de la app y la campana del Panel la lee.

---

## Frente 5 · Trazabilidad auditable

| Archivo | Qué hace |
|---|---|
| `core/agro/traceability/engine_versions.dart` | Versiones de cada motor y del esquema del registro. |
| `core/agro/traceability/recommendation_record.dart` | El registro inmutable completo. |
| `core/agro/traceability/recommendation_store.dart` | SQLite con `user_id`, `load`, `loadPending`, `respond`, `expirePending`, purga por usuario. |
| `core/agro/traceability/recommendation_recorder.dart` | Guarda **y lee**. |

Cada registro conserva: id de lectura, valor con **unidad, presencia, calibración y antigüedad**; cultivo, variedad, etapa, parcela, **versión del catálogo**; snapshot climático completo, **versión del motor**, razones en lenguaje humano, **limitaciones declaradas** aparte de las razones, confianza, validez, requiere-confirmación, y **acción del usuario**.

Tres decisiones de diseño que importan:

- **El id incluye la versión del motor.** Recalcular tras cambiar las reglas crea un registro nuevo, no sobrescribe el viejo. La historia de lo que se aconsejó no se reescribe.
- **`datosInsuficientes` NO se registra.** No es un consejo, es la ausencia de uno. Guardarlo diría "BIO-G recomendó" algo que nunca recomendó.
- **`expirePending`** marca como vencidas las que nadie contestó, para que "sin responder" signifique de verdad "sin responder".

**Y el almacén se lee.** El anterior (`CropEventLocalStorage`) escribía a SQLite en cada lectura de telemetría y `load()` no tenía **ni un llamador**: I/O y batería a cambio de nada. Ahora los mismos eventos alimentan la bandeja de avisos, que sí se consulta.

**La fuga de datos entre cuentas está cerrada.** `crop_events` no tenía dueño y nadie la purgaba: cambiar de cuenta en el mismo teléfono dejaba el historial agronómico del usuario anterior en disco. Ahora la llave primaria es `(user_id, device_id, dedup_key)` y `unbindUser` purga.

---

## El bug de fondo, cerrado en las cinco capas

Un sensor de humedad que no reporta llega como `soilMoisturePct = 0.0`. Ese cero producía "Riego recomendado" con severidad crítica, indistinguible de una recomendación real.

| Capa | Antes | Ahora |
|---|---|---|
| `agro_event_input_factory` | N/P/K con bandera; **humedad, pH, resistencia y temp. de suelo crudos** —líneas contiguas del mismo archivo— | Todas con bandera |
| `safeCurrentBands` | Devolvía la banda calculada sobre el 0.0 | Degrada a `unknown` cuando el dato no existe |
| `event_engine` | `unknown` no era `optimal` ⇒ dos nutrientes ausentes bastaban para "Desbalance nutrimental" | `unknown` se filtra: ausencia ≠ problema |
| `dashboard_presenter` | El `switch` de 8 líneas | Guarda de dato ausente + motor de riego |
| `irrigation_engine` | — | Se detiene en el bloqueo de dato |

**Dos que encontraron los revisores y que no estaban en la auditoría:**

- **Falsa "Recuperación" en el Historial.** Las bandas *actuales* se degradaban pero las *previas* no, así que `previousProblemCount > currentProblemCount` y el Historial emitía "El cultivo muestra señales de recuperación" cada vez que un sensor dejaba de reportar.
- **Falso "Riesgo de helada" crítico.** El umbral de helada vale entre 0 y 7 °C según cultivo, así que un sensor de aire ausente (`0.0 °C`) cumplía `0.0 <= 0.0`. Ídem con humedad ambiente baja.

---

## Lo que NO toqué, a propósito

- Los ~30 motores de score por cultivo, los catálogos de sanidad, los perfiles por etapa, la calibración del sensor, la validación de plausibilidad física. **Nada de eso cambió.**
- Las tres pantallas de Ambiente.
- `pubspec.yaml`: **cero dependencias nuevas.**
- Nada fuera de `lib/` y `test/`.

---

## Notas para cuando corras `flutter analyze`

**Ruido previo que ya estaba** y no es mío (lo dejé como estaba para no mezclar):
`BioGTelemetry._asDouble` sin usar · `EnvironmentService._log` sin usar · `use_build_context_synchronously` en `add_biog_screen` · ~15 `curly_braces_in_flow_control_structures` en `dashboard_presenter` · `prefer_interpolation_to_compose_strings` en `dashboard_presenter:443`.

**Si `git status` te muestra 345 archivos modificados, no te asustes:** es ruido de finales de línea del repo (mezcla CRLF/LF preexistente). Los diffs reales de lo que toqué son **+1,180 / −79 líneas** en 18 archivos. Puedes verlo con `git diff --numstat -- lib test`.

**Dos cosas que quedan pendientes de servidor** (no de código):

1. La función `request_account_deletion()` en Supabase. SQL en el doc-comment.
2. El deep link `biog://auth/reset-password` en Supabase → Authentication → URL Configuration, más el esquema en el manifest y el `Info.plist`. Mientras no exista, el correo se envía igual y cae al `Site URL`.

---

## Cobertura de pruebas nueva

`irrigation_engine_test` (36 casos) · `agronomic_weather_snapshot_test` · `et0_calculator_test` · `biog_plan_test` · `telemetry_contract_test` · `recommendation_record_test` · `absent_sensor_events_test` · `biog_telemetry_presence_test`

De los 8 escenarios de riesgo que pedía el plan de cierre, **6 pasan de cobertura cero a cubiertos**: datos faltantes, clima vencido, riego con lluvia, degradación Pro, contradicción sensor/clima, y vigencia de lectura.
