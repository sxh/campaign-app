package com.example.ui.terminal

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
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

@Composable
fun TerminalView(
    modifier: Modifier = Modifier,
    state: TerminalState = remember { TerminalState() },
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

    Box(
        modifier = modifier
            .background(TerminalColors.Background)
            .border(1.dp, TerminalColors.Border)
            .focusRequester(focusRequester)
            .onKeyEvent { event ->
                KeyboardHandler.handleKeyEvent(event, state, onCommand)
            }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp)
                .verticalScroll(scrollState)
        ) {
            state.lines.forEach { line ->
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
        LineType.Error -> TerminalColors.MutedText
    }

    Text(
        text = line.content,
        fontFamily = FontFamily.Monospace,
        fontSize = 14.sp,
        color = color,
        modifier = Modifier.padding(vertical = 1.dp)
    )
}
