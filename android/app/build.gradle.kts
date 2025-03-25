plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.company.BikeAcs"
    compileSdk = flutter.compileSdkVersion
    // compileSdkVersion (35)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.company.BikeAcs"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdkVersion(24)
        targetSdkVersion(flutter.targetSdkVersion)
        // targetSdkVersion(35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
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

dependencies {
    implementation ("androidx.multidex:multidex:2.0.1")
    implementation ("com.google.ar:core:1.33.0")
    implementation ("com.google.ar.sceneform:core:1.15.0")
    implementation ("com.google.ar.sceneform.ux:sceneform-ux:1.15.0")
    implementation ("com.google.ar.sceneform:assets:1.15.0")
    implementation ("com.google.android.gms:play-services-location:21.3.0")
}
