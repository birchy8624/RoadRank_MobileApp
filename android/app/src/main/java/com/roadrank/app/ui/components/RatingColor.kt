package com.roadrank.app.ui.components

import androidx.compose.ui.graphics.Color
import com.roadrank.app.ui.theme.RoadRankColors

fun ratingColorFor(value: Double): Color = when {
    value < 2 -> RoadRankColors.danger
    value < 3 -> RoadRankColors.warning
    value < 4 -> RoadRankColors.orange
    else -> RoadRankColors.success
}
