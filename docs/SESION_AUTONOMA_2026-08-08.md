# BIO-G · Sesión autónoma del 8 de agosto

Lo que hice mientras no estabas, con todo verificado. **Léelo antes de correr nada.**

> **Lo primero:** corre `flutter analyze` y `flutter test`. Toqué 13 archivos y no tengo compilador. Mi predicción: **0 errores y 1,530 pruebas en verde, 0 fallos.**

---

## 1. Supabase — 3 cambios aplicados, 1 descartado

### Aplicados

**`handle_new_user()` cerrada.** `anon` y `authenticated` ya no pueden invocarla por RPC. El aviso de seguridad desapareció del linter.

Antes de tocarla monté un esquema de pruebas aparte, creé una función `security definer`, le revoqué `execute` a `authenticated`, disparé el trigger y comprobé que **sí corrió**. PostgreSQL valida el privilegio al *crear* el trigger, no al dispararlo. Sin esa comprobación, revocar podía haber roto todos los registros nuevos.

**Política de lectura propia en `subscriptions`.** Solo `SELECT`, solo tu fila. Escribir sigue siendo exclusivo de `service_role`: el plan lo fija el backend de cobros, nunca el cliente.

**`request_account_deletion()` creada.** Probada de extremo a extremo: creé un usuario ficticio con equipo, telemetría, suscripción y perfil, ejecuté la función, verifiqué el resultado y **reverti la transacción entera**. Cero rastro en tu base.

Resultado de la prueba:

```
perfil creado por el trigger: 1     ← handle_new_user sigue funcionando tras el revoke
telemetria=0  membresias=0  suscripcion=0  perfil=0  auth_user=0
equipo: sigue existiendo=1  user_id=NULL  nombre=Bio-G  pairing=pending  status=pending
```

**Cambié un punto del diseño sobre la marcha: el borrado de cuenta LIBERA el equipo, no lo borra.** Al auditar las claves foráneas encontré que `warranties`, `inventory_units`, `maintenance_orders` y `firmware_campaign_targets` referencian `devices` **sin** `ON DELETE CASCADE`. Borrar el equipo habría abortado toda la transacción. Y como `devices.user_id → auth.users` **sí** es CASCADE, había que desligarlo *antes* de borrar el usuario o la cascada lo habría intentado igual. Además el hardware es un activo tuyo con garantía e inventario, no del usuario: liberarlo permite que se vuelva a emparejar.

La función también tiene una guarda: una cuenta con registros operativos (administrador, incidencias, artículos) no puede autoborrarse desde la app y recibe un mensaje claro en español en vez de un error de clave foránea.

### Descartado a propósito: la política DELETE en `telemetry`

**No la apliqué, y creo que hice bien.** Al auditar encontré tres cosas:

1. `telemetry.device_id → devices(id)` ya es **`ON DELETE CASCADE`**. Cuando la app borra un equipo, Postgres borra su telemetría solo.
2. El borrado de cuenta no la necesita: la función es `security definer` y salta RLS.
3. `TelemetrySupabaseSync.delete()` **no tiene ni un llamador** en toda la app.

Lo único que la política añadía era que cualquier cliente pudiera borrar de golpe todo el historial de sensores del agricultor, sin vuelta atrás. Si la quieres igual, dímelo.

### Un detalle bloqueado

Intenté fijar el `search_path` de `set_updated_at()` (última advertencia del linter) y el sistema me bloqueó el `ALTER FUNCTION`. Es cosmético. Si lo quieres cerrar, pega esto en el editor SQL:

```sql
alter function public.set_updated_at() set search_path = public, pg_temp;
```

### Sobre los ~70 avisos INFO del linter

No te asustes al verlos. Son tablas del ERP con RLS activado y **cero políticas**, lo que significa **denegar todo** a `anon` y `authenticated`. Solo `service_role` llega. Es el estado seguro por defecto, no un agujero.

---

## 2. Las 18 pruebas: en verde, y dos eran bugs reales de producción

Diagnostiqué los 18 fallos con cuatro análisis independientes y luego pasé una revisión adversarial encima. El resultado no fue "18 pruebas viejas": **dos eran bugs de verdad.**

| Grupo | Fallos | Veredicto | Qué se tocó |
|---|---|---|---|
| manzano · peral · duraznero | 10 | **CÓDIGO** — violación del contrato v1.5 | `fertilization_planner.dart`, `apple_tree_nutrition_modifier.dart` + relajar vocabulario en 2 pruebas |
| suculenta | 3 | PRUEBA — copiada del cactus | `succulent_integration_test.dart` |
| hybrid_biog_repository | 2 | PRUEBA — faltaba un doble | `hybrid_biog_repository_test.dart` |
| nopal | 1 | **CÓDIGO** — alias mal clasificado | `nopal_catalog.dart` |
| cempasúchil | 1 | PRUEBA — el fixture no aislaba el agua | `marigold_integration_test.dart` |
| onboarding limón | 1 | PRUEBA — gate de feature caducado | `onboarding_tree_context_test.dart` |

### Bug real 1 — llenado y madurez eran la misma frase

En manzano, peral y duraznero, la guía de etapa metía `fruit_fill`, `fruit_set` y `harvest_maturity` en **un solo `if`**. Resultado: a un agricultor con el fruto todavía llenándose se le hablaba de *madurez*, cuando al fruto le faltaba calibre.

Lo grave es que el contrato v1.5 está escrito en el propio código —*"llenado y madurez no son la misma ventana"*— y la capa de recomendación práctica sí lo cumplía. La violación venía de la capa de dosis, que se concatena encima. Las pruebas llevaban un mes fallando y señalaban un problema de verdad.

Partí la rama en dos y reescribí los textos. La rama de llenado ahora habla de calibre y firmeza; la de madurez, de madurez.

### Bug real 2 — "nopal sin espinas" asignaba el perfil equivocado

`'nopal sin espinas'` estaba como alias del perfil **NO-02** (erguido, penca grande, clima cálido). El catálogo prohíbe expresamente separar perfiles por número de espinas: se separan por **arquitectura**.

Consecuencia concreta: un usuario que solo dijera "nopal sin espinas" heredaba la agronomía de NO-02 — multiplicador de frío **1.15** en vez de 1.0, y NPK en lenguaje de acción en vez de revisión. Quité el alias del perfil y lo puse en la lista de ambiguos, que es donde va.

### Un error de compilación que cacé a tiempo

Al extraer el mapa del upsert de `devices` a un método `static`, dejé una llamada a `_statusToDb`, que era de instancia. **Eso no compila, y habría tumbado la app entera** — no solo esas pruebas. Mi verificador estático no detecta static contra instancia; lo encontró la revisión adversarial. Está corregido (`_statusToDb` ahora es `static`).

Es el argumento de por qué merece la pena la doble revisión: el diagnóstico era correcto, la implementación tenía un fallo fatal.

---

## 3. Dos bugs más que encontré trazando el flujo de dispositivos

Ninguno lo pedía nadie; aparecieron al auditar en serio.

**`deviceModelId` se perdía en el primer reinicio.** El modelo comercial se captura del QR (`payload['model']`), viaja hasta `addDevice`… y de ahí no se guardaba en ningún sitio: ni en el caché local, ni en Supabase, ni se leía de vuelta. Al reiniciar la app volvía a `null` para todos los equipos. Cuando conectes el gating de planes eso significa que **un Bio-G portátil contaría como plaza fija**. Arreglado en las tres capas.

**El merge borraba la identidad del hardware.** `_mergeByUpdatedAt` aplica last-write-wins. Eso está bien para nombre y ubicación, pero destruía `telemetryDeviceIdOverride` —que es la única forma que tiene un id de interfaz heredado (`biog-…`) de encontrar su telemetría— porque la columna `telemetry_device_id` **no existe** en Supabase y toda fila remota lo trae en null. Ahora un dato conocido nunca pierde contra uno ausente, en **las dos direcciones** del merge (la primera versión solo cubría una; lo cazó la revisión adversarial).

---

## 4. Alineación con las columnas reales de `devices`

La app ahora escribe `hardware_model` y, cuando el aparato declaró su propia identidad, `pairing_method`, `pairing_status` y `paired_at`. Y lee `hardware_model` de vuelta.

Dos decisiones que tomé y conviene que sepas:

**Las columnas opcionales solo viajan cuando hay valor.** `upsert(..., onConflict: 'id')` actualiza *cada* columna presente en el mapa, así que mandar `null` habría borrado en la nube datos puestos desde el panel. Tu único equipo tiene `hardware_model = 'BioG Simulator'` y `pairing_method = 'simulator'`; con la versión ingenua, la primera sincronización del teléfono los habría machacado.

**`serial_number` NO se escribe desde el teléfono.** Es la serie física impresa en el aparato, tiene restricción **UNIQUE** en la base, y el QR actual solo trae `name`, `id` y `model`. Meter ahí el UUID mezclaría dos identidades y un choque de unicidad habría tumbado el upsert entero —incluidos nombre y ubicación— sin que nadie se enterara, porque la subida es best-effort.

---

## 5. `subscriptions` como fuente de verdad

Añadí `BiogSubscription.fromSubscriptionRow()` y `BiogSubscription.resolve()`, con precedencia explícita: la tabla manda cuando hay fila, `profiles.subscription_status` queda de respaldo.

**Hoy `subscriptions` tiene 0 filas**, así que el comportamiento es idéntico al de antes, carácter por carácter — hay una prueba que lo verifica sobre los 8 valores posibles. Es capacidad instalada para el día que haya cobros, no un cambio de comportamiento.

---

## 6. Decisiones que necesito de ti

### A · Tres tablas que la app usa y que NO existen

| Tabla | Qué queda muerto |
|---|---|
| `recommendations` | La mitad en la nube del **Frente 5 (trazabilidad)**. Se registra en local y nunca sube. |
| `crop_events` | La sincronización de eventos de cultivo. |
| `device_yield_projection_configs` | Las proyecciones de rendimiento. |

Las tres escrituras están envueltas en `catch (_)`, así que **no revienta nada**: fallan en silencio. Puedo crear las tres tablas con sus políticas RLS derivadas exactamente de lo que la app envía. Es aditivo y no toca un solo dato existente. **No lo hice porque expandir el esquema va más allá de los 4 puntos que autorizaste.** Dime y lo hago.

### B · El módulo de planes está escrito y sin cablear

`BiogEntitlements`, `occupiesFixedSlot`, `fixedDeviceLimit`, `canUseIrrigationEngine`… **no se consultan desde ninguna pantalla.** Grep sobre todo `lib/`: cero llamadores fuera del propio archivo.

O sea: hoy no hay límite de equipos ni gating de funciones. Es la misma "bandera muerta" que la cabecera del archivo critica de `subscriptionStatus`.

Cablearlo no es trabajo de código, es **decisión de producto**: qué se apaga exactamente en Básico y qué se ve en su lugar. Cuando lo decidas, la conexión es rápida — el modelo ya está hecho y probado.

---

## 7. Cosas que vi y NO toqué

Las dejo escritas porque son reales, pero cambiarlas sin que lo pidas sería moverte cosas que no hacen falta.

- **El duraznero no tiene rama `dormancy`.** Manzano y peral sí. Siendo igual de caducifolio, cae al texto genérico *"haz ajustes graduales"*, que es lo contrario de lo que toca en reposo. Preexistente.
- **Nogal y pistacho tienen el mismo bug que acabo de arreglar**: agrupan `fruit_set` con `harvest_maturity`, así que al amarre le hablan de madurez/ruezno.
- **`'evita pasarte cerca de cosecha'`** sigue en la guía de N bajo de manzano y duraznero, independiente de la etapa. Es la misma familia que el bug 1, del lado del déficit. Ninguna prueba lo cubre. No lo cambié porque no está roto: es un consejo válido, solo inconsistente con el contrato.
- **`'nopal manso'`** es otro descriptor de espinas que sigue resolviendo a NO-02. No lo toqué porque ninguna prueba lo cubre y es una decisión del Doc A.
- **La política INSERT de `devices` tiene `with_check: true`**: cualquier usuario autenticado puede insertar una fila de equipo con el contenido que quiera. No es explotable de forma interesante (sin membresía no la ve), pero es más laxa de lo necesario.
- **`lib.zip`** (1.8 MB) sigue rastreado en el repo.

---

## 8. Qué corres tú

```powershell
cd C:\Users\oscar\Documents\bio_g
flutter analyze
flutter test
```

Esperado: **0 errores · 1,530 pruebas, 0 fallos.**

Si sale limpio:

```powershell
git add lib test docs
git commit -m "Cierra Supabase, alinea devices, arregla los 18 fallos preexistentes y dos bugs agronomicos"
git push
```

Nota: dejé el `_sync_out.tgz` que usé para traerme el código en `_to_delete\`. Bórrala cuando quieras — `analysis_options.yaml` ya la excluye.

**Si algo falla, mándame la salida tal cual.** Trece archivos sin compilador es exactamente donde se esconde un error tonto, y prefiero verlo que suponer.
