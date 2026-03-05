package com.veon.veon_pixel_tracker_flutter

import android.app.Activity
import android.util.Log
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.InitStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class VeonPixelTrackerFlutterPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null

    companion object {
        private const val TAG = "PixelTrackerFlutter"
        private const val METHOD_CHANNEL = "veon_pixel_tracker/sdk"
        private const val EVENT_CHANNEL = "veon_pixel_tracker/events"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        methodChannel =
            MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)

        eventChannel =
            EventChannel(binding.binaryMessenger, EVENT_CHANNEL)

        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(
                arguments: Any?,
                events: EventChannel.EventSink?
            ) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {

        when (call.method) {

            "initialize" -> {

                val baseUrl = call.argument<String>("baseUrl") ?: ""
                val debug = call.argument<Boolean>("debug") ?: false

                initializePixelTracker(baseUrl, debug)

                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun initializePixelTracker(baseUrl: String, debug: Boolean) {

        PixelTracker.initialize(baseUrl, debug) { status ->

            when (status) {

                is InitStatus.Success -> {

                    Log.d(TAG, "PixelTracker initialized")

                    eventSink?.success(
                        mapOf(
                            "event" to "initialized",
                            "status" to "success",
                            "message" to status.message
                        )
                    )
                }

                is InitStatus.Failure -> {

                    Log.e(TAG, "PixelTracker init failed")

                    eventSink?.success(
                        mapOf(
                            "event" to "initialized",
                            "status" to "failure",
                            "message" to status.reason
                        )
                    )
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

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
}