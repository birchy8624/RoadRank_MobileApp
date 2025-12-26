package com.roadrank.app.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LinearScale
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadrank.app.ui.theme.Theme
import kotlinx.coroutines.delay

/**
 * Splash Screen matching iOS exactly
 */
@Composable
fun SplashScreen(
    onSplashComplete: () -> Unit
) {
    // Animation states matching iOS
    var isAnimating by remember { mutableStateOf(false) }
    val logoScale by animateFloatAsState(
        targetValue = if (isAnimating) 1f else 0.6f,
        animationSpec = spring(
            dampingRatio = 0.6f,
            stiffness = Spring.StiffnessLow
        ),
        label = "logoScale"
    )
    val logoOpacity by animateFloatAsState(
        targetValue = if (isAnimating) 1f else 0f,
        animationSpec = tween(durationMillis = 800),
        label = "logoOpacity"
    )

    // Ring rotation animation
    val infiniteTransition = rememberInfiniteTransition(label = "infinite")
    val ringRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ringRotation"
    )

    // Pulse animation
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.5f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = EaseInOut),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulseScale"
    )

    // Start animations and navigate
    LaunchedEffect(Unit) {
        isAnimating = true
        delay(2500)
        onSplashComplete()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(Theme.Background, Theme.BackgroundSecondary)
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        // Ambient glow effects
        Box(
            modifier = Modifier
                .offset(x = (-50).dp, y = (-100).dp)
                .size(300.dp)
                .clip(CircleShape)
                .background(Theme.Primary.copy(alpha = 0.15f))
                .blur(80.dp)
        )

        Box(
            modifier = Modifier
                .offset(x = 80.dp, y = 150.dp)
                .size(250.dp)
                .clip(CircleShape)
                .background(Theme.Secondary.copy(alpha = 0.1f))
                .blur(60.dp)
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(modifier = Modifier.weight(1f))

            // Logo with loading ring
            Box(
                modifier = Modifier
                    .scale(logoScale)
                    .alpha(logoOpacity),
                contentAlignment = Alignment.Center
            ) {
                // Outer pulsing ring
                Box(
                    modifier = Modifier
                        .size(160.dp)
                        .scale(pulseScale)
                        .alpha((2f - pulseScale).coerceIn(0f, 1f))
                        .clip(CircleShape)
                        .border(2.dp, Theme.Primary.copy(alpha = 0.2f), CircleShape)
                )

                // Spinning gradient ring
                Box(
                    modifier = Modifier
                        .size(140.dp)
                        .rotate(ringRotation)
                ) {
                    androidx.compose.foundation.Canvas(modifier = Modifier.fillMaxSize()) {
                        drawArc(
                            brush = Brush.sweepGradient(
                                colors = listOf(
                                    Theme.Primary,
                                    Theme.Secondary,
                                    Theme.Primary.copy(alpha = 0.3f),
                                    Theme.Primary
                                )
                            ),
                            startAngle = 0f,
                            sweepAngle = 360f,
                            useCenter = false,
                            style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
                        )
                    }
                }

                // Inner glow circle
                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.radialGradient(
                                colors = listOf(
                                    Theme.Primary.copy(alpha = 0.3f),
                                    Theme.Primary.copy(alpha = 0.1f),
                                    Color.Transparent
                                )
                            )
                        )
                )

                // Logo icon
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.LinearScale,
                        contentDescription = null,
                        tint = Theme.Primary,
                        modifier = Modifier.size(44.dp)
                    )

                    // Small road indicator dots
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        repeat(3) { index ->
                            val dotAlpha by infiniteTransition.animateFloat(
                                initialValue = 0.3f,
                                targetValue = 1f,
                                animationSpec = infiniteRepeatable(
                                    animation = tween(500, delayMillis = index * 150),
                                    repeatMode = RepeatMode.Reverse
                                ),
                                label = "dotAlpha$index"
                            )
                            Box(
                                modifier = Modifier
                                    .size(4.dp)
                                    .clip(CircleShape)
                                    .background(Theme.Primary.copy(alpha = dotAlpha))
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(40.dp))

            // App name
            Column(
                modifier = Modifier.alpha(logoOpacity),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "RoadRank",
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Bold,
                    brush = Brush.verticalGradient(
                        colors = listOf(Color.White, Theme.TextSecondary)
                    )
                )
                Text(
                    text = "Rate the roads you love",
                    fontSize = 14.sp,
                    color = Theme.TextSecondary
                )
            }

            Spacer(modifier = Modifier.weight(1f))
            Spacer(modifier = Modifier.weight(1f))

            // Loading indicator
            Row(
                modifier = Modifier
                    .padding(bottom = 60.dp)
                    .alpha(logoOpacity),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                repeat(3) { index ->
                    val dotScale by infiniteTransition.animateFloat(
                        initialValue = 0.5f,
                        targetValue = 1f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(600, delayMillis = index * 200),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "loadingDot$index"
                    )
                    val dotAlpha by infiniteTransition.animateFloat(
                        initialValue = 0.3f,
                        targetValue = 1f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(600, delayMillis = index * 200),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "loadingDotAlpha$index"
                    )
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .scale(dotScale)
                            .alpha(dotAlpha)
                            .clip(CircleShape)
                            .background(Theme.Primary)
                    )
                }
            }
        }
    }
}
