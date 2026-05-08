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
import java.util.concurrent.atomic.AtomicInteger

class VeonPixelTrackerFlutterPluginTest {

    private lateinit var plugin: VeonPixelTrackerFlutterPlugin
    private val result: MethodChannel.Result = mockk(relaxed = true)
    private val mockHandle: PixelHandle = mockk(relaxed = true)

    // Give access to the private pixelHandles map via reflection
    private fun setHandle(pixelId: String, handle: PixelHandle) {
        val field = VeonPixelTrackerFlutterPlugin::class.java
            .getDeclaredField("pixelHandles")
        field.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        val map = field.get(plugin) as java.util.concurrent.ConcurrentHashMap<String, PixelHandle>
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

    // ─── initialize ───────────────────────────────────────────────────────────

    @Test
    fun `initialize with blank baseUrl returns error`() {
        val call = MethodCall("initialize", mapOf("baseUrl" to "", "debug" to false))
        plugin.onMethodCall(call, result)

        verify { result.error("INVALID_ARGUMENT", "baseUrl empty", null) }
    }

    @Test
    fun `initialize with null baseUrl returns error`() {
        val call = MethodCall("initialize", mapOf<String, Any?>())
        plugin.onMethodCall(call, result)

        verify { result.error("INVALID_ARGUMENT", "baseUrl empty", null) }
    }

    // ─── isInitialized ────────────────────────────────────────────────────────

    @Test
    fun `isInitialized returns true when SDK is initialized`() {
        every { PixelTracker.isInitialized() } returns true
        val call = MethodCall("isInitialized", null)
        plugin.onMethodCall(call, result)

        verify { result.success(true) }
    }

    @Test
    fun `isInitialized returns false when SDK is not initialized`() {
        every { PixelTracker.isInitialized() } returns false
        val call = MethodCall("isInitialized", null)
        plugin.onMethodCall(call, result)

        verify { result.success(false) }
    }

    // ─── shutdown ─────────────────────────────────────────────────────────────

    @Test
    fun `shutdown calls PixelTracker shutdown and returns success`() {
        every { PixelTracker.shutdown() } just runs
        val call = MethodCall("shutdown", null)
        plugin.onMethodCall(call, result)

        verify { PixelTracker.shutdown() }
        verify { result.success(null) }
    }

    @Test
    fun `shutdown clears pixelHandles`() {
        setHandle("p1", mockHandle)
        every { PixelTracker.shutdown() } just runs

        plugin.onMethodCall(MethodCall("shutdown", null), result)

        val field = VeonPixelTrackerFlutterPlugin::class.java
            .getDeclaredField("pixelHandles")
        field.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        val map = field.get(plugin) as java.util.concurrent.ConcurrentHashMap<*, *>
        assert(map.isEmpty())
    }

    // ─── startPixel ───────────────────────────────────────────────────────────

    @Test
    fun `startPixel calls handle start and returns success`() {
        setHandle("pixel_1", mockHandle)
        val call = MethodCall("startPixel", mapOf("pixelId" to "pixel_1"))
        plugin.onMethodCall(call, result)

        verify { mockHandle.start() }
        verify { result.success(null) }
    }

    @Test
    fun `startPixel with missing pixelId returns error`() {
        val call = MethodCall("startPixel", mapOf<String, Any?>())
        plugin.onMethodCall(call, result)

        verify { result.error("INVALID_ARGUMENT", "pixelId required", null) }
    }

    @Test
    fun `startPixel with unknown pixelId returns PIXEL_NOT_FOUND`() {
        val call = MethodCall("startPixel", mapOf("pixelId" to "ghost_pixel"))
        plugin.onMethodCall(call, result)

        verify { result.error("PIXEL_NOT_FOUND", "Pixel not found", null) }
    }

    // ─── stopPixel ────────────────────────────────────────────────────────────

    @Test
    fun `stopPixel calls handle stop and returns success`() {
        setHandle("pixel_1", mockHandle)
        val call = MethodCall("stopPixel", mapOf("pixelId" to "pixel_1"))
        plugin.onMethodCall(call, result)

        verify { mockHandle.stop() }
        verify { result.success(null) }
    }

    @Test
    fun `stopPixel with unknown pixelId returns PIXEL_NOT_FOUND`() {
        val call = MethodCall("stopPixel", mapOf("pixelId" to "ghost"))
        plugin.onMethodCall(call, result)

        verify { result.error("PIXEL_NOT_FOUND", "Pixel not found", null) }
    }

    // ─── destroyPixel ─────────────────────────────────────────────────────────

    @Test
    fun `destroyPixel with known pixelId returns success`() {
        setHandle("pixel_1", mockHandle)
        val call = MethodCall("destroyPixel", mapOf("pixelId" to "pixel_1"))
        plugin.onMethodCall(call, result)

        verify { result.success(null) }
    }

    @Test
    fun `destroyPixel with unknown pixelId returns PIXEL_NOT_FOUND`() {
        val call = MethodCall("destroyPixel", mapOf("pixelId" to "ghost"))
        plugin.onMethodCall(call, result)

        verify { result.error("PIXEL_NOT_FOUND", "Pixel not found", null) }
    }

    // ─── updateRefreshTime ────────────────────────────────────────────────────

    @Test
    fun `updateRefreshTime calls handle with correct seconds`() {
        setHandle("pixel_1", mockHandle)
        val call = MethodCall("updateRefreshTime", mapOf("pixelId" to "pixel_1", "seconds" to 10))
        plugin.onMethodCall(call, result)

        verify { mockHandle.updateRefreshTime(10L) }
        verify { result.success(null) }
    }

    @Test
    fun `updateRefreshTime with missing pixelId returns error`() {
        val call = MethodCall("updateRefreshTime", mapOf("seconds" to 10))
        plugin.onMethodCall(call, result)

        verify { result.error("INVALID_ARGUMENT", "pixelId and seconds required", null) }
    }

    @Test
    fun `updateRefreshTime with missing seconds returns error`() {
        val call = MethodCall("updateRefreshTime", mapOf("pixelId" to "pixel_1"))
        plugin.onMethodCall(call, result)

        verify { result.error("INVALID_ARGUMENT", "pixelId and seconds required", null) }
    }

    // ─── setVisibilityCheckInterval ───────────────────────────────────────────

    @Test
    fun `setVisibilityCheckInterval calls handle with correct seconds`() {
        setHandle("pixel_1", mockHandle)
        val call = MethodCall(
            "setVisibilityCheckInterval",
            mapOf("pixelId" to "pixel_1", "seconds" to 5)
        )
        plugin.onMethodCall(call, result)

        verify { mockHandle.setVisibilityCheckInterval(5L) }
        verify { result.success(null) }
    }

    @Test
    fun `setVisibilityCheckInterval with missing params returns error`() {
        val call = MethodCall("setVisibilityCheckInterval", mapOf<String, Any?>())
        plugin.onMethodCall(call, result)

        verify { result.error("INVALID_ARGUMENT", "pixelId and seconds required", null) }
    }

    // ─── getPixelStats ────────────────────────────────────────────────────────

    @Test
    fun `getPixelStats returns correct stats map`() {
        val mockStats: PixelStats = mockk {
            every { totalAppearances } returns mockk { every { get() } returns 7 }
            every { isCurrentlyVisible } returns true
            every { refreshEnabled } returns true
            every { nextRefreshInMs } returns 3000L
        }
        every { mockHandle.getStats() } returns mockStats
        setHandle("pixel_1", mockHandle)

        val call = MethodCall("getPixelStats", mapOf("pixelId" to "pixel_1"))
        plugin.onMethodCall(call, result)

        verify {
            result.success(match { map ->
                map is Map<*, *> &&
                    map["totalAppearances"] == 7 &&
                    map["isCurrentlyVisible"] == true &&
                    map["refreshEnabled"] == true &&
                    map["nextRefreshInMs"] == 3000L
            })
        }
    }

    @Test
    fun `getPixelStats with unknown pixelId returns PIXEL_NOT_FOUND`() {
        val call = MethodCall("getPixelStats", mapOf("pixelId" to "ghost"))
        plugin.onMethodCall(call, result)

        verify { result.error("PIXEL_NOT_FOUND", "Pixel not found", null) }
    }

    // ─── unknown method ───────────────────────────────────────────────────────

    @Test
    fun `unknown method calls notImplemented`() {
        val call = MethodCall("nonExistentMethod", null)
        plugin.onMethodCall(call, result)

        verify { result.notImplemented() }
    }
}
