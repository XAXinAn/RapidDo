package com.example.rapiddo.rapid_do

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "paddle_ocr"
    }

    private val ocrExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val ocrHandler by lazy { PaddleOcrHandler(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 预热 OCR，避免首轮识别阻塞主线程
        ocrExecutor.execute {
            try {
                ocrHandler.warmUp()
            } catch (_: Exception) {
                // 预热失败不影响主流程
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "recognize" -> {
                        val imagePath: String? = call.argument("imagePath")
                        if (imagePath.isNullOrBlank()) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "imagePath is required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        ocrExecutor.execute {
                            try {
                                val text = ocrHandler.recognize(imagePath)
                                runOnUiThread { result.success(text) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error(
                                        "OCR_FAILED",
                                        e.message ?: "Unknown error",
                                        null
                                    )
                                }
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        ocrExecutor.shutdown()
        ocrHandler.release()
    }
}
