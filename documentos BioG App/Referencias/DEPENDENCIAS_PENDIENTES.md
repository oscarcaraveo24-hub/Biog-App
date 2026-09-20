# BIO-G · Dependencias pendientes

**Versiones consultadas en pub.dev el 3 de agosto de 2026.**
Ninguna de estas está en `pubspec.yaml`. El código entregado funciona sin ellas: cada una enchufa en un *seam* que ya existe y está probado.

---

## Antes de nada: tu proyecto ya cumple casi todo

Revisé tu configuración nativa real contra lo que pide cada paquete:

| Requisito | Tú tienes | ¿Cumple? |
|---|---|---|
| Android Gradle Plugin ≥ 8.11.1 | **8.11.1** | ✅ justo en el mínimo |
| Gradle wrapper ≥ 8.13 | **8.14** | ✅ |
| Java 17 | **17** | ✅ |
| Kotlin | **2.2.20** | ✅ |
| `android.useAndroidX=true` | sí | ✅ |
| `compileSdk` ≥ 35 | `flutter.compileSdkVersion` (36 en Flutter 3.38) | ✅ |
| `minSdk` ≥ 24 | `flutter.minSdkVersion` (24 en Flutter 3.38) | ✅ |
| iOS deployment target ≥ 13.0 | **13.0** | ✅ justo en el mínimo |
| Dart SDK | `^3.10.4` → Flutter 3.38+ | ✅ |

**Lo único que te falta configurar:** *desugaring* en Android (una entrada en `build.gradle.kts`), que pide `flutter_local_notifications`. Sin eso el build revienta. Está el snippet exacto abajo.

> Confirma tu versión con `flutter --version`. `flutter_local_notifications 22.2.0` exige **Flutter 3.38.1 mínimo**; si estás en 3.38.0 exacto, actualiza o fija `flutter_local_notifications: 21.x`.

---

## El bloque para pegar en `pubspec.yaml`

Todo junto, comentado por fase. **No lo pegues entero de golpe** — añade una fase, `flutter pub get`, compila, y sigue. Así, si algo rompe, sabes qué fue.

```yaml
dependencies:
  # ── ya las tienes ────────────────────────────────────────────────────────
  supabase_flutter: ^2.9.1
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  image_picker: ^1.1.2
  shared_preferences: ^2.2.3
  sqflite: ^2.3.3
  path_provider: ^2.1.4
  path: ^1.9.0
  google_maps_flutter: ^2.5.0
  http: ^1.2.2
  geolocator: ^13.0.2
  share_plus: ^12.0.1
  pdf: ^3.11.0
  printing: ^5.13.0

  # ── FASE A · cierra la recuperación de contraseña (media hora) ───────────
  app_links: ^7.2.1

  # ── FASE B · reintento de subida al recuperar señal (una hora) ───────────
  connectivity_plus: ^7.1.1

  # ── FASE C · notificaciones locales reales ───────────────────────────────
  flutter_local_notifications: ^22.2.0
  timezone: ^0.11.0
  flutter_timezone: ^5.1.0

  # ── FASE D · hardware BLE real ───────────────────────────────────────────
  flutter_blue_plus: ^2.3.7
  permission_handler: ^12.0.3

  # ── FASE E · push (solo si de verdad lo necesitas; ver nota) ─────────────
  firebase_core: ^4.10.0
  firebase_messaging: ^16.3.0

  # ── FASE F · cobro real dentro de la app (P3, después de V1-A) ───────────
  in_app_purchase: ^3.3.0
```

---

## Fase A · `app_links: ^7.2.1`

**Cierra:** recuperación de contraseña de punta a punta.

Hoy el correo se envía (funciona) pero al tocar el enlace la app no lo captura, así que el usuario no puede fijar la contraseña nueva desde el teléfono.

**Dónde enchufa:** `AuthRepository.passwordResetRedirect` ya vale `'biog://auth/reset-password'`. Escuchas el stream y navegas a una pantalla que llame a `AuthRepository.updatePassword()`, que ya está escrita y probada.

```dart
final appLinks = AppLinks();
appLinks.uriLinkStream.listen((uri) {
  if (uri.host == 'auth' && uri.path == '/reset-password') {
    // Supabase ya dejó una sesión de recuperación activa aquí.
    // Navega a tu pantalla de "nueva contraseña".
  }
});
```

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro de `<activity android:name=".MainActivity">`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="biog" android:host="auth" />
</intent-filter>
```

**iOS** — en `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key><string>com.tuempresa.biog</string>
    <key>CFBundleURLSchemes</key><array><string>biog</string></array>
  </dict>
</array>
```

**Supabase** → Authentication → URL Configuration → Redirect URLs: añade `biog://auth/reset-password`.

> ⚠️ El esquema `biog://` es un *custom scheme*, no un App Link verificado. Cualquier app puede registrarlo. Para producción conviene migrar a `https://` con `assetlinks.json` (Android) y Associated Domains (iOS), que exige un dominio tuyo. Para V1-A el custom scheme es aceptable.

---

## Fase B · `connectivity_plus: ^7.1.1`

**Cierra:** que las lecturas pendientes se reintenten solas al volver la señal.

Hoy `TelemetryIngestService.flushPending()` corre al vincular usuario. Con esto corre también en cuanto vuelve la red.

**Dónde enchufa:**

```dart
Connectivity().onConnectivityChanged.listen((result) {
  if (!result.contains(ConnectivityResult.none)) {
    unawaited(store.telemetryIngest.flushPending());
  }
});
```

**Bonus:** `widgets/shared/connectivity_banner.dart` hoy detecta la red haciendo un **DNS lookup a `api.open-meteo.com`** cada vez. Con este paquete se sustituye por el estado real del sistema — más rápido, sin tráfico y sin depender de que Open-Meteo esté vivo.

**Config nativa:** ninguna. Ya cumples Gradle 8.14 y Java 17.

---

## Fase C · notificaciones locales

`flutter_local_notifications: ^22.2.0` + `timezone: ^0.11.0` + `flutter_timezone: ^5.1.0`

**Cierra:** que el aviso de las 3 a.m. suene con la app cerrada. Es el objetivo declarado del almacén de eventos, y hoy sigue sin cumplirse.

**Dónde enchufa:** implementas `NotificationChannel` (la interfaz que ya existe en `core/notifications/notification_dispatcher.dart`) y la pasas al constructor:

```dart
class LocalNotificationChannel implements NotificationChannel {
  @override String get name => 'local';
  @override Future<bool> get isAvailable async => true;
  @override Future<bool> deliver(BiogNotification n) async { /* ... */ }
}

NotificationDispatcher(channels: [
  LocalNotificationChannel(),
  const InAppNotificationChannel(),
]);
```

Las preferencias, el horario silencioso, la deduplicación y la bandeja persistente **ya funcionan** y no se tocan: solo se añade la capa que hace sonar el teléfono.

**Por qué las tres:** `timezone` da la base de datos IANA; `flutter_timezone` lee la zona del sistema. Sin ellas no se puede programar una notificación a una hora local concreta.

### ⚠️ Esto es lo que rompe el build si lo olvidas

En `android/app/build.gradle.kts`, dentro del bloque `android { }`:

```kotlin
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // <-- AÑADIR
    }
```

y al final del archivo, fuera de `android { }`:

```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
```

**Permisos** en `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

> `USE_EXACT_ALARM` no necesita permiso del usuario pero **Google Play exige justificarlo** en la ficha. Si tus avisos toleran unos minutos de desfase, usa `SCHEDULE_EXACT_ALARM` (o ninguno) y programa con `inexactAllowWhileIdle`. Para riego y helada, la ventana de minutos es perfectamente aceptable: yo iría por ahí y me ahorraría la justificación.

**iOS:** configurar el delegado de `UNUserNotificationCenter` en `AppDelegate.swift`. El permiso lo pide el propio `initialize()`.

---

## Fase D · hardware BLE

`flutter_blue_plus: ^2.3.7` + `permission_handler: ^12.0.3`

**Cierra:** el frente 3 de verdad.

**Dónde enchufa:** implementas `TelemetryTransport` (`core/telemetry/telemetry_transport.dart`) y lo enchufas con una línea:

```dart
store.telemetryIngest.bindTransport(BleTelemetryTransport());
```

Todo lo demás —validación del contrato, guardado local, cola de pendientes, reintentos con confirmación explícita— ya está escrito y probado. El transporte solo tiene que producir `TelemetryEnvelope`.

**Permisos Android:**

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<!-- Android 11 y anteriores -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
```

`neverForLocation` te ahorra pedir ubicación para escanear, que es una fricción enorme en el alta. Úsalo salvo que el firmware haga beacons de posición.

**iOS** — en `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bio-G usa Bluetooth para leer los datos de tu sensor de suelo.</string>
```

> **Lo importante no es el paquete.** El firmware tiene que emitir el sobre completo del contrato: UUID propio del dispositivo, serie, versión de firmware, versión de protocolo, hora de medición **separada** de la de recepción, número de secuencia y banderas de calidad. Eso está definido en `telemetry_contract.dart` y probado. Pásale ese archivo a quien haga el firmware **antes** de que empiece: es el punto donde el proyecto se ahorra un rediseño.

---

## Fase E · push

`firebase_core: ^4.10.0` + `firebase_messaging: ^16.3.0`

**Cierra:** avisos desde el servidor con la app cerrada.

**Pregúntate primero si lo necesitas.** Con la Fase C ya suenan los avisos que la app calcula en el teléfono, que es el 90 % de lo que le importa al agricultor: riego, helada, sensor caído. Push solo hace falta para cosas que **solo el servidor sabe**: aviso de vencimiento de suscripción, mensaje de soporte, alerta regional.

Push arrastra bastante: proyecto de Firebase, `google-services.json`, `GoogleService-Info.plist`, certificado APNs en la cuenta de desarrollador de Apple, el plugin de Gradle de Google Services, y una capa de servidor que envíe. Es media jornada larga, no una tarde.

**Dónde enchufa:** exactamente igual que la Fase C — otro `NotificationChannel`. La bandeja no cambia.

---

## Fase F · cobro real

`in_app_purchase: ^3.3.0`

**No la necesitas todavía.** Tu plan dice activación **manual** en V1-A, y `BiogSubscription.activateManually()` ya lo soporta con término de 12 meses y gracia de 30 días.

Cuando llegue: `BiogSubscription` y `BiogEntitlements` no cambian. Solo se sustituye el origen de la fecha de vencimiento —hoy `profiles.subscription_status`, mañana el recibo de la tienda— y el resto del gating sigue igual.

> Aviso que cuesta dinero: **si no llamas a `completePurchase` y recibes confirmación en 3 días, Android reembolsa la compra automáticamente.**
> Requiere iOS 13+ (lo tienes, justo) y Android SDK 24+ (lo tienes).

---

## Orden que yo seguiría

1. **A (`app_links`)** — media hora, cierra un frente entero, cero riesgo.
2. **B (`connectivity_plus`)** — una hora, y de paso quita el DNS lookup del banner.
3. **C (notificaciones locales)** — la que más valor da al agricultor. Cuidado con el desugaring.
4. **D (BLE)** — cuando exista firmware. Manda el contrato antes.
5. **E (push)** — solo si el servidor necesita hablar.
6. **F (cobro)** — P3, después de V1-A.

**A + B se pueden hacer hoy mismo** sin tocar nada nativo más allá de un `intent-filter`.

---

## Lo que NO es una dependencia

- **Los 222.8 MB de assets** se arreglan con `cwebp` (herramienta de línea de comandos, no un paquete). 222 MB → ~28 MB.
- **Los secretos** salen con `--dart-define`, que es del SDK. No metas `flutter_dotenv`: un `.env` empaquetado en el APK es igual de extraíble que una constante, con la ilusión añadida de que es seguro.
- **El `applicationId`, el keystore y la rotación de la llave de Maps** son configuración, no paquetes. Y son bloqueantes de tienda.

---

**Fuentes:** [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) · [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) · [app_links](https://pub.dev/packages/app_links) · [permission_handler](https://pub.dev/packages/permission_handler) · [firebase_messaging](https://pub.dev/packages/firebase_messaging) · [connectivity_plus](https://pub.dev/packages/connectivity_plus) · [in_app_purchase](https://pub.dev/packages/in_app_purchase) · [flutter_timezone](https://pub.dev/packages/flutter_timezone) · [timezone](https://pub.dev/packages/timezone) · [Flutter 3.38 / Dart 3.10](https://blog.flutter.dev/announcing-flutter-3-38-dart-3-10-building-the-future-of-apps-503429eeb685)
