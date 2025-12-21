package com.example.rapiddo.rapid_do

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.example.rapiddo.rapid_do.floating.FloatingOcrService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "paddle_ocr"
        private const val FLOATING_CHANNEL = "floating_ocr"
        private const val FLOATING_EVENTS = "floating_ocr_events"
        private const val REQ_MEDIA_PROJECTION = 1001
        private const val TAG = "MainActivity"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val ACCESS_TOKEN_KEY = "flutter.access_token"
    }

    private val ocrExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val ocrHandler by lazy { PaddleOcrHandler(this) }
    private var pendingProjectionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // 预热 OCR，避免首轮识别阻塞主线程
        ocrExecutor.execute {
            try {
                ocrHandler.warmUp()
            } catch (_: Exception) {
                // 预热失败不影响主流程
            }
        }

        MethodChannel(messenger, CHANNEL)
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

        MethodChannel(messenger, FLOATING_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startFloatingOcr" -> {
                        Log.d(TAG, "startFloatingOcr invoked")
                        handleStartFloating(result)
                    }
                    "stopFloatingOcr" -> {
                        Log.d(TAG, "stopFloatingOcr invoked")
                        stopService(Intent(this, FloatingOcrService::class.java))
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(messenger, FLOATING_EVENTS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                FloatingOcrBridge.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                FloatingOcrBridge.eventSink = null
            }
        })
    }

    private fun handleStartFloating(result: MethodChannel.Result) {
        if (pendingProjectionResult != null) {
            Log.w(TAG, "startFloating: pending projection request in flight")
            result.error("BUSY", "正在申请录屏权限，请稍后重试", null)
            return
        }

        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "startFloating: overlay permission missing")
            result.error("OVERLAY_PERMISSION_REQUIRED", "需要悬浮窗权限，请先授予", null)
            return
        }

        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        if (mgr == null) {
            Log.e(TAG, "startFloating: MediaProjectionManager unavailable")
            result.error("UNAVAILABLE", "媒体投影服务不可用", null)
            return
        }

        pendingProjectionResult = result
        Log.d(TAG, "startFloating: request projection permission")
        startActivityForResult(mgr.createScreenCaptureIntent(), REQ_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQ_MEDIA_PROJECTION) {
            val pending = pendingProjectionResult
            pendingProjectionResult = null

            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d(TAG, "projection granted, starting service")
                
                // 从 SharedPreferences 获取 accessToken
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val accessToken = prefs.getString(ACCESS_TOKEN_KEY, null)
                Log.d(TAG, "accessToken from prefs: ${if (accessToken.isNullOrEmpty()) "null" else "***"}")
                
                val intent = Intent(this, FloatingOcrService::class.java).apply {
                    putExtra(FloatingOcrService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(FloatingOcrService.EXTRA_RESULT_DATA, data)
                    putExtra(FloatingOcrService.EXTRA_ACCESS_TOKEN, accessToken)
                }
                ContextCompat.startForegroundService(this, intent)
                pending?.success(true)
            } else {
                Log.w(TAG, "projection denied")
                pending?.error("PROJECTION_DENIED", "用户拒绝录屏权限", null)
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        super.onDestroy()
        ocrExecutor.shutdown()
        ocrHandler.release()
        FloatingOcrBridge.eventSink = null
    }
}
