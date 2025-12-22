package com.roadrank.app.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

object RoadRankColors {
    val primary = Color(0xFF0EA5E9)
    val primaryDark = Color(0xFF0284C7)
    val secondary = Color(0xFF06B6D4)

    val success = Color(0xFF10B981)
    val warning = Color(0xFFF59E0B)
    val danger = Color(0xFFEF4444)

    val purple = Color(0xFF8B5CF6)
    val pink = Color(0xFFEC4899)
    val orange = Color(0xFFF97316)
    val teal = Color(0xFF14B8A6)

    val background = Color(0xFF0F172A)
    val backgroundSecondary = Color(0xFF1E293B)
    val surface = Color(0xFF334155)
    val surfaceLight = Color(0xFF475569)

    val textPrimary = Color.White
    val textSecondary = Color(0xFF94A3B8)
    val textMuted = Color(0xFF64748B)

    val cardBorder = Color.White.copy(alpha = 0.1f)
    val cardShadow = Color.Black.copy(alpha = 0.3f)

    val primaryGradient = Brush.linearGradient(listOf(primary, secondary))
    val successGradient = Brush.linearGradient(listOf(success, teal))
    val dangerGradient = Brush.linearGradient(listOf(danger, pink))
}
