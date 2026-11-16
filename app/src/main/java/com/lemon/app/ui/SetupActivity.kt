package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.util.Keypad
import com.lemon.app.util.SecureActivity

/**
 * First-run setup: create the real PIN, optionally a Secret PIN.
 * Pseudo mode needs no PIN - any wrong PIN opens it.
 */
class SetupActivity : SecureActivity() {

    private enum class Step { CREATE_REAL, CONFIRM_REAL, CREATE_SECRET, CONFIRM_SECRET }

    private var step = Step.CREATE_REAL
    private var firstPin = ""
    private var secretPin = ""

    private lateinit var keypad: Keypad
    private lateinit var titleView: TextView
    private lateinit var subtitleView: TextView
    private lateinit var errorView: TextView
    private lateinit var primary: Button
    private lateinit var skip: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_setup)

        titleView = findViewById(R.id.setup_title)
        subtitleView = findViewById(R.id.setup_subtitle)
        errorView = findViewById(R.id.setup_error)
        primary = findViewById(R.id.setup_primary)
        skip = findViewById(R.id.setup_skip)

        keypad = Keypad(findViewById(R.id.keypad), findViewById(R.id.setup_dots))

        primary.setOnClickListener { onPrimary() }
        skip.setOnClickListener { finishSetup() }

        renderStep()
    }

    private fun renderStep() {
        errorView.visibility = View.GONE
        keypad.clear()
        when (step) {
            Step.CREATE_REAL -> {
                titleView.text = getString(R.string.setup_create_pin)
                subtitleView.text = getString(R.string.setup_subtitle)
                primary.text = getString(R.string.setup_continue)
                skip.visibility = View.GONE
            }
            Step.CONFIRM_REAL -> {
                titleView.text = getString(R.string.setup_confirm_pin)
                subtitleView.text = getString(R.string.setup_subtitle)
                primary.text = getString(R.string.setup_continue)
                skip.visibility = View.GONE
            }
            Step.CREATE_SECRET -> {
                titleView.text = getString(R.string.setup_secret_title)
                subtitleView.text = getString(R.string.setup_secret_subtitle)
                primary.text = getString(R.string.setup_continue)
                skip.visibility = View.VISIBLE
            }
            Step.CONFIRM_SECRET -> {
                titleView.text = getString(R.string.setup_confirm_pin)
                subtitleView.text = getString(R.string.setup_secret_subtitle)
                primary.text = getString(R.string.setup_finish)
                skip.visibility = View.GONE
            }
        }
    }

    private fun showError(msg: String) {
        errorView.text = msg
        errorView.visibility = View.VISIBLE
        keypad.clear()
    }

    private fun onPrimary() {
        val pin = keypad.pin()
        when (step) {
            Step.CREATE_REAL -> {
                if (pin.length < 4) {
                    showError(getString(R.string.pin_too_short))
                    return
                }
                firstPin = pin
                step = Step.CONFIRM_REAL
                renderStep()
            }
            Step.CONFIRM_REAL -> {
                if (pin == firstPin) {
                    VaultStore.createProfile(VaultStore.Profile.REAL, firstPin)
                    step = Step.CREATE_SECRET
                    renderStep()
                } else {
                    showError(getString(R.string.pin_mismatch))
                    step = Step.CREATE_REAL
                }
            }
            Step.CREATE_SECRET -> {
                if (pin.length < 4) {
                    showError(getString(R.string.pin_too_short))
                    return
                }
                secretPin = pin
                step = Step.CONFIRM_SECRET
                renderStep()
            }
            Step.CONFIRM_SECRET -> {
                if (pin == secretPin) {
                    VaultStore.createProfile(VaultStore.Profile.SECRET, secretPin)
                    finishSetup()
                } else {
                    showError(getString(R.string.pin_mismatch))
                    step = Step.CREATE_SECRET
                }
            }
        }
    }

    private fun finishSetup() {
        // Pseudo profile only needs its salt; its "PIN" is a fixed internal value
        // and it is opened by ANY wrong PIN.
        VaultStore.createProfile(VaultStore.Profile.PSEUDO, "pseudo-decoy")
        VaultStore.markSetupDone()
        VaultStore.tryUnlock(VaultStore.Profile.REAL, firstPin)

        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
