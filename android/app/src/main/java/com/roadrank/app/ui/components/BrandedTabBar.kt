package com.roadrank.app.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.theme.Theme

/**
 * Tab enum matching iOS
 */
enum class Tab(val title: String, val icon: ImageVector) {
    MAP("Map", Icons.Default.Map),
    DISCOVER("Discover", Icons.Default.Search),
    PROFILE("Profile", Icons.Default.Person)
}

/**
 * Branded Tab Bar matching iOS exactly
 */
@Composable
fun BrandedTabBar(
    selectedTab: Tab,
    onTabSelected: (Tab) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .padding(horizontal = 32.dp, vertical = 8.dp)
            .shadow(20.dp, RoundedCornerShape(50), spotColor = Theme.CardShadow)
            .clip(RoundedCornerShape(50))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(50))
            .padding(horizontal = 20.dp, vertical = 10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Tab.entries.forEach { tab ->
                BrandedTabBarButton(
                    tab = tab,
                    isSelected = selectedTab == tab,
                    onClick = {
                        onTabSelected(tab)
                        HapticManager.selection()
                    }
                )
            }
        }
    }
}

@Composable
private fun BrandedTabBarButton(
    tab: Tab,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor by animateColorAsState(
        targetValue = if (isSelected) Theme.Primary.copy(alpha = 0.15f) else Color.Transparent,
        label = "backgroundColor"
    )
    val iconColor by animateColorAsState(
        targetValue = if (isSelected) Theme.Primary else Theme.TextMuted,
        label = "iconColor"
    )

    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(backgroundColor)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier.size(32.dp),
            contentAlignment = Alignment.Center
        ) {
            // Glow effect for selected
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(Theme.Primary.copy(alpha = 0.2f))
                        .blur(8.dp)
                )
            }
            Icon(
                imageVector = tab.icon,
                contentDescription = tab.title,
                tint = iconColor,
                modifier = Modifier.size(20.dp)
            )
        }
        Text(
            text = tab.title,
            color = iconColor,
            fontSize = 10.sp,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}
