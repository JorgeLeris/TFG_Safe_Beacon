import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("env")

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "com.jlerisla.safebeacon.safebeacon.dev"
            resValue(type = "string", name = "app_name", value = "SafeBeacon Dev")
        }
        create("pre") {
            dimension = "env"
            applicationId = "com.jlerisla.safebeacon.safebeacon.pre"
            resValue(type = "string", name = "app_name", value = "SafeBeacon Pre")
        }
        create("prod") {
            dimension = "env"
            applicationId = "com.jlerisla.safebeacon.safebeacon"
            resValue(type = "string", name = "app_name", value = "SafeBeacon")
        }
    }
}