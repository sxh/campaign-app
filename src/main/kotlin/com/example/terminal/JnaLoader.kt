package com.example.terminal

import org.slf4j.LoggerFactory
import java.io.File
import java.io.FileOutputStream

private const val JNA_LIBRARY_NAME = "jnativehook"
private const val MIN_MACOS_MAJOR_VERSION = 10

internal object JnaLoader {
    private val logger = LoggerFactory.getLogger(JnaLoader::class.java)

    fun load() {
        if (!isMacOs()) {
            logger.debug("JNA loading skipped - not macOS")
            return
        }

        if (!requiresJna()) {
            logger.debug("JNA loading skipped - macOS version sufficient")
            return
        }

        try {
            loadJnaFromClasspath()
        } catch (e: SecurityException) {
            logger.warn("Failed to load JNA from classpath, native JNI will be used", e)
        } catch (e: UnsatisfiedLinkError) {
            logger.warn("Failed to load JNA from classpath, native JNI will be used", e)
        }
    }

    private fun isMacOs(): Boolean = System.getProperty("os.name")?.startsWith("Mac") == true

    private fun requiresJna(): Boolean {
        val version = System.getProperty("os.version") ?: return false
        val parts = version.split(".")
        return when {
            parts.isEmpty() -> false
            else -> {
                val major = parts[0].toIntOrNull() ?: return false
                major < MIN_MACOS_MAJOR_VERSION
            }
        }
    }

    private fun loadJnaFromClasspath() {
        val classLoader = Thread.currentThread().contextClassLoader
            ?: JnaLoader::class.java.classLoader

        val resourceName = "/META-INF/lib/${System.mapLibraryName(JNA_LIBRARY_NAME)}"
        val resource = classLoader.getResource(resourceName)
            ?: classLoader.getResourceAsStream(resourceName)?.use { input ->
                val temp = File.createTempFile("jna-", ".tmp")
                temp.deleteOnExit()
                FileOutputStream(temp).use { output ->
                    input.copyTo(output)
                }
                temp
            }

        if (resource != null) {
            val file = when (resource) {
                is File -> resource
                is java.net.URL -> {
                    val temp = File.createTempFile("jna-", ".tmp")
                    temp.deleteOnExit()
                    temp.outputStream().use { it.write(resource.readBytes()) }
                    temp
                }
                else -> null
            }
            file?.let { System.load(it.absolutePath) }
        }
    }
}
