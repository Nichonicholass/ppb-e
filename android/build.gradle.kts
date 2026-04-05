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
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate

        val currentNamespace = runCatching {
            androidExtension.javaClass.getMethod("getNamespace").invoke(androidExtension) as String?
        }.getOrNull()

        if (!currentNamespace.isNullOrBlank()) return@afterEvaluate

        val manifestFile = file("src/main/AndroidManifest.xml")
        if (!manifestFile.exists()) return@afterEvaluate

        val packageName =
            Regex("""package\s*=\s*\"([^\"]+)\"""")
                .find(manifestFile.readText())
                ?.groupValues
                ?.getOrNull(1)

        if (packageName.isNullOrBlank()) return@afterEvaluate

        runCatching {
            androidExtension.javaClass
                .getMethod("setNamespace", String::class.java)
                .invoke(androidExtension, packageName)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
