package com.veon.veon_pixel_tracker_flutter

import android.content.Context
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
        mockkConstructor(PixelTrackerPlatformView::class)

        every {
            anyConstructed<PixelTrackerPlatformView>().getView()
        } returns mockk(relaxed = true)
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun `create passes full params to PixelTrackerPlatformView`() {
        val params = mapOf(
            "pixelId" to "factory_pixel",
            "refreshTimeSeconds" to 8,
            "pixelSize" to 32,
            "visibilityThreshold" to 60,
            "color" to "#AABBCC",
        )

        factory.create(context, 1, params)

        verify {
            constructedWith<PixelTrackerPlatformView>(
                EqMatcher(context),
                EqMatcher(1),
                EqMatcher("factory_pixel"),
                EqMatcher(8L),
                EqMatcher(32),
                EqMatcher(60),
                EqMatcher("#AABBCC"),
                EqMatcher(messenger),
                any(),
                any()
            )
        }
    }

    @Test
    fun `create with null args uses defaults`() {
        factory.create(context, 2, null)

        verify {
            constructedWith<PixelTrackerPlatformView>(
                EqMatcher(context),
                EqMatcher(2),
                EqMatcher("pixel_2"),
                EqMatcher(0L),
                EqMatcher(1),
                EqMatcher(1),
                EqMatcher(null),
                EqMatcher(messenger),
                any(),
                any()
            )
        }
    }

    @Test
    fun `pixelId defaults to pixel_viewId when missing`() {
        factory.create(
            context,
            99,
            mapOf("refreshTimeSeconds" to 5)
        )

        verify {
            constructedWith<PixelTrackerPlatformView>(
                EqMatcher(context),
                EqMatcher(99),
                EqMatcher("pixel_99"),
                EqMatcher(5L),
                EqMatcher(1),
                EqMatcher(1),
                EqMatcher(null),
                EqMatcher(messenger),
                any(),
                any()
            )
        }
    }
}
