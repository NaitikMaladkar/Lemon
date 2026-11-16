package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.util.Keypad
import com.lemon.app.util.SecureActivity

/**
 * PIN unlock. Correct PIN opens the real vault; any wrong PIN opens the
 * pseudo decoy vault. Submits automatically once 4 digits are typed.
 */
class PinActivity : SecureActivity() {

    private lateinit var keypad: Keypad
    private lateinit var error: TextView
    private var opening = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!VaultStore.isSetupDone()) {
            startActivity(Intent(this, SetupActivity::class.java))
            finish()
            return
        }

        setContentView(R.layout.activity_pin)
        error = findViewById(R.id.pin_error)
        keypad = Keypad(
            root = window.decorView,
            dotsContainer = findViewById(R.id.pin_dots),
            maxLen = 4,
            onComplete = { pin -> unlock(pin) }
        )
    }

    private fun unlock(pin: String) {
        if (opening) return
        opening = true
        error.visibility = TextView.GONE

        if (VaultStore.tryUnlock(VaultStore.Profile.REAL, pin)) {
            // real vault
        } else {
            // decoy: any wrong PIN opens the pseudo vault
            VaultStore.unlockPseudo()
        }
        startActivity(Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        })
        finish()
    }
}
