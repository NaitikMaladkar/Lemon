package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.util.Keypad
import com.lemon.app.util.SecureActivity
import java.util.concurrent.Executors

/**
 * First-run setup: create a 4-digit PIN (and confirm it). Submits
 * automatically once all 4 digits are typed; all key derivation happens on a
 * background thread so the dots never hang.
 */
class SetupActivity : SecureActivity() {

    override fun requiresUnlockedVault(): Boolean = false

    private enum class Step { CREATE, CONFIRM }

    private var step = Step.CREATE
    private var firstPin = ""
    private var finishing = false

    private lateinit var keypad: Keypad
    private lateinit var title: TextView
    private lateinit var subtitle: TextView
    private lateinit var error: TextView
    private lateinit var busy: ProgressBar
    private val worker = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_setup)

        title = findViewById(R.id.setup_title)
        subtitle = findViewById(R.id.setup_subtitle)
        error = findViewById(R.id.setup_error)
        busy = findViewById(R.id.setup_busy)
        val dots = findViewById<LinearLayout>(R.id.setup_dots)

        keypad = Keypad(
            root = window.decorView,
            dotsContainer = dots,
            maxLen = 4,
            onComplete = { pin -> onPinComplete(pin) }
        )

        animateIn(
            findViewById(R.id.setup_logo),
            title,
            subtitle,
            dots,
            findViewById(R.id.keypad)
        )
    }

    private fun onPinComplete(pin: String) {
        if (finishing) return
        when (step) {
            Step.CREATE -> {
                firstPin = pin
                keypad.clear()
                showError(0)
                step = Step.CONFIRM
                swapTitle(R.string.setup_confirm_pin)
                subtitle.setText(R.string.setup_confirm_subtitle)
            }
            Step.CONFIRM -> {
                if (pin == firstPin) {
                    finishSetup(pin)
                } else {
                    showError(R.string.pin_mismatch)
                    keypad.shake()
                    keypad.clear()
                    step = Step.CREATE
                    swapTitle(R.string.setup_create_pin)
                    subtitle.setText(R.string.setup_subtitle)
                }
            }
        }
    }

    private fun swapTitle(resId: Int) {
        title.animate().alpha(0f).translationY(-8f).setDuration(90).withEndAction {
            title.setText(resId)
            title.translationY = 8f
            title.animate().alpha(1f).translationY(0f).setDuration(150).start()
        }.start()
        subtitle.animate().alpha(0f).setDuration(90).withEndAction {
            subtitle.animate().alpha(1f).setDuration(150).start()
        }.start()
    }

    private fun finishSetup(pin: String) {
        finishing = true
        keypad.setEnabled(false)
        busy.visibility = View.VISIBLE
        busy.alpha = 0f
        busy.animate().alpha(1f).setDuration(140).start()

        worker.execute {
            val ok = try {
                VaultStore.createProfile(VaultStore.Profile.REAL, pin)
                VaultStore.markSetupDone()
                VaultStore.tryUnlock(VaultStore.Profile.REAL, pin)
            } catch (t: Throwable) {
                false
            }
            runOnUiThread {
                if (isFinishing || isDestroyed) return@runOnUiThread
                if (ok && VaultStore.unlocked) {
                    openMain()
                } else {
                    finishing = false
                    keypad.setEnabled(true)
                    keypad.clear()
                    keypad.shake()
                    busy.visibility = View.INVISIBLE
                    showError(R.string.pin_could_not_open)
                    step = Step.CREATE
                    swapTitle(R.string.setup_create_pin)
                }
            }
        }
    }

    private fun openMain() {
        val root = findViewById<View>(R.id.setup_root)
        root.animate().alpha(0f).scaleX(0.97f).scaleY(0.97f).setDuration(170).withEndAction {
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
            )
            @Suppress("DEPRECATION")
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
            finish()
        }.start()
    }

    private fun showError(resId: Int) {
        if (resId == 0) {
            error.animate().alpha(0f).setDuration(120).withEndAction {
                error.visibility = View.GONE
            }.start()
        } else {
            error.setText(resId)
            error.visibility = View.VISIBLE
            error.alpha = 0f
            error.animate().alpha(1f).setDuration(160).start()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        worker.shutdownNow()
    }
}
