allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// SAFELY OVERRIDE SDK CONFIGURATIONS FOR PLUGINS LIKE OPENCV_DART
subprojects {
    val subproject = this

    val configureAndroid = Action<Project> {
        if (subproject.extensions.findByName("android") != null) {
            subproject.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
                defaultConfig {
                    targetSdkVersion(36)
                }
            }
        }
    }

    if (subproject.state.executed) {
        configureAndroid.execute(subproject)
    } else {
        subproject.afterEvaluate {
            configureAndroid.execute(subproject)
        }
    }
}
