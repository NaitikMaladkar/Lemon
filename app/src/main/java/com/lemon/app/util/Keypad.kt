package com.lemon.app.util

import android.animation.ObjectAnimator
import android.graphics.drawable.GradientDrawable
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.animation.LinearInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import com.lemon.app.R

/**
 * Binds the shared numeric keypad (view_pin_keypad) and the PIN dots row.
 *
 * Every interaction is animated: dots pop in when filled, keys dip on press,
 * and [shake] gives a springy "wrong PIN" wobble instead of a hard freeze.
 * [onComplete] fires automatically once [maxLen] digits are typed.
 */
class Keypad(
    private val root: View,
    private val dotsContainer: LinearLayout,
    private val maxLen: Int = 4,
    private val onComplete: (String) -> Unit = {}
) {
    private val input = StringBuilder()
    private val dots = ArrayList<View>(maxLen)
    private val density = root.resources.displayMetrics.density
    private var locked = false
    private var enabled = true
    private var filledCount = 0

    init {
        val size = (26 * density).toInt()
        val margin = (8 * density).toInt()
        for (i in 0 until maxLen) {
            val dot = View(root.context)
            val lp = LinearLayout.LayoutParams(size, size)
            lp.setMargins(margin, 0, margin, 0)
            dot.layoutParams = lp
            dot.background = dotDrawable(filled = false)
            dotsContainer.addView(dot)
            dots.add(dot)
        }

        val ids = intArrayOf(
            R.id.key_1, R.id.key_2, R.id.key_3,
            R.id.key_4, R.id.key_5, R.id.key_6,
            R.id.key_7, R.id.key_8, R.id.key_9, R.id.key_0
        )
        val chars = charArrayOf('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
        ids.forEachIndexed { index, id ->
            val key = root.findViewById<View>(id)
            key.setOnClickListener { append(chars[index]) }
            pressAnimation(key)
        }
        val back = root.findViewById<View>(R.id.key_back)
        back.setOnClickListener { delete() }
        pressAnimation(back)
    }

    private fun pressAnimation(view: View) {
        view.setOnTouchListener { v, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN ->
                    v.animate().scaleX(0.9f).scaleY(0.9f).setDuration(70).start()
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL ->
                    v.animate().scaleX(1f).scaleY(1f).setDuration(140)
                        .setInterpolator(OvershootInterpolator(2f)).start()
            }
            false // never consume - normal click still happens
        }
    }

    private fun dotDrawable(filled: Boolean): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        if (filled) {
            setColor(ContextCompat.getColor(root.context, R.color.lemon_deep))
        } else {
            setColor(0x00000000)
            setStroke(
                (2 * density).toInt(),
                ContextCompat.getColor(root.context, R.color.ink_soft)
            )
        }
    }

    private fun append(c: Char) {
        if (!enabled || locked || input.length >= maxLen) return
        root.findViewById<View>(R.id.pin_dots)?.performHapticFeedback(
            HapticFeedbackConstants.KEYBOARD_TAP
        )
        input.append(c)
        updateDots()
        if (input.length == maxLen) {
            locked = true
            onComplete(pin())
        }
    }

    private fun delete() {
        if (!enabled || locked) return
        if (input.isNotEmpty()) {
            input.deleteCharAt(input.length - 1)
            updateDots()
        }
    }

    fun clear() {
        input.setLength(0)
        locked = false
        updateDots()
    }

    fun pin(): String = input.toString()

    /** Blocks input while a PIN is being verified (keeps the dots visible). */
    fun setEnabled(value: Boolean) {
        enabled = value
    }

    /** Springy horizontal wobble, used for a wrong PIN / PIN mismatch. */
    fun shake() {
        val d = density
        val anim = ObjectAnimator.ofFloat(
            dotsContainer, "translationX",
            0f, -14f * d, 12f * d, -9f * d, 6f * d, -3f * d, 0f
        )
        anim.duration = 420
        anim.interpolator = LinearInterpolator()
        anim.start()
        dotsContainer.performHapticFeedback(HapticFeedbackConstants.REJECT)
    }

    private fun updateDots() {
        dots.forEachIndexed { i, dot ->
            val filled = i < input.length
            dot.background = dotDrawable(filled)
            if (filled && i >= filledCount) {
                dot.animate().cancel()
                dot.scaleX = 0.45f
                dot.scaleY = 0.45f
                dot.alpha = 0.5f
                dot.animate().scaleX(1f).scaleY(1f).alpha(1f)
                    .setDuration(170)
                    .setInterpolator(OvershootInterpolator(3f))
                    .start()
            } else if (!filled) {
                dot.animate().cancel()
                dot.scaleX = 1f
                dot.scaleY = 1f
                dot.alpha = 1f
            }
        }
        filledCount = input.length
    }
}
