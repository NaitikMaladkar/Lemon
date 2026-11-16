package com.lemon.app.ui

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.widget.ImageButton
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.totp.Totp
import com.lemon.app.util.SecureActivity
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.min

/**
 * Scans otpauth://totp QR codes with CameraX + ZXing. Fully offline.
 * Only the framed square in the middle of the screen is analysed, the rest of
 * the screen is a translucent mask.
 */
class ScannerActivity : SecureActivity() {

    private lateinit var cameraExecutor: ExecutorService
    private lateinit var overlay: ScanOverlayView
    private var handled = false

    private val requestPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                startCamera()
            } else {
                Toast.makeText(this, R.string.totp_camera_permission, Toast.LENGTH_SHORT).show()
                finish()
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_scanner)

        cameraExecutor = Executors.newSingleThreadExecutor()
        overlay = findViewById(R.id.overlay)
        findViewById<ImageButton>(R.id.scanner_close).setOnClickListener { finish() }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            startCamera()
        } else {
            requestPermission.launch(Manifest.permission.CAMERA)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
    }

    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            try {
                val provider = future.get()
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(findViewById<PreviewView>(R.id.preview).surfaceProvider)
                }
                val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                analysis.setAnalyzer(cameraExecutor) { image -> analyze(image) }
                provider.unbindAll()
                provider.bindToLifecycle(
                    this, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis
                )
            } catch (e: Exception) {
                Toast.makeText(this, R.string.totp_camera_unavailable, Toast.LENGTH_SHORT).show()
                finish()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun analyze(image: ImageProxy) {
        try {
            if (handled) return
            val raw = image.toRgbBitmap()
            val rotated = rotate(raw, image.imageInfo.rotationDegrees)
            if (rotated !== raw) raw.recycle()
            val entry = decodeQr(rotated)
            rotated.recycle()
            if (entry != null) {
                handled = true
                runOnUiThread { onScanned(entry) }
            }
        } catch (e: Exception) {
            // no QR code in this frame - keep scanning
        } finally {
            image.close()
        }
    }

    /** Decode only the central square, which is exactly what the mask frames. */
    private fun decodeQr(bitmap: Bitmap): TotpEntry? {
        val side = (min(bitmap.width, bitmap.height) * 0.82f).toInt().coerceAtLeast(1)
        val cx = (bitmap.width - side) / 2
        val cy = (bitmap.height - side) / 2
        var crop = Bitmap.createBitmap(bitmap, cx, cy, side, side)
        val maxSide = 720
        if (crop.width > maxSide) {
            val scaled = Bitmap.createScaledBitmap(crop, maxSide, maxSide, false)
            if (scaled !== crop) crop.recycle()
            crop = scaled
        }

        val w = crop.width
        val h = crop.height
        val pixels = IntArray(w * h)
        crop.getPixels(pixels, 0, w, 0, 0, w, h)
        crop.recycle()

        val reader = MultiFormatReader().apply {
            setHints(
                mapOf(
                    DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
                    DecodeHintType.TRY_HARDER to true
                )
            )
        }
        val text = try {
            reader.decodeWithState(
                BinaryBitmap(HybridBinarizer(RGBLuminanceSource(w, h, pixels)))
            ).text
        } catch (e: Exception) {
            return null
        } finally {
            reader.reset()
        }
        return Totp.parseOtpAuthUri(text)
    }

    private fun onScanned(entry: TotpEntry) {
        val saved = VaultStore.addTotp(entry)
        overlay.playSuccess {
            Toast.makeText(
                this,
                if (saved) R.string.totp_added else R.string.vault_readonly,
                Toast.LENGTH_SHORT
            ).show()
            finish()
        }
    }

    /** Convert a CameraX YUV_420_888 frame to RGB, subsampling large frames. */
    private fun ImageProxy.toRgbBitmap(): Bitmap {
        val width = width
        val height = height
        val yPlane = planes[0]
        val uPlane = planes[1]
        val vPlane = planes[2]
        val yBuf = yPlane.buffer
        val uBuf = uPlane.buffer
        val vBuf = vPlane.buffer
        val yRowStride = yPlane.rowStride
        val uvRowStride = uPlane.rowStride
        val uvPixelStride = uPlane.pixelStride

        val step = if (width > 720) 2 else 1
        val outW = width / step
        val outH = height / step
        val pixels = IntArray(outW * outH)
        var index = 0
        var j = 0
        while (j < height) {
            val uvRow = (j / 2) * uvRowStride
            val yRow = j * yRowStride
            var i = 0
            while (i < width) {
                val y = yBuf.get(yRow + i).toInt() and 0xFF
                val uvIndex = uvRow + (i / 2) * uvPixelStride
                val u = uBuf.get(uvIndex).toInt() and 0xFF
                val v = vBuf.get(uvIndex).toInt() and 0xFF
                val r = (y + 1.402 * (v - 128)).toInt().coerceIn(0, 255)
                val g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
                    .toInt().coerceIn(0, 255)
                val b = (y + 1.772 * (u - 128)).toInt().coerceIn(0, 255)
                pixels[index++] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
                i += step
            }
            j += step
        }
        val bitmap = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
        bitmap.setPixels(pixels, 0, outW, 0, 0, outW, outH)
        return bitmap
    }

    private fun rotate(bitmap: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bitmap
        val matrix = Matrix()
        matrix.postRotate(degrees.toFloat())
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, false)
    }
}
