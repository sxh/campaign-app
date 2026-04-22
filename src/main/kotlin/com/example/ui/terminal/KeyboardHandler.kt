package com.example.ui.terminal

import androidx.compose.ui.input.key.KeyEvent

object KeyboardHandler {

    private const val MIN_PRINTABLE_CHAR = 32
    private const val MAX_PRINTABLE_CHAR = 126

    fun handleKeyEvent(
        event: KeyEvent,
        state: TerminalState,
        onSubmit: (String) -> Unit
    ): Boolean {
        val native = event.nativeKeyEvent as java.awt.event.KeyEvent
        val keyCode = native.keyCode
        val keyChar = native.keyChar

        return when (keyCode) {
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
            java.awt.event.KeyEvent.VK_SPACE -> {
                state.insertChar(' ')
                true
            }
            else -> {
                if (keyChar != java.awt.event.KeyEvent.CHAR_UNDEFINED &&
                    keyChar.code in MIN_PRINTABLE_CHAR..MAX_PRINTABLE_CHAR
                ) {
                    state.insertChar(keyChar)
                    true
                } else {
                    false
                }
            }
        }
    }

    private const val TAB_SPACES = 4
}
