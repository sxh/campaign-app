package com.example.ui.terminal

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.terminal.PtyProcessManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runInterruptible
import java.util.concurrent.Executors

private val ioExecutor = Executors.newSingleThreadExecutor()
private const val MAX_VISIBLE_LINES = 10000

@Composable
fun TerminalView(
    modifier: Modifier = Modifier,
    state: TerminalState = remember { TerminalState() },
    processManager: PtyProcessManager? = null,
    onCommand: (String) -> Unit = {}
) {
    val focusRequester = remember { FocusRequester() }
    val scrollState = rememberScrollState()

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    LaunchedEffect(state.lines.size) {
        scrollState.scrollTo(scrollState.maxValue)
    }

    LaunchedEffect(processManager) {
        if (processManager != null) {
            state.setStatus(TerminalStatus.Connecting)
            runInterruptible(Dispatchers.IO) {
                val success = processManager.start(
                    command = listOf("/bin/bash", "-i"),
                    workingDirectory = System.getProperty("user.dir"),
                    outputHandler = createOutputHandler(state)
                )
                if (success) {
                    state.setStatus(TerminalStatus.Connected)
                } else {
                    state.setStatus(TerminalStatus.Error, "Failed to start process")
                }
            }
        } else {
            state.setStatus(TerminalStatus.Disconnected)
        }
    }

    Column(
        modifier = modifier
            .background(TerminalColors.Background)
            .border(1.dp, TerminalColors.Border)
    ) {
        TerminalStatusBar(
            status = state.status,
            statusMessage = state.statusMessage
        )

        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .weight(1f)
                .focusRequester(focusRequester)
                .onKeyEvent { event ->
                    KeyboardHandler.handleKeyEvent(event, state) { command ->
                        handleCommand(command, state, processManager, onCommand)
                    }
                }
        ) {
            TerminalContent(state, scrollState)
        }
    }
}

@Composable
private fun TerminalContent(
    state: TerminalState,
    scrollState: androidx.compose.foundation.ScrollState
) {
    val visibleLines = if (state.lines.size > MAX_VISIBLE_LINES) {
        state.lines.takeLast(MAX_VISIBLE_LINES)
    } else {
        state.lines
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp)
            .verticalScroll(scrollState)
    ) {
        visibleLines.forEach { line ->
            TerminalLineContent(line)
        }

        Row {
            TerminalPrompt()
            BasicTextField(
                value = state.currentInput,
                onValueChange = { },
                textStyle = TextStyle(
                    fontFamily = FontFamily.Monospace,
                    fontSize = 14.sp,
                    color = TerminalColors.Text
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 2.dp),
                readOnly = true,
                cursorBrush = SolidColor(TerminalColors.Cursor)
            )
        }
    }
}

private fun handleCommand(
    command: String,
    state: TerminalState,
    processManager: PtyProcessManager?,
    onCommand: (String) -> Unit
) {
    when {
        command == "clear" -> state.clearScreen()
        command == "exit" -> {
            processManager?.stop()
            state.setStatus(TerminalStatus.Disconnected)
            onCommand(command)
        }
        processManager?.isRunning() == true -> {
            ioExecutor.submit {
                processManager.writeLineToProcess(command)
            }
        }
        else -> onCommand(command)
    }
}

private fun createOutputHandler(state: TerminalState) = object : PtyProcessManager.ProcessOutputHandler {
    override fun onOutput(output: String) {
        state.appendOutput(output)
    }

    override fun onError(error: String) {
        state.appendError(error)
    }

    override fun onProcessStarted() {
        state.setStatus(TerminalStatus.Connected)
    }

    override fun onProcessStopped(exitCode: Int?) {
        state.setStatus(TerminalStatus.Disconnected, "Process exited: $exitCode")
        state.appendOutput("Process exited with code: $exitCode\n")
    }
}

@Composable
private fun TerminalPrompt() {
    Text(
        text = "$ ",
        fontFamily = FontFamily.Monospace,
        fontSize = 14.sp,
        color = TerminalColors.Prompt
    )
}

@Composable
private fun TerminalLineContent(line: TerminalLine) {
    val color = when (line.type) {
        LineType.Output -> TerminalColors.Text
        LineType.Input -> TerminalColors.Command
        LineType.Prompt -> TerminalColors.Prompt
        LineType.Error -> TerminalColors.Error
    }

    Text(
        text = line.content,
        fontFamily = FontFamily.Monospace,
        fontSize = 14.sp,
        color = color,
        modifier = Modifier.padding(vertical = 1.dp)
    )
}
