package com.example.ui.terminal

import androidx.compose.ui.input.key.KeyEvent

object KeyboardHandler {

    private const val MIN_PRINTABLE_CHAR = 32
    private const val MAX_PRINTABLE_CHAR = 126
    private const val TAB_SPACES = 4

    fun handleKeyEvent(
        event: KeyEvent,
        state: TerminalState,
        onSubmit: (String) -> Unit
    ): Boolean {
        val native = event.nativeKeyEvent as java.awt.event.KeyEvent
        val keyCode = native.keyCode
        val keyChar = native.keyChar

        return handleSpecialKeys(keyCode, state, onSubmit) ||
            handlePrintableChar(keyChar, state)
    }

    private fun handleSpecialKeys(
        keyCode: Int,
        state: TerminalState,
        onSubmit: (String) -> Unit
    ): Boolean = when (keyCode) {
        java.awt.event.KeyEvent.VK_ENTER -> {
            val input = state.submitInput()
            onSubmit(input)
            true
        }
        java.awt.event.KeyEvent.VK_BACK_SPACE -> {
            state.handleBackspace()
            true
        }
        java.awt.event.KeyEvent.VK_DELETE -> {
            state.handleDelete()
            true
        }
        java.awt.event.KeyEvent.VK_LEFT -> {
            state.moveCursor(-1)
            true
        }
        java.awt.event.KeyEvent.VK_RIGHT -> {
            state.moveCursor(1)
            true
        }
        java.awt.event.KeyEvent.VK_HOME -> {
            state.moveCursorToStart()
            true
        }
        java.awt.event.KeyEvent.VK_END -> {
            state.moveCursorToEnd()
            true
        }
        java.awt.event.KeyEvent.VK_TAB -> {
            repeat(TAB_SPACES) { state.insertChar(' ') }
            true
        }
        java.awt.event.KeyEvent.VK_UP -> {
            state.navigateHistoryUp()
            true
        }
        java.awt.event.KeyEvent.VK_DOWN -> {
            state.navigateHistoryDown()
            true
        }
        java.awt.event.KeyEvent.VK_SPACE -> {
            state.insertChar(' ')
            true
        }
        else -> false
    }

    private fun handlePrintableChar(keyChar: Char, state: TerminalState): Boolean {
        return if (keyChar != java.awt.event.KeyEvent.CHAR_UNDEFINED &&
            keyChar.code in MIN_PRINTABLE_CHAR..MAX_PRINTABLE_CHAR
        ) {
            state.insertChar(keyChar)
            true
        } else {
            false
        }
    }
}
