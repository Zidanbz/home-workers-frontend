import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Harus terakhir
}

fun decodeDartDefines(raw: String?): Map<String, String> {
    if (raw.isNullOrBlank()) return emptyMap()

    return raw
        .split(",")
        .mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded))
            }.getOrNull()
        }
        .mapNotNull { entry ->
            val separatorIndex = entry.indexOf('=')
            if (separatorIndex <= 0) {
                null
            } else {
                entry.substring(0, separatorIndex) to entry.substring(separatorIndex + 1)
            }
        }
        .toMap()
}

tasks.matching { task ->
    task.name.contains("GoogleServices", ignoreCase = true)
}.configureEach {
    doFirst {
        val runtimeDartDefines =
            decodeDartDefines(project.findProperty("dart-defines") as String?)
        val runtimeAppEnv = runtimeDartDefines["APP_ENV"]?.lowercase() ?: "prod"
        val runtimeGoogleServicesSourceFileName =
            if (runtimeAppEnv == "sandbox") {
                "google-services-dev.json"
            } else {
                "google-services-prod.json"
            }
        val runtimeGoogleServicesSourceFile = file(runtimeGoogleServicesSourceFileName)

        if (!runtimeGoogleServicesSourceFile.exists()) {
            error(
                "File Firebase config tidak ditemukan: ${runtimeGoogleServicesSourceFile.absolutePath}"
            )
        }

        copy {
            from(runtimeGoogleServicesSourceFile)
            into(project.projectDir)
            rename { "google-services.json" }
        }

        println(
            "Using ${runtimeGoogleServicesSourceFile.name} for APP_ENV=$runtimeAppEnv"
        )
    }
}

// ⬇️ Load dari key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// ⬇️ Load dari local.properties (MAPS_API_KEY)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "com.homeworkers.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    defaultConfig {
        applicationId = "com.homeworkers.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        // Inject Google Maps API Key dari local.properties (jangan commit ke repo)
        manifestPlaceholders += mapOf(
            "MAPS_API_KEY" to (localProperties.getProperty("MAPS_API_KEY") ?: "")
        )
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        } else {
            println("Warning: key.properties tidak ditemukan. Release build tidak akan tersign otomatis.")
        }
    }

    buildTypes {
        getByName("release") {
            // TEMP: Nonaktifkan R8 sementara karena error R8 di JDK/desugaring.
            // Nanti bisa diaktifkan kembali setelah perbaikan (update desugar libs / rules).
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                println("Warning: Release build belum tersign. Siapkan keystore & key.properties.")
            }
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
