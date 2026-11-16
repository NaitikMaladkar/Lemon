package com.lemon.app

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate
import com.lemon.app.data.AppPrefs
import com.lemon.app.data.VaultStore

class LemonApp : Application() {
    override fun onCreate() {
        super.onCreate()
        VaultStore.init(this)
        AppCompatDelegate.setDefaultNightMode(
            when (AppPrefs.getThemeMode(this)) {
                AppPrefs.THEME_LIGHT -> AppCompatDelegate.MODE_NIGHT_NO
                AppPrefs.THEME_DARK -> AppCompatDelegate.MODE_NIGHT_YES
                else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
            }
        )
    }
}
