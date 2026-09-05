# BIO-G · Auditoría integral · 31 de agosto de 2026

Auditoría desde cinco perfiles: **ingeniero de software senior**, **backend/web**,
**ingeniero agrónomo**, **agricultor usuario** e **integrador de hardware**.

**Base:** el código real en `C:\Users\oscar\Documents\bio_g` y la base Supabase
real (`akujcvatjtfeevlxdrfx`), consultada en vivo.

> ## ⚠ Corrección · 31 de agosto, misma tarde
>
> Oscar revisó este informe y encontró **un error mío de bulto** en la sección
> agronómica. Lo corregí abajo y dejo constancia aquí porque cambia la lectura:
>
> **Dije que el frijol "corre con el motor genérico". Es falso.** Medí solo
> `lib/core/crops/<cultivo>/` y los motores de score viven en `lib/core/agro/`.
> El frijol tiene `bean_agro_score_engine.dart`, **515 líneas propias**.
>
> Peor: afirmé que "un motor genérico ignora sus rizobios". También falso. La
> fijación biológica está modelada explícitamente —inhibición de la nodulación
> por exceso de N, el papel del P en nodular, etapa "Arranque (pre-nodulación)"—
> en `alerts_engine.dart`, `fertilization_planner.dart` y
> `nutrient_recommendation_engine.dart`.
>
> **La sección §4 "asimetría de cultivos" queda retirada por completo.** No
> había hallazgo. Y como esa lectura alimentó mi estimación de madurez, también
> retiro el número de "55 % listo para el agricultor" (ver §0).

**Lo que NO pude verificar** (igual que la auditoría del 9 de agosto): `flutter
analyze` y `flutter test`. No hay Flutter ni acceso a pub.dev desde donde corro.
Eso lo corres tú. Todo lo demás está verificado contra el código y la base.

---

## 0. Veredicto

Quité la tabla de porcentajes que tenía aquí. Dos razones, y las dos son mías:

1. El "55 % listo para el agricultor" salía de una definición que **yo inventé**
   y que Oscar no comparte. No es una medida, es una opinión disfrazada de dato.
2. Parte de esa opinión venía de la sección agronómica que resultó **estar mal**.

Lo que sí sostengo, porque son hechos verificables y no juicios:

- **De los 9 bloqueadores del 9 de agosto, 3 están cerrados y 6 siguen abiertos.**
  Es un conteo, no una estimación. El detalle está en §1.
- **No se puede recuperar la contraseña.** La app no captura el enlace del correo.
- **Cero observabilidad.** Cero coincidencias de `runZonedGuarded`,
  `FlutterError.onError`, Sentry o Crashlytics en 506 archivos.
- **La política de `device_memberships` no valida el dispositivo** (B4, §3).
- **5 `testWidgets`** en 1 649 pruebas.

Sobre "cuánto falta": Oscar dice ~80 % y que lo que queda es de lo más sencillo
de hacer. Con la corrección agronómica encima, **no tengo base para
contradecirlo.** Lo que queda son piezas conocidas, acotadas y sin rediseño
escondido — que es exactamente lo que dijo también la auditoría de agosto.

Mi única reserva, y la dejo como reserva y no como veredicto: lo que falta es
sencillo **de escribir**, pero la recuperación de contraseña y la observabilidad
son las dos que un usuario nota el primer día y que no se pueden probar sin
usuarios. Ahí conviene no dejarlas hasta el final.

## 1. Qué pasó con los 9 bloqueadores del 9 de agosto

Esto es lo más útil que puedo decirte, porque responde directo a "¿qué tanto
nos falta?". Verifiqué cada uno contra el código y la base de hoy.

### ✅ Cerrados o sustancialmente cerrados (3)

| # | Bloqueador | Evidencia de que se cerró |
|---|---|---|
| **B3** | Prescripción sin compuerta de salinidad | Hay **compuertas EC reales**, no texto: `if (ec != null && ec > 2.2)` y siete cortes más, con umbral más estricto en etapa reproductiva crítica (`isCriticalRepro ? 1.8 : 2.1`). `NpkCaps` da techo por cultivo. |
| **B6** | La cola de sync pierde operaciones | `PendingSyncQueue` serializa con `_chain` (mata la carrera) y `flushPending()` **ya tiene llamador vivo** en `biog_store.dart:177`. |
| **B9** | Trampa de sesión del onboarding | `_signOutStaleSession()` existe en `bootstrap_gate.dart`. |

### 🔴 Siguen abiertos (6)

| # | Bloqueador | Evidencia de que sigue abierto |
|---|---|---|
| **B1** | **Contrato de unidad de humedad** | `biog_telemetry.dart:170` sigue diciendo `final double soilMoisturePct; // %`. Sin tipo de escala, sin VWC declarado. **40 cultivos siguen con `optimalMin: 60`** — justo donde tu propio firmware declara "Saturado". Sigue siendo el hallazgo #1. |
| **B2** | "Sensor ausente = 0" en motores de score | **8 de 26** motores de score todavía tienen `?? 0.0`. Corregido en la ruta de eventos, no en todas las fronteras. |
| **B4** | Cualquier cuenta puede apropiarse de un BIO-G | **Confirmado en la política RLS de hoy.** Detalle abajo en §3. |
| **B5** | Fuga de datos entre cuentas en el mismo teléfono | El propio código lo documenta y declara que no se tocó: `account_deletion_service.dart:229` — *"el logout destruye lo que debería conservar y conserva lo que debería destruir"*. |
| **B7** | Un solo ambiente, todo hardcodeado | `supabase_config.dart` sigue con URL y llave como constantes. Cero separación dev/prod. |
| **B8** | Cero observabilidad | Cero coincidencias de `runZonedGuarded`, `FlutterError.onError`, Sentry o Crashlytics en las 506 fuentes. Si la app truena en el campo, no te enteras nunca. |

**Traducción:** en tres semanas cerraste los tres bloqueadores de *lógica*.
Los seis que quedan son de *contrato, plataforma y seguridad* — que es
exactamente el trabajo que se posterga cuando uno está entusiasmado con el
hardware. Es normal. Pero B1 y B4 no aguantan el prototipo.

---

## 2. Perfil: ingeniero de software senior

### Lo que está bien y no es común

- **506 archivos, 245 mil líneas, y solo 11 marcas de TODO/FIXME** — y la mayoría
  son falsos positivos (la palabra española "TODOS"). Eso es disciplina real.
- **3 `catch` vacíos, 1 `print` crudo, 26 `debugPrint`** en todo el proyecto.
- **1 649 pruebas** en 86 archivos, 27 mil líneas. Subiste 116 pruebas desde el
  9 de agosto.
- Inyección por constructor, interfaces reales, motores puros sin `BuildContext`.
  El código es testeable y se nota que fue diseñado, no acumulado.

### 🔴 El agujero real: la UI no tiene pruebas

```
1 649 pruebas totales
    5 testWidgets   ← toda la cobertura de interfaz del proyecto
```

Las 1 644 restantes prueban catálogos, fenología y motores. **Cero pruebas de
autenticación, cero de onboarding, cero de sincronización de pantalla.** Las
tres capas donde un agricultor realmente se atora son las tres sin red.

No te pido cobertura de UI completa. Te pido **cinco `testWidgets` de flujo**:
alta de cuenta, onboarding completo, dashboard sin datos, pérdida de red a
media captura, y borrado de cuenta. Es medio día y cubre el 80 % de lo que
rompe en manos de un usuario.

### 🟡 Otros

- `AnimationController` aparece 107 veces contra 48 `dispose()`. No es
  concluyente (hay States con varios controladores) pero merece una pasada.
- El motor nutrimental tiene un archivo de **277 KB** (`nutrient_recommendation_
  engine.dart`). Funciona, pero ya está en el rango donde un archivo se vuelve
  imposible de revisar. No lo refactorices ahora — anótalo para después del
  hardware.

---

## 3. Perfil: backend / web

### Las políticas RLS de la app están bien pensadas

Verifiqué las 11 tablas de la app. Todas usan `auth.uid()` con alcance por
membresía. **Ni una sola `USING (true)`.** El `DELETE` de `devices` exige
`role = 'owner'`. Eso es trabajo correcto.

### 🔴 B4 confirmado: cualquiera puede auto-inscribirse a un dispositivo ajeno

La política de `device_memberships` para INSERT es, literalmente:

```sql
WITH CHECK (auth.uid() = user_id)
```

No verifica **nada** sobre el dispositivo. Todo el modelo de seguridad cuelga de
`device_memberships`, y la tabla deja que cualquier usuario autenticado se
inscriba a **cualquier** `device_id`. Con eso obtiene lectura de toda la
telemetría, contextos de cultivo y proyecciones de rendimiento de ese aparato —
y como `role` tiene `DEFAULT 'owner'`, también obtiene derecho de **borrarlo**.

**Lo que baja la severidad:** `devices.id` es `uuid` con `gen_random_uuid()`.
No se adivina por fuerza bruta. Hoy no es explotable a ciegas.

**Lo que la sube:** el UUID va a salir de la app. Va a estar en un QR de
emparejamiento, en un ticket de soporte, en una captura de pantalla, en el panel
de admin, en un CSV de distribuidores. **El día que un UUID se filtre, ese
BIO-G se pierde para siempre** — porque tampoco hay política de DELETE en
`device_memberships`, así que el intruso no se puede quitar.

**El arreglo correcto no es parchar la política.** Es que el emparejamiento
exija un **secreto que solo tiene quien tiene el aparato en la mano** (un código
de emparejamiento impreso o emitido por BLE), y que la membresía se cree desde
una función `SECURITY DEFINER` que valide ese secreto. Eso es media jornada y
es **decisión de hardware**: el código tiene que existir en el firmware. Por eso
te lo marco ahora, antes de que congeles el ESP32.

### 🟠 Otros hallazgos de base de datos

| Hallazgo | Severidad | Detalle |
|---|---|---|
| `devices` INSERT permite `user_id IS NULL` | Media | `WITH CHECK ((user_id IS NULL) OR (user_id = auth.uid()))`. Cualquier autenticado puede crear filas huérfanas sin límite. Vector de spam. |
| UUID de admin **hardcodeado** en 2 políticas | Media | `auth.uid() = '7d4a294c-…'::uuid` en `admin_audit_log` y `subscriptions`. Un segundo admin exige una migración. Debería ser un rol o un claim. |
| **29 avisos `auth_rls_initplan`** | Media | `auth.uid()` se re-evalúa **por fila**. Con 1 770 lecturas no se nota; con un millón sí. Arreglo mecánico: envolver en `(select auth.uid())`. Es de los cambios de mejor relación esfuerzo/beneficio que tienes. |
| Sin política DELETE en `telemetry`, `crop_care_history`, `device_crop_items` | Media | El usuario no puede borrar sus propios datos. Roza el derecho de supresión. |
| **70 tablas del ERP con RLS activo y CERO políticas** | ⚠️ **Pregunta abierta** | `leads`, `invoices`, `orders`, `payments`, `commissions`, `distributors`, `warranties`, `tickets`, `meetings`… Casi todas vacías. Cerrado por omisión = seguro **si** nadie las lee. **Pero si tu panel de admin las consulta, tiene que estar usando `service_role`. Si esa llave está en un navegador, toda la base está expuesta.** Necesito que me confirmes cómo lee el panel. |
| Protección de contraseñas filtradas **desactivada** | Baja | Supabase puede contrastar contra HaveIBeenPwned. Es un switch. |
| `telemetry_backup.device_id` es `text`, el resto `uuid` | Baja | La política castea `(dm.device_id)::text`. Inconsistencia de esquema. |
| 32 llaves foráneas sin índice, 1 índice duplicado | Baja | Ruido en su mayoría sobre las tablas ERP vacías. |

### 🟡 Migraciones

Solo hay **2 archivos** en `supabase/migrations/`, pero la base tiene 81 tablas.
El esquema real vive en la nube y no en el repo. Si pierdes el proyecto Supabase
o necesitas un ambiente de pruebas, no lo puedes reconstruir. `supabase db pull`
resuelve esto en diez minutos y cierra la mitad de B7.

---

## 4. Perfil: ingeniero agrónomo

### Lo que sostengo que está por encima del mercado

- **32 catálogos de sanidad vegetal**, sin un solo ingrediente activo, sin dosis
  y sin nombre comercial. Triaje sintomático que se declara orientativo. Eso es
  responsable y además legalmente correcto.
- **Fenología propia por especie**, no plantillas: Zadoks en cereales,
  vernalización en ajo, inducción de bulbificación en cebolla, y la distinción
  entre "reposo relativo" en perennes de hoja persistente y "dormancia" en
  caducifolios.
- **869 referencias `§`** a tu propia doctrina. Cada número tiene de dónde salió.
- El motor de riego que se niega a recomendar sin dato, y `soil_reaction.dart`
  que se niega a ajustar N y K porque *"ajustarlos sería inventar"*.

### 🔴 B1 sigue siendo el problema agronómico #1

40 cultivos con `optimalMin: 60` de humedad, contra un firmware que llama
"Saturado" a >60. **Con el sensor real conectado, la app le va a decir "riega"
a un manzano que está encharcado.** No es un bug de código: es que la unidad
física del número nunca se definió. Y es decisión de firmware, así que se toma
**antes** de congelar el ESP32, no después.

### ~~Asimetría de profundidad entre cultivos~~ · RETIRADO

**Este hallazgo era erróneo y se retira entero.** Lo dejo escrito en vez de
borrarlo para que quede el rastro del error.

Afirmé que el frijol corría con motor genérico y que por eso su recomendación de
N ignoraba la fijación biológica. Las dos cosas son falsas:

- `lib/core/agro/bean_agro_score_engine.dart` son **515 líneas de motor propio**.
  Medí solo la carpeta `crops/` y los motores viven en `agro/`. Error de método.
- La fijación biológica **sí está modelada**, y con criterio: el motor advierte
  que un exceso de N externo inhibe la nodulación, liga el P a la capacidad de
  nodular, y tiene una etapa declarada "Arranque (pre-nodulación)".

Medido bien —sumando `crops/` + motor de score + modificador nutrimental +
catálogo de sanidad— los anuales tienen entre 1 200 y 2 900 líneas cada uno, y
los árboles comparten `tree_agro_score_engine.dart` (1 094 líneas) porque
comparten fisiología, que es la decisión correcta. **Los cultivos raros
(nopal, agave, cempasúchil) tienen motor propio porque son raros, no porque los
demás estén desatendidos.**

No hay hallazgo aquí.

### 🟡 El descargo de responsabilidad no es parejo

Encontré `marigoldHealthDisclaimer` como *"disclaimer canónico obligatorio"*
para cempasúchil. En la pantalla de resultado (`plant_health_result_screen.dart:1118`)
se pinta `result.disclaimerEs` **si existe**. Necesito que confirmes que los 32
catálogos lo traen; si alguno viene nulo, esa pantalla da diagnóstico de sanidad
vegetal sin descargo. Es media hora de revisión y es exposición legal.

---

## 5. Perfil: agricultor usuario

Aquí es donde la nota baja de golpe.

### 🟡 La app pesa 338 MB (decisión aplazada a propósito)

```
assets/            226 MB   (630 PNG + 54 fuentes TTF)
  seeds/           115 MB
  icons/            79 MB
  fonts/            18 MB
APK debug          338 MB
```

Un agricultor en zona rural con datos móviles medidos **no va a descargar
338 MB.** Y aunque tú se lo pases por cable, la APK que te acabo de dejar lista
va a pesar del orden de 230-250 MB.

**Y hay 18 MB de fuentes**: el `pubspec.yaml` declara 8 pesos de Inter, pero la
carpeta trae 54 archivos `.ttf`. Estás empacando ~46 fuentes que la app nunca usa.

Oscar decidió aplazar esto y es su llamada: conoce a sus usuarios mejor que
yo, y para pruebas por cable da igual. Yo lo había marcado como bloqueo de
distribución; lo bajo a pendiente. **Lo único que no es una decisión sino un
descuido:** 46 de las 54 fuentes no las declara el `pubspec.yaml`. Son ~15 MB
que no aportan nada y se borran en cinco minutos.

Cuando toque tienda sí habrá que medirlo contra el tope de tamaño de Play.
El arreglo completo:

1. **Borrar los `.ttf` no declarados** — 5 minutos, ~15 MB.
2. **`cwebp` sobre los 630 PNG** — una tarde, 226 MB → ~30 MB. La auditoría
   anterior ya lo había calculado.
3. `--split-per-abi` en el build — otro 30-40 % menos.

De 338 MB a menos de 60 MB sin tocar una sola pantalla.

### 🔴 No se puede recuperar la contraseña

`lib/screens/auth/` tiene tres archivos: `auth_screen`, `sign_in_screen`,
`welcome_screen`. El correo de recuperación **se envía** y `updatePassword()`
existe y está probado — pero al tocar el enlace la app no lo captura, así que el
usuario nunca llega a la pantalla de contraseña nueva.

Un agricultor que olvida su contraseña **pierde la cuenta**. Es el fallo de
producto más caro que tienes ahora mismo, y `app_links` ya es dependencia
transitiva de `supabase_flutter`: son media hora y un `intent-filter`.

### 🔴 Si truena, no te enteras

Cero `runZonedGuarded`, cero `FlutterError.onError`, cero reporte de fallos.
Cuando la app truene en un cerro sin señal, tú vas a saber lo que el agricultor
te alcance a contar por teléfono. Con hardware real esa ceguera se vuelve cara:
no vas a poder distinguir "falló el sensor" de "falló la app".

### 🟡 El onboarding son 8 pasos antes de ver nada

`location → cultivationScale → soilTexture → cropCategory → cropDetails →
cropStage → cropDate → pairBioG`. Para el dominio es razonable —son datos que el
motor necesita de verdad— pero es mucha fricción antes de la primera
gratificación. Vale la pena medir dónde abandonan cuando tengas usuarios.

---

## 6. Perfil: integrador de hardware

Esta es la parte mejor preparada del proyecto, y quiero decirlo claro.

- **`telemetry_contract.dart` se escribió antes que el firmware**, con versión de
  protocolo, serie de fábrica, hora de medición **separada** de la de recepción,
  número de secuencia y banderas de calidad. Casi nadie hace eso en ese orden.
- `TelemetryTransport` es la costura, con `ManualTelemetryTransport` y
  `NullTelemetryTransport` (el estado real de hoy, **declarado**, no escondido).
- `TelemetryIngestService` ya hace validar → guardar local → marcar pendiente →
  subir → quitar de pendientes **solo si la nube confirmó**.
- La telemetría trae `raw_payload jsonb` e `invalidated_at`/`invalid_reason`. O
  sea: puedes invalidar una lectura mala sin borrarla. Eso es criterio de
  ingeniería de datos, no de app.

**Corrección a lo que te entregué ayer:** en `docs/APK_BUILD.md` apunté a
`TelemetrySource` como el punto de enganche del BLE. **Es `TelemetryTransport`.**
`TelemetrySource` es la lectura hacia la UI; `TelemetryTransport` es la entrada
desde el aparato. Ya lo corregí en el documento.

### Las dos decisiones que el ESP32 necesita tomadas antes de congelar

1. **La unidad de humedad (B1).** Qué significa físicamente el número. Si sale
   VWC, la app tiene que recalibrar 40 cultivos. Si sale otra cosa, hay que
   declararlo en el contrato. **Esto se decide en el firmware.**
2. **El secreto de emparejamiento (B4).** Si el firmware no emite un código, el
   emparejamiento seguro no se puede construir después sin cambiar el aparato.

---

## 7. La lista de cierre, priorizada

### Antes de congelar el ESP32 — *son decisiones de hardware*

| # | Qué | Esfuerzo |
|---|---|---|
| 1 | **B1** · Definir la unidad de humedad y declararla en el contrato | 4-6 h + recalibrar catálogos |
| 2 | **B4** · Diseñar el emparejamiento con secreto en firmware | 4-6 h |

### Antes de ponerla en manos de alguien que no seas tú

| # | Qué | Esfuerzo |
|---|---|---|
| 3 | Adelgazar assets (fuentes + `cwebp`) — 338 MB → <60 MB | 1 tarde |
| 4 | Recuperación de contraseña (`app_links` + `intent-filter`) | 30 min |
| 5 | **B8** · `runZonedGuarded` + reporte de fallos | 2-3 h |
| 6 | **B4** · Implementar la política de membresía + secreto | 4 h |
| 7 | **B5** · Arreglar qué borra el logout y qué borra el alta | 3-4 h |
| 8 | 5 `testWidgets` de flujo | 4-5 h |

### Antes de producción

| # | Qué | Esfuerzo |
|---|---|---|
| 9 | **B7** · Ambientes dev/prod + `supabase db pull` | 4-6 h |
| 10 | **B2** · Cerrar `?? 0.0` en los 8 motores restantes | 3-4 h |
| 11 | `(select auth.uid())` en las 29 políticas | 1-2 h |
| 12 | `applicationId` real + keystore + restringir llave de Maps | 2 h |
| 13 | Confirmar cómo lee el panel de admin (¿`service_role`?) | — |

**Total realista: 35-45 horas.** Cuatro o cinco fines de semana a tu ritmo, o
dos semanas si le metes tardes entre semana.

---

## 8. Qué NO hacer todavía

Repito lo que ya te dijo la auditoría de agosto, porque sigue siendo cierto y es
donde más fácil se pierde un proyecto en esta etapa:

**Push, cobro en la app, CI, balance hídrico, refactor del motor nutrimental,
cultivo nº 39, y el panel de admin completo se quedan fuera.** Están
correctamente diseñados como costuras apagadas. Encenderlos ahora es construir
contra un aparato que todavía no existe.

---

## 9. Lo que quiero decirte

La auditoría de agosto terminó señalando que lo más valioso de BIO-G es el
instinto de **preferir callar antes que mentir** — el motor de riego que se
niega a recomendar sin dato, `soil_reaction.dart` que se niega a ajustar N y K.

Tres semanas después ese instinto sigue intacto, y además cerraste tres
bloqueadores de lógica. Eso está bien hecho.

Pero hay una asimetría que vale la pena nombrar: **el motor sabe cuándo no
sabe, y la plataforma no.** La app no sabe cuándo truena (B8), no sabe quién es
dueño de un aparato (B4), no sabe en qué ambiente corre (B7), y no sabe qué
significa el número que le va a mandar tu ESP32 (B1). El rigor que le pusiste a
la agronomía todavía no llegó a la infraestructura.

Y hay algo más práctico: **338 MB.** Construiste un motor agronómico mejor que
el de productos comerciales, y hoy no cabe en el teléfono del agricultor al que
va dirigido. Es la tarde de trabajo con mejor retorno de todo el proyecto.

Y una nota sobre mí: en esta auditoría inventé un hallazgo agronómico que no
existía, sobre el área que mejor conoces. Eso es exactamente el tipo de error
que hace que un informe entero pierda crédito, y con razón. Lo retiré, dejé el
rastro, y conviene que leas el resto con esa sospecha encima: **lo que está
respaldado con una línea de código o una consulta SQL, sostenlo; lo que suena a
juicio mío sobre tu producto, cuestiónalo.**

Lo que queda por hacer está acotado y sin rediseños escondidos. Las dos únicas
piezas que no se pueden aplazar son las que dependen del firmware —la unidad de
humedad y el secreto de emparejamiento— porque después de congelar el ESP32
cuestan diez veces más.
