package com.roadrank.app.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.theme.Theme
import kotlinx.coroutines.launch

/**
 * Onboarding page data matching iOS
 */
data class OnboardingPage(
    val icon: ImageVector,
    val title: String,
    val subtitle: String,
    val highlight: String
)

private val onboardingPages = listOf(
    OnboardingPage(
        icon = Icons.Default.Route,
        title = "Discover Epic Roads",
        subtitle = "Found a Laguna Seca Corkscrew in the wild?\nA Mugello chicane on your commute?",
        highlight = "Find it."
    ),
    OnboardingPage(
        icon = Icons.Default.PinDrop,
        title = "Mark Your Favorites",
        subtitle = "Draw the road on the map and save it.\nBuild your collection of the best drives.",
        highlight = "Mark it."
    ),
    OnboardingPage(
        icon = Icons.Default.Star,
        title = "Rate & Share",
        subtitle = "Rate roads and help others discover\nthe best driving experiences.",
        highlight = "Share it."
    )
)

/**
 * Onboarding Screen matching iOS exactly
 */
@Composable
fun OnboardingScreen(
    onOnboardingComplete: () -> Unit
) {
    val pagerState = rememberPagerState(pageCount = { onboardingPages.size })
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Theme.Background)
    ) {
        // Ambient glows that follow page changes
        Box(
            modifier = Modifier
                .offset(
                    x = ((pagerState.currentPage - 1) * 100).dp,
                    y = (-200).dp
                )
                .size(400.dp)
                .clip(CircleShape)
                .background(Theme.Primary.copy(alpha = 0.1f))
                .blur(100.dp)
        )

        Box(
            modifier = Modifier
                .offset(
                    x = ((1 - pagerState.currentPage) * 80).dp,
                    y = 200.dp
                )
                .size(300.dp)
                .clip(CircleShape)
                .background(Theme.Secondary.copy(alpha = 0.08f))
                .blur(80.dp)
        )

        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Skip button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 10.dp)
                    .height(44.dp),
                horizontalArrangement = Arrangement.End
            ) {
                if (pagerState.currentPage < onboardingPages.size - 1) {
                    TextButton(onClick = onOnboardingComplete) {
                        Text(
                            text = "Skip",
                            color = Theme.TextSecondary,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Page content
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(3f)
            ) { page ->
                OnboardingPageView(
                    page = onboardingPages[page],
                    isActive = pagerState.currentPage == page
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Page indicators
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 30.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(onboardingPages.size) { index ->
                    val isSelected = pagerState.currentPage == index
                    val width by animateDpAsState(
                        targetValue = if (isSelected) 24.dp else 8.dp,
                        animationSpec = spring(dampingRatio = 0.7f),
                        label = "indicatorWidth"
                    )
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 5.dp)
                            .width(width)
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(if (isSelected) Theme.Primary else Theme.Surface)
                    )
                }
            }

            // Action button
            Button(
                onClick = {
                    if (pagerState.currentPage < onboardingPages.size - 1) {
                        scope.launch {
                            pagerState.animateScrollToPage(pagerState.currentPage + 1)
                        }
                    } else {
                        HapticManager.success()
                        onOnboardingComplete()
                    }
                    HapticManager.buttonTap()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp)
                    .padding(bottom = 40.dp)
                    .height(56.dp)
                    .shadow(15.dp, RoundedCornerShape(16.dp), spotColor = Theme.Primary.copy(alpha = 0.4f)),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                contentPadding = PaddingValues(0.dp)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Theme.PrimaryGradient),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = if (pagerState.currentPage < onboardingPages.size - 1) "Continue" else "Get Started",
                            color = Color.White,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 16.sp
                        )
                        Icon(
                            imageVector = if (pagerState.currentPage < onboardingPages.size - 1)
                                Icons.Default.ArrowForward
                            else
                                Icons.Default.Check,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun OnboardingPageView(
    page: OnboardingPage,
    isActive: Boolean
) {
    var iconScale by remember { mutableFloatStateOf(0.8f) }
    var contentOpacity by remember { mutableFloatStateOf(0f) }

    val animatedIconScale by animateFloatAsState(
        targetValue = iconScale,
        animationSpec = spring(dampingRatio = 0.7f),
        label = "iconScale"
    )
    val animatedContentOpacity by animateFloatAsState(
        targetValue = contentOpacity,
        animationSpec = tween(400, delayMillis = 100),
        label = "contentOpacity"
    )

    LaunchedEffect(isActive) {
        if (isActive) {
            iconScale = 0.8f
            contentOpacity = 0f
            iconScale = 1f
            contentOpacity = 1f
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Icon with glow
        Box(
            modifier = Modifier.scale(animatedIconScale),
            contentAlignment = Alignment.Center
        ) {
            // Glow background
            Box(
                modifier = Modifier
                    .size(160.dp)
                    .clip(CircleShape)
                    .background(Theme.Primary.copy(alpha = 0.2f))
                    .blur(40.dp)
            )

            // Icon container
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(Theme.BackgroundSecondary)
                    .border(
                        width = 2.dp,
                        brush = Brush.linearGradient(
                            colors = listOf(
                                Theme.Primary.copy(alpha = 0.5f),
                                Theme.Secondary.copy(alpha = 0.3f)
                            )
                        ),
                        shape = CircleShape
                    )
                    .shadow(20.dp, CircleShape, spotColor = Theme.Primary.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = page.icon,
                    contentDescription = null,
                    tint = Theme.Primary,
                    modifier = Modifier.size(48.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(40.dp))

        // Text content
        Column(
            modifier = Modifier.alpha(animatedContentOpacity),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = page.title,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                textAlign = TextAlign.Center
            )

            Text(
                text = page.subtitle,
                fontSize = 16.sp,
                color = Theme.TextSecondary,
                textAlign = TextAlign.Center,
                lineHeight = 24.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Highlight text
            Text(
                text = page.highlight,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                brush = Theme.PrimaryGradient
            )
        }
    }
}
