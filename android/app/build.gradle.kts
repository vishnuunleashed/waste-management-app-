plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.myapp.wastemanagementapp"
    compileSdk = 36
    // Required by flutter_gemma, background_downloader, connectivity_plus,
    // and several other plugins' native code — higher than flutter.ndkVersion
    // (26.3.11579264) resolves to.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by recent firebase_auth/cloud_firestore Android artifacts.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.myapp.wastemanagementapp"
        // flutter_gemma requires minSdk 24+ (Firebase Auth/Firestore only
        // needed 23+). Drops support for Android 7.0 (API 23) and below,
        // which is a negligible population at this point and unavoidable
        // for on-device LLM inference anyway.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
