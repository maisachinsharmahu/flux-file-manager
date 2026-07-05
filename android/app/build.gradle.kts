plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flux"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.flux"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // WorkManager: guarantees physical delete survives app kill / device reboot.
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    // Index 3 (Token) + Index 5 (Type Buckets) + Deletion Set:
    // RoaringBitmap uses 25x less RAM than plain BitSet for sparse sets (rare tokens)
    // and skips empty 16-bit containers automatically during AND intersections.
    implementation("org.roaringbitmap:RoaringBitmap:0.9.49")
}

flutter {
    source = "../.."
}
