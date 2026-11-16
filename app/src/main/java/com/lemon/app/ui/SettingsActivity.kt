package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.util.SecureActivity

class SettingsActivity : SecureActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)

        findViewById<Button>(R.id.button_lock_now).setOnClickListener {
            VaultStore.lock()
            val intent = Intent(this, PinActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(intent)
            finish()
        }

        findViewById<Button>(R.id.button_wipe).setOnClickListener {
            MaterialAlertDialogBuilder(this)
                .setTitle(R.string.settings_wipe)
                .setMessage(R.string.settings_wipe_confirm)
                .setNegativeButton(R.string.cancel, null)
                .setPositiveButton(R.string.settings_wipe) { _, _ ->
                    VaultStore.wipeAll()
                    val intent = Intent(this, PinActivity::class.java)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    startActivity(intent)
                    finish()
                }
                .show()
        }
    }
}
