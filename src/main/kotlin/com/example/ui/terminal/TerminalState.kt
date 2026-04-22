package com.example.ui.terminal

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

data class TerminalLine(
    val content: String,
    val type: LineType = LineType.Output
)

enum class LineType {
    Output,
    Input,
    Prompt,
    Error
}

@Suppress("TooManyFunctions")
class TerminalState {
    private val _lines = mutableStateListOf<TerminalLine>()
    val lines: List<TerminalLine> get() = _lines

    var currentInput by mutableStateOf("")
        private set

    var cursorPosition by mutableIntStateOf(0)
        private set

    var scrollOffset by mutableIntStateOf(0)

    var status by mutableStateOf(TerminalStatus.Disconnected)
        private set

    var statusMessage by mutableStateOf("")
        private set

    private val commandHistory = mutableListOf<String>()
    private var historyIndex = -1
    private var historySearchInput = ""

    fun navigateHistoryUp() {
        if (commandHistory.isEmpty()) return
        
        if (historyIndex == -1) {
            historySearchInput = currentInput
        }
        
        if (historyIndex < commandHistory.size - 1) {
            historyIndex++
            currentInput = commandHistory[commandHistory.size - 1 - historyIndex]
            cursorPosition = currentInput.length
        }
    }

    fun navigateHistoryDown() {
        if (historyIndex == -1) return
        
        if (historyIndex > 0) {
            historyIndex--
            currentInput = commandHistory[commandHistory.size - 1 - historyIndex]
            cursorPosition = currentInput.length
        } else {
            historyIndex = -1
            currentInput = historySearchInput
            cursorPosition = currentInput.length
        }
    }

    private fun addToHistory(command: String) {
        if (command.isNotBlank() && (commandHistory.isEmpty() || commandHistory.last() != command)) {
            commandHistory.add(command)
        }
        historyIndex = -1
        historySearchInput = ""
    }

    fun clearScreen() {
        _lines.clear()
    }

    fun setStatus(newStatus: TerminalStatus, message: String = "") {
        status = newStatus
        statusMessage = message
    }

    fun appendOutput(text: String) {
        _lines.add(TerminalLine(text, LineType.Output))
    }

    fun appendError(text: String) {
        _lines.add(TerminalLine(text, LineType.Error))
    }

    fun appendInput(input: String) {
        _lines.add(TerminalLine("$ $input", LineType.Input))
    }

    fun insertChar(char: Char) {
        if (cursorPosition == currentInput.length) {
            currentInput += char
        } else {
            val before = currentInput.substring(0, cursorPosition)
            val after = currentInput.substring(cursorPosition)
            currentInput = before + char + after
        }
        cursorPosition++
    }

    fun handleBackspace(): Boolean {
        if (cursorPosition > 0) {
            val before = currentInput.substring(0, cursorPosition - 1)
            val after = currentInput.substring(cursorPosition)
            currentInput = before + after
            cursorPosition--
            return true
        }
        return false
    }

    fun handleDelete(): Boolean {
        if (cursorPosition < currentInput.length) {
            val before = currentInput.substring(0, cursorPosition)
            val after = currentInput.substring(cursorPosition + 1)
            currentInput = before + after
            return true
        }
        return false
    }

    fun moveCursor(delta: Int) {
        cursorPosition = (cursorPosition + delta).coerceIn(0, currentInput.length)
    }

    fun moveCursorToStart() {
        cursorPosition = 0
    }

    fun moveCursorToEnd() {
        cursorPosition = currentInput.length
    }

    fun submitInput(): String {
        val input = currentInput
        addToHistory(input)
        appendInput(input)
        currentInput = ""
        cursorPosition = 0
        return input
    }
}
