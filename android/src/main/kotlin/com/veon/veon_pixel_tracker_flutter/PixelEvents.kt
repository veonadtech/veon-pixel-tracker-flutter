package com.veon.veon_pixel_tracker_flutter

object PixelEvents {
    // SDK events
    const val INITIALIZED = "initialized"
    const val SHUTDOWN = "shutdown"
    const val PIXEL_EVENT = "pixel_event"

    // Pixel event types
    const val APPEARANCE = "appearance"
    const val DISAPPEARANCE = "disappearance"
    const val REFRESH = "refresh"
    const val ERROR = "error"

    // Status values
    const val SUCCESS = "success"
    const val FAILURE = "failure"
}