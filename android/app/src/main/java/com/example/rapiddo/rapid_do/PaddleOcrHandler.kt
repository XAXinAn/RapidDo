package com.example.rapiddo.rapid_do

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.equationl.paddleocr4android.OCR
import com.equationl.paddleocr4android.OcrConfig
import com.equationl.paddleocr4android.bean.OcrResult
import java.io.File

class PaddleOcrHandler(private val context: Context) {
    private val assetManager = context.assets
    private val cacheModelDir = File(context.cacheDir, "ocr_models")

    private val assetFiles = listOf(
        "models/cls.nb",
        "models/det.nb",
        "models/rec.nb",
        "models/ppocr_keys_v1.txt",
    )

    @Volatile
    private var ocr: OCR? = null

    @Synchronized
    @Throws(Exception::class)
    private fun ensureInited() {
        if (ocr != null) return

        val config = OcrConfig().apply {
            // 让库自行从 assets/models 复制到 cache
            modelPath = "models"
            clsModelFilename = "cls.nb"
            detModelFilename = "det.nb"
            recModelFilename = "rec.nb"
            labelPath = "models/ppocr_keys_v1.txt"
            isRunDet = true
            isRunCls = true
            isRunRec = true
            // 限制 CPU 线程数，兼顾性能与流畅度
            cpuThreadNum = Runtime.getRuntime().availableProcessors().coerceIn(1, 4)
        }

        val paddleOcr = OCR(context)
        val initOk = when (val r = paddleOcr.initModelSync(config)) {
            is Result<*> -> {
                if (r.isFailure) throw (r.exceptionOrNull() ?: IllegalStateException("initModelSync failed"))
                (r.getOrNull() as? Boolean) == true
            }
            is Boolean -> r
            else -> false
        }
        if (!initOk) throw IllegalStateException("PaddleOCR initModelSync returned false")

        ocr = paddleOcr
    }

    @Throws(Exception::class)
    fun recognize(imagePath: String): String {
        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            throw IllegalArgumentException("图片不存在: $imagePath")
        }

        ensureInited()
        val bitmap = decodeScaledBitmap(imageFile) ?: throw IllegalStateException("无法读取图片: $imagePath")

        val result: OcrResult = when (val r = ocr?.runSync(bitmap)) {
            is Result<*> -> (r.getOrNull() as? OcrResult) ?: throw (r.exceptionOrNull() ?: IllegalStateException("PaddleOCR 未初始化"))
            is OcrResult -> r
            else -> throw IllegalStateException("PaddleOCR 未初始化")
        }

        return result.simpleText.ifBlank { "" }
    }

    private fun decodeScaledBitmap(imageFile: File, maxDim: Int = 1280): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(imageFile.absolutePath, bounds)
        var sample = 1
        while (bounds.outWidth / sample > maxDim || bounds.outHeight / sample > maxDim) {
            sample *= 2
        }
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeFile(imageFile.absolutePath, opts)
    }

    fun release() {
        ocr?.releaseModel()
        ocr = null
    }

    /**
     * 预热模型，避免首次调用时阻塞 UI。
     * 调用方应在后台线程执行。
     */
    fun warmUp() {
        try {
            ensureInited()
        } catch (_: Exception) {
            // 预热失败不影响主流程，静默吞掉
        }
    }
}
