package com.example

import androidx.compose.desktop.ui.tooling.preview.Preview
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import com.example.ui.terminal.TerminalState
import com.example.ui.terminal.TerminalView

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "Campaign Terminal",
        state = rememberWindowState()
    ) {
        App()
    }
}

@Composable
@Preview
fun App() {
    val state = remember { TerminalState() }

    TerminalView(
        state = state,
        onCommand = { command ->
            state.appendOutput("Executing: $command")
        }
    )
}
