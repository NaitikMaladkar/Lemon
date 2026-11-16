package com.lemon.app.gen

import java.security.SecureRandom

object PasswordGenerator {

    private const val UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ"   // no I, O
    private const val LOWER = "abcdefghijkmnpqrstuvwxyz"   // no l
    private const val DIGITS = "23456789"                  // no 0, 1
    private const val SYMBOLS = "!@#$%^&*()-_=+[]{};:,.<>/?"

    fun password(
        length: Int,
        upper: Boolean,
        lower: Boolean,
        digits: Boolean,
        symbols: Boolean
    ): String {
        val pools = mutableListOf<String>()
        if (upper) pools.add(UPPER)
        if (lower) pools.add(LOWER)
        if (digits) pools.add(DIGITS)
        if (symbols) pools.add(SYMBOLS)
        if (pools.isEmpty()) pools.add(LOWER)
        val all = pools.joinToString("")
        val len = length.coerceAtLeast(pools.size)
        val random = SecureRandom()
        val chars = CharArray(len)
        // guarantee at least one char from every selected pool
        pools.forEachIndexed { i, pool -> chars[i] = pool[random.nextInt(pool.length)] }
        for (i in pools.size until len) chars[i] = all[random.nextInt(all.length)]
        // Fisher-Yates shuffle so the guaranteed chars are not predictable
        for (i in chars.size - 1 downTo 1) {
            val j = random.nextInt(i + 1)
            val t = chars[i]
            chars[i] = chars[j]
            chars[j] = t
        }
        return String(chars)
    }

    fun passphrase(
        words: Int,
        capitalize: Boolean,
        addNumber: Boolean,
        separator: String
    ): String {
        val random = SecureRandom()
        val out = ArrayList<String>(words + 1)
        repeat(words) {
            var w = WordList.WORDS[random.nextInt(WordList.WORDS.size)]
            if (capitalize) w = w.replaceFirstChar { it.uppercase() }
            out.add(w)
        }
        if (addNumber) out.add(random.nextInt(1000).toString())
        return out.joinToString(separator)
    }
}
