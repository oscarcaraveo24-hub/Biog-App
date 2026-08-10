# BIO-G · Auditoría final de la fase de software

**Fecha:** 9 de agosto de 2026
**Alcance:** aplicación Flutter (487 archivos Dart · 228,825 líneas), base Supabase en producción (`akujcvatjtfeevlxdrfx`, 76 tablas, 1,154 lecturas reales), documentos fundacionales, catálogo agronómico (85 cultivos habilitados), suite de pruebas (75 archivos · 1,533 pruebas).
**Pregunta que responde:** ¿se puede cerrar la fase de software y pasar al prototipo físico?

---

## Cómo se hizo esta auditoría

Se recorrió el proyecto completo desde seis perspectivas simultáneas e independientes —agronomía de campo, fertilidad de suelos, riego y clima, arquitectura de software, backend y seguridad, y producto/UX— y después se pasó **una ronda adversarial** que intentó refutar cada hallazgo crítico uno por uno, con el código en la mano y consultando la base de datos real.

Eso importa porque **tres afirmaciones fueron corregidas o degradadas** en esa segunda vuelta, y dos resultaron **más graves** de lo que decía el primer análisis. Los hallazgos que verás abajo llevan marca de confianza:

- **[V]** = verificado adversarialmente, con evidencia de código y/o de base de datos
- **[U]** = hallazgo de una sola fuente, plausible pero no contrastado

**Lo único que no pude verificar:** `flutter analyze` y `flutter test`. Flutter no existe en el puente Linux hacia tu equipo y el SDK está bloqueado en el sandbox. Es la única pieza que necesito que corras tú (comandos exactos en §8). Todo lo demás está verificado contra el código y la base reales.

---

## 1. Estado actual de BIO-G

**BIO-G no es un prototipo de software. Es un producto grande, profundo y en su mayor parte bien construido, al que le faltan piezas concretas y bien identificadas.**

Conviene decir primero lo que está sólido, porque es mucho y no es habitual:

- **El motor agronómico está por encima de lo que se ve en productos comerciales.** 85 cultivos habilitados con fenología propia por especie —no plantillas—: la cebolla tiene `induccionBulbificacion` y `llenadoBulbo`, el ajo tiene vernalización e inducción por frío, los cereales usan Zadoks real. Nadie reusó "vegetativo / floración / cosecha" genérico.
- **La distinción más difícil de la fenología perenne está bien resuelta.** Cítricos, mango y aguacate comparten el `stageId` `dormancy` pero se etiquetan "Reposo relativo / baja actividad", reservando "Pelón / dormancia" solo para caducifolios. Eso no se acierta por accidente.
- **`soil_reaction.dart` es trabajo de nivel profesional.** Tabula los cuatro extractantes (Bray, Olsen, Mehlich, Morgan) con sus cortes reales, deriva el factor de suelo calcáreo mostrando la aritmética desde dos calibraciones publicadas, pone el corte en 7.3 y no 7.0 argumentando asimetría de costo del error, y **se niega explícitamente a ajustar N y K** porque no existe calibración equivalente: *"ajustarlos sería inventar"*.
- **El motor de riego decide bien y sabe cuándo no sabe.** Cinco estados cerrados, `datosInsuficientes` declarado explícitamente como NO-recomendación, confianza que solo baja y nunca sube, y el veto por lluvia exige **probabilidad ≥60 % Y volumen ≥5 mm simultáneos** —porque un 80 % de 0.2 mm no moja la zona radicular—. Eso es criterio agronómico real, no una regla copiada.
- **La ET0 es matemáticamente correcta.** Repliqué el Dart en Python y lo anclé contra FAO-56: Ejemplo 8 (Ra = 32.2 MJ/m²/d a 20°S) reproduce con **0.02 % de error**; Ejemplo 20 (ET0 = 5.0 mm/d en Lyon) reproduce con **0.7 %**. El bug del factor 0.408 que cazaste en agosto está corregido y verificado.
- **El módulo de sanidad vegetal hace lo correcto por omisión:** cero ingredientes activos, cero dosis, cero nombres comerciales en los 32 catálogos. Es un triaje sintomático que se declara orientativo y remite a SENASICA en plagas reglamentadas. **Legalmente correcto y agronómicamente responsable.**
- **El contrato de telemetría se escribió antes que el firmware**, con versión de protocolo, hora de medición separada de la de recepción, número de secuencia y banderas de calidad. Ese es el orden correcto y casi nadie lo hace.
- **`request_account_deletion()` existe, funciona y está bien diseñada:** valida sesión, bloquea cuentas con registros operativos, y **libera el hardware en vez de destruirlo** —el aparato es un activo con garantía, no propiedad borrable del usuario—.

Y ahora lo que falta, agrupado por naturaleza:

**(a) Un contrato de unidades sin cerrar.** No es un bug: es la definición física de qué significa el número que devuelve el sensor de humedad. Está declarada de cuatro maneras incompatibles en el propio repositorio. Es el hallazgo más importante de toda la auditoría y, no por casualidad, es también **una decisión de hardware**, no de software.

**(b) Un patrón corregido a medias.** El bug de "sensor ausente = 0.0" está impecablemente resuelto en la ruta de eventos (`AgroEventInputFactory` + `EventEngine`) y **sigue vivo en los ~34 motores de score por cultivo y en la rama de árboles del panel**. El diagnóstico ya está escrito en tu propio código; falta aplicarlo en las otras fronteras.

**(c) Costuras diseñadas pero no conectadas.** `TelemetryTransport`, `BiogEntitlements`, `IrrigationDepthEstimate`, `SoilContext`, `Calibration`, el recorder de trazabilidad: todos existen, están probados, y **ninguno tiene llamador vivo en producción**. Esto no es deuda mala —es la forma correcta de prepararse para el hardware— pero hay que saber que el número de piezas apagadas es alto.

**(d) Higiene de plataforma sin empezar.** Un solo proyecto Supabase para todo, cero separación dev/prod, cero observabilidad (ni `runZonedGuarded` ni crash reporting), y CI no verificable.

---

## 2. Nivel de madurez

Distingo dos medidas porque dan números muy distintos y ambos son verdad:

| Medida | Nivel | Qué significa |
|---|---|---|
| **Por volumen construido** | **~92 %** | Lo que falta son ~6-8 días de trabajo enfocado sobre lo que claramente han sido meses. |
| **Por riesgo cerrado** | **~78 %** | Los pendientes están concentrados en pocos puntos, pero son de los que producen consejo equivocado o pérdida de datos. |

Desglose por subsistema (0-100):

| Subsistema | Nota | Comentario |
|---|---|---|
| Dominio agronómico / fenología | **84** | Profundo y bien fundado. Penaliza la escala de humedad y ~6 deudas puntuales de especie. |
| Motor nutrimental — interpretación | **80** | Arquitectura correcta, unidades declaradas, honestidad documental notable. |
| Motor nutrimental — prescripción | **45** | Sin techo de dosis, sin compuerta de salinidad, fuga de "ausente = 0". |
| Motor de riego | **72** | Bien construido; no usa ET0 ni balance hídrico y tres de sus entradas nunca se rellenan. |
| Sanidad vegetal | **74** | Diseño responsable; motor sin ninguna prueba y maíz con solo 5 síndromes. |
| Sistema de alertas | **41** | Reproduce íntegro el bug del cero sintetizado que el proyecto declara corregido. |
| Trazabilidad | **45** | El registro es completo y auditable; no se lee desde ninguna pantalla ni sube a la nube. |
| Arquitectura y capas | **72** | Limpia, con interfaces reales y DI por constructor. Testeable. |
| Persistencia local / offline lectura | **70** | SQLite bien migrado, TTL, deduplicación. La **lectura** offline sí funciona. |
| Offline escritura (cola de subida) | **35** | Carrera determinista y nunca drena al recuperar señal. |
| Backend / RLS (para prototipo) | **58** | Escalada de privilegios confirmada por explotación en transacción revertida. |
| Backend / RLS (para producción) | **31** | Bloqueado. |
| Costura con hardware real | **25** | Diseñada, no conectada. QR y BLE son stubs. |
| Producto / UX | **58** | Motor excelente, envoltura en beta. |
| Configuración y ambientes | **20** | Un solo proyecto Supabase, todo hardcodeado. |
| Observabilidad | **10** | Inexistente. |
| Pruebas | **62** | 1,533 pruebas reales, pero cubren catálogos, no motores. |

**Lectura práctica: BIO-G está en el último 20 % de su fase de software, y ese 20 % está bien mapeado.** No hay sorpresas estructurales ni rediseños escondidos.

---

## 3. Bloqueadores reales

Estos son los que **de verdad** impedirían cerrar hoy. Cada uno cumple al menos uno de estos criterios: *(i)* le da un consejo equivocado a un agricultor, *(ii)* pierde o filtra datos de forma irreversible, *(iii)* bloquea o corrompe el trabajo del prototipo físico.

### B1 · El contrato de unidad de humedad no existe [V] — *el más importante*

`soilMoisturePct` está definido de **cuatro maneras incompatibles** dentro del mismo repositorio:

| Fuente | Escala declarada |
|---|---|
| `lib/models/biog_telemetry.dart:170` | `// %` — sin escala |
| `lib/core/agro/irrigation/irrigation_inputs.dart:56-62` | "humedad **volumétrica** expresada en porcentaje" → VWC |
| `lib/crops/lettuce/lettuce_universal_profile.dart:82` | "**Agua disponible** 60-95 % óptimo" → % de agua disponible |
| `docs/.../REGLAS DE ESCALA...pdf` §5.3 (firmware) | `VWC = (1023 − ADC)/1023 × 100`, y **">60 = Saturado"** |

**La contradicción decisiva no requiere discutir física de suelos:** el firmware de tu propio proyecto llama **"Saturado" a >60**, y el catálogo de la app usa **60 como el piso del ÓPTIMO** (manzano `optimalMin: 60`, lechuga `optimalMin: 60`). La banda buena de la app empieza exactamente donde tu firmware declara anoxia.

Y el documento que justifica los targets lo dice por escrito: `docs/ornamentales/CALIBRACION_HUMEDAD_ORNAMENTALES_v2.md:28` admite que **la saturación del suelo mineral es 40-55 % VWC** mientras ancla los targets en "capacidad de campo de una mezcla de maceta (turba/coco) ≈ 55-80 % VWC". Para una suculenta en maceta eso es defendible. Para un manzano o una lechuga en suelo, la banda óptima queda **por encima de la saturación del suelo**.

**Consecuencia medida sobre tus 1,154 lecturas reales de Supabase** (min 37.7 · media 52.6 · max 60.5):

| Cultivo | CRÍTICO BAJO | BAJO | ÓPTIMO | ALTO | SATURADO |
|---|---|---|---|---|---|
| Manzano (45/60/80/90) | 266 (23 %) | 830 (72 %) | 58 (5 %) | **0** | **0** |
| Lechuga (50/60/95/100) | 372 (32 %) | 724 (63 %) | 58 (5 %) | **0** | **0** |

**El 95 % de las lecturas produce "riega".** Y la alarma de encharcamiento es inalcanzable por dos vías: los umbrales altos (88-100) y además `biog_telemetry.dart:355`, que convierte cualquier lectura >100 en `null` → "dato ausente". Un anegamiento real —causa nº1 de muerte por *Phytophthora* en aguacate, cítrico y nogal— **nunca disparará aviso**.

Además, la calibración por dispositivo es **código muerto**: `Calibration` nunca se instancia en `lib/`, `irrigation_coordinator.dart:87` no la pasa, y todo cae a `raw/100`.

> **Por qué esto es de hardware y no de software:** no puedes diseñar la calibración del prototipo sin haber decidido si el aparato entrega VWC, índice relativo o % de agua disponible. Es la primera decisión de la interfaz firmware↔app, y hoy está tomada tres veces de forma distinta.

### B2 · "Sensor ausente = 0" sigue vivo en los motores de score [V]

El proyecto declara este bug corregido, y lo está **en la ruta de eventos**. No lo está en:

- `core/agro/agro_score_engine.dart:431-432` y ~20 gemelos por cultivo (`tomato:403`, `chili:398`, `lettuce:463`, `bean:390`, `cereal:293`, `nopal:682`, `rose:465`…): `if (airTemp <= 0) → 'airTemp.frost'` **sin comprobar `hasAirTempData`**. Sensor de aire desconectado ⇒ **"Riesgo de helada" crítico**. Un productor puede quemar diésel encendiendo calefactores por un sensor apagado.
- `core/agro/tree_agro_score_engine.dart:727, 789, 865`: idéntico en todos los frutales, más `soilTempC <= 12` sin bandera.
- `screens/dashboard/dashboard_presenter.dart:838-841, 894-1060`: `_buildTreeDashboardEvents` es **la única rama de eventos que se salta `AgroEventInputFactory.safeCurrentBands`**. Sensor de humedad ausente ⇒ "Déficit hídrico en floración" crítico. **Y lo crítico atraviesa el horario silencioso** (`notification_preferences.dart:212`): despierta al productor a las 3 a.m. por un sensor caído.
- El `criticalPenalty` hunde el score de suelo ~0.45× por cada sensor ausente: **el "estado del suelo" que ve el productor es falso** cuando falta un canal.

> **Aviso metodológico:** estos cuatro **no llevan `?? 0`**. Son lecturas directas sobre el 0.0 ya materializado en el constructor. `grep "?? 0"` no los encuentra. El patrón a buscar es `t.<campo>` sin su `has<Campo>Data` adyacente.

### B3 · Prescripción de fertilizante sin límites ni compuerta de salinidad [U, evidencia fuerte]

- `fertilization_planner.dart:1486-1506`: `_calculateDeficitPpm` devuelve `max(0, targetMid − rawPpm)` **sin techo**. `grep clamp|math.min|maxDose` en todo el planner: **0 resultados**. Combinado con B2, un canal NPK muerto puede producir **230 kg N/ha en maíz (= 501 kg de urea/ha)** o **390 kg K₂O/ha en pepino (= 650 kg de KCl/ha)**.
- La **CE no es parámetro** de `buildGuide` (`:145-200`). Y en `_resolveContextModifier01`, `ec > 2.2` **sube** la urgencia en vez de moderarla: el suelo salino recibe la recomendación más agresiva. 650 kg/ha de KCl aportan ~390 kg Cl⁻/ha sobre un suelo que el motor ya sabe salino.
- pH ausente (0.0) dispara la rama `ph < 5.8`; humedad ausente (0.0) dispara `< 28`. `soilReactionFromPh` **sí** guarda contra esto; el modificador de contexto no.

En el escenario normal las dosis son sanas (maíz 75 kg N/ha, trigo 66, tomate 101 kg K₂O/ha). **El problema no es la calibración: es la ausencia de límites en el borde.**

### B4 · Cualquier cuenta puede apropiarse de cualquier BIO-G [V — explotado y revertido]

`device_memberships` INSERT tiene `WITH CHECK (auth.uid() = user_id)` y **no valida ningún derecho sobre `device_id`**. En una transacción revertida contra tu base real: una cuenta que veía 0 filas se auto-insertó `role='owner'` y pasó a ver **las 1,154 lecturas de telemetría, el dispositivo y el contexto de cultivo**, con permiso de borrarlo. Basta conocer el UUID.

Y es **irreversible desde la app**: `device_memberships` no tiene políticas UPDATE ni DELETE, así que el dueño legítimo **no puede expulsar al intruso**.

Agravado por `supabase_device_identity_repository.dart:252-256`, donde `removeDevice` hace `delete()` sobre la tabla **`devices`**, no sobre la membresía —y `_uploadDevice:299` da `role:'owner'` a todo el que empareja—. Como `telemetry`, `device_crop_contexts`, `device_crop_items` y `device_yield_projection_configs` son **`ON DELETE CASCADE`**, un usuario borrando "su" equipo destruye **todo el historial del otro**. Irrecuperable.

> El emparejamiento es, literalmente, lo que introduce el prototipo físico. Este es el bloqueador nº1 para conectar hardware.

### B5 · Fuga de datos personales entre cuentas [V — más grave de lo reportado]

`profile_local_service.dart:22-27` usa claves globales sin `userId` (`profile_avatar_path`, `profile_location`, `profile_phone`), y nadie las purga en `signOut()`.

Lo que la verificación adversarial encontró y el primer análisis no: `account_screen.dart:181-182`, si el usuario B no tiene avatar remoto, **sube la foto del usuario A a Supabase Storage y la escribe en `profiles.avatar_url` de B**. No es mostrar datos ajenos en local: es **escribir el dato personal de A dentro de la cuenta de B, en la nube**. Eso es un incidente de privacidad reportable.

### B6 · La cola de sincronización pierde operaciones de forma determinista [V — más grave de lo reportado]

Dos problemas distintos:

1. **Nunca drena al recuperar señal.** `drain()` tiene exactamente **dos llamadores**: `enqueue()` y `bindUser()`. No hay `WidgetsBindingObserver`, no hay `connectivity_plus`, y `connectivity_banner.dart:71` **detecta que volvió la red y no dispara nada**. El backoff (30 s → 6 h) se calcula, se persiste y **ningún temporizador lo consume**.
2. **Carrera enqueue-contra-enqueue, determinista.** `enqueue` hace `await load()` → mutar → `await _write()` sin atomicidad. Y `biog_store.dart:229-235` lanza N `enqueue` sin `await` en un bucle, en **cada `bindUser`**. Con 2+ dispositivos con contexto local más nuevo, **N−1 subidas se pierden en cada arranque de sesión**. Lo local queda bien; la nube queda desincronizada en silencio.

### B7 · Un solo ambiente Supabase, todo hardcodeado [V]

`lib/core/config/supabase_config.dart:2-4` tiene URL y clave publishable en constantes. **Cero `String.fromEnvironment` en las 229k líneas.** No hay dev, ni staging, ni QA.

La clave es *publishable* (protegida por RLS) —no es una fuga de secreto—, pero **la primera prueba de hardware escribirá en producción**. Y dado B4, la RLS que la protege está rota.

### B8 · Cero observabilidad [V]

`lib/main.dart:12-20` no tiene `runZonedGuarded`, ni `FlutterError.onError`, ni `PlatformDispatcher.onError`. Cero Sentry/Crashlytics. Hay **124 `catch (_)`** en `lib/`, y el peor (`irrigation_coordinator.dart:169`) envuelve clima + decisión + registro completo: un fallo permanente del motor es invisible y la decisión anterior sigue mostrándose.

**Un crash del prototipo en campo será invisible.** No sabrás por qué falló.

### B9 · La trampa de sesión del onboarding [V]

`onboarding_wizard_screen.dart:195` + `bootstrap_gate.dart:645`: la flecha «atrás» en el paso 1 llama `onExited` → **`signOut()` sin confirmación**, con un icono idéntico al de los pasos 2..N. Y `_signOutStaleSession()` se dispara siempre que la sesión venga restaurada del disco: **reabrir la app a media alta expulsa al usuario**. `OnboardingDraft` no tiene `toJson`: es solo memoria.

En campo, con señal intermitente y batería baja, esto pasa el primer día.

---

## 4. Auditoría de la lista anterior (los ~28 puntos)

Reevaluados contra el estado real del código de hoy. **No todo debe hacerse.**

### ✅ Ya resuelto o sustancialmente resuelto (9)

| # | Punto | Estado verificado |
|---|---|---|
| 1 | Bug ET0 / unidades Hargreaves | **Resuelto y verificado.** Anclado contra FAO-56 Ej. 8 (0.02 % error) y Ej. 20 (0.7 %). |
| 2 | "Sensor ausente = 0" en ruta de **eventos** | **Resuelto.** `AgroEventInputFactory` + `EventEngine` filtran `unknown` correctamente. *(Ver B2: falta la ruta de score.)* |
| 3 | Contrato de telemetría | **Resuelto.** `TelemetryEnvelope` con versión de protocolo, hora de medición vs recepción, secuencia, calidad. 200+ líneas de test. |
| 4 | `handle_new_user()` abierta a `anon` | **Resuelto.** `EXECUTE` revocado, `search_path` fijado. Verificado en vivo. |
| 5 | Eliminación de cuenta | **Resuelto y bien hecho.** `request_account_deletion()` existe, valida, bloquea cuentas operativas y **libera el hardware** en vez de destruirlo. |
| 6 | Lectura de la propia suscripción | **Resuelto.** Política creada; `BiogSubscription.resolve()` con precedencia tabla > `profiles`. |
| 7 | Bug de llenado vs madurez en manzano/peral/duraznero | **Resuelto.** Verificado: ramas separadas con textos distintos. |
| 8 | Nogal y pistacho con el mismo bug | **YA RESUELTO** — el doc del 8-ago está desactualizado. `fertilization_planner.dart:992-1017` y `:1137-1162` tienen `fruitFill`, `fruitSet` y `harvestMaturity` en tres `if` separados. La frase `'evita pasarte cerca de cosecha'` tampoco existe ya. **Actualiza ese documento.** |
| 9 | `'nopal sin espinas'` mal clasificado | **Resuelto.** *(Queda `'nopal manso'`, mismo patrón — punto 26.)* |

### 🔴 Crítico antes de cerrar la app (8)

| # | Punto | Por qué sigue siendo crítico |
|---|---|---|
| 10 | **Contrato de unidad de humedad** | B1. Es además una decisión de interfaz con el firmware: no puedes calibrar el prototipo sin ella. |
| 11 | **"Ausente = 0" en los ~34 motores de score y en la rama de árboles** | B2. Helada falsa, score de suelo falso, aviso crítico a las 3 a.m. |
| 12 | **Techo de dosis + compuerta de CE + neutralizar pH/humedad ausentes** | B3. Es el único hallazgo que puede quemar un cultivo. |
| 13 | **RLS de `device_memberships` (INSERT/UPDATE/DELETE)** | B4. Apropiación de dispositivo confirmada por explotación. |
| 14 | **`removeDevice` borra el device y cascada la telemetría ajena** | B4. Pérdida irreversible con hardware vivo. |
| 15 | **Fuga de perfil entre cuentas** | B5. Escribe el dato personal de A dentro de la cuenta de B, en la nube. |
| 16 | **Cola de sincronización: carrera + nunca drena** | B6. Pérdida determinista en cada arranque multi-dispositivo. |
| 17 | **Separación de ambientes (dev/prod)** | B7. Sin esto, la primera prueba de hardware ensucia producción. |

### 🟡 Importante, pero puede hacerse durante el prototipo físico (7)

| # | Punto | Razonamiento |
|---|---|---|
| 18 | **Observabilidad mínima** (`runZonedGuarded` + `FlutterError.onError` + destino) | Cuanto antes mejor, porque el prototipo la va a necesitar; pero no impide *cerrar*. Hazlo en la primera semana de prototipo. |
| 19 | **Vinculación real: QR y BLE** | Hoy son stubs (`qr_scan_screen.dart:90` devuelve `'BIOG-QR-001'` fijo). **Esto ES trabajo de prototipo**, no de cierre: depende de decisiones de hardware que aún no existen (¿el aparato habla BLE o WiFi? ¿trae serial de fábrica? ¿código de emparejamiento?). |
| 20 | **Conectar `TelemetryTransport` / `bindTransport()`** | Sin llamador hoy. Correcto: la costura está diseñada y no debe cablearse hasta saber cómo habla el aparato. |
| 21 | **Trampa de sesión del onboarding** | B9. Duele en retención, no en datos. Arreglable en paralelo al hardware. |
| 22 | **Escribir `firmware_version` y `raw_payload` en telemetría** | Hoy 100 % NULL. Clave para depurar hardware — pero solo tiene sentido cuando haya firmware que reportar. |
| 23 | **Bandera de presencia para `battery_pct` y `signal_rssi`** | Mismo bug de "cero sintetizado" en los dos únicos campos que quedaron fuera del arreglo. Cobra importancia cuando haya batería real. |
| 24 | **Cerrar el ciclo de trazabilidad** (leer `pending()`/`respond()` desde una pantalla) | Hoy el recorder escribe y nadie lee — el mismo defecto que la cabecera del archivo dice haber corregido. Vale más con datos reales de campo. |

### 🟠 Necesario antes de producción / lanzamiento (6)

| # | Punto | Nota |
|---|---|---|
| 25 | **Identidad de la app: `applicationId`, keystore, firma de release** | `com.example.bio_g` lo rechaza Google Play. **El `applicationId` es irreversible tras la primera subida: decídelo antes.** |
| 26 | **Assets a WebP** (222.8 MB hoy) | Bloqueante de tienda, no de prototipo. |
| 27 | **Endurecer RLS a nivel producción** | Sacar la escritura de telemetría del JWT de usuario (que escriba un gateway con `service_role`); exigir `role='owner'` en UPDATE/DELETE de `devices`; envolver los 29 `auth.uid()` en `(select auth.uid())`; activar protección de contraseñas filtradas. |
| 28 | **Notificaciones push reales** | `flutter_local_notifications` + `firebase_messaging` + desugaring de Android. Hoy la bandeja funciona y **nada suena el teléfono**. |
| 29 | **`app_links` para el reset de contraseña** | El correo se envía; el enlace no vuelve a la app. Media hora de trabajo, pero sin urgencia hasta que haya usuarios reales. |
| 30 | **Respaldo en nube de la trazabilidad** | Hoy `recommendations` y `crop_events` son **SQLite local** (corrección a la nota anterior: no son tablas de Supabase que fallen; nunca se intenta subirlas). Reinstalar la app borra el histórico. |

### 🔵 Mejora futura o V2 (5)

| # | Punto | Por qué esperar |
|---|---|---|
| 31 | **Balance hídrico real (ETc = ET0 × Kc, lámina en mm/litros)** | `grep Kc\|ETc\|cropCoefficient` → **0 resultados**. La ET0 se calcula bien y **no decide nada**. Requiere perfil de suelo y validación de campo — justo lo que dará el prototipo. |
| 32 | **Cablear planes Básico/Pro** | `BiogEntitlements` no se consulta desde ninguna pantalla. No es trabajo de código: es **decisión de producto** (qué se apaga en Básico). Y no hay cobro activo. |
| 33 | **CI / integración continua** | Con un desarrollador y sin releases, aporta poco hoy. Móntala cuando haya un segundo par de manos o un canal beta. |
| 34 | **Unificar `lib/crops` ↔ `lib/core/crops` y trocear los archivos de 275 KB** | Es layering roto, no duplicación de datos. Refactorizar antes de congelar el flujo es riesgo sin retorno. |
| 35 | **Accesibilidad completa (WCAG, `Semantics`)** | Solo 2 usos de `Semantics` en 487 archivos. Primero contraste y tamaño de texto (§6); `Semantics` después. |

### ⚪ Ya no necesario, o mejor planteado de otra forma (4)

| # | Punto | Veredicto |
|---|---|---|
| 36 | **Política DELETE en `telemetry`** | **No la hagas.** Bien descartada: la FK ya es CASCADE, el borrado de cuenta es `SECURITY DEFINER` y salta RLS, y `TelemetrySupabaseSync.delete()` no tiene llamador. Lo único que añadiría es que un cliente pueda borrar de golpe todo el historial del agricultor. |
| 37 | **Los ~70 avisos INFO del linter de Supabase** | **Ruido.** Son tablas del ERP con RLS activo y cero políticas = *deny-all*. Es el estado seguro por defecto. |
| 38 | **"Crear las tablas `recommendations` y `crop_events` en Supabase"** | **Replanteado.** No son tablas faltantes: son bases SQLite locales. El riesgo real es distinto (falta de respaldo, punto 30), y la solución es un `RecommendationSupabaseSync`, no un `CREATE TABLE`. |
| 39 | **Simulador dentro de la app** | **Correcto como está.** `kEnableSensorSimulator = false` y el `SensorSimulator` de `lib/` es puramente en memoria. El simulador que puebla Supabase es tu repo externo, y ese es el diseño correcto: separado, desechable, reemplazable por firmware. |

---

## 5. Auditoría agronómica

**Confiabilidad científica global: 68/100.** Se descompone en algo importante: **la agronomía descriptiva es de 80-85; la agronomía prescriptiva es de 45-50.** BIO-G sabe mucho de plantas y todavía no sabe poner límites a lo que ordena.

### Si yo fuera agricultor, ¿confiaría?

**En el diagnóstico y la interpretación, sí.** En la prescripción numérica, todavía no.

- **Fenología: confiaría.** Las etapas son de la especie, no de una plantilla. Cebolla, ajo, cereales con Zadoks, la distinción caducifolio/perennifolio en dormancia. Esto lo escribió alguien que sabe.
- **Sanidad vegetal: confiaría como orientación, y no es peligroso equivocarse.** El riesgo de "aplicar el tratamiento equivocado" está estructuralmente cortado porque **la app no dice qué aplicar**. Un diagnóstico errado produce a lo sumo una inspección innecesaria.
- **Riego: confiaría en la lógica, no en el umbral.** El árbol de decisión es defendible y honesto. La escala contra la que compara (B1) no lo es.
- **Fertilización: hoy no confiaría sin un análisis de laboratorio al lado.** Ni por la calibración —que es sana— sino porque no hay techo y porque la CE empuja en la dirección contraria.

### Hallazgos agronómicos, por severidad

**CRÍTICOS**

1. **Escala de humedad (B1)** — 19 de 32 cultivos revisados con targets de sustrato de maceta sobre suelo mineral. Alarma de encharcamiento inalcanzable.
2. **Ausente = 0 en score y en dosis (B2 + B3)** — helada falsa, desbalance nutrimental falso, dosis máxima sobre un canal muerto.
3. **Dosis sin techo (B3)** — `_calculateDeficitPpm` sin `clamp`.

**ALTOS**

4. **Manzano fuera de estándar** [U]. `apple_tree_universal_profile.dart:152-779`: cotas críticas **planas** en las 12 etapas — CE `highMin=3.0` siempre, resistencia `highMin=3.0 MPa` siempre. Peral y duraznero, con la misma sensibilidad real (ECe umbral ≈1.7 dS/m, Maas-Hoffman), usan 1.8-2.5; el resto del catálogo usa 2.0-2.6 MPa. **El manzano es el árbol menos alertado del catálogo pese a ser de los más sensibles a sal.** Además `:310` tiene `lowMax: 45, optimalMin: 45` — banda "baja" vacía: la lectura salta de ÓPTIMO a CRÍTICO en un punto.
5. **CE con semántica partida 16/16** [U]. La mitad de los cultivos tiene `optimalMin: 0` (CE=0 se clasifica óptima); la otra mitad penaliza el lado bajo. Un suelo lavado marca "CE óptima" en hoja y bulbo. **Decide una sola semántica y aplícala a los 85.**
6. **La CE sube la urgencia de fertilizar** (`_resolveContextModifier01`, `ec > 2.2 → +0.05`). Contradice la doctrina propia que sí está en los textos de etapa.
7. **Banda de P del manzano** [U]: óptimo 60-80 mg/kg, umbral bajo derivado 39 ppm. Bray-1 en frutales da suficiencia ~25-50 ppm. En suelo calcáreo (×1.75) la meta llega a 105-140 ppm → hasta **639 kg DAP/ha**. Antagonismo P-Zn.
8. **Maíz con 5 síndromes** de sanidad. Faltan carbón/huitlacoche, achaparramiento (*Spiroplasma*/*Dalbulus*), gallina ciega y gusano elotero. Es el cultivo nº1 de México.

**MEDIOS**

9. **Espinaca, ajo y cebolla comparten `_phStd = (5.7, 6.0, 7.5, 7.8)`.** Espinaca real: 6.5-7.5. A pH 6.0 hay clorosis y toxicidad de Mn/Al, y la app dirá "óptimo".
10. **Cebolla riega en madurez** (`onion_universal_profile.dart:356`, `45/55/80/90`) mientras el **ajo sí corta** (`curingRest = 35/45/65/82`). Regar en madurez de cebolla = cuello grueso y pudrición en almacén. Dos cultivos casi gemelos con criterios opuestos.
11. **Berenjena y calabaza sin diferenciación fenológica**: humedad, pH y temperatura idénticos en las 8 etapas, mientras tomate, chile y pepino sí varían.
12. **CE demasiado restrictiva en las especies más tolerantes**: nopal y agave (`highMin` 2.2) cuando *Opuntia* tolera 4-8 dS/m; pistachero 4.65 cuando su ECe umbral es ≈9.4. Falsas alarmas de salinidad → lavado innecesario en zona árida.
13. **`Leveillula taurica` mal señalizada** (`tomato_syndromes.dart:438-450`): agrupada con *Oidium neolycopersici* y con `signalCannotScrapeOff` como **contradictorio**. *Leveillula* es endoparásita y no se desprende al frotar — la señal descarta precisamente la cenicilla dominante en México.
14. **`nIndex` de maíz en `flowerSet` = 70-90** cuando las demás etapas van de 22 a 52 (outlier de 1.7×), y no cae en `_isNitrogenRescueStage`, así que se emite sin la advertencia de "rescate, no plan" que el propio código documenta.
15. **Extractante nunca declarado** fuera de comentarios. Bray/Olsen/Mehlich cambian el corte de "alto" hasta 4.5×. Sin base analítica declarada, las bandas de P y K **no son auditables**.
16. **Sanidad: "gana un solo síndrome"** (`plant_health_engine.dart:105`) y tope de probabilidad al **99.5 %** mostrado como elemento héroe, con el descargo a 12 px al final. Sobreconfianza sobre un triaje declaradamente orientativo.

### Lo que está sólido y no hay que tocar

- **0 rangos invertidos en 900+ tuplas.** Higiene estructural impecable.
- **Los extremos de CE están bien anclados**: frijol el más sensible (0.8/1.2 en germinación), cebada el más tolerante (5.0/8.0). Coincide con Maas-Hoffman.
- **Avena correctamente modelada como el cereal más acidotolerante** (pH `lowMax 4.5 / optMin 5.0` vs trigo 5.5/5.8). Ese detalle no se acierta por accidente.
- **Cactáceas y suculentas realmente diferenciadas**: ni una etapa idéntica entre cactus/suculenta/nopal/agave/sábila, con gradiente hídrico coherente y justificado con literatura.
- **pH por contexto en ornamentales** (maceta / jardinera / suelo), con agave y nopal tolerando más alcalinidad que cactus y suculenta. Correcto.
- **Temperaturas germinativas correctas**: maíz 12/18, lechuga 9/15/22/27 (termodormancia >27 °C), espinaca 5/7/24/27.
- **Los perennes no emiten kg/ha**, y hay un test que lo congela. Conservadurismo correcto donde el dato es más débil.
- **`tree_restitution_planner.dart`** maneja óxido vs elemental con rigor y **corrige valores erróneos del documento interno citando la fuente primaria**.
- **Rendimientos plausibles para México**: maíz 6.2-18 t/ha, trigo 3.3-8, frijol 1.2-2.8, tomate separado en campo (45-75) vs protegido (90-160).

### Sobre la calidad de los datos del simulador

Los 1,154 registros son **físicamente plausibles pero estadísticamente degenerados**: el pH se mueve 0.16 unidades en 104 días, el NPK oscila ±4 ppm, y **la batería sube de 94.5 % a 96 %** — nunca se descarga. No hay un solo evento de riego, lluvia, fertilización ni fallo de sensor. La cadencia va de 2.6 segundos a 8.7 días.

**Estos datos no ejercitan los caminos de alerta ni de dato ausente.** Antes del prototipo, vale la pena que el simulador emita: nulos, valores fuera de rango, saltos de riego y lluvia, descarga de batería y pérdida de señal. Es barato y es lo que va a pasar en campo.

---

## 6. Auditoría de producto

**Madurez de producto: 58/100.** Traducción honesta: **demo excelente, producto todavía no confiable en manos de un productor solo en su parcela.**

El motor vale ~80. La envoltura vale ~40. Y como el agricultor solo ve la envoltura, el promedio se pondera hacia abajo.

### El flujo tiene sentido

23 pantallas, 18 alcanzables, profundidad máxima 3 niveles. Cinco pestañas (Historial · Cuenta · Semillas · Entorno · **Panel**) con el Panel como CTA central. La arquitectura de información es razonable y **la redundancia es menor de lo esperado**: Panel = suelo + decisión; Entorno = aire + pronóstico; Historial = las mismas métricas en el tiempo; NPK = profundidad; Semillas = etapa. Los únicos solapes reales son **etapa** (aparece en 4 pantallas) y **rendimiento aproximado** (Semillas y Proyección).

### Lo que le falta de verdad

1. **La respuesta a la única pregunta que decide su día: ¿cuánta agua?** `IrrigationDepthEstimate` (mm, litros/planta) existe en `irrigation_types.dart:211` y **nunca se calcula ni se muestra**. La app dice "Riega ahora" y nunca cuánto ni cuánto tiempo. Sin eso, la recomendación no reemplaza su criterio: lo repite.
2. **Ayuda y soporte reales.** `account_screen.dart:492-494`: «Centro de ayuda», «Contactar soporte» y «Manual rápido Bio-G» son literalmente `() {}`. Es la **única salida** del usuario no técnico, y no hace nada. Pulsa y no pasa absolutamente nada. *(Barrido completo: solo 5 closures vacías en toda la app, 3 de ellas estas. No es un patrón sistémico — es justo el peor sitio.)*
3. **Persistencia del borrador de onboarding** (B9).
4. **Un "no lo sé" con valor típico en densidad de siembra.** `yield_projection_setup_screen.dart:2288` exige superficie **y** densidad sin precargar nada — solo un hint «Ej. 800». El onboarding sí le deja decir «No lo recuerdo» con la fecha; aquí no. Es una pantalla de 138 KB que muchos no podrán completar.
5. **Banner de conexión en las 5 pestañas.** Hoy solo en Panel y Entorno. En Historial sin señal ve «Sin datos para este rango» y cree que su sensor falló.

### Legibilidad en campo

- La pestaña activa se distingue de la inactiva por **alpha 1.0 vs 0.92** más peso de fuente. Etiquetas de 11.5 px. **Bajo sol no distingue en qué pantalla está.**
- El tab principal es un **icono de encendido sin etiqueta**: parece "apagar el aparato".
- 22 `BackdropFilter` y 82 superficies blancas translúcidas — el cristal esmerilado es lo peor posible a mediodía.
- Cero manejo de `textScaler`: si sube el tamaño de letra del sistema, los layouts fijos revientan.

### Jerga sin traducir

Una pestaña principal etiquetada **`'RT'`** (`history_metric_tabs.dart:24`) — sigla interna de "Resistencia". Y en la pantalla principal, a **11.8 px en gris 54 %**: *"~0.02 g/kg de suelo; ~45 kg/ha de nutriente puro con el default BIO-G de 20 cm y 1.2 g/cm³"*. `MPa`, `mg/kg` y `CE` no se explican en ningún lado.

### Lo que ya está bien y no hay que tocar

Tres textos reales del código que son ejemplares:

- `onboarding_wizard_screen.dart:697` — **«Recomendado si no sabes la variedad»**. Contesta exactamente la duda del productor en el momento en que la tiene.
- `fertilization_planner.dart:1708` — **«¡Viene el estirón de la milpa! Aplica $puroText ahora para que esté disponible cuando la mazorca lo pida.»** Registro de campo, momento y motivo.
- `irrigation_engine.dart:95` — **«No se recomienda riego sin dato de humedad. Revisa que el Bio-G esté...»** La app admite que no sabe en vez de inventar. Reforzado por `irrigation_evidence_note.dart:128`: «Confirma en campo antes de aplicar.»

Y también: los estados vacíos honestos (`'--'`, `'Sin datos del sensor'`), el triaje sintomático parte→síntoma→señales, y las salidas «No lo recuerdo muy bien» del paso de fecha.

### Lo que sobra

El segundo wizard (`configure_seed_wizard_*`, ~200 KB) duplica el onboarding con vocabulario divergente · 4 steps muertos en `screens/onboarding/steps/` · `auth_gate.dart` (nadie lo importa) · el **toggle °C/°F, que se guarda y nunca se lee** (no existe conversión a Fahrenheit en el código) · dos interruptores de notificación (`hardware` y `account`) que **nunca reciben eventos** · la mitad del cristal esmerilado.

---

## 7. Qué NO debemos hacer todavía

Esta sección importa tanto como la de bloqueadores. **El riesgo de un proyecto en este punto no es quedarse corto: es seguir construyendo.**

| No hagas ahora | Por qué |
|---|---|
| **BLE, push, deep links, `in_app_purchase`** | Cinco de las seis fases de dependencias pendientes. Cada una añade configuración nativa, permisos y superficie de fallo **para funciones que el prototipo aún no puede ejercitar**. Las costuras ya están escritas: enchufarlas después cuesta lo mismo. |
| **Balance hídrico / ETc / lámina de riego** | Requiere perfil de suelo real y validación de campo. Construirlo antes del prototipo es inventar constantes que el prototipo va a desmentir. *(Excepción: si no lo construyes, **retira la ET0 de la interfaz** — hoy es precisión aparente que no influye en nada.)* |
| **Cablear el gating de planes Básico/Pro** | No es trabajo de código: el modelo está escrito y probado. Es **decisión de producto** y no hay cobro activo. Cablearlo ahora congela una decisión comercial que aún no has tomado. |
| **CI / GitHub Actions** | Con un desarrollador y sin canal de releases, el retorno es casi cero. Móntala cuando haya un segundo par de manos. |
| **Refactorizar los archivos de 275 KB / 138 KB / 115 KB** | El riesgo de romper supera el beneficio **hasta que el flujo esté congelado**. Congélalo primero. |
| **Unificar `lib/crops` ↔ `lib/core/crops`** | Es layering feo, no duplicación de datos, y no produce ni un solo consejo equivocado. |
| **Accesibilidad WCAG completa / `Semantics`** | Primero contraste y tamaño de texto (que sí afectan a un productor bajo el sol). El lector de pantalla, después. |
| **Nuevos cultivos** | Ya hay **85 habilitados**. Añadir el 86 antes de arreglar la escala de humedad multiplica el problema por 86. |
| **Sincronizar la trazabilidad a la nube** | Vale mucho más con datos reales de campo. Hoy respaldaría decisiones tomadas sobre datos de simulador. |
| **`applicationId`, keystore, assets a WebP** | Son de tienda, no de prototipo. **Pero decide el `applicationId` antes de la primera subida: es irreversible.** |
| **Migrar `biog://` a App Links verificados** | Producción. Para V1-A el custom scheme es aceptable. |

---

## 8. Ruta final de cierre

Ordenada por retorno, con estimaciones honestas. **Total: ~35-45 horas de trabajo enfocado (5-7 días).**

### Paso 0 · Lo que corres tú, antes que nada (30 min)

```powershell
cd C:\Users\oscar\Documents\bio_g
flutter analyze
flutter test
```

El documento del 8 de agosto predice **0 errores y 1,530 pruebas en verde**, pero esos cambios **no estaban commiteados** cuando revisé el repo, así que ese resultado no está confirmado. Es la única pieza de la auditoría que me falta. Pégame la salida si algo sale rojo.

### Bloque A · Que la app no mienta (16-20 h) — *innegociable*

| | Tarea | Horas |
|---|---|---|
| A1 | **Definir el contrato de humedad en UN solo sitio.** Un archivo `moisture_scale.dart` con la escala canónica, su origen (firmware `(1023−ADC)/1023×100`) y qué significa. Alinear `irrigation_inputs.dart:56` y el comentario de `biog_telemetry.dart:170`. **Decidir con el firmware si el aparato entrega índice relativo o VWC.** | 3-4 |
| A2 | **Recalibrar los cultivos de suelo mineral** contra esa escala. Mínimo viable: `lowMax ≈ 0.6×CC`, `highMin ≈ 1.15×CC` del franco, y **bajar el umbral de encharcamiento por debajo de 55** para que la alarma sea alcanzable. Además: quitar el `_plausible(0,100)` que convierte >100 en "ausente". | 5-6 |
| A3 | **Extender las banderas de presencia** a los ~34 motores de score y a `_buildTreeDashboardEvents`. El patrón correcto ya existe en `tree_agro_score_engine.dart:262`. Es mecánico. | 5-6 |
| A4 | **Techo de dosis** (`min(déficit, extracción_máxima_de_etapa)`), **pasar `ec` a `buildGuide`** con compuerta de salinidad, **invertir el signo del término de CE**, y neutralizar pH/humedad ausentes en `_resolveContextModifier01`. | 4-5 |

### Bloque B · Que no pierda ni filtre datos (10-13 h) — *innegociable antes del hardware*

| | Tarea | Horas |
|---|---|---|
| B1 | **RLS de `device_memberships`**: quitar la política INSERT abierta, mover el alta a un RPC `SECURITY DEFINER` que exija `serial_number` + código de emparejamiento, y **añadir políticas UPDATE/DELETE** para que el owner pueda revocar. | 3-4 |
| B2 | **`removeDevice`**: borrar solo la membresía; el `delete` de `devices` únicamente si no quedan membresías (mejor, en el servidor). Y `devices_user_id_fkey` → `ON DELETE SET NULL`. | 2-3 |
| B3 | **Namespacing por `userId`** en `ProfileLocalService`, `TelemetryLocalStorage`, `TelemetryIngestService` y la bandeja de notificaciones + purga en `signOut`. **Y quitar el backfill de avatar** que sube la foto de A a la cuenta de B. | 3-4 |
| B4 | **Serializar la cola de sincronización** (una única cadena `Future`: `_lock = _lock.then(...)`) y **disparar `drain()`** desde un `WidgetsBindingObserver` en `resumed` + el `_check()` del banner de conectividad. | 2-3 |

### Bloque C · Que puedas trabajar con hardware (6-8 h)

| | Tarea | Horas |
|---|---|---|
| C1 | **Separar ambientes**: `SupabaseConfig` con `String.fromEnvironment` + `--dart-define-from-file`, y un segundo proyecto Supabase para dev/staging. | 2-3 |
| C2 | **Observabilidad mínima**: `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`, con destino (Sentry, o una tabla `app_errors` en Supabase si prefieres cero dependencias). Y quitar el `catch (_)` de `irrigation_coordinator.dart:169`. | 3-4 |
| C3 | **Enriquecer el simulador** para que emita nulos, valores fuera de rango, descarga de batería, pérdida de señal y eventos de riego/lluvia. Es lo que va a pasar en campo y hoy no se prueba nunca. | 1-2 |

### Bloque D · Dignidad de producto (5-6 h)

| | Tarea | Horas |
|---|---|---|
| D1 | **Sellar la trampa de sesión**: confirmación antes de salir del paso 1 + persistir `OnboardingDraft` + reanudar en vez de desloguear. | 3-4 |
| D2 | **Cablear ayuda, soporte y manual** — aunque sea un `mailto:`, un WhatsApp y un PDF local. O esconderlos. Un botón muerto en la única salida del usuario no técnico es peor que no tenerlo. | 1 |
| D3 | **Sacar la jerga de la superficie**: `'RT'` → «Suelo apretado», mover el bloque de g/cm³ al PDF, borrar el toggle °C/°F y los dos interruptores de notificación sin eventos. | 1 |

### Bloque E · Barato y de alto retorno si sobra tiempo (4-6 h)

- Las **6 deudas puntuales de especie**: pH propio para espinaca · secado pre-cosecha en cebolla · nivelar el manzano al patrón de peral · CE real de nopal/agave/pistachero · unificar la semántica de CE baja · señal de *Leveillula* en tomate.
- **Bajar el tope de probabilidad de sanidad** de 99.5 % a 90 % y subir el descargo por encima del porcentaje.
- **Test del `PlantHealthEngine`** (575 líneas con softmax y **cero pruebas**) y test de presencia de sensores en los motores de score.
- **Anclar el test de ET0** contra los ejemplos 8 y 20 de FAO-56 (hoy el test recalcula Ra con la misma función que valida).

---

## 9. Veredicto final

> ### **CERRAR DESPUÉS DE CORREGIR UNOS POCOS PUNTOS.**
> **No mantengas el desarrollo de software abierto. Y no cierres este fin de semana.**

**No es "hay problemas importantes".** La arquitectura es sana, el dominio es profundo, las costuras con el hardware están bien elegidas, y no encontré un solo rediseño escondido. Nada de lo que falta requiere repensar el producto.

**Tampoco es "ya está".** Hay ocho cosas que, con hardware real conectado, producirían consejo equivocado o pérdida irreversible de datos. Y una de ellas —el contrato de unidad de humedad— **no es opcional aplazar: es una decisión de interfaz con el firmware que el prototipo necesita tomada antes de existir.**

### Sobre tu fin de semana

Con honestidad: **los bloques A y B son ~30 horas.** Un fin de semana intenso (dos días de 10-12 h) cubre el bloque A completo o el bloque B completo, no ambos. Mi recomendación concreta:

- **Este fin de semana: bloque A** (que la app no mienta). Es lo que decide si un agricultor puede confiar en BIO-G, y es la parte que **necesitas resuelta para diseñar la calibración del prototipo**.
- **Primeros 3-4 días de la semana: bloque B + C.** Se solapan naturalmente con el arranque del prototipo, porque son exactamente lo que el hardware va a ejercitar.
- **Bloque D en paralelo**, cuando necesites descanso del código de motores.
- **Declara cerrada la fase al terminar B.** El bloque E es bienvenido pero no condiciona el cierre.

### Lo que NO debe entrar en ese cierre

Repito lo de §7 porque es donde más fácil se pierde un proyecto en esta etapa: **BLE, push, deep links, cobro, CI, balance hídrico, refactors y cultivo nº86 se quedan fuera.** Están correctamente diseñados como costuras apagadas. Encenderlos antes de tener firmware es construir contra un aparato imaginario.

### Y una cosa que sí quiero decirte

De todo lo que revisé, lo que más me llamó la atención no fue un bug. Fue `soil_reaction.dart` negándose a ajustar N y K porque *"ajustarlos sería inventar"*, y `irrigation_engine.dart` diciéndole al agricultor «no recomiendo riego sin dato de humedad» en vez de adivinar.

**Ese instinto —preferir callar antes que mentir— es el activo más valioso de BIO-G**, y es exactamente el que los ocho bloqueadores traicionan sin querer: un sensor caído que grita "helada crítica", una escala que dice "riega" el 95 % del tiempo, una dosis sin techo. No son fallos de criterio. Son sitios donde el criterio, que ya está escrito en tu código, todavía no llegó.

Ciérralos y la fase de software está terminada de verdad.

---

### Anexo · Verificación pendiente

| Pieza | Estado | Quién |
|---|---|---|
| `flutter analyze` · `flutter test` | **No verificado** — Flutter no disponible en el puente ni en el sandbox | **Tú** |
| Configuración nativa Android/iOS (`applicationId`, firma, permisos, key de Maps) | **No verificado** — la copia auditada no incluye `android/` ni `ios/` | **Tú** |
| Redirect URLs de Auth en Supabase | **No verificable por MCP** — requiere el panel | **Tú** |
| CI (`.github/workflows`) | **No verificable** — no está en la copia auditada | **Tú** |
| Todo lo demás (código, base de datos, políticas RLS, datos de telemetría) | **Verificado** contra el código y la base reales | — |
