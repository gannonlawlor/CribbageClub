plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Applied below, but only when a google-services.json is actually present.
    id("com.google.gms.google-services") apply false
}

// google-services.json isn't checked in, so a fresh clone has no Firebase
// config and the plugin would fail the build outright. Apply it only when the
// config exists; without it the app still builds and runs, just with push
// notifications disabled (see lib/core/services/firebase_availability.dart).
val hasGoogleServices =
    listOf(
        "google-services.json",
        "src/dev/google-services.json",
        "src/alpha/google-services.json",
    ).any { file(it).exists() }

if (hasGoogleServices) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "google-services.json not found - building without Firebase; " +
            "push notifications will be disabled.",
    )
}

android {
    namespace = "com.jackabee.cribbageclub"
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
        applicationId = "com.jackabee.cribbageclub"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ""
            resValue("string", "app_name", "Cribbage Club")
        }
        create("alpha") {
            dimension = "environment"
            applicationIdSuffix = ".alpha"
            resValue("string", "app_name", "Cribbage Club Alpha")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
