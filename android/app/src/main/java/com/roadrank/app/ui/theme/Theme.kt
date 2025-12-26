package com.roadrank.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = Theme.Primary,
    onPrimary = Color.White,
    primaryContainer = Theme.PrimaryDark,
    onPrimaryContainer = Color.White,
    secondary = Theme.Secondary,
    onSecondary = Color.White,
    secondaryContainer = Theme.Secondary.copy(alpha = 0.3f),
    onSecondaryContainer = Color.White,
    tertiary = Theme.Teal,
    onTertiary = Color.White,
    background = Theme.Background,
    onBackground = Theme.TextPrimary,
    surface = Theme.BackgroundSecondary,
    onSurface = Theme.TextPrimary,
    surfaceVariant = Theme.Surface,
    onSurfaceVariant = Theme.TextSecondary,
    error = Theme.Danger,
    onError = Color.White,
    outline = Theme.CardBorder,
    outlineVariant = Theme.Surface
)

@Composable
fun RoadRankTheme(
    darkTheme: Boolean = true, // Always use dark theme to match iOS
    content: @Composable () -> Unit
) {
    val colorScheme = DarkColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            window.navigationBarColor = Color.Transparent.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = false
                isAppearanceLightNavigationBars = false
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
