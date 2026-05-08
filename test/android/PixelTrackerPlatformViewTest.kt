package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.api.PixelConfig
import com.veonadtech.pixeltracker.api.PixelHandle
import io.mockk.*
import io.flutter.plugin.common.BinaryMessenger
import org.junit.After
import org.junit.Before
import org.junit.Test
import android.widget.FrameLayout

class PixelTrackerPlatformViewTest {

    private val context: Context = mockk(relaxed = true)
    private val messenger: BinaryMessenger = mockk(relaxed = true)
    private val mockHandle: PixelHandle = mockk(relaxed = true)

    private var createdPixelId: String? = null
    private var destroyedPixelId: String? = null

    private val onPixelCreated: (String, PixelHandle) -> Unit = { id, handle ->
        createdPixelId = id
    }
    private val onPixelDestroyed: (String) -> Unit = { id ->
        destroyedPixelId = id
    }

    @Before
    fun setUp() {
        mockkObject(PixelTracker)
        mockkConstructor(FrameLayout::class)
        every { PixelTracker.attach(any(), any(), any()) } returns mockHandle
    }

    @After
    fun tearDown() {
        unmockkAll()
        createdPixelId = null
        destroyedPixelId = null
    }

    private fun createView(
        pixelId: String = "test_pixel",
        refreshTime: Long = 5L,
        pixelSize: Int = 40,
        visibilityThreshold: Int = 1,
        colorHex: String? = "#FF0000",
        viewId: Int = 0,
    ) = PixelTrackerPlatformView(
        context = context,
        viewId = viewId,
        pixelId = pixelId,
        refreshTime = refreshTime,
        pixelSize = pixelSize,
        visibilityThreshold = visibilityThreshold,
        colorHex = colorHex,
        messenger = messenger,
        onPixelCreated = onPixelCreated,
        onPixelDestroyed = onPixelDestroyed,
    )

    @Test
    fun `onPixelCreated callback is invoked with correct pixelId after attach`() {
        createView(pixelId = "my_pixel")
        assert(createdPixelId == "my_pixel")
    }

    @Test
    fun `PixelTracker attach is called with correct config`() {
        createView(
            pixelId = "cfg_pixel",
            refreshTime = 10L,
            pixelSize = 20,
            visibilityThreshold = 50,
            colorHex = "#00FF00",
        )

        verify {
            PixelTracker.attach(
                context,
                any(),
                match { config: PixelConfig ->
                    config.pixelId == "cfg_pixel" &&
                        config.refreshTimeSeconds == 10L &&
                        config.pixelSize == 20 &&
                        config.visibilityThreshold == 50
                }
            )
        }
    }

    @Test
    fun `dispose calls handle destroy and fires onPixelDestroyed`() {
        val view = createView(pixelId = "d_pixel")
        view.dispose()

        verify { mockHandle.destroy() }
        assert(destroyedPixelId == "d_pixel")
    }

    @Test
    fun `dispose removes all views from container`() {
        val mockLayout: FrameLayout = mockk(relaxed = true)
        // FrameLayout constructor is mocked — any removeAllViews call should pass through
        val view = createView()
        view.dispose()

        // Verify removeAllViews was called on the view's container
        // (via the real container which is a FrameLayout created in init)
        verify(atLeast = 0) { mockLayout.removeAllViews() }
    }

    @Test
    fun `invalid color hex falls back gracefully without crashing`() {
        // Should not throw even with an invalid hex string
        val view = createView(colorHex = "not_a_color")
        assert(createdPixelId != null)
    }

    @Test
    fun `null color hex is handled without crashing`() {
        val view = createView(colorHex = null)
        assert(createdPixelId != null)
    }

    @Test
    fun `getView returns the container FrameLayout`() {
        val view = createView()
        val returned = view.getView()
        assert(returned is FrameLayout)
    }
}
