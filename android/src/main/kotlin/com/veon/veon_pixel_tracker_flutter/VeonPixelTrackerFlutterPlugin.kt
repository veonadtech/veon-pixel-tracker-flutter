package com.veon.veon_pixel_tracker_flutter

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.InitStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class VeonPixelTrackerFlutterPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val pixelHandles = ConcurrentHashMap<String, com.veonadtech.pixeltracker.api.PixelHandle>()

    companion object {
        private const val TAG = "PixelTrackerFlutter"
        private const val METHOD_CHANNEL = "veon_pixel_tracker/sdk"
        private const val EVENT_CHANNEL = "veon_pixel_tracker/events"
        private const val VIEW_TYPE = "veon_pixel_tracker_view_default"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
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

        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            PixelTrackerViewFactory(
                messenger = binding.binaryMessenger,
                onPixelCreated = { pixelId, handle ->
                    pixelHandles[pixelId] = handle
                    Log.d(TAG, "✅ Pixel stored: $pixelId")
                },
                onPixelDestroyed = { pixelId ->
                    pixelHandles.remove(pixelId)
                    Log.d(TAG, "🗑️ Pixel removed: $pixelId")
                }
            )
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "initialize" -> {
                val baseUrl = call.argument<String>("baseUrl") ?: ""
                val debug = call.argument<Boolean>("debug") ?: false

                if (baseUrl.isBlank()) {
                    result.error("INVALID_ARGUMENT", "baseUrl empty", null)
                    return
                }

                PixelTracker.initialize(baseUrl, debug) { status ->
                    when (status) {
                        is InitStatus.Success -> {
                            sendEvent("initialized", mapOf("status" to "success"))
                            result.success(null)
                        }
                        is InitStatus.Failure -> {
                            sendEvent("initialized", mapOf("status" to "failure"))
                            result.error("INIT_FAILED", status.reason, null)
                        }
                    }
                }
            }

            "isInitialized" -> {
                result.success(PixelTracker.isInitialized())
            }

            "shutdown" -> {
                pixelHandles.clear()
                PixelTracker.shutdown()
                sendEvent("shutdown", emptyMap())
                result.success(null)
            }

            "startPixel" -> {
                val pixelId = call.argument<String>("pixelId")
                    ?: return result.error("INVALID_ARGUMENT", "pixelId required", null)

                val handle = pixelHandles[pixelId]
                    ?: return result.error("PIXEL_NOT_FOUND", "Pixel not found", null)

                handle.start()
                result.success(null)
            }

            "stopPixel" -> {
                val pixelId = call.argument<String>("pixelId")
                    ?: return result.error("INVALID_ARGUMENT", "pixelId required", null)

                val handle = pixelHandles[pixelId]
                    ?: return result.error("PIXEL_NOT_FOUND", "Pixel not found", null)

                handle.stop()
                result.success(null)
            }

            "destroyPixel" -> {
                val pixelId = call.argument<String>("pixelId")
                    ?: return result.error("INVALID_ARGUMENT", "pixelId required", null)

                if (!pixelHandles.containsKey(pixelId)) {
                    return result.error("PIXEL_NOT_FOUND", "Pixel not found", null)
                }

                Log.d(TAG, "⚠️ destroyPixel ignored (handled by PlatformView)")
                result.success(null)
            }

            "updateRefreshTime" -> {
                val pixelId = call.argument<String>("pixelId")
                val seconds = call.argument<Int>("seconds")?.toLong()

                if (pixelId == null || seconds == null) {
                    result.error("INVALID_ARGUMENT", "pixelId and seconds required", null)
                    return
                }

                val handle = pixelHandles[pixelId]
                    ?: return result.error("PIXEL_NOT_FOUND", "Pixel not found", null)

                handle.updateRefreshTime(seconds)
                result.success(null)
            }

            "setVisibilityCheckInterval" -> {
                val pixelId = call.argument<String>("pixelId")
                val seconds = call.argument<Int>("seconds")?.toLong()

                if (pixelId == null || seconds == null) {
                    result.error("INVALID_ARGUMENT", "pixelId and seconds required", null)
                    return
                }

                val handle = pixelHandles[pixelId]
                    ?: return result.error("PIXEL_NOT_FOUND", "Pixel not found", null)

                handle.setVisibilityCheckInterval(seconds)
                result.success(null)
            }

            "getPixelStats" -> {
                val pixelId = call.argument<String>("pixelId")
                    ?: return result.error("INVALID_ARGUMENT", "pixelId required", null)

                val handle = pixelHandles[pixelId]
                    ?: return result.error("PIXEL_NOT_FOUND", "Pixel not found", null)

                val stats = handle.getStats()

                result.success(mapOf(
                    "totalAppearances" to stats.totalAppearances.get(),
                    "isCurrentlyVisible" to stats.isCurrentlyVisible,
                    "refreshEnabled" to stats.refreshEnabled,
                    "nextRefreshInMs" to stats.nextRefreshInMs
                ))
            }

            else -> result.notImplemented()
        }
    }

    private fun sendEvent(type: String, data: Map<String, Any>) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(mapOf("event" to type, "data" to data))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        pixelHandles.clear()
        eventSink = null
    }

}
