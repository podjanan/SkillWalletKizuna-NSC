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

subprojects {
    val configureJvmTarget = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val targetCompat = compileOptions.javaClass.getMethod("getTargetCompatibility").invoke(compileOptions)
                if (targetCompat != null) {
                    val targetVersionString = targetCompat.toString() // e.g. "1.8" or "11" or "17"
                    tasks.configureEach {
                        if (this.javaClass.name.contains("KotlinCompile")) {
                            val kotlinOptions = this.property("kotlinOptions")
                            if (kotlinOptions != null) {
                                try {
                                    val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                                    setJvmTarget.invoke(kotlinOptions, targetVersionString)
                                } catch (e: Exception) {
                                    // Fallback / Ignore if task does not support it
                                }
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore if reflection fails
            }
        }
    }

    val configureAction = {
        if (project.state.executed) {
            configureJvmTarget()
        } else {
            project.afterEvaluate {
                configureJvmTarget()
            }
        }
    }

    project.pluginManager.withPlugin("com.android.application") { configureAction() }
    project.pluginManager.withPlugin("com.android.library") { configureAction() }
}
