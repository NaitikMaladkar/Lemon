package com.lemon.app.ui

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.AttributeSet
import android.util.TypedValue
import android.view.View
import android.view.animation.OvershootInterpolator
import androidx.core.content.ContextCompat
import com.lemon.app.R
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min

/**
 * A miniature lemon that counts down the current TOTP window.
 *
 * The lemon is made of citrus segments - one slice per second. The outermost
 * slice fades away during its final second and, when the window rolls over,
 * the whole lemon "regenerates" with a small pop. The remaining seconds are
 * printed in the middle so the countdown is readable at a glance.
 */
class LemonTimerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val density = resources.displayMetrics.density

    private val slicePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val rindPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1.6f * density
    }
    private val ghostPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1.2f * density
    }
    private val corePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val leafPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
        typeface = android.graphics.Typeface.DEFAULT_BOLD
    }

    private val slicePath = Path()
    private val oval = RectF()

    private val lemonYellow = ContextCompat.getColor(context, R.color.lemon_yellow)
    private val lemonDeep = ContextCompat.getColor(context, R.color.lemon_deep)
    private val lemonDark = ContextCompat.getColor(context, R.color.lemon_dark)
    private val lemonLight = ContextCompat.getColor(context, R.color.lemon_light)
    private val leafGreen = ContextCompat.getColor(context, R.color.leaf_green)
    private val onSurface = themeColor(android.R.attr.textColorPrimary, R.color.ink)

    /** TOTP window length in seconds. */
    var periodSeconds: Int = 30
        set(value) {
            field = value.coerceIn(1, 300)
            lastSeconds = -1
            invalidate()
        }

    private var popScale = 1f
    private var lastSeconds = -1
    private var popAnimator: ValueAnimator? = null

    init {
        textPaint.textSize = 11f * density
        textPaint.color = onSurface
    }

    private fun themeColor(attr: Int, fallback: Int): Int {
        val tv = TypedValue()
        return if (context.theme.resolveAttribute(attr, tv, true)) {
            if (tv.resourceId != 0) ContextCompat.getColor(context, tv.resourceId) else tv.data
        } else {
            ContextCompat.getColor(context, fallback)
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val size = (60 * density).toInt()
        setMeasuredDimension(
            resolveSize(size, widthMeasureSpec),
            resolveSize(size, heightMeasureSpec)
        )
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val periodMs = periodSeconds * 1000L
        val now = System.currentTimeMillis()
        val remainingMs = periodMs - (now % periodMs)
        val frac = (remainingMs.toFloat() / periodMs).coerceIn(0f, 1f)
        val seconds = ceil(remainingMs / 1000.0).toInt().coerceIn(1, periodSeconds)

        // window rolled over -> the lemon regrows
        if (lastSeconds != -1 && seconds > lastSeconds) pop()
        lastSeconds = seconds

        val cx = width / 2f
        val cy = height / 2f + 1.5f * density
        val r = min(width, height) / 2f - 7f * density

        canvas.save()
        canvas.scale(popScale, popScale, cx, cy)

        oval.set(cx - r, cy - r, cx + r, cy + r)

        // ghost of the finished slices
        ghostPaint.color = Color.argb(46, Color.red(lemonYellow), Color.green(lemonYellow), Color.blue(lemonYellow))
        canvas.drawCircle(cx, cy, r, ghostPaint)

        // citrus slices
        val count = min(periodSeconds, 30)
        val sweepPer = 360f / count
        val gap = if (count > 20) 1.2f else 2f
        val visible = ceil(frac * count).toInt()
        val partialRaw = frac * count - floor(frac * count)
        val partial = if (partialRaw == 0f) 1f else partialRaw

        for (i in 0 until visible) {
            val start = -90f + i * sweepPer + gap / 2f
            val sweep = sweepPer - gap
            slicePath.reset()
            slicePath.moveTo(cx, cy)
            slicePath.arcTo(oval, start, sweep, false)
            slicePath.close()

            slicePaint.color = if (i % 2 == 0) lemonYellow else lemonDeep
            val alpha = if (i == visible - 1) partial else 1f
            slicePaint.alpha = (255 * alpha).toInt().coerceIn(0, 255)
            canvas.drawPath(slicePath, slicePaint)
        }

        // rind along the remaining part
        ghostPaint.color = Color.argb(60, Color.red(lemonDark), Color.green(lemonDark), Color.blue(lemonDark))
        canvas.drawCircle(cx, cy, r, ghostPaint)
        rindPaint.color = lemonDark
        canvas.drawArc(oval, -90f, 360f * frac, false, rindPaint)

        // little leaf
        val leafX = cx + r * 0.62f
        val leafY = cy - r * 0.86f
        leafPaint.color = leafGreen
        canvas.save()
        canvas.rotate(-32f, leafX, leafY)
        canvas.drawOval(
            leafX - r * 0.26f, leafY - r * 0.13f,
            leafX + r * 0.26f, leafY + r * 0.13f,
            leafPaint
        )
        canvas.restore()

        // seconds core
        corePaint.color = lemonLight
        canvas.drawCircle(cx, cy, r * 0.36f, corePaint)
        rindPaint.color = Color.argb(90, Color.red(lemonDark), Color.green(lemonDark), Color.blue(lemonDark))
        canvas.drawCircle(cx, cy, r * 0.36f, rindPaint)
        val textY = cy - (textPaint.descent() + textPaint.ascent()) / 2f
        canvas.drawText(seconds.toString(), cx, textY, textPaint)

        canvas.restore()

        if (isShown && abs(popScale - 1f) < 0.5f) postInvalidateOnAnimation()
    }

    private fun pop() {
        popAnimator?.cancel()
        popAnimator = ValueAnimator.ofFloat(0.72f, 1f).apply {
            duration = 330
            interpolator = OvershootInterpolator(2.4f)
            addUpdateListener {
                popScale = it.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        popAnimator?.cancel()
        popAnimator = null
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        lastSeconds = -1
        popScale = 1f
        invalidate()
    }
}
