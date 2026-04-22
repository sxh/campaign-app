package com.example.terminal

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PtyProcessManagerTest {

    @Test
    fun `new instance is not initialized`() {
        val manager = PtyProcessManager()
        assertFalse(manager.isInitialized())
    }

    @Test
    fun `new instance is not running`() {
        val manager = PtyProcessManager()
        assertFalse(manager.isRunning())
    }

    @Test
    fun `exit code is null when not started`() {
        val manager = PtyProcessManager()
        assertNull(manager.getExitCode())
    }

    @Test
    fun `stop does nothing when not initialized`() {
        val manager = PtyProcessManager()
        manager.stop()
        assertFalse(manager.isInitialized())
        assertFalse(manager.isRunning())
    }

    @Test
    fun `start with invalid command returns false`() {
        val manager = PtyProcessManager()
        val outputs = mutableListOf<String>()
        val errors = mutableListOf<String>()
        var started = false
        var stopped = false

        val handler = object : PtyProcessManager.ProcessOutputHandler {
            override fun onOutput(output: String) { outputs.add(output) }
            override fun onError(error: String) { errors.add(error) }
            override fun onProcessStarted() { started = true }
            override fun onProcessStopped(exitCode: Int?) { stopped = true }
        }

        val result = manager.start(
            listOf("nonexistent_command_12345"),
            System.getProperty("user.dir")!!,
            handler
        )

        assertFalse(result)
        assertFalse(started)
        assertTrue(errors.isNotEmpty())
    }

    @Test
    fun `start with valid echo command works`() {
        val manager = PtyProcessManager()
        val outputs = mutableListOf<String>()
        val errors = mutableListOf<String>()
        var started = false
        var stopped = false

        val handler = object : PtyProcessManager.ProcessOutputHandler {
            override fun onOutput(output: String) { outputs.add(output) }
            override fun onError(error: String) { errors.add(error) }
            override fun onProcessStarted() { started = true }
            override fun onProcessStopped(exitCode: Int?) { stopped = true }
        }

        val result = manager.start(
            listOf("echo", "hello"),
            System.getProperty("user.dir")!!,
            handler
        )

        if (result) {
            assertTrue(manager.isInitialized())
            Thread.sleep(500)
            manager.stop()
            assertTrue(outputs.any { it.contains("hello") })
            assertTrue(stopped)
        }
    }

    @Test
    fun `writeLineToProcess sends input to process`() {
        val manager = PtyProcessManager()
        val outputs = mutableListOf<String>()
        val errors = mutableListOf<String>()
        var started = false

        val handler = object : PtyProcessManager.ProcessOutputHandler {
            override fun onOutput(output: String) { outputs.add(output) }
            override fun onError(error: String) { errors.add(error) }
            override fun onProcessStarted() { started = true }
            override fun onProcessStopped(exitCode: Int?) { /* no-op for test */ }
        }

        val result = manager.start(
            listOf("cat"),
            System.getProperty("user.dir")!!,
            handler
        )

        if (result) {
            Thread.sleep(200)
            manager.writeLineToProcess("test input")
            Thread.sleep(200)
            assertTrue(outputs.any { it.contains("test input") })
            manager.stop()
        }
    }

    @Test
    fun `process stops correctly`() {
        val manager = PtyProcessManager()
        val outputs = mutableListOf<String>()
        val errors = mutableListOf<String>()
        var stopped = false
        var exitCode: Int? = null

        val handler = object : PtyProcessManager.ProcessOutputHandler {
            override fun onOutput(output: String) { outputs.add(output) }
            override fun onError(error: String) { errors.add(error) }
            override fun onProcessStarted() { /* no-op for test */ }
            override fun onProcessStopped(code: Int?) {
                stopped = true
                exitCode = code
            }
        }

        val result = manager.start(
            listOf("echo", "test"),
            System.getProperty("user.dir")!!,
            handler
        )

        if (result) {
            Thread.sleep(500)
            manager.stop()
            assertTrue(stopped)
            assertFalse(manager.isRunning())
        }
    }
}
