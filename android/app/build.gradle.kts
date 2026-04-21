plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.decideforus.app"
    compileSdk = 36

    ndkVersion = "25.1.8937393"

    defaultConfig {
        applicationId = "com.decideforus.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = 24
        versionName = "1.0.23"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false

            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 🔥 HARD OVERRIDE: disable symbol stripping
    packaging {
        jniLibs {
            useLegacyPackaging = true
            keepDebugSymbols += "**/*.so"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

// 🔥 THIS IS THE REAL FIX (disables failing task)
tasks.configureEach {
    if (name.contains("strip", ignoreCase = true)) {
        enabled = false
    }
}

flutter {
    source = "../.."
}
