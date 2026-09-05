plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bio_g"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.bio_g"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Fijado explicitamente en vez de heredar `flutter.minSdkVersion`:
        // el BLE del ESP32 necesita como minimo API 21, y a partir de API 31
        // cambia el modelo de permisos Bluetooth. 24 = Android 7.0, que ya es
        // el default de Flutter; asi el minimo no se mueve solo al actualizar
        // el SDK de Flutter.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // APK DE DESARROLLO: se firma con la llave de debug a proposito.
            // Es instalable en cualquier telefono via "origenes desconocidos".
            // Antes de publicar en Play Store hay que generar un keystore
            // propio y reemplazar esta linea (ver docs/APK_BUILD.md).
            signingConfig = signingConfigs.getByName("debug")

            // Sin R8/shrinking. Para pruebas de hardware conviene que el APK
            // sea un reflejo fiel del codigo: si algo truena, truena por el
            // codigo y no porque el minificador se comio una clase que se usa
            // por reflexion (pdf/printing/supabase). Reactivar cuando se
            // prepare el build de tienda.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // El lint "vital" solo corre en builds release: es la causa clasica de
    // "en `flutter run` compila y en `flutter build apk` no". Para el APK de
    // pruebas no queremos que un warning frene el build.
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}
