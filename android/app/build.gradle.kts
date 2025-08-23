plugins {
    id("com.android.application")
    // FlutterFire / Google services
    id("com.google.gms.google-services")
    // Kotlin Android
    id("kotlin-android")
    // Must be applied after Android & Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.paw_ui" // ← change if your package differs

    // SDK/NDK versions
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.paw_ui" // ← match your package
        minSdk = 23               // required by firebase_auth
        targetSdk = 34            // can stay 34 (compileSdk is 35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Java/Kotlin toolchains
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Avoid duplicate META-INF files in some libs
    packagingOptions {
        resources { excludes += "/META-INF/{AL2.0,LGPL2.1}" }
    }

    buildTypes {
        release {
            // Using debug signing so `flutter run --release` works out of the box
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Point Flutter to the module root
flutter {
    source = "../.."
}

// Usually no extra dependencies needed here for FlutterFire;
// the Flutter plugins add them for you via the Flutter Gradle plugin.
// dependencies {
//     implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
// }
