package com.lemon.app.util

import android.graphics.drawable.GradientDrawable
import android.view.View
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import com.lemon.app.R

/**
 * Binds the shared numeric keypad (view_pin_keypad) and the PIN dots row.
 * Dots are large filled circles; [onComplete] fires automatically as soon
 * as [maxLen] digits have been typed (no confirm button needed).
 */
class Keypad(
    private val root: View,
    private val dotsContainer: LinearLayout,
    private val maxLen: Int = 4,
    private val onComplete: (String) -> Unit = {}
) {
    private val input = StringBuilder()
    private val dots = ArrayList<View>(maxLen)
    private var locked = false

    init {
        val density = root.resources.displayMetrics.density
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
            root.findViewById<View>(id).setOnClickListener { append(chars[index]) }
        }
        root.findViewById<View>(R.id.key_back).setOnClickListener { delete() }
    }

    private fun dotDrawable(filled: Boolean): GradientDrawable {
        val density = root.resources.displayMetrics.density
        return GradientDrawable().apply {
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
    }

    private fun append(c: Char) {
        if (locked || input.length >= maxLen) return
        input.append(c)
        updateDots()
        if (input.length == maxLen) {
            locked = true
            onComplete(pin())
        }
    }

    private fun delete() {
        if (locked) return
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

    private fun updateDots() {
        dots.forEachIndexed { i, dot ->
            dot.background = dotDrawable(filled = i < input.length)
        }
    }
}
