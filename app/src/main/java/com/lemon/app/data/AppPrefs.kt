package com.lemon.app.data

import android.content.Context

/** Small preferences that are not part of the encrypted vault (theme). */
object AppPrefs {

    const val THEME_SYSTEM = 0
    const val THEME_LIGHT = 1
    const val THEME_DARK = 2

    private const val PREFS = "lemon_prefs"
    private const val KEY_THEME = "theme_mode"

    fun getThemeMode(context: Context): Int =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_THEME, THEME_SYSTEM)

    fun setThemeMode(context: Context, mode: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putInt(KEY_THEME, mode).apply()
    }
}
