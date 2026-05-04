plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

android {
    namespace = "com.example.hiddencam.hidden_cam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        @Suppress("DEPRECATION")
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    kotlin {
        jvmToolchain(21)
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hiddencam.hidden_cam"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        val marketApplicationId = "ir.mservices.market"
        val marketBindAddress = "ir.mservices.market.InAppBillingService.BIND"
        manifestPlaceholders += mapOf(
            "marketApplicationId" to marketApplicationId,
            "marketBindAddress" to marketBindAddress,
            "marketPermission" to "${marketApplicationId}.BILLING"
        )
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    val hasSigningConfig = keystorePropertiesFile.exists()
    if (hasSigningConfig) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }

    signingConfigs {
        create("release") {
            if (hasSigningConfig) {
                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
                storeFile = keystoreProperties["storeFile"]?.let { path -> file(path) }
                storePassword = keystoreProperties["storePassword"].toString()
            }
        }
    }

    buildTypes {
        release {
            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    
    // CameraX core library using the camera2 implementation
    val camerax_version = "1.3.1"
    implementation("androidx.camera:camera-core:${camerax_version}")
    implementation("androidx.camera:camera-camera2:${camerax_version}")
    implementation("androidx.camera:camera-lifecycle:${camerax_version}")
    implementation("androidx.camera:camera-video:${camerax_version}")
    implementation("androidx.camera:camera-view:${camerax_version}")
    implementation("androidx.camera:camera-extensions:${camerax_version}")
    
    implementation("androidx.lifecycle:lifecycle-service:2.6.2")
    implementation("com.google.guava:guava:31.1-android")
    implementation("androidx.localbroadcastmanager:localbroadcastmanager:1.1.0")
}
