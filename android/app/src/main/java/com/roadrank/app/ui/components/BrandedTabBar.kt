package com.roadrank.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.roadrank.app.RoadRankTab
import com.roadrank.app.ui.theme.RoadRankColors

@Composable
fun BrandedTabBar(
    selectedTab: RoadRankTab,
    onTabSelected: (RoadRankTab) -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        color = RoadRankColors.backgroundSecondary,
        shape = RoundedCornerShape(999.dp),
        tonalElevation = 8.dp,
        modifier = modifier
            .padding(horizontal = 32.dp)
            .shadow(20.dp, RoundedCornerShape(999.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            RoadRankTab.values().forEach { tab ->
                val isSelected = tab == selectedTab
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { onTabSelected(tab) }
                        .padding(vertical = 6.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier
                            .background(
                                color = if (isSelected) RoadRankColors.primary.copy(alpha = 0.2f) else Color.Transparent,
                                shape = CircleShape
                            )
                            .padding(8.dp)
                    ) {
                        Text(
                            text = tab.icon,
                            color = if (isSelected) RoadRankColors.primary else RoadRankColors.textMuted
                        )
                    }
                    Text(
                        text = tab.label,
                        color = if (isSelected) RoadRankColors.primary else RoadRankColors.textMuted,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                    )
                }
            }
        }
    }
}
