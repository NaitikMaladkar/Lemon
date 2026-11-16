package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.util.Keypad
import com.lemon.app.util.SecureActivity

/**
 * PIN lock.
 *  - real PIN      -> real vault
 *  - secret PIN    -> secret (polished decoy) vault
 *  - any other PIN -> pseudo (fake) vault
 */
class PinActivity : SecureActivity() {

    private lateinit var keypad: Keypad
    private lateinit var hint: TextView
    private lateinit var error: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!VaultStore.isSetupDone()) {
            startActivity(Intent(this, SetupActivity::class.java))
            finish()
            return
        }

        setContentView(R.layout.activity_pin)

        hint = findViewById(R.id.pin_hint)
        error = findViewById(R.id.pin_error)
        keypad = Keypad(findViewById(R.id.keypad), findViewById(R.id.pin_dots))

        findViewById<Button>(R.id.pin_confirm).setOnClickListener { attemptUnlock() }

        // If the vault is already unlocked (e.g. process re-created), skip ahead.
        if (VaultStore.unlocked) {
            goToMain()
        }
    }

    private fun attemptUnlock() {
        val pin = keypad.pin()
        if (pin.isEmpty()) {
            showError(getString(R.string.pin_wrong))
            return
        }
        error.visibility = View.GONE

        if (VaultStore.tryUnlock(VaultStore.Profile.REAL, pin)) {
            goToMain()
            return
        }
        if (VaultStore.hasPin(VaultStore.Profile.SECRET) &&
            VaultStore.tryUnlock(VaultStore.Profile.SECRET, pin)
        ) {
            goToMain()
            return
        }
        // Any wrong PIN opens the pseudo decoy - no error shown on purpose.
        VaultStore.unlockPseudo()
        goToMain()
    }

    private fun showError(msg: String) {
        error.text = msg
        error.visibility = View.VISIBLE
        keypad.clear()
    }

    private fun goToMain() {
        keypad.clear()
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
