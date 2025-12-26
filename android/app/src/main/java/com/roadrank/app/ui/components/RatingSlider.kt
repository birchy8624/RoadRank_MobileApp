package com.roadrank.app.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.LinearScale
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadrank.app.data.RatingCategory
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.theme.Theme

/**
 * Rating Slider Row matching iOS
 */
@Composable
fun BrandedRatingSliderRow(
    category: RatingCategory,
    value: Int,
    onValueChange: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RatingCategoryIcon(category = category)
                Text(
                    text = category.title,
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.Medium,
                    fontSize = 14.sp
                )
            }
            Text(
                text = value.toString(),
                color = category.color,
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp
            )
        }

        // Slider
        BrandedRatingSlider(
            value = value,
            onValueChange = onValueChange,
            color = category.color
        )

        // Labels
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = category.lowDescription,
                color = Theme.TextMuted,
                fontSize = 10.sp
            )
            Text(
                text = category.highDescription,
                color = Theme.TextMuted,
                fontSize = 10.sp
            )
        }
    }
}

/**
 * Rating Category Icon
 */
@Composable
fun RatingCategoryIcon(
    category: RatingCategory,
    modifier: Modifier = Modifier,
    size: Int = 28
) {
    val icon = when (category) {
        RatingCategory.TWISTINESS -> Icons.Default.SwapHoriz
        RatingCategory.SURFACE_CONDITION -> Icons.Default.LinearScale
        RatingCategory.FUN_FACTOR -> Icons.Default.Bolt
        RatingCategory.SCENERY -> Icons.Default.Landscape
        RatingCategory.VISIBILITY -> Icons.Default.Visibility
    }

    Icon(
        imageVector = icon,
        contentDescription = category.title,
        tint = category.color,
        modifier = modifier.size(size.dp)
    )
}

/**
 * Branded Rating Slider matching iOS
 */
@Composable
fun BrandedRatingSlider(
    value: Int,
    onValueChange: (Int) -> Unit,
    color: Color,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    var sliderWidth by remember { mutableStateOf(0f) }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(36.dp)
            .onSizeChanged { sliderWidth = it.width.toFloat() }
            .pointerInput(Unit) {
                detectHorizontalDragGestures { change, _ ->
                    change.consume()
                    val stepWidth = sliderWidth / 5
                    val newValue = ((change.position.x / stepWidth) + 1).toInt().coerceIn(1, 5)
                    if (newValue != value) {
                        onValueChange(newValue)
                        HapticManager.selection()
                    }
                }
            }
    ) {
        // Track background
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .align(Alignment.Center)
                .clip(RoundedCornerShape(4.dp))
                .background(Theme.Surface)
        )

        // Filled track
        val fillFraction = (value - 0.5f) / 5f
        Box(
            modifier = Modifier
                .fillMaxWidth(fillFraction)
                .height(8.dp)
                .align(Alignment.CenterStart)
                .clip(RoundedCornerShape(4.dp))
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(color.copy(alpha = 0.8f), color)
                    )
                )
        )

        // Dots
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            for (i in 1..5) {
                val isSelected = i == value
                val isFilled = i <= value

                Box(
                    modifier = Modifier
                        .size(if (isSelected) 28.dp else 20.dp)
                        .clip(CircleShape)
                        .then(
                            if (isSelected) {
                                Modifier
                                    .shadow(5.dp, CircleShape, spotColor = color.copy(alpha = 0.5f))
                                    .border(3.dp, color, CircleShape)
                            } else Modifier
                        )
                        .background(if (isFilled) color else Theme.Surface)
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null
                        ) {
                            onValueChange(i)
                            HapticManager.selection()
                        }
                )
            }
        }
    }
}

/**
 * Rating Dots View matching iOS
 */
@Composable
fun RatingDotsView(
    rating: Int,
    color: Color,
    modifier: Modifier = Modifier,
    size: Int = 8
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        for (i in 0 until 5) {
            Box(
                modifier = Modifier
                    .size(size.dp)
                    .clip(CircleShape)
                    .background(if (i < rating) color else Theme.Surface)
            )
        }
    }
}
