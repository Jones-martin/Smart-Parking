plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // <-- Firebase Plugin Added
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.product.smartParking" // <-- FIXED
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.product.smartParking" // <-- FIXED
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            isShrinkResources = false
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    configurations.all {
        resolutionStrategy {
            force("com.google.android.play:core-common:2.0.3")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.razorpay:checkout:1.6.33") {
        exclude(group = "com.google.android.play", module = "core-common")
        exclude(group = "com.google.android.play", module = "core")
    }

    implementation("com.google.android.play:core-common:2.0.3")
}
