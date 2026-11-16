package com.lemon.app.gen

import java.security.SecureRandom

object PasswordGenerator {

    private const val LENGTH = 32
    private const val LOWER = "abcdefghijklmnopqrstuvwxyz"
    private const val UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private const val DIGITS = "0123456789"
    private const val SYMBOLS = "!@#$%^&*()-_=+[]{};:,.<>?/|~`\"'\\"

    /** 32 random characters: lowercase + uppercase + digits + symbols & punctuation. */
    fun password32(): String {
        val all = LOWER + UPPER + DIGITS + SYMBOLS
        val random = SecureRandom()
        val chars = CharArray(LENGTH)
        // guarantee at least one character of every class
        chars[0] = LOWER[random.nextInt(LOWER.length)]
        chars[1] = UPPER[random.nextInt(UPPER.length)]
        chars[2] = DIGITS[random.nextInt(DIGITS.length)]
        chars[3] = SYMBOLS[random.nextInt(SYMBOLS.length)]
        for (i in 4 until LENGTH) chars[i] = all[random.nextInt(all.length)]
        for (i in chars.size - 1 downTo 1) {
            val j = random.nextInt(i + 1)
            val t = chars[i]
            chars[i] = chars[j]
            chars[j] = t
        }
        return String(chars)
    }

    /** 1..32 words from the built-in English dictionary. */
    fun passphrase(words: Int): List<String> {
        val count = words.coerceIn(1, 32)
        val random = SecureRandom()
        return (0 until count).map { WordList.WORDS[random.nextInt(WordList.WORDS.size)] }
    }
}
