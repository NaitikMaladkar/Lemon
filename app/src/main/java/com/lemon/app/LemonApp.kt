package com.lemon.app

import android.app.Application
import com.lemon.app.data.VaultStore

class LemonApp : Application() {
    override fun onCreate() {
        super.onCreate()
        VaultStore.init(this)
    }
}
