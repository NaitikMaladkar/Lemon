package com.lemon.app.totp

import com.lemon.app.data.TotpEntry
import java.io.ByteArrayOutputStream
import java.net.URLDecoder
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * RFC 6238 TOTP (and otpauth:// URI parsing) with zero external dependencies.
 */
object Totp {

    private const val ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    fun base32Decode(input: String): ByteArray {
        val clean = input.trim().replace(" ", "").replace("-", "").uppercase()
        val out = ByteArrayOutputStream()
        var buffer = 0
        var bits = 0
        for (c in clean) {
            val v = ALPHABET.indexOf(c)
            if (v < 0) continue
            buffer = (buffer shl 5) or v
            bits += 5
            if (bits >= 8) {
                bits -= 8
                out.write((buffer shr bits) and 0xFF)
            }
        }
        return out.toByteArray()
    }

    fun isValidBase32(input: String): Boolean {
        val clean = input.trim().replace(" ", "").replace("-", "")
        if (clean.isEmpty()) return false
        return clean.uppercase().all { ALPHABET.indexOf(it) >= 0 }
    }

    fun code(
        secretBase32: String,
        timeMillis: Long = System.currentTimeMillis(),
        period: Int = 30,
        digits: Int = 6,
        algorithm: String = "SHA1"
    ): String {
        val key = base32Decode(secretBase32)
        if (key.isEmpty()) return "-".repeat(digits)
        return try {
            val counter = timeMillis / 1000L / period
            val data = ByteArray(8)
            var c = counter
            for (i in 7 downTo 0) {
                data[i] = (c and 0xFF).toByte()
                c = c shr 8
            }
            val mac = Mac.getInstance("Hmac$algorithm")
            mac.init(SecretKeySpec(key, "Hmac$algorithm"))
            val hash = mac.doFinal(data)
            val offset = hash[hash.size - 1].toInt() and 0x0F
            val binary = ((hash[offset].toInt() and 0x7F) shl 24) or
                ((hash[offset + 1].toInt() and 0xFF) shl 16) or
                ((hash[offset + 2].toInt() and 0xFF) shl 8) or
                (hash[offset + 3].toInt() and 0xFF)
            val mod = Math.pow(10.0, digits.toDouble()).toInt()
            (binary % mod).toString().padStart(digits, '0')
        } catch (e: Exception) {
            "-".repeat(digits)
        }
    }

    fun secondsRemaining(period: Int = 30): Int =
        (period - (System.currentTimeMillis() / 1000L) % period).toInt()

    /** Parse an otpauth://totp/... URI into a TotpEntry, or null if invalid. */
    fun parseOtpAuthUri(uri: String): TotpEntry? {
        if (!uri.startsWith("otpauth://")) return null
        val rest = uri.removePrefix("otpauth://")
        val type = rest.substringBefore('/').lowercase()
        if (type != "totp") return null
        val labelAndQuery = rest.substringAfter('/', "")
        val label = urlDecode(labelAndQuery.substringBefore('?'))
        val query = labelAndQuery.substringAfter('?', "")
        val params = HashMap<String, String>()
        query.split('&').forEach { part ->
            if (part.isEmpty()) return@forEach
            val k = part.substringBefore('=')
            val v = part.substringAfter('=', "")
            params[k.lowercase()] = urlDecode(v)
        }
        val secret = params["secret"] ?: return null
        if (!isValidBase32(secret)) return null
        val issuerParam = params["issuer"] ?: ""
        val labelIssuer = if (label.contains(':')) label.substringBefore(':').trim() else ""
        val account = if (label.contains(':')) label.substringAfter(':').trim() else label
        val issuer = issuerParam.ifEmpty { labelIssuer }
        val digits = params["digits"]?.toIntOrNull() ?: 6
        val period = params["period"]?.toIntOrNull() ?: 30
        val algorithm = (params["algorithm"] ?: "SHA1").uppercase()
        return TotpEntry(
            label = account.ifEmpty { issuer.ifEmpty { "Account" } },
            issuer = issuer,
            secret = secret.replace(" ", "").uppercase(),
            period = if (period in 5..300) period else 30,
            digits = if (digits == 6 || digits == 8) digits else 6,
            algorithm = if (algorithm in listOf("SHA1", "SHA256", "SHA512")) algorithm else "SHA1"
        )
    }

    private fun urlDecode(s: String): String = try {
        URLDecoder.decode(s, "UTF-8")
    } catch (e: Exception) {
        s
    }

    /** Format code as "123 456" (or "1234 5678" for 8 digits). */
    fun pretty(code: String): String {
        val size = if (code.length == 8) 4 else 3
        return code.chunked(size).joinToString(" ")
    }
}
