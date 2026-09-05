# APK de desarrollo — BIO-G

Cómo dejar la app corriendo sola en el teléfono, sin `flutter run` y sin PC
conectada. Pensado para las pruebas reales de hardware con el ESP32.

---

## 1. Cómo generar la APK

Desde la raíz del proyecto (`C:\Users\oscar\Documents\bio_g`), en PowerShell:

```powershell
.\build_apk.ps1
```

Eso es todo. El script hace `pub get`, corre el análisis estático, compila en
modo release con la llave de Google Maps ya inyectada, y te dice al final la
ruta exacta del `.apk`.

Si PowerShell bloquea el script:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_apk.ps1
```

**Variantes útiles**

| Comando | Para qué |
|---|---|
| `.\build_apk.ps1 -Install` | Compila **e instala** en el teléfono conectado por USB |
| `.\build_apk.ps1 -Clean` | Borra `build/` primero. Solo si algo quedó corrupto — es lento |
| `.\build_apk.ps1 -SkipAnalyze` | Se salta `flutter analyze` (ahorra ~1 min) |
| `.\build_apk.ps1 -SplitAbi` | Una APK por arquitectura, ~40% más chicas |

---

## 2. Dónde queda el archivo

Se generan **dos copias**:

**La que produce Flutter** (la oficial, siempre se sobrescribe):

```
C:\Users\oscar\Documents\bio_g\build\app\outputs\flutter-apk\app-release.apk
```

> Ojo: esta ruta no es la que sale en los tutoriales (`android\app\build\...`).
> El `android/build.gradle.kts` de este proyecto redirige el directorio de build
> a la raíz, por eso queda en `build\app\...` y no dentro de `android\`.

**La copia versionada** que hace el script, para que sepas siempre qué build
trae puesto el teléfono:

```
C:\Users\oscar\Documents\bio_g\dist\BIO-G-1.0.0_1-20260830-1830.apk
```

`dist\` ya está en `.gitignore`, no se sube al repo.

---

## 3. Cómo instalarla en el teléfono

**Por USB** (con depuración USB activada):

```powershell
adb install -r "C:\Users\oscar\Documents\bio_g\build\app\outputs\flutter-apk\app-release.apk"
```

**A mano**: copia el `.apk` de `dist\` al teléfono (cable, Drive, WhatsApp a ti
mismo, lo que sea), ábrelo desde el explorador de archivos y acepta *"instalar
apps de orígenes desconocidos"* cuando el sistema lo pida.

La app aparece en el launcher como **BIO-G**.

> ⚠️ **Ojo con el peso.** `assets/` pesa **226 MB** (630 PNG + 54 fuentes TTF, de
> las cuales el `pubspec.yaml` solo declara 8). La APK de debug que ya tienes
> pesa **338 MB** y la de release va a rondar los 230-250 MB. Para pruebas por
> cable da igual, pero **no se la mandes por datos a nadie**. El arreglo
> (borrar fuentes no declaradas + `cwebp` sobre los PNG) baja el paquete a menos
> de 60 MB sin tocar una pantalla. Está en la auditoría del 31 de agosto.

**Importante sobre reinstalar:** una reinstalación limpia borra las
`SharedPreferences`. No pasa nada — el script inyecta la llave de Google Maps en
cada build vía `--dart-define`, así que el buscador de direcciones funciona
desde el primer arranque. Ya no dependes de `run.ps1` para eso.

---

## 4. Qué se cambió en el proyecto

Cambios mínimos, todos en configuración. **Nada de diseño ni de lógica de la
app.** Los archivos originales quedaron respaldados como `*.bak`.

### `android/app/src/main/AndroidManifest.xml`
- **Se quitó `package="com.example.bio_g"`.** Ese atributo está obsoleto desde
  AGP 7.3 y es error en AGP 8.x (aquí corre 8.11.1). El identificador real vive
  en `namespace` dentro de `build.gradle.kts`. Era una bomba de tiempo.
- Se agregó el namespace `xmlns:tools` (lo necesita el permiso de escaneo BLE).
- Se agregaron los permisos y features de Bluetooth (detalle en §5).
- `android:label` pasó de `bio_g` a `BIO-G`.

### `android/app/build.gradle.kts`
- `minSdk` fijado explícitamente en **24** en vez de heredar
  `flutter.minSdkVersion`. BLE necesita mínimo API 21 y el modelo de permisos
  cambia en API 31; conviene que ese piso no se mueva solo cuando actualices
  Flutter.
- `isMinifyEnabled = false` y `isShrinkResources = false` en release. Para
  pruebas de hardware quieres que la APK sea un reflejo fiel del código: si algo
  truena, que truene por el código y no porque R8 se comió una clase que se usa
  por reflexión (`pdf`, `printing`, `supabase`).
- `lint { checkReleaseBuilds = false }`. El lint "vital" **solo corre en builds
  release** — es la causa clásica de "en `flutter run` compila y en
  `flutter build apk` no".

### `pubspec.yaml`
- Se agregó `flutter_blue_plus: ^2.3.7` (la serie actual es 2.x; `docs/DEPENDENCIAS_PENDIENTES.md` la tenía verificada contra pub.dev). Si `pub` se queja de la versión, el
  script lo repara solo con `flutter pub add flutter_blue_plus`.

### Archivos nuevos
- `build_apk.ps1` — el script de build.
- `docs/APK_BUILD.md` — este documento.
- `.gitignore` — se agregaron `/dist/` y `*.bak`.

---

## 5. Android/BLE: lo que ya quedó preparado

El manifest ya declara todo lo que necesita la app como **central BLE** (ella
escanea y se conecta; el ESP32 es el periférico que anuncia):

```xml
<!-- Android 11 (API 30) y anteriores -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Android 12 (API 31) en adelante -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" tools:targetApi="s" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="false" />
<uses-feature android:name="android.hardware.bluetooth" android:required="false" />
```

Tres decisiones que importan y por qué:

1. **`neverForLocation`** declara que no derivas ubicación del escaneo. En
   Android 12+ eso evita que el sistema te exija permiso de ubicación *nada más
   para escanear*. Válido en tu caso: buscas el ESP32 por nombre o UUID de
   servicio, no estás haciendo triangulación.

2. **`ACCESS_FINE_LOCATION` se quedó SIN `maxSdkVersion`.** Los tutoriales de
   BLE te dicen que le pongas `maxSdkVersion="30"`. Aquí sería un error: esta
   app la necesita de verdad, en todas las versiones, para mapas y
   geolocalización. Si alguien la limita, se rompe la pantalla de Ubicación.

3. **`required="false"` en las features** para que la app siga siendo
   instalable en equipos sin BLE.

**Gotcha operativo:** en Android 11 o menor, el escaneo BLE **no devuelve nada
si el GPS del teléfono está apagado**, aunque el permiso esté concedido. Es
comportamiento del sistema, no un bug tuyo. Si el teléfono de pruebas es
Android 12+, con `neverForLocation` ya no aplica.

---

## 6. Lo que falta para la integración BLE real con el ESP32

El paquete nativo ya viaja en la APK, pero **todavía no está cableado a ninguna
pantalla**. El simulador de sensores sigue intacto y es el que alimenta la UI.

### El punto de enganche correcto es `TelemetryTransport`

> **Corrección (31-ago):** la primera versión de este documento apuntaba a
> `TelemetrySource`. Estaba mal. `TelemetrySource` es la **lectura hacia la UI**;
> lo que el BLE tiene que implementar es `TelemetryTransport`, que es la
> **entrada desde el aparato**.

`lib/core/telemetry/telemetry_transport.dart` es la interfaz. Hoy corre un
`NullTelemetryTransport` — el estado real, declarado, no escondido. Se conecta
con una línea:

```dart
store.telemetryIngest.bindTransport(BleTelemetryTransport());
```

Todo lo de después ya está escrito y probado en `telemetry_ingest_service.dart`:
validar → guardar local → marcar pendiente → subir → quitar de pendientes **solo
si la nube confirmó**. El transporte solo tiene que producir un
`TelemetryEnvelope` válido.

**Lo importante no es el paquete de BLE, es el sobre.** `telemetry_contract.dart`
define lo que el firmware tiene que emitir: UUID del dispositivo, serie de
fábrica, versión de firmware, versión de protocolo, **hora de medición separada
de la de recepción**, número de secuencia y banderas de calidad. Pásale ese
archivo a quien escriba el firmware antes de que empiece.

`SensorSimulator` (`services/biog/telemetry/sensor_simulator.dart`) se queda
intacto hasta que el transporte real esté probado.

### ⚠️ Dos decisiones que el ESP32 necesita ANTES de congelarse

1. **Qué significa físicamente el número de humedad.** Hoy `soilMoisturePct` no
   declara escala, y 40 cultivos tienen `optimalMin: 60` mientras el firmware
   llama "Saturado" a >60. Si no se cierra, la app va a decir "riega" sobre
   suelo encharcado.
2. **El secreto de emparejamiento.** Sin un código emitido por el aparato, el
   emparejamiento seguro no se puede construir después sin cambiar el firmware.

Ambas están detalladas en `docs/AUDITORIA_INTEGRAL_2026-08-31.md`.

### Si más adelante agregas notificaciones locales

`flutter_local_notifications` **rompe el build** si no habilitas *desugaring*.
En `android/app/build.gradle.kts`, dentro de `compileOptions`:
`isCoreLibraryDesugaringEnabled = true`, más
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` en un bloque
`dependencies`. Detalle completo en `docs/DEPENDENCIAS_PENDIENTES.md`.

### Contrato de datos que tiene que mandar el ESP32

`BioGTelemetry` espera estos campos por lectura:

| Campo | Unidad |
|---|---|
| `deviceId` | string |
| `timestamp` | fecha/hora |
| `airTempC`, `soilTempC` | °C |
| `airHumidityPct`, `soilMoisturePct` | % |
| `ph` | pH |
| `ec` | conductividad |
| `resistance` | resistencia |
| `n`, `p`, `k` | NPK |
| `batteryPct` | % |
| `signalRssi` | dBm |

Encaja directo con el sensor 7-en-1 que ya tienes. Lo más práctico es que el
ESP32 mande **un JSON por notificación** en una característica `notify` y que el
`signalRssi` lo ponga el teléfono desde el resultado del escaneo, no el ESP32.

### Checklist para arrancar

- [ ] En el ESP32: definir UUID de servicio y de característica propios (no uses
      los de ejemplo de Nordic — vas a tener colisiones en el taller).
- [ ] Característica de telemetría con `notify`; opcionalmente una de comandos
      con `write`.
- [ ] Nombre de advertising estable y reconocible (ej. `BIOG-<serie>`), para
      filtrar el escaneo por nombre.
- [ ] Negociar MTU (`requestMtu(512)`) antes de mandar JSON — con el MTU por
      defecto de 23 bytes no cabe una lectura completa.
- [ ] En Flutter: pedir `BLUETOOTH_SCAN` y `BLUETOOTH_CONNECT` en runtime en
      Android 12+. Verifica si tu versión de `flutter_blue_plus` ya lo hace sola;
      si no, agrega `permission_handler`.
- [ ] Mapear el `deviceId` BLE contra la identidad que ya maneja
      `services/biog/identity/` — no inventes un registro paralelo.

> La API de `flutter_blue_plus` ha cambiado entre versiones mayores. Revisa el
> README de la versión que te haya instalado `pub` antes de escribir el driver.

---

## 7. Pendientes antes de pensar en Play Store

Nada de esto estorba hoy, pero déjalo anotado:

1. **`applicationId` sigue siendo `com.example.bio_g`.** Play Store rechaza
   cualquier cosa que empiece con `com.example`. **No lo cambies todavía**: la
   llave de Google Maps puede estar restringida a ese nombre de paquete, y
   cambiarlo rompería el mapa. Cuando toque, se cambia el `applicationId` y la
   restricción de la llave en Google Cloud Console **al mismo tiempo**.

2. **La APK está firmada con la llave de debug**, a propósito. Es instalable en
   cualquier teléfono, pero no sirve para publicar. Antes de publicar hay que
   generar un keystore propio y guardarlo bien — si se pierde, no puedes
   actualizar la app nunca más.

3. **La llave de Google Maps está en texto plano** en `AndroidManifest.xml`,
   `run.ps1` y ahora en `build_apk.ps1`. Si el repo es público o algún día lo
   es, esa llave se puede abusar y te llega la factura. Restrínge la llave en
   Google Cloud Console por nombre de paquete + huella SHA-1, que es gratis y
   te cubre.

4. Reactivar `minify` + `shrinkResources` y el lint de release cuando prepares
   el build de tienda, y probar bien el flujo de PDF/impresión con R8 activo.
