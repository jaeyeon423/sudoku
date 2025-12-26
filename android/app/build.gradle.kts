import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jysudoku.sudoku"
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
        applicationId = "com.jysudoku.sudoku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            var keystorePropertiesFile = file("key.properties")
            if (!keystorePropertiesFile.exists()) {
                 // Fallback to root project if not found in app module
                 keystorePropertiesFile = rootProject.file("key.properties")
            }
            
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            } else {
                println("ALARM: key.properties not found at ${keystorePropertiesFile.absolutePath}")
            }

            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            
            val storeFileName = keystoreProperties.getProperty("storeFile")
            if (storeFileName != null) {
                var sFile = file(storeFileName)
                if (!sFile.exists()) {
                    sFile = rootProject.file(storeFileName)
                }
                storeFile = sFile
            }
            
            if (keyAlias == null || keyPassword == null || storePassword == null || storeFile == null) {
                println("ALARM: Missing keys in key.properties or storeFile not found.")
                println("keyAlias: $keyAlias")
                println("storeFile: $storeFile")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
