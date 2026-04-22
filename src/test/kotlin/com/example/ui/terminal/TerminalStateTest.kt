package com.example.ui.terminal

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TerminalStateTest {

    @Test
    fun `initial state is empty`() {
        val state = TerminalState()
        assertTrue(state.lines.isEmpty())
        assertEquals("", state.currentInput)
        assertEquals(0, state.cursorPosition)
    }

    @Test
    fun `appendOutput adds line to history`() {
        val state = TerminalState()
        state.appendOutput("Hello World")
        assertEquals(1, state.lines.size)
        assertEquals("Hello World", state.lines[0].content)
        assertEquals(LineType.Output, state.lines[0].type)
    }

    @Test
    fun `appendError adds error line`() {
        val state = TerminalState()
        state.appendError("Something went wrong")
        assertEquals(1, state.lines.size)
        assertEquals(LineType.Error, state.lines[0].type)
    }

    @Test
    fun `insertChar adds character at cursor`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        assertEquals("ab", state.currentInput)
        assertEquals(2, state.cursorPosition)
    }

    @Test
    fun `insertChar inserts at cursor position`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        state.moveCursor(-1)
        state.insertChar('X')
        assertEquals("aXb", state.currentInput)
        assertEquals(2, state.cursorPosition)
    }

    @Test
    fun `handleBackspace removes character before cursor`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        val result = state.handleBackspace()
        assertTrue(result)
        assertEquals("a", state.currentInput)
        assertEquals(1, state.cursorPosition)
    }

    @Test
    fun `handleBackspace returns false at start`() {
        val state = TerminalState()
        val result = state.handleBackspace()
        assertFalse(result)
        assertEquals("", state.currentInput)
    }

    @Test
    fun `handleDelete removes character at cursor`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        state.insertChar('c')
        state.moveCursor(-2)
        val result = state.handleDelete()
        assertTrue(result)
        assertEquals("ac", state.currentInput)
        assertEquals(1, state.cursorPosition)
    }

    @Test
    fun `handleDelete returns false at end`() {
        val state = TerminalState()
        state.insertChar('a')
        val result = state.handleDelete()
        assertFalse(result)
        assertEquals("a", state.currentInput)
    }

    @Test
    fun `moveCursor respects bounds`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        state.moveCursor(-10)
        assertEquals(0, state.cursorPosition)
        state.moveCursor(10)
        assertEquals(2, state.cursorPosition)
    }

    @Test
    fun `moveCursorToStart sets position to zero`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        state.moveCursorToStart()
        assertEquals(0, state.cursorPosition)
    }

    @Test
    fun `moveCursorToEnd sets position to length`() {
        val state = TerminalState()
        state.insertChar('a')
        state.insertChar('b')
        state.moveCursor(-5)
        state.moveCursorToEnd()
        assertEquals(2, state.cursorPosition)
    }

    @Test
    fun `submitInput clears buffer and adds to history`() {
        val state = TerminalState()
        state.insertChar('l')
        state.insertChar('s')
        val result = state.submitInput()
        assertEquals("ls", result)
        assertEquals("", state.currentInput)
        assertEquals(0, state.cursorPosition)
        assertEquals(1, state.lines.size)
        assertEquals("$ ls", state.lines[0].content)
    }
}
