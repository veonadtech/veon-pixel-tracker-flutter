package com.veon.veon_pixel_tracker_flutter

import android.app.Activity
import android.util.Log
import com.veonadtech.pixeltracker.PixelTracker
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CompletableFuture

class VeonPixelTrackerFlutterPlugin : FlutterPlugin, ActivityAware {

    private lateinit var activity: Activity
    private lateinit var channel: MethodChannel
    private val activityFuture = CompletableFuture<Activity>()

    private val TAG = "PixelTrackerPlugin"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        channel = MethodChannel(
            binding.binaryMessenger,
            "com.veon.veon_pixel_tracker_flutter/android_init"
        )

        channel.setMethodCallHandler { call, result ->

            if (call.method == "startPixelTracker") {

                val arguments = call.arguments as? Map<*, *>

                val baseUrl = arguments?.get("baseUrl") as? String ?: ""
                val debug = arguments?.get("debug") as? Boolean ?: false

                initializePixelTracker(baseUrl, debug)

                result.success(null)

            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityFuture.complete(activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityFuture.complete(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityFuture.complete(activity)
    }

    override fun onDetachedFromActivity() {
        activityFuture.complete(null)
    }

    /**
     * PixelTracker SDK initialization
     */
    private fun initializePixelTracker(baseUrl: String, debug: Boolean) {

        activityFuture.thenAccept {

            try {
                PixelTracker.initialize(
                    baseUrl,
                    debug
                )

                Log.d(TAG, "PixelTracker initialized successfully")

                channel.invokeMethod("pixelTrackerInitialized", "successfully")

            } catch (e: Exception) {

                Log.e(TAG, "PixelTracker initialization error: ${e.message}")

                channel.invokeMethod(
                    "pixelTrackerInitializeFailed",
                    e.message ?: "Unknown error"
                )
            }
        }
    }
}