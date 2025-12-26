package com.roadrank.app.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/**
 * RoadRank Theme Colors - Matching iOS exactly
 */
object Theme {
    // Primary Brand Colors
    val Primary = Color(0xFF0EA5E9)        // Vibrant sky blue
    val PrimaryDark = Color(0xFF0284C7)    // Darker blue
    val Secondary = Color(0xFF06B6D4)      // Cyan accent

    // Action Colors
    val Success = Color(0xFF10B981)        // Emerald green
    val SuccessDark = Color(0xFF059669)    // Darker green
    val Warning = Color(0xFFF59E0B)        // Amber
    val Danger = Color(0xFFEF4444)         // Red
    val DangerDark = Color(0xFFDC2626)     // Darker red

    // Accent Colors
    val Purple = Color(0xFF8B5CF6)         // Violet
    val Pink = Color(0xFFEC4899)           // Pink
    val Orange = Color(0xFFF97316)         // Orange
    val Teal = Color(0xFF14B8A6)           // Teal

    // Neutral Colors
    val Background = Color(0xFF0F172A)     // Dark navy
    val BackgroundSecondary = Color(0xFF1E293B)  // Slate
    val Surface = Color(0xFF334155)        // Slate surface
    val SurfaceLight = Color(0xFF475569)   // Lighter slate

    // Text Colors
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFF94A3B8)  // Slate gray
    val TextMuted = Color(0xFF64748B)      // Muted gray

    // Card Styles
    val CardBackground = Color(0xFF1E293B).copy(alpha = 0.95f)
    val CardBorder = Color.White.copy(alpha = 0.1f)
    val CardShadow = Color.Black.copy(alpha = 0.3f)

    // Gradients
    val PrimaryGradient = Brush.linearGradient(
        colors = listOf(Primary, Secondary)
    )

    val SuccessGradient = Brush.linearGradient(
        colors = listOf(Success, Teal)
    )

    val DangerGradient = Brush.linearGradient(
        colors = listOf(Danger, Pink)
    )

    val PurpleGradient = Brush.linearGradient(
        colors = listOf(Purple, Pink)
    )

    val WarmGradient = Brush.linearGradient(
        colors = listOf(Orange, Warning)
    )

    val DarkGradient = Brush.verticalGradient(
        colors = listOf(Background, BackgroundSecondary)
    )
}

/**
 * Rating color based on value (matching iOS)
 */
fun ratingColor(value: Double): Color {
    return when {
        value < 2 -> Theme.Danger
        value < 3 -> Theme.Warning
        value < 4 -> Theme.Orange
        else -> Theme.Success
    }
}

/**
 * Rating color enum matching iOS
 */
enum class RatingColor {
    Poor, Fair, Good, Excellent;

    val color: Color
        get() = when (this) {
            Poor -> Theme.Danger
            Fair -> Theme.Warning
            Good -> Color(0xFFFFD700) // Yellow
            Excellent -> Theme.Success
        }

    companion object {
        fun fromRating(rating: Double): RatingColor {
            return when {
                rating < 2 -> Poor
                rating < 3 -> Fair
                rating < 4 -> Good
                else -> Excellent
            }
        }
    }
}

/**
 * Rating category colors (matching iOS)
 */
object RatingCategoryColors {
    val Twistiness = Theme.Purple
    val SurfaceCondition = Color(0xFF3B82F6) // Blue
    val FunFactor = Theme.Orange
    val Scenery = Theme.Success
    val Visibility = Color(0xFF22D3EE) // Cyan
}
