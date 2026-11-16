package com.lemon.app.util

import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import com.lemon.app.R

/**
 * Binds the shared numeric keypad (view_pin_keypad) and the PIN dots row.
 */
class Keypad(
    private val root: View,
    private val dotsContainer: LinearLayout,
    private val maxLen: Int = 8
) {
    private val input = StringBuilder()
    private val dots = ArrayList<TextView>(maxLen)

    init {
        val density = root.resources.displayMetrics.density
        val size = (20 * density).toInt()
        val margin = (4 * density).toInt()
        for (i in 0 until maxLen) {
            val tv = TextView(root.context)
            val lp = LinearLayout.LayoutParams(size, size)
            lp.setMargins(margin, 0, margin, 0)
            tv.layoutParams = lp
            tv.text = "•"
            tv.gravity = Gravity.CENTER
            tv.textSize = 18f
            tv.visibility = View.INVISIBLE
            dotsContainer.addView(tv)
            dots.add(tv)
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

    private fun append(c: Char) {
        if (input.length < maxLen) {
            input.append(c)
            updateDots()
        }
    }

    private fun delete() {
        if (input.isNotEmpty()) {
            input.deleteCharAt(input.length - 1)
            updateDots()
        }
    }

    fun clear() {
        input.setLength(0)
        updateDots()
    }

    fun pin(): String = input.toString()

    private fun updateDots() {
        dots.forEachIndexed { i, tv ->
            tv.visibility = if (i < input.length) View.VISIBLE else View.INVISIBLE
        }
    }
}
