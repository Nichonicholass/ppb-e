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

subprojects {
    // AGP 8+ requires an explicit namespace for every Android library module.
    // Some transitive packages (for example older pub packages) still omit it.
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        runCatching {
            val getNamespace = androidExt.javaClass.getMethod("getNamespace")
            val currentNamespace = getNamespace.invoke(androidExt) as? String
            if (currentNamespace.isNullOrBlank()) {
                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                setNamespace.invoke(androidExt, "autogen.${project.name.replace('-', '_')}")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
