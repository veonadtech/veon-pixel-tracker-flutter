package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import com.veonadtech.pixeltracker.api.PixelHandle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PixelTrackerViewFactory(
    private val messenger: BinaryMessenger,
    private val onPixelCreated: (String, PixelHandle) -> Unit,
    private val onPixelDestroyed: (String) -> Unit
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *> ?: emptyMap<String, Any>()

        return PixelTrackerPlatformView(
            context = context,
            viewId = viewId,
            pixelId = params["pixelId"] as? String ?: "pixel_$viewId",
            refreshTime = (params["refreshTimeSeconds"] as? Int)?.toLong() ?: 0L,
            pixelSize = params["pixelSize"] as? Int ?: 1,
            visibilityThreshold = params["visibilityThreshold"] as? Int ?: 1,
            colorHex = params["color"] as? String,
            messenger = messenger,
            onPixelCreated = onPixelCreated,
            onPixelDestroyed = onPixelDestroyed
        )
    }

}
