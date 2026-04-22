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

    @Test
    fun `navigateHistoryUp retrieves previous command`() {
        val state = TerminalState()
        state.insertChar('c')
        state.insertChar('m')
        state.submitInput()
        state.insertChar('d')
        state.insertChar('a')
        state.submitInput()
        state.navigateHistoryUp()
        assertEquals("da", state.currentInput)
    }

    @Test
    fun `navigateHistoryDown returns current input when at start`() {
        val state = TerminalState()
        state.insertChar('c')
        state.insertChar('m')
        state.submitInput()
        state.navigateHistoryUp()
        assertEquals("cm", state.currentInput)
        state.navigateHistoryDown()
        assertEquals("", state.currentInput)
    }

    @Test
    fun `navigateHistoryUp wraps to oldest command`() {
        val state = TerminalState()
        state.insertChar('f')
        state.insertChar('i')
        state.insertChar('r')
        state.insertChar('s')
        state.insertChar('t')
        state.submitInput()
        state.insertChar('s')
        state.insertChar('e')
        state.insertChar('c')
        state.insertChar('o')
        state.insertChar('n')
        state.submitInput()
        state.navigateHistoryUp()
        state.navigateHistoryUp()
        assertEquals("first", state.currentInput)
    }

    @Test
    fun `submitInput adds command to history`() {
        val state = TerminalState()
        state.insertChar('e')
        state.insertChar('c')
        state.insertChar('h')
        state.insertChar('o')
        state.submitInput()
        state.navigateHistoryUp()
        assertEquals("echo", state.currentInput)
    }

    @Test
    fun `clearScreen removes all lines`() {
        val state = TerminalState()
        state.appendOutput("line 1")
        state.appendOutput("line 2")
        state.appendOutput("line 3")
        assertEquals(3, state.lines.size)
        state.clearScreen()
        assertEquals(0, state.lines.size)
    }

    @Test
    fun `navigateHistoryDown restores current input`() {
        val state = TerminalState()
        state.insertChar('w')
        state.insertChar('o')
        state.insertChar('r')
        state.insertChar('k')
        state.submitInput()
        state.insertChar('p')
        state.insertChar('l')
        state.insertChar('a')
        state.insertChar('y')
        state.navigateHistoryUp()
        assertEquals("work", state.currentInput)
        state.navigateHistoryDown()
        assertEquals("play", state.currentInput)
    }

    @Test
    fun `submitInput does not add consecutive duplicate commands to history`() {
        val state = TerminalState()
        state.insertChar('t')
        state.insertChar('e')
        state.insertChar('s')
        state.insertChar('t')
        state.submitInput()
        state.insertChar('t')
        state.insertChar('e')
        state.insertChar('s')
        state.insertChar('t')
        state.submitInput()
        state.insertChar('a')
        state.submitInput()
        state.insertChar('t')
        state.insertChar('e')
        state.insertChar('s')
        state.insertChar('t')
        state.submitInput()
        state.navigateHistoryUp()
        assertEquals("test", state.currentInput)
        state.navigateHistoryUp()
        assertEquals("a", state.currentInput)
    }

    @Test
    fun `submitInput adds all different commands to history`() {
        val state = TerminalState()
        state.insertChar('c')
        state.insertChar('m')
        state.submitInput()
        state.insertChar('d')
        state.insertChar('a')
        state.submitInput()
        state.insertChar('l')
        state.insertChar('s')
        state.submitInput()
        assertEquals(3, state.lines.size)
    }
}
