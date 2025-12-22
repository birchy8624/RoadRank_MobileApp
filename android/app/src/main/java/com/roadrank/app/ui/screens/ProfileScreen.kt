package com.roadrank.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.roadrank.app.data.DeviceIdManager
import com.roadrank.app.ui.theme.RoadRankColors

@Composable
fun ProfileScreen(viewModel: RoadViewModel) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RoadRankColors.background)
            .padding(horizontal = 20.dp, vertical = 48.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Profile",
            style = MaterialTheme.typography.headlineLarge,
            color = RoadRankColors.textPrimary
        )
        Text(
            text = "Manage your RoadRank preferences",
            style = MaterialTheme.typography.bodyMedium,
            color = RoadRankColors.textSecondary
        )

        Surface(
            color = RoadRankColors.backgroundSecondary,
            shape = MaterialTheme.shapes.large,
            tonalElevation = 6.dp
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Device ID",
                    style = MaterialTheme.typography.titleMedium,
                    color = RoadRankColors.textPrimary
                )
                Text(
                    text = DeviceIdManager.deviceId,
                    style = MaterialTheme.typography.bodyMedium,
                    color = RoadRankColors.textSecondary
                )
            }
        }

        Surface(
            color = RoadRankColors.backgroundSecondary,
            shape = MaterialTheme.shapes.large,
            tonalElevation = 6.dp
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Settings",
                    style = MaterialTheme.typography.titleMedium,
                    color = RoadRankColors.textPrimary
                )
                Spacer(modifier = Modifier.padding(top = 6.dp))
                Text(
                    text = "• Enable haptic feedback",
                    color = RoadRankColors.textSecondary
                )
                Text(
                    text = "• Location permissions",
                    color = RoadRankColors.textSecondary
                )
                Text(
                    text = "• Privacy policy",
                    color = RoadRankColors.textSecondary
                )
            }
        }
    }
}
