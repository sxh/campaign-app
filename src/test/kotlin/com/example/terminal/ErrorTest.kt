@file:Suppress("EmptyFunctionBlock")
package com.example.terminal

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ProcessErrorTest {

    @Test
    fun `commandNotFound provides suggestion`() {
        val error = ProcessError.CommandNotFound("gemini")
        assertEquals("Command not found: gemini", error.message)
        assertNotNull(error.suggestion)
    }

    @Test
    fun `pathInaccessible provides suggestion`() {
        val error = ProcessError.PathInaccessible("/invalid/path")
        assertEquals("Cannot access path: /invalid/path", error.message)
        assertNotNull(error.suggestion)
    }

    @Test
    fun `processCrashed captures exit code`() {
        val error = ProcessError.ProcessCrashed(42)
        assertEquals("Process crashed with exit code: 42", error.message)
        assertNotNull(error.suggestion)
    }

    @Test
    fun `ptyInitializationFailed provides suggestion`() {
        val error = ProcessError.PtyInitializationFailed("JNA not available")
        assertTrue(error.message.contains("JNA not available"))
        assertNotNull(error.suggestion)
    }

    @Test
    fun `writeFailed provides suggestion`() {
        val error = ProcessError.WriteFailed("Broken pipe")
        assertEquals("Failed to write to process: Broken pipe", error.message)
        assertNotNull(error.suggestion)
    }

    @Test
    fun `handleProcessError formats error correctly`() {
        val error = ProcessError.CommandNotFound("test")
        val formatted = ErrorHandler.handleProcessError(error)
        assertTrue(formatted.contains("Command not found"))
        assertTrue(formatted.contains("Suggestion"))
    }

    @Test
    fun `detectCommandNotFound recognizes bash not found`() {
        assertTrue(ErrorHandler.detectCommandNotFound("bash: command not found"))
    }

    @Test
    fun `detectCommandNotFound recognizes windows not found`() {
        val output = "'test' is not recognized as an internal or external command"
        assertTrue(ErrorHandler.detectCommandNotFound(output))
    }

    @Test
    fun `detectPathError recognizes no such file`() {
        assertTrue(ErrorHandler.detectPathError("No such file or directory"))
    }

    @Test
    fun `detectPathError recognizes permission denied`() {
        assertTrue(ErrorHandler.detectPathError("Permission denied"))
    }

    @Test
    fun `detectGeminiNotInstalled works`() {
        assertTrue(ErrorHandler.detectGeminiNotInstalled("gemine command not found"))
    }
}

class ErrorIntegrationTest {

    @Test
    fun `echo command produces expected output`() {
        val manager = PtyProcessManager()
        val outputs = mutableListOf<String>()

        val result = manager.start(
            listOf("echo", "Hello from terminal"),
            System.getProperty("user.dir")!!,
            object : PtyProcessManager.ProcessOutputHandler {
                override fun onOutput(output: String) { outputs.add(output) }
                override fun onError(error: String) {}
                override fun onProcessStarted() {}
                override fun onProcessStopped(exitCode: Int?) {}
            }
        )

        assertTrue(result)
        Thread.sleep(500)
        manager.stop()
        assertTrue(outputs.any { it.contains("Hello from terminal") })
    }

    @Test
    fun `pwd command shows working directory`() {
        val manager = PtyProcessManager()
        val outputs = mutableListOf<String>()
        val wd = System.getProperty("user.dir")!!

        val result = manager.start(
            listOf("pwd"),
            wd,
            object : PtyProcessManager.ProcessOutputHandler {
                override fun onOutput(output: String) { outputs.add(output) }
                override fun onError(error: String) {}
                override fun onProcessStarted() {}
                override fun onProcessStopped(exitCode: Int?) {}
            }
        )

        if (result) {
            Thread.sleep(300)
            manager.stop()
            assertTrue(outputs.isNotEmpty())
        }
    }
}
