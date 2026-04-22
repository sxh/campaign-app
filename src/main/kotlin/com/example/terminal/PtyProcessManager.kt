package com.example.terminal

import org.jline.terminal.Terminal
import org.jline.terminal.TerminalBuilder
import org.jline.terminal.Attributes
import org.slf4j.LoggerFactory
import java.io.InputStream
import java.io.OutputStream
import java.io.IOException

class PtyProcessManager {
    private val logger = LoggerFactory.getLogger(PtyProcessManager::class.java)
    private var terminal: Terminal? = null
    private var process: Process? = null
    private var inputReader: Thread? = null
    private var errorReader: Thread? = null
    private var outputWriter: Thread? = null
    private var processMonitor: Thread? = null
    private var savedAttributes: Attributes? = null
    private var outputHandler: ProcessOutputHandler? = null

    companion object {
        private const val BUFFER_SIZE = 4096
    }

    interface ProcessOutputHandler {
        fun onOutput(output: String)
        fun onError(error: String)
        fun onProcessStarted()
        fun onProcessStopped(exitCode: Int?)
    }

    fun start(
        command: List<String>,
        workingDirectory: String,
        outputHandler: ProcessOutputHandler
    ): Boolean {
        return try {
            JnaLoader.load()

            terminal = TerminalBuilder.builder()
                .jna(true)
                .jni(true)
                .type(Terminal.TYPE_DUMB)
                .build()

            this.outputHandler = outputHandler
            savedAttributes = terminal?.enterRawMode()

            val processBuilder = ProcessBuilder(command)
            processBuilder.directory(java.io.File(workingDirectory))
            processBuilder.redirectErrorStream(false)

            process = processBuilder.start()
            spawnIoThreads()

            outputHandler.onProcessStarted()
            logger.info("Process started: ${command.joinToString(" ")}")

            true
        } catch (e: IOException) {
            logger.error("Failed to start process", e)
            outputHandler.onError("Failed to start process: ${e.message}")
            false
        } catch (e: IllegalStateException) {
            logger.error("Failed to start PTY", e)
            outputHandler.onError("Failed to start PTY: ${e.message}")
            false
        }
    }

    private fun spawnIoThreads() {
        val inputStream = process?.inputStream
        val errorStream = process?.errorStream
        val outputStream = process?.outputStream
        val term = terminal

        inputReader = Thread {
            readFromStream(inputStream) { output ->
                outputHandler?.onOutput(output)
                term?.writer()?.print(output)
                term?.writer()?.flush()
            }
        }.apply { start() }

        errorReader = Thread {
            readFromStream(errorStream) { error ->
                outputHandler?.onError(error)
            }
        }.apply { start() }

        outputWriter = Thread {
            writeToStream(outputStream)
        }.apply { start() }

        processMonitor = Thread {
            process?.waitFor()
            outputHandler?.onProcessStopped(process?.exitValue())
        }.apply { start() }
    }

    private fun readFromStream(stream: InputStream?, onRead: (String) -> Unit) {
        stream ?: return
        val buffer = ByteArray(BUFFER_SIZE)
        var bytesRead: Int
        while (!Thread.currentThread().isInterrupted) {
            bytesRead = stream.read(buffer)
            if (bytesRead == -1) break
            val output = String(buffer, 0, bytesRead)
            onRead(output)
        }
    }

    private fun writeToStream(stream: OutputStream?) {
        val reader = terminal?.reader()
        val writer = stream
        while (!Thread.currentThread().isInterrupted) {
            val char = reader?.read() ?: -1
            if (char == -1) break
            when (char) {
                '\n'.code -> {
                    writer?.write('\n'.code)
                    writer?.flush()
                }
                '\r'.code -> { }
                else -> {
                    writer?.write(char)
                    writer?.flush()
                }
            }
        }
    }

    fun writeToProcess(input: String) {
        try {
            process?.outputStream?.write(input.toByteArray())
            process?.outputStream?.flush()
        } catch (e: IOException) {
            logger.error("Failed to write to process", e)
        }
    }

    fun writeLineToProcess(line: String) = writeToProcess("$line\n")

    fun stop() {
        inputReader?.interrupt()
        errorReader?.interrupt()
        outputWriter?.interrupt()
        processMonitor?.interrupt()

        process?.let { proc ->
            if (proc.isAlive) {
                proc.destroyForcibly()
            }
            try {
                val exitCode = proc.waitFor()
                savedAttributes?.let { terminal?.setAttributes(it) }
                logger.info("Process stopped with exit code: $exitCode")
            } catch (e: InterruptedException) {
                logger.warn("Error waiting for process", e)
            }
        }

        outputHandler = null
        terminal?.close()
        terminal = null
        process = null
        inputReader = null
        errorReader = null
        outputWriter = null
        processMonitor = null
    }

    fun isRunning(): Boolean = process?.isAlive == true

    fun getExitCode(): Int? = process?.exitValue()

    fun isInitialized(): Boolean = terminal != null
}
