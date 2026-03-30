package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.FrameLayout
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.api.PixelConfig
import com.veonadtech.pixeltracker.api.PixelEventListener
import com.veonadtech.pixeltracker.api.PixelHandle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView
import java.util.HashMap

class PixelTrackerPlatformView(
    context: Context,
    viewId: Int,
    private val pixelId: String,
    private val refreshTime: Long,
    private val pixelSize: Int,
    private val visibilityThreshold: Int,
    private val colorHex: String?,
    messenger: BinaryMessenger,
    private val onPixelCreated: (String, PixelHandle) -> Unit
) : PlatformView {

    private val container: FrameLayout = FrameLayout(context)
    private var pixelHandle: PixelHandle? = null
    private val eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    init {
        eventChannel = EventChannel(messenger, "veon_pixel_tracker/view_events_$viewId")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        createAndAttachPixel(context)
    }

    private fun createAndAttachPixel(context: Context) {
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

        pixelHandle = PixelTracker.attach(
            context = context,
            container = container,
            config = config
        )

        pixelHandle?.let { handle ->
            onPixelCreated(pixelId, handle)
            handle.setEventListener(createEventListener())
        }
    }

    private fun createEventListener(): PixelEventListener {
        return object : PixelEventListener {
            override fun onAppearance(pixelId: String, timestamp: String) {
                sendEvent("appearance", timestamp)
            }

            override fun onDisappearance(pixelId: String, timestamp: String) {
                sendEvent("disappearance", timestamp)
            }

            override fun onRefresh(pixelId: String, timestamp: String) {
                sendEvent("refresh", timestamp)
            }

            override fun onError(pixelId: String, error: String, timestamp: String) {
                sendEvent("error", timestamp, error)
            }
        }
    }

    private fun sendEvent(type: String, timestamp: String, error: String? = null) {
        val map = HashMap<String, Any?>()
        map["type"] = type
        map["timestamp"] = timestamp
        map["error"] = error
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(map)
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        pixelHandle?.destroy()
        container.removeAllViews()
        pixelHandle = null
        eventChannel.setStreamHandler(null)
    }

}
