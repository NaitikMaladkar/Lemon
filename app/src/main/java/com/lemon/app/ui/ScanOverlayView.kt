package com.lemon.app.ui

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.os.SystemClock
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import com.lemon.app.R
import kotlin.math.abs
import kotlin.math.min

/**
 * Scanner mask: everything except a small square window is covered by a
 * translucent theme-coloured scrim, the window itself shows a light grid, and
 * lemon coloured brackets frame it. A soft scan line sweeps up and down.
 */
class ScanOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    private val density = resources.displayMetrics.density

    private val scrimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#E616150E") // translucent theme colour
    }
    private val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 0.8f * density
        color = Color.parseColor("#33FFFDE7")
    }
    private val bracketPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3.2f * density
        strokeCap = Paint.Cap.ROUND
        color = ContextCompat.getColor(context, R.color.lemon_yellow)
    }
    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        strokeWidth = 2f * density
        strokeCap = Paint.Cap.ROUND
        color = ContextCompat.getColor(context, R.color.lemon_yellow)
    }
    private val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val holePath = Path()
    private val window = RectF()
    private val radius = 20f * density

    private var success = false
    private var glow = 0f
    private var successAnim: ValueAnimator? = null

    /** Square (in view coordinates) that is actually being scanned. */
    fun windowRect(): RectF = RectF(window)

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        val side = min(w, h) * 0.64f
        val left = (w - side) / 2f
        val top = (h - side) / 2f
        window.set(left, top, left + side, top + side)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (window.isEmpty) return

        val w = width.toFloat()
        val h = height.toFloat()

        // translucent scrim with a clear rounded hole
        holePath.reset()
        holePath.fillType = Path.FillType.EVEN_ODD
        holePath.addRect(0f, 0f, w, h, Path.Direction.CW)
        holePath.addRoundRect(window, radius, radius, Path.Direction.CW)
        canvas.drawPath(holePath, scrimPaint)

        // light grid inside the window
        val cols = 3
        val rows = 3
        for (i in 1 until cols) {
            val x = window.left + window.width() * i / cols
            canvas.drawLine(x, window.top + 8f * density, x, window.bottom - 8f * density, gridPaint)
        }
        for (i in 1 until rows) {
            val y = window.top + window.height() * i / rows
            canvas.drawLine(window.left + 8f * density, y, window.right - 8f * density, y, gridPaint)
        }

        // lemon corner brackets
        val len = 30f * density
        val off = 2f * density
        val l = window.left - off
        val t = window.top - off
        val r = window.right + off
        val b = window.bottom + off
        canvas.drawLine(l, t, l + len, t, bracketPaint)
        canvas.drawLine(l, t, l, t + len, bracketPaint)
        canvas.drawLine(r, t, r - len, t, bracketPaint)
        canvas.drawLine(r, t, r, t + len, bracketPaint)
        canvas.drawLine(l, b, l + len, b, bracketPaint)
        canvas.drawLine(l, b, l, b - len, bracketPaint)
        canvas.drawLine(r, b, r - len, b, bracketPaint)
        canvas.drawLine(r, b, r, b - len, bracketPaint)

        if (success && glow > 0f) {
            bracketPaint.alpha = (255 * glow).toInt().coerceIn(0, 255)
            holePath.reset()
            holePath.addRoundRect(
                RectF(window).apply { inset(-off, -off) },
                radius + off, radius + off, Path.Direction.CW
            )
            canvas.drawPath(holePath, Paint(bracketPaint).apply {
                style = Paint.Style.STROKE
                strokeWidth = 5f * density
            })
            bracketPaint.alpha = 255
        }

        // sweeping scan line
        if (!success) {
            val period = 2400f
            val t = (SystemClock.uptimeMillis() % period.toLong()) / period
            val y = window.top + window.height() * abs(1f - 2f * t)
            glowPaint.shader = LinearGradient(
                0f, y - 26f * density, 0f, y,
                intArrayOf(Color.TRANSPARENT, Color.parseColor("#66FDD835")),
                floatArrayOf(0f, 1f), Shader.TileMode.CLAMP
            )
            canvas.drawRect(window.left, y - 26f * density, window.right, y, glowPaint)
            canvas.drawLine(window.left + 10f * density, y, window.right - 10f * density, y, linePaint)
            postInvalidateOnAnimation()
        }
    }

    /** Green flash of the window, then [onEnd]. */
    fun playSuccess(onEnd: () -> Unit) {
        success = true
        bracketPaint.color = ContextCompat.getColor(context, R.color.leaf_green)
        linePaint.color = ContextCompat.getColor(context, R.color.leaf_green)
        performHapticFeedback(android.view.HapticFeedbackConstants.CONFIRM)
        successAnim?.cancel()
        successAnim = ValueAnimator.ofFloat(1f, 0.15f).apply {
            duration = 320
            addUpdateListener {
                glow = it.animatedValue as Float
                invalidate()
            }
            doOnEnd { onEnd() }
            start()
        }
    }

    private fun ValueAnimator.doOnEnd(action: () -> Unit) {
        addListener(object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) = action()
        })
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        successAnim?.cancel()
        successAnim = null
    }
}
