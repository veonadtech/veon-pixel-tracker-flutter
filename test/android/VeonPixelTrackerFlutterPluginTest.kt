package com.veon.veon_pixel_tracker_flutter

import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.api.PixelHandle
import com.veonadtech.pixeltracker.api.PixelStats
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.*
import org.junit.After
import org.junit.Before
import org.junit.Test

class VeonPixelTrackerFlutterPluginTest {

    private lateinit var plugin: VeonPixelTrackerFlutterPlugin

    private val result: MethodChannel.Result = mockk(relaxed = true)
    private val mockHandle: PixelHandle = mockk(relaxed = true)

    private fun setHandle(pixelId: String, handle: PixelHandle) {
        val field = VeonPixelTrackerFlutterPlugin::class.java
            .getDeclaredField("pixelHandles")

        field.isAccessible = true

        @Suppress("UNCHECKED_CAST")
        val map =
            field.get(plugin) as java.util.concurrent.ConcurrentHashMap<String, PixelHandle>

        map[pixelId] = handle
    }

    @Before
    fun setUp() {
        plugin = VeonPixelTrackerFlutterPlugin()
        mockkObject(PixelTracker)
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun `initialize with blank baseUrl returns error`() {
        val call = MethodCall(
            "initialize",
            mapOf(
                "baseUrl" to "",
                "debug" to false,
            )
        )

        plugin.onMethodCall(call, result)

        verify {
            result.error(
                "INVALID_ARGUMENT",
                "baseUrl empty",
                null
            )
        }
    }

    @Test
    fun `initialize with null baseUrl returns error`() {
        val call = MethodCall(
            "initialize",
            mapOf<String, Any?>()
        )

        plugin.onMethodCall(call, result)

        verify {
            result.error(
                "INVALID_ARGUMENT",
                "baseUrl empty",
                null
            )
        }
    }

    @Test
    fun `isInitialized returns true when SDK initialized`() {
        every { PixelTracker.isInitialized() } returns true

        plugin.onMethodCall(
            MethodCall("isInitialized", null),
            result
        )

        verify {
            result.success(true)
        }
    }

    @Test
    fun `isInitialized returns false when SDK not initialized`() {
        every { PixelTracker.isInitialized() } returns false

        plugin.onMethodCall(
            MethodCall("isInitialized", null),
            result
        )

        verify {
            result.success(false)
        }
    }

    @Test
    fun `shutdown calls PixelTracker shutdown`() {
        every { PixelTracker.shutdown() } just runs

        plugin.onMethodCall(
            MethodCall("shutdown", null),
            result
        )

        verify {
            PixelTracker.shutdown()
        }

        verify {
            result.success(null)
        }
    }

    @Test
    fun `shutdown clears pixel handles`() {
        setHandle("pixel_1", mockHandle)

        every { PixelTracker.shutdown() } just runs

        plugin.onMethodCall(
            MethodCall("shutdown", null),
            result
        )

        val field = VeonPixelTrackerFlutterPlugin::class.java
            .getDeclaredField("pixelHandles")

        field.isAccessible = true

        @Suppress("UNCHECKED_CAST")
        val map =
            field.get(plugin) as java.util.concurrent.ConcurrentHashMap<String, PixelHandle>

        assert(map.isEmpty())
    }

    @Test
    fun `startPixel calls handle start`() {
        setHandle("pixel_1", mockHandle)

        plugin.onMethodCall(
            MethodCall(
                "startPixel",
                mapOf("pixelId" to "pixel_1")
            ),
            result
        )

        verify {
            mockHandle.start()
        }

        verify {
            result.success(null)
        }
    }

    @Test
    fun `startPixel with missing pixelId returns error`() {
        plugin.onMethodCall(
            MethodCall(
                "startPixel",
                mapOf<String, Any?>()
            ),
            result
        )

        verify {
            result.error(
                "INVALID_ARGUMENT",
                "pixelId required",
                null
            )
        }
    }

    @Test
    fun `startPixel with unknown pixelId returns not found`() {
        plugin.onMethodCall(
            MethodCall(
                "startPixel",
                mapOf("pixelId" to "ghost")
            ),
            result
        )

        verify {
            result.error(
                "PIXEL_NOT_FOUND",
                "Pixel not found",
                null
            )
        }
    }

    @Test
    fun `stopPixel calls handle stop`() {
        setHandle("pixel_1", mockHandle)

        plugin.onMethodCall(
            MethodCall(
                "stopPixel",
                mapOf("pixelId" to "pixel_1")
            ),
            result
        )

        verify {
            mockHandle.stop()
        }

        verify {
            result.success(null)
        }
    }

    @Test
    fun `stopPixel with unknown pixelId returns not found`() {
        plugin.onMethodCall(
            MethodCall(
                "stopPixel",
                mapOf("pixelId" to "ghost")
            ),
            result
        )

        verify {
            result.error(
                "PIXEL_NOT_FOUND",
                "Pixel not found",
                null
            )
        }
    }

    @Test
    fun `destroyPixel returns success for existing pixel`() {
        setHandle("pixel_1", mockHandle)

        plugin.onMethodCall(
            MethodCall(
                "destroyPixel",
                mapOf("pixelId" to "pixel_1")
            ),
            result
        )

        verify {
            result.success(null)
        }
    }

    @Test
    fun `destroyPixel with unknown pixelId returns not found`() {
        plugin.onMethodCall(
            MethodCall(
                "destroyPixel",
                mapOf("pixelId" to "ghost")
            ),
            result
        )

        verify {
            result.error(
                "PIXEL_NOT_FOUND",
                "Pixel not found",
                null
            )
        }
    }

    @Test
    fun `updateRefreshTime calls handle update`() {
        setHandle("pixel_1", mockHandle)

        plugin.onMethodCall(
            MethodCall(
                "updateRefreshTime",
                mapOf(
                    "pixelId" to "pixel_1",
                    "seconds" to 10,
                )
            ),
            result
        )

        verify {
            mockHandle.updateRefreshTime(10L)
        }

        verify {
            result.success(null)
        }
    }

    @Test
    fun `updateRefreshTime with missing params returns error`() {
        plugin.onMethodCall(
            MethodCall(
                "updateRefreshTime",
                mapOf<String, Any?>()
            ),
            result
        )

        verify {
            result.error(
                "INVALID_ARGUMENT",
                "pixelId and seconds required",
                null
            )
        }
    }

    @Test
    fun `setVisibilityCheckInterval calls handle update`() {
        setHandle("pixel_1", mockHandle)

        plugin.onMethodCall(
            MethodCall(
                "setVisibilityCheckInterval",
                mapOf(
                    "pixelId" to "pixel_1",
                    "seconds" to 5,
                )
            ),
            result
        )

        verify {
            mockHandle.setVisibilityCheckInterval(5L)
        }

        verify {
            result.success(null)
        }
    }

    @Test
    fun `setVisibilityCheckInterval with missing params returns error`() {
        plugin.onMethodCall(
            MethodCall(
                "setVisibilityCheckInterval",
                mapOf<String, Any?>()
            ),
            result
        )

        verify {
            result.error(
                "INVALID_ARGUMENT",
                "pixelId and seconds required",
                null
            )
        }
    }

    @Test
    fun `getPixelStats returns mapped stats`() {
        val stats: PixelStats = mockk {
            every { totalAppearances } returns mockk {
                every { get() } returns 7
            }

            every { isCurrentlyVisible } returns true
            every { refreshEnabled } returns true
            every { nextRefreshInMs } returns 3000L
        }

        every { mockHandle.getStats() } returns stats

        setHandle("pixel_1", mockHandle)

        plugin.onMethodCall(
            MethodCall(
                "getPixelStats",
                mapOf("pixelId" to "pixel_1")
            ),
            result
        )

        verify {
            result.success(
                match { map ->
                    map is Map<*, *> &&
                        map["totalAppearances"] == 7 &&
                        map["isCurrentlyVisible"] == true &&
                        map["refreshEnabled"] == true &&
                        map["nextRefreshInMs"] == 3000L
                }
            )
        }
    }

    @Test
    fun `getPixelStats with unknown pixelId returns not found`() {
        plugin.onMethodCall(
            MethodCall(
                "getPixelStats",
                mapOf("pixelId" to "ghost")
            ),
            result
        )

        verify {
            result.error(
                "PIXEL_NOT_FOUND",
                "Pixel not found",
                null
            )
        }
    }

    @Test
    fun `unknown method returns notImplemented`() {
        plugin.onMethodCall(
            MethodCall("unknownMethod", null),
            result
        )

        verify {
            result.notImplemented()
        }
    }
}