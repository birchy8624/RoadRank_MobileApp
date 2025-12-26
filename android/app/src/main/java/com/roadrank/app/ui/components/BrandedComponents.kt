package com.roadrank.app.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadrank.app.ui.theme.Theme

/**
 * Button styles matching iOS
 */
enum class ButtonStyle {
    PRIMARY, SECONDARY, SUCCESS, DANGER
}

fun ButtonStyle.gradient(): Brush = when (this) {
    ButtonStyle.PRIMARY -> Theme.PrimaryGradient
    ButtonStyle.SECONDARY -> Brush.linearGradient(listOf(Theme.Surface, Theme.SurfaceLight))
    ButtonStyle.SUCCESS -> Theme.SuccessGradient
    ButtonStyle.DANGER -> Theme.DangerGradient
}

fun ButtonStyle.shadowColor(): Color = when (this) {
    ButtonStyle.PRIMARY -> Theme.Primary.copy(alpha = 0.4f)
    ButtonStyle.SECONDARY -> Color.Transparent
    ButtonStyle.SUCCESS -> Theme.Success.copy(alpha = 0.4f)
    ButtonStyle.DANGER -> Theme.Danger.copy(alpha = 0.4f)
}

fun ButtonStyle.textColor(): Color = when (this) {
    ButtonStyle.SECONDARY -> Theme.TextSecondary
    else -> Color.White
}

/**
 * Branded Button matching iOS
 */
@Composable
fun BrandedButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: ButtonStyle = ButtonStyle.PRIMARY,
    enabled: Boolean = true
) {
    Box(
        modifier = modifier
            .shadow(10.dp, RoundedCornerShape(50), spotColor = style.shadowColor())
            .clip(RoundedCornerShape(50))
            .background(style.gradient())
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = style.textColor(),
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text(
                text = text,
                color = style.textColor(),
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }
    }
}

/**
 * Full Width Button matching iOS
 */
@Composable
fun BrandedFullWidthButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: ButtonStyle = ButtonStyle.PRIMARY,
    isLoading: Boolean = false,
    enabled: Boolean = true
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .shadow(10.dp, RoundedCornerShape(14.dp), spotColor = style.shadowColor())
            .clip(RoundedCornerShape(14.dp))
            .background(style.gradient())
            .clickable(enabled = enabled && !isLoading, onClick = onClick)
            .padding(vertical = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                color = Color.White,
                strokeWidth = 2.dp,
                modifier = Modifier.size(24.dp)
            )
        } else {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (icon != null) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = style.textColor(),
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    text = text,
                    color = style.textColor(),
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                )
            }
        }
    }
}

/**
 * Icon Button matching iOS
 */
enum class IconButtonStyle {
    GLASS, SOLID, OUTLINE
}

@Composable
fun BrandedIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    style: IconButtonStyle = IconButtonStyle.GLASS
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(
                when (style) {
                    IconButtonStyle.GLASS -> Color.White.copy(alpha = 0.15f)
                    IconButtonStyle.SOLID -> Theme.Surface
                    IconButtonStyle.OUTLINE -> Color.Transparent
                }
            )
            .then(
                if (style == IconButtonStyle.OUTLINE) {
                    Modifier.border(1.dp, Color.White.copy(alpha = 0.3f), CircleShape)
                } else Modifier
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(size * 0.4f)
        )
    }
}

/**
 * Branded Card modifier matching iOS
 */
fun Modifier.brandedCard() = this
    .shadow(15.dp, RoundedCornerShape(20.dp), spotColor = Theme.CardShadow)
    .clip(RoundedCornerShape(20.dp))
    .background(Theme.BackgroundSecondary)
    .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
    .padding(20.dp)

/**
 * Glass Card modifier matching iOS
 */
fun Modifier.glassCard() = this
    .clip(RoundedCornerShape(16.dp))
    .background(Theme.Surface.copy(alpha = 0.5f))
    .border(1.dp, Color.White.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
    .padding(16.dp)

/**
 * Stat Card matching iOS
 */
@Composable
fun BrandedStatCard(
    icon: ImageVector,
    value: String,
    label: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(28.dp)
        )
        Text(
            text = value,
            color = Theme.TextPrimary,
            fontWeight = FontWeight.Bold,
            fontSize = 20.sp
        )
        Text(
            text = label,
            color = Theme.TextSecondary,
            fontSize = 12.sp
        )
    }
}

/**
 * Badge matching iOS
 */
@Composable
fun BrandedBadge(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = Theme.Success,
    isAnimated: Boolean = false
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(color.copy(alpha = 0.2f))
            .border(1.dp, color.copy(alpha = 0.5f), RoundedCornerShape(50))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        if (isAnimated) {
            val infiniteTransition = rememberInfiniteTransition(label = "pulse")
            val alpha by infiniteTransition.animateFloat(
                initialValue = 0.5f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(1000),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "alpha"
            )
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(color.copy(alpha = alpha))
            )
        }
        Text(
            text = text,
            color = Color.White,
            fontWeight = FontWeight.Medium,
            fontSize = 14.sp
        )
    }
}

/**
 * Toast View matching iOS
 */
@Composable
fun BrandedToast(
    message: String,
    type: ToastType,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .shadow(15.dp, RoundedCornerShape(20.dp), spotColor = Theme.CardShadow)
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, type.color.copy(alpha = 0.3f), RoundedCornerShape(20.dp))
            .padding(horizontal = 18.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(type.color.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = type.icon,
                contentDescription = null,
                tint = type.color,
                modifier = Modifier.size(16.dp)
            )
        }
        Text(
            text = message,
            color = Theme.TextPrimary,
            fontWeight = FontWeight.Medium,
            fontSize = 14.sp
        )
    }
}

enum class ToastType(val color: Color, val icon: ImageVector) {
    SUCCESS(Theme.Success, Icons.Default.CheckCircle),
    ERROR(Theme.Danger, Icons.Default.Cancel),
    WARNING(Theme.Warning, Icons.Default.Warning),
    INFO(Color(0xFF3B82F6), Icons.Default.Info)
}
