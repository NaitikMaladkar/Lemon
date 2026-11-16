package com.lemon.app.util

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import androidx.appcompat.app.AppCompatActivity
import com.lemon.app.data.VaultStore
import com.lemon.app.ui.PinActivity

/**
 * Base activity that
 *  - blocks screenshots and screen recording (FLAG_SECURE) on every screen
 *  - sends the user back to the PIN screen whenever the in-memory vault is
 *    not unlocked (e.g. Android restored the task after killing the process).
 *    Without this the UI showed an empty vault and silently dropped new saves.
 *  - provides a small shared entrance animation helper.
 */
abstract class SecureActivity : AppCompatActivity() {

    /** PinActivity / SetupActivity override this. */
    protected open fun requiresUnlockedVault(): Boolean = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onResume() {
        super.onResume()
        if (requiresUnlockedVault() && !VaultStore.unlocked) {
            startActivity(
                Intent(this, PinActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
            )
            finish()
        }
    }

    /** Fade + rise entrance used on every screen so opening never feels frozen. */
    protected fun animateIn(vararg views: View) {
        val density = resources.displayMetrics.density
        views.forEachIndexed { index, view ->
            view.alpha = 0f
            view.translationY = 18f * density
            view.animate()
                .alpha(1f)
                .translationY(0f)
                .setStartDelay(40L + index * 45L)
                .setDuration(240L)
                .setInterpolator(DecelerateInterpolator(1.6f))
                .start()
        }
    }
}
