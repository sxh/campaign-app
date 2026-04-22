package com.example.terminal

sealed class ProcessError(val message: String, val suggestion: String? = null) {
    class CommandNotFound(command: String) : ProcessError(
        message = "Command not found: $command",
        suggestion = "Ensure the command is installed and available in your PATH"
    )

    class PathInaccessible(path: String) : ProcessError(
        message = "Cannot access path: $path",
        suggestion = "Check that the directory exists and you have permission to access it"
    )

    class ProcessCrashed(exitCode: Int?) : ProcessError(
        message = "Process crashed with exit code: $exitCode",
        suggestion = "Try restarting the process or check the logs for more details"
    )

    class PtyInitializationFailed(cause: String) : ProcessError(
        message = "Failed to initialize terminal: $cause",
        suggestion = "Ensure JNA/JNI libraries are available on your system"
    )

    class WriteFailed(cause: String) : ProcessError(
        message = "Failed to write to process: $cause",
        suggestion = "The process may have terminated unexpectedly"
    )
}

object ErrorHandler {
    fun handleProcessError(error: ProcessError): String {
        return buildString {
            appendLine("\nError: ${error.message}")
            error.suggestion?.let {
                appendLine("Suggestion: $it")
            }
        }
    }

    fun detectCommandNotFound(output: String): Boolean {
        return output.contains("command not found", ignoreCase = true) ||
            output.contains("not recognized as an internal or external command", ignoreCase = true)
    }

    fun detectPathError(output: String): Boolean {
        return output.contains("no such file or directory", ignoreCase = true) ||
            output.contains("permission denied", ignoreCase = true) ||
            output.contains("operation not permitted", ignoreCase = true)
    }

    fun detectGeminiNotInstalled(output: String): Boolean {
        return output.contains("gemine", ignoreCase = true) ||
            output.contains("ai", ignoreCase = true) && output.contains("not found", ignoreCase = true)
    }

    fun formatForTerminal(error: ProcessError): String {
        return buildString {
            appendLine()
            appendLine("\u001b[31mError: ${error.message}\u001b[0m")
            error.suggestion?.let {
                appendLine("\u001b[33mSuggestion: $it\u001b[0m")
            }
        }
    }
}
