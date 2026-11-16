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
 * PIN unlock. Correct PIN opens the real vault; any wrong PIN opens the
 * pseudo decoy vault. Submits automatically once 4 digits are typed.
 *
 * The key derivation runs off the main thread, so the screen never freezes,
 * and the transition into the vault is a short fade + scale.
 */
class PinActivity : SecureActivity() {

    override fun requiresUnlockedVault(): Boolean = false

    private lateinit var keypad: Keypad
    private lateinit var error: TextView
    private lateinit var busy: ProgressBar
    private var opening = false
    private val worker = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!VaultStore.isSetupDone()) {
            startActivity(Intent(this, SetupActivity::class.java))
            finish()
            return
        }

        setContentView(R.layout.activity_pin)
        error = findViewById(R.id.pin_error)
        busy = findViewById(R.id.pin_busy)
        val dots = findViewById<LinearLayout>(R.id.pin_dots)

        keypad = Keypad(
            root = window.decorView,
            dotsContainer = dots,
            maxLen = 4,
            onComplete = { pin -> unlock(pin) }
        )

        animateIn(
            findViewById(R.id.pin_logo),
            findViewById(R.id.pin_title),
            findViewById(R.id.pin_hint),
            dots,
            findViewById(R.id.keypad)
        )
    }

    private fun unlock(pin: String) {
        if (opening) return
        opening = true
        error.visibility = View.GONE
        keypad.setEnabled(false)
        busy.visibility = View.VISIBLE
        busy.alpha = 0f
        busy.animate().alpha(1f).setDuration(140).start()

        worker.execute {
            val ok = try {
                if (VaultStore.tryUnlock(VaultStore.Profile.REAL, pin)) {
                    true
                } else {
                    VaultStore.unlockPseudo()
                }
            } catch (t: Throwable) {
                false
            }
            runOnUiThread { onVerified(ok) }
        }
    }

    private fun onVerified(ok: Boolean) {
        if (isFinishing || isDestroyed) return
        if (!ok || !VaultStore.unlocked) {
            opening = false
            keypad.setEnabled(true)
            keypad.clear()
            keypad.shake()
            busy.visibility = View.INVISIBLE
            error.setText(R.string.pin_could_not_open)
            error.visibility = View.VISIBLE
            return
        }
        if (VaultStore.readOnly) {
            Toast.makeText(this, R.string.vault_readonly, Toast.LENGTH_LONG).show()
        }
        openMain()
    }

    private fun openMain() {
        val root = findViewById<View>(R.id.pin_root)
        root.animate()
            .alpha(0f)
            .scaleX(0.97f)
            .scaleY(0.97f)
            .setDuration(170)
            .withEndAction {
                startActivity(
                    Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    }
                )
                @Suppress("DEPRECATION")
                overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
                finish()
            }
            .start()
    }

    override fun onDestroy() {
        super.onDestroy()
        worker.shutdownNow()
    }
}
