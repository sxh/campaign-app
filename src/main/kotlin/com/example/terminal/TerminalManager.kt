package com.example.terminal

import org.jline.reader.LineReader
import org.jline.reader.LineReaderBuilder
import org.jline.terminal.Attributes
import org.jline.terminal.Terminal
import org.jline.terminal.TerminalBuilder
import org.slf4j.LoggerFactory
import java.io.IOException

class TerminalManager {
    private val logger = LoggerFactory.getLogger(TerminalManager::class.java)
    private var terminal: Terminal? = null
    private var lineReader: LineReader? = null

    fun initialize(): Boolean {
        return try {
            JnaLoader.load()

            terminal = TerminalBuilder.builder()
                .jna(true)
                .jni(true)
                .build()

            lineReader = LineReaderBuilder.builder()
                .terminal(terminal!!)
                .build()

            logger.info("Terminal initialized successfully")
            true
        } catch (e: IOException) {
            logger.error("Failed to initialize terminal", e)
            false
        } catch (e: UnsatisfiedLinkError) {
            logger.error("Failed to initialize terminal", e)
            false
        }
    }

    fun getTerminal(): Terminal? = terminal

    fun getLineReader(): LineReader? = lineReader

    fun readLine(prompt: String): String? {
        return try {
            lineReader?.readLine(prompt)
        } catch (e: IOException) {
            logger.error("Error reading line", e)
            null
        }
    }

    fun write(output: String) {
        terminal?.writer()?.print(output)
        terminal?.writer()?.flush()
    }

    fun getAttributes(): Attributes? = terminal?.enterRawMode()

    fun resetAttributes(attrs: Attributes?) {
        attrs?.let { terminal?.setAttributes(it) }
    }

    fun close() {
        try {
            terminal?.close()
            logger.info("Terminal closed")
        } catch (e: IOException) {
            logger.error("Error closing terminal", e)
        }
    }
}
