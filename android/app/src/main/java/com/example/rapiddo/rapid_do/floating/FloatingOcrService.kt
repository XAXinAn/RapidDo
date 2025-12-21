package com.example.rapiddo.rapid_do.floating

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.example.rapiddo.rapid_do.FloatingOcrBridge
import com.example.rapiddo.rapid_do.MainActivity
import com.example.rapiddo.rapid_do.PaddleOcrHandler
import android.util.Log

/**
 * 前台悬浮窗服务：点击悬浮球 -> 申请 MediaProjection 截屏 -> OCR -> 在悬浮弹窗中显示AI结果。
 */
class FloatingOcrService : Service() {

    companion object {
        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_DATA = "extra_result_data"
        const val EXTRA_ACCESS_TOKEN = "extra_access_token"
        const val EXTRA_SESSION_ID = "extra_session_id"
        private const val NOTIFICATION_CHANNEL_ID = "floating_ocr_channel"
        private const val NOTIFICATION_ID = 1001
        private const val TAG = "FloatingOcrService"
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private lateinit var ocrHandler: PaddleOcrHandler
    private var resultDialog: FloatingResultDialog? = null
    private var accessToken: String? = null
    private var sessionId: String? = null
    @Volatile
    private var isCapturing: Boolean = false
    private val captureScale = 0.5f
    @Volatile
    private var warmUpDone = false
    @Volatile
    private var lastCaptureStart = 0L

    override fun onCreate() {
        super.onCreate()
        ocrHandler = PaddleOcrHandler(this)
        handlerThread = HandlerThread("FloatingOcrCapture").apply { start() }
        handler = handlerThread?.looper?.let { Handler(it) }
        windowManager = getSystemService(WINDOW_SERVICE) as? WindowManager
        windowManager?.let { resultDialog = FloatingResultDialog(this, it) }

        // 预热一次，触发模型和 OpenCL 等加载，降低首帧时延。
        Thread {
            try {
                val dummy = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
                ocrHandler.recognize(dummy)
                dummy.recycle()
                warmUpDone = true
            } catch (_: Exception) {
                // 预热失败不影响正常流程
            }
        }.start()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
        val resultData: Intent? = intent?.getParcelableExtra(EXTRA_RESULT_DATA)
        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager

        // 保存访问令牌和会话ID
        accessToken = intent?.getStringExtra(EXTRA_ACCESS_TOKEN)
        sessionId = intent?.getStringExtra(EXTRA_SESSION_ID)

        if (resultCode != Activity.RESULT_OK || resultData == null || mgr == null) {
            FloatingOcrBridge.emit("error", message = "录屏权限无效，无法启动悬浮截屏")
            stopSelf()
            return START_NOT_STICKY
        }

        // 必须先进入前台并声明 mediaProjection 类型，避免 SecurityException。
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }

        mediaProjection?.stop()
        mediaProjection = mgr.getMediaProjection(resultCode, resultData)
        attachOverlayIfNeeded()
        Toast.makeText(applicationContext, "悬浮截屏已就绪", Toast.LENGTH_SHORT).show()
        FloatingOcrBridge.emit("ready")
        return START_STICKY
    }

    override fun onBind(intent: Intent?) = null

    override fun onDestroy() {
        super.onDestroy()
        tearDownCapture()
        removeOverlay()
        resultDialog?.destroy()
        handlerThread?.quitSafely()
    }

    private fun buildNotification(): Notification {
        val channelName = "悬浮截屏"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            this,
            1001,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconRes = if (applicationInfo.icon != 0) applicationInfo.icon else android.R.drawable.ic_menu_camera

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle("截屏待命")
            .setContentText("点击悬浮球以截屏并添加日程")
            .setContentIntent(pending)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun attachOverlayIfNeeded() {
        if (overlayView != null || windowManager == null) return

        val bubble = ImageButton(applicationContext).apply {
            setImageResource(android.R.drawable.ic_menu_camera)
            val bg = GradientDrawable().apply {
                cornerRadius = 48f
                setColor(0x66000000)
            }
            background = bg
            setPadding(24, 24, 24, 24)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                captureScreenOnce()
            }
        }

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val sizePx = (64 * resources.displayMetrics.density).toInt()
        val params = WindowManager.LayoutParams(
            sizePx,
            sizePx,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 48
            y = 240
        }

        windowManager?.addView(bubble, params)
        overlayView = bubble
        overlayParams = params
        enableDrag(bubble, params)
    }

    private fun removeOverlay() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (_: Exception) {
        } finally {
            overlayView = null
        }
    }

    private fun captureScreenOnce() {
        if (isCapturing) {
            return
        }
        val mp = mediaProjection
        val h = this.handler
        if (mp == null || h == null) {
            FloatingOcrBridge.emit("error", message = "录屏服务不可用，请重启悬浮窗")
            Toast.makeText(applicationContext, "悬浮窗未准备好，请重新开启", Toast.LENGTH_SHORT).show()
            Log.e(TAG, "captureScreenOnce: mediaProjection=$mp, handler=$h")
            return
        }

        isCapturing = true
        lastCaptureStart = android.os.SystemClock.uptimeMillis()
        resultDialog?.showLoading("正在截屏...")
        FloatingOcrBridge.emit("capturing")
        Toast.makeText(applicationContext, "开始截屏…", Toast.LENGTH_SHORT).show()

        // 防止异常情况下 isCapturing 一直为 true，5 秒后兜底重置。
        handler?.postDelayed({
            if (isCapturing) {
                isCapturing = false
                tearDownCapture()
            }
        }, 5000)

        val metrics = resources.displayMetrics
        val width = (metrics.widthPixels * captureScale).toInt().coerceAtLeast(1)
        val height = (metrics.heightPixels * captureScale).toInt().coerceAtLeast(1)
        val density = metrics.densityDpi

        tearDownCapture()
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mp.createVirtualDisplay(
            "floating_ocr",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            h
        )

        var frameCount = 0
        val maxSkipFrames = 2
        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            frameCount++
            
            val plane = image.planes[0]
            val buffer = plane.buffer.duplicate()
            if (buffer.remaining() >= 4) {
                val firstPixel = buffer.getInt(0)
                val alpha = (firstPixel shr 24) and 0xFF
                
                if (alpha == 0 && frameCount < maxSkipFrames) {
                    image.close()
                    return@setOnImageAvailableListener
                }
            }
            
            handleImage(image, width, height)
        }, h)
    }

    private fun enableDrag(view: View, params: WindowManager.LayoutParams) {
        var downX = 0f
        var downY = 0f
        var startRawX = 0f
        var startRawY = 0f
        val touchSlop = 12
        view.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.x
                    downY = event.y
                    startRawX = event.rawX
                    startRawY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val wm = windowManager ?: return@setOnTouchListener false
                    val newX = (event.rawX - downX).toInt()
                    val newY = (event.rawY - downY).toInt()
                    params.x = newX
                    params.y = newY
                    wm.updateViewLayout(view, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val dx = (event.rawX - startRawX).toInt()
                    val dy = (event.rawY - startRawY).toInt()
                    if (kotlin.math.abs(dx) < touchSlop && kotlin.math.abs(dy) < touchSlop) {
                        captureScreenOnce()
                        view.performClick()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun handleImage(image: Image, width: Int, height: Int) {
        // 先转换bitmap（这个很快），然后关闭image释放资源
        val bitmap: android.graphics.Bitmap
        val tCaptureEnd: Long
        try {
            bitmap = imageToBitmap(image, width, height)
            tCaptureEnd = android.os.SystemClock.uptimeMillis()
        } catch (e: Exception) {
            Log.e(TAG, "handleImage bitmap conversion error", e)
            image.close()
            tearDownCapture()
            isCapturing = false
            return
        } finally {
            image.close()
            tearDownCapture()
        }
        
        // 立即显示"识别中..."弹窗，让用户知道正在处理
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
        mainHandler.post {
            resultDialog?.showLoading("正在识别文字...")
        }
        
        // OCR 在后台线程执行，避免阻塞UI
        Thread {
            try {
                val tPrepStart = android.os.SystemClock.uptimeMillis()
                val roi = cropRoi(bitmap)
                if (roi !== bitmap) {
                    bitmap.recycle()
                }
                val scaled = scaleBitmapIfNeeded(roi)
                if (scaled !== roi) {
                    roi.recycle()
                }
                val tPrepEnd = android.os.SystemClock.uptimeMillis()
                val text = ocrHandler.recognize(scaled)
                val tOcrEnd = android.os.SystemClock.uptimeMillis()
                Log.i(
                    TAG,
                    "perf: capture=${tCaptureEnd - lastCaptureStart}ms, prep=${tPrepEnd - tPrepStart}ms, ocr=${tOcrEnd - tPrepEnd}ms, total=${tOcrEnd - lastCaptureStart}ms"
                )
                scaled.recycle()
                
                // 切回主线程显示结果
                mainHandler.post {
                    // 在悬浮弹窗中显示结果并调用AI
                    resultDialog?.show(text, accessToken, sessionId, lastCaptureStart)
                    Log.i(TAG, "perf: ai_trigger=${android.os.SystemClock.uptimeMillis() - lastCaptureStart}ms")
                    FloatingOcrBridge.emit("success", text = text)
                    isCapturing = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "handleImage OCR error", e)
                bitmap.recycle()
                mainHandler.post {
                    resultDialog?.show("截屏识别失败: ${e.message}", null, null)
                    FloatingOcrBridge.emit("error", message = e.message ?: "截屏识别失败")
                    isCapturing = false
                }
            }
        }.start()
    }

    private fun scaleBitmapIfNeeded(src: Bitmap): Bitmap {
        val maxSide = maxOf(src.width, src.height)
        val targetMaxSide = 900
        if (maxSide <= targetMaxSide) return src
        val scale = targetMaxSide.toFloat() / maxSide
        val targetWidth = (src.width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (src.height * scale).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(src, targetWidth, targetHeight, true)
    }

    private fun cropRoi(src: Bitmap): Bitmap {
        // 粗裁掉状态栏/导航栏/底部输入区，保留中部区域
        val cutTop = (src.height * 0.15f).toInt()
        val cutBottom = (src.height * 0.18f).toInt()
        val top = cutTop.coerceAtLeast(0)
        val height = (src.height - top - cutBottom).coerceAtLeast(src.height / 2)
        return if (height <= 0 || top + height > src.height) src
        else Bitmap.createBitmap(src, 0, top, src.width, height)
    }

    private fun tearDownCapture() {
        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        } finally {
            virtualDisplay = null
        }

        try {
            imageReader?.close()
        } catch (_: Exception) {
        } finally {
            imageReader = null
        }
    }

    private fun imageToBitmap(image: Image, width: Int, height: Int): Bitmap {
        val plane = image.planes[0]
        val buffer = plane.buffer
        val pixelStride = plane.pixelStride
        val rowStride = plane.rowStride
        val rowPadding = rowStride - pixelStride * width
        val temp = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888
        )
        temp.copyPixelsFromBuffer(buffer)
        val cropped = Bitmap.createBitmap(temp, 0, 0, width, height)
        temp.recycle()
        return cropped
    }

}
