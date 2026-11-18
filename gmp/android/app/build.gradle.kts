import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    alias(libs.plugins.kotlin.compose)
}

val localProperties = Properties().apply {
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        localFile.inputStream().use { load(it) }
    }
}
val googleMapsApiKey: String =
    localProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: ""

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun signingProp(name: String): String? {
    val fromKeyFile = keystoreProperties.getProperty(name)?.trim()
    if (!fromKeyFile.isNullOrEmpty()) return fromKeyFile
    val fromProject = (project.findProperty(name) as? String)?.trim()
    if (!fromProject.isNullOrEmpty()) return fromProject
    return System.getenv(name)?.trim()?.takeIf { it.isNotEmpty() }
}

val releaseStoreFilePath = signingProp("storeFile")
    ?: signingProp("MYAPP_UPLOAD_STORE_FILE")
val releaseStorePassword = signingProp("storePassword")
    ?: signingProp("MYAPP_UPLOAD_STORE_PASSWORD")
val releaseKeyAlias = signingProp("keyAlias")
    ?: signingProp("MYAPP_UPLOAD_KEY_ALIAS")
val releaseKeyPassword = signingProp("keyPassword")
    ?: signingProp("MYAPP_UPLOAD_KEY_PASSWORD")

val hasReleaseSigning =
    !releaseStoreFilePath.isNullOrEmpty() &&
        !releaseStorePassword.isNullOrEmpty() &&
        !releaseKeyAlias.isNullOrEmpty() &&
        !releaseKeyPassword.isNullOrEmpty()

android {
    namespace = "com.getmypair.userapp"
    compileSdk = 36
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
        applicationId = "com.getmypair.userapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Local/CI builds without key.properties still configure successfully.
                signingConfigs.getByName("debug")
            }
        }
    }

    buildFeatures {
        compose = true
    }
}
dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.activity.compose)
    implementation(libs.core.ktx)
    implementation(libs.lifecycle.runtime.ktx)
    implementation(libs.material3)
    implementation(libs.ui)
    implementation(libs.ui.graphics)
    implementation(libs.ui.tooling.preview)
    testImplementation(libs.junit)
    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.espresso.core)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.ui.test.junit4)
    debugImplementation(libs.ui.test.manifest)
    debugImplementation(libs.ui.tooling)
}

flutter {
    source = "../.."
}
