package com.veon.veon_pixel_tracker_flutter

import android.app.Activity
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.InitStatus
import com.veonadtech.pixeltracker.api.PixelConfig
import com.veonadtech.pixeltracker.api.PixelEventListener
import com.veonadtech.pixeltracker.api.PixelHandle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

class VeonPixelTrackerFlutterPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var binaryMessenger: BinaryMessenger? = null

    private val pixelHandles = ConcurrentHashMap<String, PixelHandle>()
    private val pixelViewFactories = ConcurrentHashMap<String, PixelTrackerViewFactory>()

    companion object {
        private const val TAG = "PixelTrackerFlutter"
        private const val METHOD_CHANNEL = "veon_pixel_tracker/sdk"
        private const val EVENT_CHANNEL = "veon_pixel_tracker/events"
        private const val VIEW_TYPE = "veon_pixel_tracker_view_default"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binaryMessenger = binding.binaryMessenger
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)

        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        registerPixelViewFactory(binding)
    }

    private fun registerPixelViewFactory(binding: FlutterPlugin.FlutterPluginBinding) {
        val factory = PixelTrackerViewFactory(binaryMessenger!!) { pixelId, handle ->
            pixelHandles[pixelId] = handle
        }
        pixelViewFactories["default"] = factory
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            factory
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // SDK-level methods
            "initialize" -> handleInitialize(call, result)
            "isInitialized" -> handleIsInitialized(result)
            "shutdown" -> handleShutdown(result)

            // PixelHandle methods
            "createPixel" -> handleCreatePixel(call, result)
            "startPixel" -> handleStartPixel(call, result)
            "stopPixel" -> handleStopPixel(call, result)
            "destroyPixel" -> handleDestroyPixel(call, result)
            "updateRefreshTime" -> handleUpdateRefreshTime(call, result)
            "setVisibilityCheckInterval" -> handleSetVisibilityCheckInterval(call, result)
            "getPixelStats" -> handleGetPixelStats(call, result)

            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val baseUrl = call.argument<String>("baseUrl") ?: ""
        val debug = call.argument<Boolean>("debug") ?: false

        if (baseUrl.isBlank()) {
            result.error("INVALID_ARGUMENT", "baseUrl cannot be empty", null)
            return
        }

        PixelTracker.initialize(baseUrl, debug) { status ->
            when (status) {
                is InitStatus.Success -> {
                    Log.d(TAG, "PixelTracker initialized: ${status.message}")
                    sendEvent("initialized", mapOf(
                        "status" to "success",
                        "message" to status.message
                    ))
                    result.success(null)
                }
                is InitStatus.Failure -> {
                    Log.e(TAG, "PixelTracker init failed: ${status.reason}")
                    sendEvent("initialized", mapOf(
                        "status" to "failure",
                        "message" to status.reason
                    ))
                    result.error("INIT_FAILED", status.reason, status.exception)
                }
            }
        }
    }

    private fun handleIsInitialized(result: Result) {
        result.success(PixelTracker.isInitialized())
    }

    private fun handleShutdown(result: Result) {
        pixelHandles.values.forEach { it.destroy() }
        pixelHandles.clear()

        PixelTracker.shutdown()
        sendEvent("shutdown", mapOf("status" to "success"))
        result.success(null)
    }

    private fun handleCreatePixel(call: MethodCall, result: Result) {
        val activity = activity ?: run {
            result.error("NO_ACTIVITY", "Activity not attached", null)
            return
        }

        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val refreshTime = call.argument<Int>("refreshTimeSeconds")?.toLong() ?: 0L
        val pixelSize = call.argument<Int>("pixelSize") ?: 1
        val visibilityThreshold = call.argument<Int>("visibilityThreshold") ?: 1
        val colorHex = call.argument<String>("color")

        // Создаем контейнер для пикселя
        val container = FrameLayout(activity)
        val layoutParams = FrameLayout.LayoutParams(
            pixelSize,
            pixelSize
        )
        container.layoutParams = layoutParams

        val parsedColor = try {
            colorHex?.let { Color.parseColor(it) }
        } catch (e: IllegalArgumentException) {
            null
        }

        val config = PixelConfig(
            pixelId = pixelId,
            refreshTimeSeconds = refreshTime,
            pixelSize = pixelSize,
            visibilityThreshold = visibilityThreshold,
            color = parsedColor
        )

        val pixelHandle = PixelTracker.attach(
            context = activity,
            container = container,
            config = config
        )

        if (pixelHandle == null) {
            result.error("ATTACH_FAILED", "Failed to attach pixel", null)
            return
        }

        pixelHandles[pixelId] = pixelHandle

        pixelHandle.setEventListener(createPixelEventListener(pixelId))

        result.success(mapOf(
            "pixelId" to pixelId,
            "viewId" to container.hashCode()
        ))
    }

    private fun handleStartPixel(call: MethodCall, result: Result) {
        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val handle = pixelHandles[pixelId]
        if (handle == null) {
            result.error("PIXEL_NOT_FOUND", "Pixel with id $pixelId not found", null)
            return
        }

        handle.start()
        result.success(null)
    }

    private fun handleStopPixel(call: MethodCall, result: Result) {
        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val handle = pixelHandles[pixelId]
        if (handle == null) {
            result.error("PIXEL_NOT_FOUND", "Pixel with id $pixelId not found", null)
            return
        }

        handle.stop()
        result.success(null)
    }

    private fun handleDestroyPixel(call: MethodCall, result: Result) {
        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val handle = pixelHandles.remove(pixelId)
        handle?.destroy()
        result.success(null)
    }

    private fun handleUpdateRefreshTime(call: MethodCall, result: Result) {
        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val seconds = call.argument<Int>("seconds")?.toLong() ?: run {
            result.error("INVALID_ARGUMENT", "seconds required", null)
            return
        }

        val handle = pixelHandles[pixelId]
        if (handle == null) {
            result.error("PIXEL_NOT_FOUND", "Pixel with id $pixelId not found", null)
            return
        }

        handle.updateRefreshTime(seconds)
        result.success(null)
    }

    private fun handleSetVisibilityCheckInterval(call: MethodCall, result: Result) {
        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val seconds = call.argument<Int>("seconds")?.toLong() ?: run {
            result.error("INVALID_ARGUMENT", "seconds required", null)
            return
        }

        val handle = pixelHandles[pixelId]
        if (handle == null) {
            result.error("PIXEL_NOT_FOUND", "Pixel with id $pixelId not found", null)
            return
        }

        handle.setVisibilityCheckInterval(seconds)
        result.success(null)
    }

    private fun handleGetPixelStats(call: MethodCall, result: Result) {
        val pixelId = call.argument<String>("pixelId") ?: run {
            result.error("INVALID_ARGUMENT", "pixelId required", null)
            return
        }

        val handle = pixelHandles[pixelId]
        if (handle == null) {
            result.error("PIXEL_NOT_FOUND", "Pixel with id $pixelId not found", null)
            return
        }

        val stats = handle.getStats()
        result.success(mapOf(
            "totalAppearances" to stats.totalAppearances.get(),
            "isCurrentlyVisible" to stats.isCurrentlyVisible,
            "refreshEnabled" to stats.refreshEnabled,
            "nextRefreshInMs" to stats.nextRefreshInMs
        ))
    }

    private fun createPixelEventListener(pixelId: String): PixelEventListener {
        return object : PixelEventListener {
            override fun onAppearance(pixelId: String, timestamp: String) {
                sendEvent("pixel_event", mapOf(
                    "pixelId" to pixelId,
                    "type" to "appearance",
                    "timestamp" to timestamp
                ))
            }

            override fun onDisappearance(pixelId: String, timestamp: String) {
                sendEvent("pixel_event", mapOf(
                    "pixelId" to pixelId,
                    "type" to "disappearance",
                    "timestamp" to timestamp
                ))
            }

            override fun onRefresh(pixelId: String, timestamp: String) {
                sendEvent("pixel_event", mapOf(
                    "pixelId" to pixelId,
                    "type" to "refresh",
                    "timestamp" to timestamp
                ))
            }

            override fun onError(pixelId: String, error: String, timestamp: String) {
                sendEvent("pixel_event", mapOf(
                    "pixelId" to pixelId,
                    "type" to "error",
                    "error" to error,
                    "timestamp" to timestamp
                ))
            }
        }
    }

    private fun sendEvent(eventType: String, data: Map<String, Any>) {
        val event = mapOf(
            "event" to eventType,
            "data" to data
        )
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(event)
        }
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)

        pixelHandles.values.forEach { it.destroy() }
        pixelHandles.clear()
        pixelViewFactories.clear()
        eventSink = null
        binaryMessenger = null
    }

}
