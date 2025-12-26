package com.roadrank.app.services

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.content.getSystemService

/**
 * Haptic Manager for haptic feedback - matching iOS
 */
object HapticManager {
    private var vibrator: Vibrator? = null

    fun init(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService<VibratorManager>()
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    enum class ImpactStyle(val duration: Long, val amplitude: Int) {
        LIGHT(20L, 50),
        MEDIUM(30L, 100),
        HEAVY(40L, 180),
        SOFT(15L, 30),
        RIGID(25L, 255)
    }

    enum class NotificationType(val pattern: LongArray, val amplitudes: IntArray) {
        SUCCESS(longArrayOf(0, 50, 50, 50), intArrayOf(0, 100, 0, 150)),
        WARNING(longArrayOf(0, 50, 100, 50), intArrayOf(0, 150, 0, 100)),
        ERROR(longArrayOf(0, 100, 50, 100), intArrayOf(0, 200, 0, 200))
    }

    fun impact(style: ImpactStyle) {
        vibrator?.let { vib ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vib.vibrate(
                    VibrationEffect.createOneShot(style.duration, style.amplitude)
                )
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(style.duration)
            }
        }
    }

    fun selection() {
        impact(ImpactStyle.LIGHT)
    }

    fun notification(type: NotificationType) {
        vibrator?.let { vib ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vib.vibrate(
                    VibrationEffect.createWaveform(type.pattern, type.amplitudes, -1)
                )
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(type.pattern, -1)
            }
        }
    }

    // Convenience methods matching iOS
    fun success() = notification(NotificationType.SUCCESS)
    fun warning() = notification(NotificationType.WARNING)
    fun error() = notification(NotificationType.ERROR)
    fun buttonTap() = impact(ImpactStyle.LIGHT)
    fun toggle() = impact(ImpactStyle.MEDIUM)
    fun sliderChange() = selection()
    fun longPress() = impact(ImpactStyle.HEAVY)
    fun draw() = impact(ImpactStyle.SOFT)
}
