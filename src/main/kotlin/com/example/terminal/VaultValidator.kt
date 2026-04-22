package com.example.terminal

import java.io.File

data class VaultContext(
    val path: String,
    val isValid: Boolean,
    val errorMessage: String? = null
)

object VaultValidator {
    private const val VAULT_TOKEN = ".vault-token"
    private const val VAULT_CONFIG = "config"

    fun validateVaultPath(path: String): VaultContext {
        val file = File(path)
        return when {
            !file.exists() -> VaultContext(
                path = path,
                isValid = false,
                errorMessage = "Vault directory does not exist: $path"
            )
            !file.isDirectory -> VaultContext(
                path = path,
                isValid = false,
                errorMessage = "Path is not a directory: $path"
            )
            !file.canRead() -> VaultContext(
                path = path,
                isValid = false,
                errorMessage = "Cannot read vault directory: $path"
            )
            !file.canWrite() -> VaultContext(
                path = path,
                isValid = false,
                errorMessage = "Cannot write to vault directory: $path"
            )
            else -> {
                val hasVaultMarker = File(file, VAULT_TOKEN).exists() || File(file, VAULT_CONFIG).exists()
                VaultContext(
                    path = path,
                    isValid = true,
                    errorMessage = if (!hasVaultMarker) {
                        "Warning: Vault marker files not found in $path"
                    } else null
                )
            }
        }
    }

    fun getDefaultVaultPath(): String {
        val home = System.getProperty("user.home")
        val defaultVault = File(home, ".vault")
        return if (defaultVault.exists()) {
            defaultVault.absolutePath
        } else {
            home
        }
    }
}
