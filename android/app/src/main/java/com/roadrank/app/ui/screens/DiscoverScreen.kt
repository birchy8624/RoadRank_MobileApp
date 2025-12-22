package com.roadrank.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.roadrank.app.data.Road
import com.roadrank.app.ui.components.ratingColorFor
import com.roadrank.app.ui.theme.RoadRankColors

@Composable
fun DiscoverScreen(
    viewModel: RoadViewModel,
    onRateRoad: (Road) -> Unit
) {
    val roads by viewModel.roads.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RoadRankColors.background)
            .padding(horizontal = 20.dp, vertical = 48.dp)
    ) {
        Text(
            text = "Discover",
            style = MaterialTheme.typography.headlineLarge,
            color = RoadRankColors.textPrimary
        )
        Text(
            text = "Find community-ranked routes nearby",
            style = MaterialTheme.typography.bodyMedium,
            color = RoadRankColors.textSecondary
        )

        Spacer(modifier = Modifier.padding(8.dp))

        LazyColumn(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            items(roads) { road ->
                DiscoverRoadCard(road = road, onRateRoad = onRateRoad)
            }
        }
    }
}

@Composable
private fun DiscoverRoadCard(
    road: Road,
    onRateRoad: (Road) -> Unit
) {
    Surface(
        color = RoadRankColors.backgroundSecondary,
        shape = MaterialTheme.shapes.large,
        tonalElevation = 6.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = road.displayName,
                style = MaterialTheme.typography.titleMedium,
                color = RoadRankColors.textPrimary
            )
            Text(
                text = "${"%.1f".format(road.overallRating)} ★ • ${road.ratingCount ?: 0} ratings",
                style = MaterialTheme.typography.bodyMedium,
                color = ratingColorFor(road.overallRating)
            )
            Text(
                text = if (road.path.isNotEmpty()) "${road.path.size} points mapped" else "No path data yet",
                style = MaterialTheme.typography.bodyMedium,
                color = RoadRankColors.textSecondary
            )

            Button(
                onClick = { onRateRoad(road) },
                modifier = Modifier
                    .padding(top = 12.dp)
                    .fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = RoadRankColors.primary)
            ) {
                Text("Rate this road")
            }
        }
    }
}
