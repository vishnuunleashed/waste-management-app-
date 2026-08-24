pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.10.0" apply false
    // background_downloader's dependencies (androidx.work-runtime 2.11.0,
    // kotlinx-serialization, kotlin-stdlib) ship Kotlin 2.1/2.2 metadata —
    // 1.9.24's compiler can only read up to 2.0.0, so it must move up too.
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
