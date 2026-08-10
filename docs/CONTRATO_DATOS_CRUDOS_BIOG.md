# BIO-G · Contrato de datos crudos (firmware → nube → app)

**Versión 1.0 · 9 de agosto de 2026**
**Sensor de referencia:** 8-en-1 RS485 / Modbus RTU · N, P, K, pH, CE, humedad, temperatura, salinidad
**Para:** quien escriba el firmware del prototipo, y quien mantenga `biog_telemetry.dart`

Este documento define **exactamente qué número, en qué unidad, debe salir del aparato**. Es el único punto donde firmware y app se ponen de acuerdo. Si algo aquí cambia, cambia la versión del protocolo.

---

## 0. El hallazgo que motivó este documento

> **Con el firmware conectado tal como está hoy la app, el canal de CE se perdería por completo, en silencio, en todas las lecturas.**

La ficha del sensor declara **CE: 0–20 000 µS/cm**. La app aplica esta guarda de plausibilidad (`lib/models/biog_telemetry.dart:358`):

```dart
final double? vEc = _plausible(ec, 0.0, 20.0);
```

Un suelo agrícola normal tiene **1.2 dS/m = 1 200 µS/cm**. Ese valor cae fuera de `[0, 20]`, así que `_plausible` lo convierte en `null`, `hasEcData` pasa a `false`, y la lectura se presenta como **dato ausente**. No hay error, no hay aviso: el canal simplemente desaparece.

Lo único que sobreviviría a esa guarda son lecturas por debajo de 20 µS/cm, es decir, prácticamente agua destilada.

**Por qué nadie lo ha visto todavía:** el simulador envía CE ya en dS/m (1.02–1.49), así que la frontera nunca se ha ejercitado. Es el tipo de fallo que solo aparece el día que se conecta el hardware, y que después cuesta días de depuración porque *nada falla* — solo faltan datos.

Y la consecuencia se multiplica: los canales N, P y K de este sensor **se derivan de la conductividad**. Sin CE válida, se cae el pilar del que cuelga toda la lectura de fertilidad.

**La unidad interna de BIO-G es correcta y no hay que tocarla:** el catálogo y los motores razonan en **mS/cm**, que es idéntico a **dS/m** (1 mS/cm = 1 dS/m exactamente). El problema no es la unidad de la app. Es que **nadie declaró que el aparato manda otra**, y la conversión ×1000 no existe en ningún lado.

---

## 1. Regla de oro

**El aparato manda unidades físicas ya convertidas, nunca registros crudos de Modbus.**

Los sensores RS485 de esta familia devuelven enteros escalados: la humedad como VWC×10, el pH como pH×10 o pH×100 según modelo, la temperatura como °C×10 en complemento a dos. **Esa desescalada se hace en el firmware, no en la nube y no en el teléfono.** Si un entero escalado llega a la app, la guarda de plausibilidad lo descarta y el canal desaparece en silencio — el mismo fallo que la CE.

Corolario práctico: **el aparato manda además el registro crudo** en `raw_payload`. No para que la app lo use, sino para poder recalibrar y depurar sin ir al campo a tocar dispositivos.

---

## 2. Tabla del contrato

| Campo JSON | Unidad que manda el aparato | Registro del sensor | Conversión en firmware | Rango válido | Guarda actual en la app | ¿Alineado? |
|---|---|---|---|---|---|---|
| `soil_moisture_pct` | **% VWC (m³/m³)** | VWC × 10 | `/10` | 0 – 100 | `0 – 100` | ✅ |
| `soil_temp_c` | **°C** | °C × 10, con signo | `/10`, complemento a 2 | −40 – 80 | `−40 – 80` | ✅ |
| `ec` | **mS/cm (= dS/m)** | µS/cm | **`/1000`** | 0 – 20 | `0 – 20` | ❌ **falta la conversión** |
| `ph` | **pH** | pH × 10 (o ×100) | `/10` o `/100` | 3 – 10 | `0 – 14` | ⚠️ guarda más ancha que el sensor |
| `n` | **mg/kg (índice)** | mg/kg directo | ninguna | 0 – 1999 | `0 – 2000` | ✅ |
| `p` | **mg/kg (índice)** | mg/kg directo | ninguna | 0 – 1999 | `0 – 1000` | ❌ **guarda corta**: descarta 1000–1999 |
| `k` | **mg/kg (índice)** | mg/kg directo | ninguna | 0 – 1999 | `0 – 3000` | ✅ |
| `salinity_mg_l` | **mg/L** | mg/L directo | ninguna | 0 – 20 000 | **no existe** | ⚠️ canal disponible sin usar |
| `battery_pct` | **%** | — | — | 0 – 100 | sin bandera de presencia | ⚠️ |
| `signal_rssi` | **dBm** | — | — | −120 – 0 | sin bandera de presencia | ⚠️ |

### Canales que este sensor NO provee

| Campo que la app espera | Situación |
|---|---|
| `air_temp_c` | El 8-en-1 **no mide aire**. Hoy la ausencia llega como `0.0` y dispara **"Riesgo de helada" crítico**. Hay que decidir: sensor de aire aparte, o tomarlo del pronóstico y marcarlo como estimado. **Mientras no se decida, el canal debe viajar como `null`, jamás como 0.** |
| `air_humidity_pct` | Igual. |
| `resistance` (MPa) | El sensor **no mide resistencia a la penetración**. Es la pestaña `'RT'` del historial. O se añade otro sensor, o el canal se retira de la interfaz. Hoy la app lo espera y nadie lo va a llenar. |

---

## 3. Reglas de presencia

Esta es la regla más importante del contrato, y ya está bien resuelta en el modelo de telemetría para diez de los doce canales. Falta cerrarla en los dos que quedaron fuera.

**Un canal que no midió viaja como `null`. Nunca como `0`.**

```json
{
  "device_id": "…",
  "timestamp": "2026-08-09T14:32:10-06:00",
  "soil_moisture_pct": 27.4,
  "soil_temp_c": 21.8,
  "ec": 1.24,
  "ph": 6.7,
  "n": 68, "p": 31, "k": 88,
  "salinity_mg_l": 620,
  "air_temp_c": null,
  "air_humidity_pct": null,
  "resistance": null,
  "battery_pct": 87,
  "signal_rssi": -61,
  "firmware_version": "1.0.3",
  "raw_payload": { "regs": [274, 218, 1240, 67, 68, 31, 88, 620] }
}
```

Un `0.0` en un canal significa **cero medido de verdad**: 0 °C es helada, 0 % de humedad es suelo seco muerto. Por eso el aparato nunca debe emitirlo por defecto ni por inicialización de estructura.

### Los dos que faltan

`battery_pct` y `signal_rssi` se escriben hoy **sin bandera de presencia**. Es el mismo bug del cero sintetizado, en los dos únicos campos que quedaron fuera del arreglo anterior. Cobra importancia en cuanto haya batería real: un aparato que no reporta batería aparecerá como **batería al 0 %**.

---

## 4. Tiempo

- `timestamp` = **cuándo se midió**, en ISO-8601 **con zona horaria**. La declara el aparato.
- `created_at` = cuándo lo recibió la nube. Lo pone Postgres. La app ya sabe que manda `timestamp`; no se toca.
- Sin reloj fiable, el aparato manda **segundos desde el arranque** más un `boot_id`, y la nube resuelve. **Nunca inventes una hora.** Una lectura sin hora no puede decidir riego: el motor la bloquea a propósito.
- `sequence` = contador monótono por dispositivo. Es lo que permite detectar huecos y deduplicar sin depender del reloj.

---

## 5. Identidad

| Campo | Quién lo pone | Nota |
|---|---|---|
| `serial_number` | **De fábrica, impreso en el aparato** | Tiene restricción UNIQUE en la base. El teléfono **no debe escribirlo nunca**: un choque de unicidad tumbaría el upsert entero en silencio. |
| `device_id` (UUID) | La nube, al emparejar | Hoy lo genera el teléfono. Con hardware real, el emparejamiento debe ser una función de servidor que valide `serial_number` + código impreso y cree la membresía de forma atómica. |
| `firmware_version` | El aparato, en cada lectura | Hoy es NULL en las 1 154 filas. Sin esto no se puede correlacionar un fallo de campo con una versión. |
| `protocol_version` | El aparato | `TelemetryEnvelope` ya rechaza por MAJOR incompatible. Úsalo. |

---

## 6. Calibración

**La humedad no necesita calibración de usuario.** El sensor entrega VWC ya calibrado de fábrica por FDR, ±2 %. La calibración de dos puntos aire/agua que se había planteado corresponde a otra clase de sonda (capacitiva analógica barata) y **no aplica aquí**.

Lo que sí conviene, y es lo que el prototipo debe medir:

1. **Verificar la exactitud en al menos tres texturas reales.** Riega a saturación, deja drenar 24 h, y compara la lectura contra la capacidad de campo tabulada (arena ~12 %, franco ~28 %, arcilla ~40 %). Si el aparato se desvía sistemáticamente, se corrige con un factor por dispositivo, no reescribiendo el catálogo.
2. **El pH de estas sondas deriva.** ±0.2 es la especificación de fábrica; en campo, tras semanas enterrado, es optimista. Conviene contrastar contra un potenciómetro de laboratorio al inicio y al mes.
3. **La CE depende de la temperatura.** Verifica si el aparato ya compensa a 25 °C. Si no, la compensación va en el firmware, no en la app.

---

## 7. Cadencia

Los 1 154 registros actuales tienen intervalos que van de **2.6 segundos a 8.7 días** — reflejan cuándo estuvo abierto el simulador, no un muestreo. Y `devices.reporting_interval_seconds` está en NULL, así que no hay cadencia declarada contra la cual validar.

Para el prototipo:

- Cadencia nominal **cada 30 minutos**, declarada en `devices.reporting_interval_seconds`.
- El aparato **acumula y reenvía** lo que no pudo subir. La app ya tiene el pasillo de reintento escrito (`TelemetryIngestService.flushPending`).
- Una lectura más vieja de 6 h no decide riego. Es política del motor y está bien puesta; el firmware debe conocerla para no acumular indefinidamente.

---

## 8. Qué debe emitir el simulador a partir de ahora

Los datos actuales son físicamente plausibles pero **estadísticamente degenerados**: el pH se mueve 0.16 unidades en 104 días, el NPK oscila ±4 ppm, y la batería *sube* de 94.5 % a 96 % — nunca se descarga. No hay un solo evento de riego, lluvia, fertilización ni fallo de sensor.

**Esos datos no ejercitan ni un solo camino de alerta ni de dato ausente.** Antes de conectar hardware, el simulador debería emitir:

- [ ] **CE en µS/cm**, para que el fallo de la sección 0 aparezca en desarrollo y no en campo
- [ ] Canales en `null` de forma intermitente (sensor caído)
- [ ] Valores fuera de rango físico (sonda descalibrada)
- [ ] Un evento de riego: salto de humedad hacia capacidad de campo y descenso gradual
- [ ] Un evento de lluvia fuerte: humedad por encima del umbral de encharcamiento
- [ ] Descarga de batería monótona
- [ ] Pérdida de señal y reenvío en lote de lecturas atrasadas
- [ ] Huecos de horas, y lecturas duplicadas con el mismo `sequence`

---

## 9. Lista de verificación antes de conectar el primer aparato

- [ ] **Convertir CE de µS/cm a mS/cm en el firmware** (o ampliar la guarda de la app y convertir al ingerir — pero conviértela en un solo sitio y déjalo escrito)
- [ ] Ampliar la guarda de `p` de `0–1000` a `0–1999`
- [ ] Estrechar la guarda de `ph` de `0–14` a `3–10.5`, que es lo que el sensor puede entregar
- [ ] Añadir `has_battery_data` y `has_signal_data`
- [ ] Decidir el origen de `air_temp_c` y `air_humidity_pct`, y mientras tanto mandarlos `null`
- [ ] Decidir si `resistance` se mide o se retira de la interfaz
- [ ] Empezar a poblar `firmware_version` y `raw_payload`
- [ ] Poblar `devices.reporting_interval_seconds`
- [ ] Añadir `salinity_mg_l` al modelo si se va a usar
- [ ] Emparejamiento por `serial_number` + código impreso, en una función de servidor

---

## Anexo · Por qué la app descarta en vez de recortar

`_plausible` convierte lo que está fuera de rango en `null`, y no lo recorta al límite. Es la decisión correcta y conviene que el firmware la conozca: **una lectura implausible es una sonda averiada, no un valor extremo.** Recortar 20 000 µS/cm a 20 mS/cm habría producido un número creíble y falso; convertirlo en ausencia produce un hueco visible.

El precio de esa decisión es exactamente el fallo de la sección 0: si la unidad no coincide, no hay error ruidoso, hay silencio. Por eso este contrato existe.
