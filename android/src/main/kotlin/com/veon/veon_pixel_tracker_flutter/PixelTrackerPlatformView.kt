package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.api.PixelConfig
import com.veonadtech.pixeltracker.api.PixelEventListener
import com.veonadtech.pixeltracker.api.PixelHandle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class PixelTrackerPlatformView(
    context: Context,
    viewId: Int,
    private val pixelId: String,
    private val refreshTime: Long,
    private val pixelSize: Int,
    private val visibilityThreshold: Int,
    private val colorHex: String?,
    messenger: BinaryMessenger,
    private val onPixelCreated: (String, PixelHandle) -> Unit,
    private val onPixelDestroyed: (String) -> Unit
) : PlatformView {

    companion object {
        private const val TAG = "PixelTrackerPlatformView"
    }

    private val container = FrameLayout(context)
    private var pixelHandle: PixelHandle? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val eventChannel = EventChannel(messenger, "veon_pixel_tracker/view_events_$viewId")
    private var eventSink: EventChannel.EventSink? = null

    init {
        setupEventChannel()
        createPixel(context)
    }

    private fun setupEventChannel() {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun createPixel(context: Context) {
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

        pixelHandle = PixelTracker.attach(context, container, config)

        pixelHandle?.let { handle ->
            onPixelCreated(pixelId, handle)
            handle.setEventListener(createEventListener())
        }
    }

    private fun createEventListener(): PixelEventListener {
        return object : PixelEventListener {
            override fun onAppearance(pixelId: String, timestamp: String) {
                sendEvent(PixelEvents.APPEARANCE, timestamp)
            }

            override fun onDisappearance(pixelId: String, timestamp: String) {
                sendEvent(PixelEvents.DISAPPEARANCE, timestamp)
            }

            override fun onRefresh(pixelId: String, timestamp: String) {
                sendEvent(PixelEvents.REFRESH, timestamp)
            }

            override fun onError(pixelId: String, error: String, timestamp: String) {
                sendEvent(PixelEvents.ERROR, timestamp, error)
            }
        }
    }

    private fun sendEvent(type: String, timestamp: String, error: String? = null) {
        val sink = eventSink ?: return
        val event = mapOf("type" to type, "timestamp" to timestamp, "error" to error)
        mainHandler.post { sink.success(event) }
    }

    override fun getView(): View = container

    override fun dispose() {
        pixelHandle?.let {
            onPixelDestroyed(pixelId)
            it.destroy()
        }
        container.removeAllViews()
        pixelHandle = null
        eventChannel.setStreamHandler(null)
        eventSink = null
    }

}
