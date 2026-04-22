package com.example.ui.terminal

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class TerminalStatus {
    Disconnected,
    Connecting,
    Connected,
    Error
}

private const val ROTATION_DURATION_MS = 1000

@Composable
fun TerminalStatusBar(
    status: TerminalStatus,
    statusMessage: String = "",
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(TerminalColors.StatusBarBackground)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            StatusIndicator(status)
            Text(
                text = when (status) {
                    TerminalStatus.Disconnected -> "Disconnected"
                    TerminalStatus.Connecting -> "Connecting..."
                    TerminalStatus.Connected -> "Connected"
                    TerminalStatus.Error -> "Error"
                },
                fontFamily = FontFamily.Monospace,
                fontSize = 10.sp,
                color = when (status) {
                    TerminalStatus.Disconnected -> TerminalColors.MutedText
                    TerminalStatus.Connecting -> TerminalColors.Prompt
                    TerminalStatus.Connected -> TerminalColors.Success
                    TerminalStatus.Error -> TerminalColors.Error
                }
            )
        }

        if (statusMessage.isNotEmpty()) {
            Text(
                text = statusMessage,
                fontFamily = FontFamily.Monospace,
                fontSize = 10.sp,
                color = TerminalColors.MutedText,
                maxLines = 1
            )
        }
    }
}

@Composable
private fun StatusIndicator(status: TerminalStatus) {
    when (status) {
        TerminalStatus.Connecting -> {
            val infiniteTransition = rememberInfiniteTransition(label = "loading")
            val rotation by infiniteTransition.animateFloat(
                initialValue = 0f,
                targetValue = 360f,
                animationSpec = infiniteRepeatable(
                    animation = tween(ROTATION_DURATION_MS, easing = LinearEasing),
                    repeatMode = RepeatMode.Restart
                ),
                label = "rotation"
            )
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .rotate(rotation)
                    .background(TerminalColors.Prompt, CircleShape)
            )
        }
        TerminalStatus.Connected -> {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(TerminalColors.Success, CircleShape)
            )
        }
        TerminalStatus.Error -> {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(TerminalColors.Error, CircleShape)
            )
        }
        TerminalStatus.Disconnected -> {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .width(8.dp)
                    .background(TerminalColors.MutedText, CircleShape)
            )
        }
    }
}
