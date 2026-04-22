package com.example.terminal

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class VaultValidatorTest {

    @Test
    fun `nonExistentPath is invalid`() {
        val context = VaultValidator.validateVaultPath("/nonexistent/path/12345")
        assertFalse(context.isValid)
        assertTrue(context.errorMessage!!.contains("does not exist"))
    }

    @Test
    fun `userHome is valid vault path`() {
        val home = System.getProperty("user.home")
        val context = VaultValidator.validateVaultPath(home)
        assertTrue(context.isValid)
        assertEquals(home, context.path)
    }

    @Test
    fun `fileAsPath is invalid`() {
        val tempFile = File.createTempFile("test", "txt")
        try {
            val context = VaultValidator.validateVaultPath(tempFile.absolutePath)
            assertFalse(context.isValid)
            assertTrue(context.errorMessage!!.contains("not a directory"))
        } finally {
            tempFile.delete()
        }
    }

    @Test
    fun `getDefaultVaultPath returns valid path`() {
        val path = VaultValidator.getDefaultVaultPath()
        assertTrue(File(path).exists())
        assertTrue(File(path).isDirectory)
    }
}
