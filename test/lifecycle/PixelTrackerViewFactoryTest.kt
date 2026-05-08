package com.veon.veon_pixel_tracker_flutter

import android.content.Context
import com.veonadtech.pixeltracker.PixelTracker
import com.veonadtech.pixeltracker.api.PixelHandle
import io.flutter.plugin.common.BinaryMessenger
import io.mockk.*
import org.junit.After
import org.junit.Before
import org.junit.Test

class PixelTrackerViewFactoryTest {

    private val context: Context = mockk(relaxed = true)
    private val messenger: BinaryMessenger = mockk(relaxed = true)

    private val factory = PixelTrackerViewFactory(
        messenger = messenger,
        onPixelCreated = { _: String, _: PixelHandle -> },
        onPixelDestroyed = { _: String -> },
    )

    @Before
    fun setUp() {
        mockkObject(PixelTracker)
        every { PixelTracker.attach(any(), any(), any()) } returns mockk(relaxed = true)
        mockkConstructor(PixelTrackerPlatformView::class)
        every { anyConstructed<PixelTrackerPlatformView>().getView() } returns mockk(relaxed = true)
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun `create with full params returns PlatformView`() {
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
    fun `create with null args does not throw`() {
        val view = factory.create(context, 2, null)

        assert(view != null)
    }

    @Test
    fun `create with empty map does not throw`() {
        val view = factory.create(context, 3, emptyMap<String, Any>())

        assert(view != null)
    }

    @Test
    fun `create returns PixelTrackerPlatformView instance`() {
        val view = factory.create(context, 4, mapOf("pixelId" to "p"))

        assert(view is PixelTrackerPlatformView)
    }
}