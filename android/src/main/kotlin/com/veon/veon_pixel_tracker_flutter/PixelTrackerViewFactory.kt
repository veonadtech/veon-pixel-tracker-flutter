package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import com.veonadtech.pixeltracker.api.PixelHandle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

// PlatformViewFactory для создания пикселей как нативных виджетов
class PixelTrackerViewFactory(
    private val messenger: BinaryMessenger,
    private val onPixelCreated: (String, PixelHandle) -> Unit
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any> ?: emptyMap()

        val pixelId = params["pixelId"] as? String ?: "pixel_$viewId"
        val refreshTime = (params["refreshTimeSeconds"] as? Int)?.toLong() ?: 0L
        val pixelSize = params["pixelSize"] as? Int ?: 1
        val visibilityThreshold = params["visibilityThreshold"] as? Int ?: 1
        val colorHex = params["color"] as? String

        return PixelTrackerPlatformView(
            context = context,
            viewId = viewId,
            pixelId = pixelId,
            refreshTime = refreshTime,
            pixelSize = pixelSize,
            visibilityThreshold = visibilityThreshold,
            colorHex = colorHex,
            messenger = messenger,
            onPixelCreated = onPixelCreated
        )
    }
}