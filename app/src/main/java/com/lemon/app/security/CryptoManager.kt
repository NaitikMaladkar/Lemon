package com.lemon.app.security

import java.security.SecureRandom
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/**
 * All cryptography for Lemon:
 *  - PIN -> AES-256 key via PBKDF2-HMAC-SHA256 (per-profile random salt)
 *  - Vault file -> AES-256-GCM (random 12-byte IV prepended to ciphertext)
 *  - PIN verifier: the PIN-derived key must decrypt a known token.
 */
object CryptoManager {

    private const val ITERATIONS = 120_000
    private const val KEY_BITS = 256
    private const val IV_LEN = 12
    private const val VERIFIER_TEXT = "LEMON::VERIFY::v1"

    fun randomBytes(n: Int): ByteArray = ByteArray(n).also { SecureRandom().nextBytes(it) }

    fun deriveKey(pin: String, salt: ByteArray): ByteArray {
        val spec = PBEKeySpec(pin.toCharArray(), salt, ITERATIONS, KEY_BITS)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        return factory.generateSecret(spec).encoded
    }

    fun encrypt(key: ByteArray, plain: ByteArray): ByteArray {
        val iv = randomBytes(IV_LEN)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, iv))
        return iv + cipher.doFinal(plain)
    }

    fun decrypt(key: ByteArray, data: ByteArray): ByteArray? {
        if (data.size <= IV_LEN) return null
        return try {
            val iv = data.copyOfRange(0, IV_LEN)
            val ct = data.copyOfRange(IV_LEN, data.size)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, iv))
            cipher.doFinal(ct)
        } catch (e: Exception) {
            null
        }
    }

    fun makeVerifier(key: ByteArray): String =
        Base64.getEncoder().encodeToString(encrypt(key, VERIFIER_TEXT.toByteArray()))

    fun checkVerifier(key: ByteArray, verifierB64: String): Boolean {
        return try {
            val data = Base64.getDecoder().decode(verifierB64)
            val plain = decrypt(key, data) ?: return false
            String(plain) == VERIFIER_TEXT
        } catch (e: Exception) {
            false
        }
    }

    fun b64(data: ByteArray): String = Base64.getEncoder().encodeToString(data)

    fun unb64(text: String): ByteArray = Base64.getDecoder().decode(text)
}
