package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.util.Keypad
import com.lemon.app.util.SecureActivity

/**
 * First-run setup: create a 4-digit PIN (and confirm it). Submits
 * automatically once all 4 digits are typed.
 */
class SetupActivity : SecureActivity() {

    private enum class Step { CREATE, CONFIRM }

    private var step = Step.CREATE
    private var firstPin = ""

    private lateinit var keypad: Keypad
    private lateinit var title: TextView
    private lateinit var subtitle: TextView
    private lateinit var error: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_setup)

        title = findViewById(R.id.setup_title)
        subtitle = findViewById(R.id.setup_subtitle)
        error = findViewById(R.id.setup_error)

        keypad = Keypad(
            root = window.decorView,
            dotsContainer = findViewById(R.id.setup_dots),
            maxLen = 4,
            onComplete = { pin -> onPinComplete(pin) }
        )
    }

    private fun onPinComplete(pin: String) {
        when (step) {
            Step.CREATE -> {
                firstPin = pin
                keypad.clear()
                showError(0)
                step = Step.CONFIRM
                title.setText(R.string.setup_confirm_pin)
            }
            Step.CONFIRM -> {
                if (pin == firstPin) {
                    finishSetup(pin)
                } else {
                    showError(R.string.pin_mismatch)
                    keypad.clear()
                    step = Step.CREATE
                    title.setText(R.string.setup_create_pin)
                }
            }
        }
    }

    private fun finishSetup(pin: String) {
        VaultStore.createProfile(VaultStore.Profile.REAL, pin)
        VaultStore.markSetupDone()
        VaultStore.tryUnlock(VaultStore.Profile.REAL, pin)
        startActivity(Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        })
        finish()
    }

    private fun showError(resId: Int) {
        if (resId == 0) {
            error.visibility = TextView.GONE
        } else {
            error.setText(resId)
            error.visibility = TextView.VISIBLE
        }
    }
}
