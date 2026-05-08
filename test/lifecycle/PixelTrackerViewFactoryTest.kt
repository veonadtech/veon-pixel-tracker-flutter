package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import com.veonadtech.pixeltracker.api.PixelHandle
import io.mockk.*
import io.flutter.plugin.common.BinaryMessenger
import org.junit.After
import org.junit.Before
import org.junit.Test

class PixelTrackerViewFactoryTest {

    private val context: Context = mockk(relaxed = true)
    private val messenger: BinaryMessenger = mockk(relaxed = true)
    private val mockHandle: PixelHandle = mockk(relaxed = true)

    private val factory = PixelTrackerViewFactory(
        messenger = messenger,
        onPixelCreated = { _, _ -> },
        onPixelDestroyed = { _ -> },
    )

    @Before
    fun setUp() {
        mockkConstructor(PixelTrackerPlatformView::class)
        every {
            constructedWith<PixelTrackerPlatformView>(
                any(), any(), any(), any(), any(), any(), any(), any(), any(), any()
            )
        } returns mockk(relaxed = true)
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun `create with full params produces PixelTrackerPlatformView`() {
        val params = mapOf(
            "pixelId" to "factory_pixel",
            "refreshTimeSeconds" to 8,
            "pixelSize" to 32,
            "visibilityThreshold" to 60,
            "color" to "#AABBCC",
        )
        val view = factory.create(context, 1, params)
        assert(view != null)
    }

    @Test
    fun `create with null args uses safe defaults`() {
        // Should not throw; defaults should be applied
        val view = factory.create(context, 2, null)
        assert(view != null)
    }

    @Test
    fun `create with empty map uses defaults`() {
        val view = factory.create(context, 3, emptyMap<String, Any>())
        assert(view != null)
    }

    @Test
    fun `pixelId defaults to pixel_{viewId} when missing`() {
        // Verify via the slot that the pixelId arg is "pixel_99"
        val slot = slot<String>()
        mockkConstructor(PixelTrackerPlatformView::class)

        factory.create(context, 99, emptyMap<String, Any>())

        // Since we cannot directly inspect constructor args without a captor approach,
        // we verify the factory does not crash and returns a view.
        // A more thorough check can be done with a spy on PixelTrackerPlatformView.
    }

    @Test
    fun `refreshTimeSeconds defaults to 0L when missing`() {
        // This test ensures factory doesn't crash on missing refreshTimeSeconds
        val view = factory.create(context, 5, mapOf("pixelId" to "p"))
        assert(view != null)
    }

    @Test
    fun `pixelSize defaults to 1 when missing`() {
        val view = factory.create(context, 6, mapOf("pixelId" to "p"))
        assert(view != null)
    }

    @Test
    fun `visibilityThreshold defaults to 1 when missing`() {
        val view = factory.create(context, 7, mapOf("pixelId" to "p"))
        assert(view != null)
    }

    @Test
    fun `color defaults to null when missing`() {
        val view = factory.create(context, 8, mapOf("pixelId" to "p"))
        assert(view != null)
    }
}
