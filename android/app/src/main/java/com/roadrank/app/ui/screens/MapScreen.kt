package com.roadrank.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.CameraPositionState
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Polyline
import com.google.maps.android.compose.rememberCameraPositionState
import com.roadrank.app.data.Road
import com.roadrank.app.ui.components.ratingColorFor
import com.roadrank.app.ui.theme.RoadRankColors

@Composable
fun MapScreen(
    viewModel: RoadViewModel,
    onRateRoad: (Road) -> Unit,
    onToast: (String) -> Unit
) {
    val roads by viewModel.roads.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val cameraPositionState = rememberCameraPositionState()
    var isDrawing by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        MapContent(roads = roads, cameraPositionState = cameraPositionState)

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 48.dp, start = 20.dp, end = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "RoadRank",
                style = MaterialTheme.typography.headlineLarge,
                color = RoadRankColors.textPrimary
            )
            Text(
                text = if (isDrawing) "Tap to add points to your route." else "Discover and rate your favorite roads.",
                style = MaterialTheme.typography.bodyMedium,
                color = RoadRankColors.textSecondary
            )

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(
                    onClick = {
                        isDrawing = !isDrawing
                        onToast(if (isDrawing) "Drawing mode enabled" else "Drawing mode disabled")
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = RoadRankColors.primary)
                ) {
                    Text(if (isDrawing) "Finish Draw" else "Draw Road")
                }

                Button(
                    onClick = viewModel::fetchRoads,
                    colors = ButtonDefaults.buttonColors(containerColor = RoadRankColors.surface)
                ) {
                    Text("Refresh")
                }

                if (roads.isNotEmpty()) {
                    Button(
                        onClick = { onRateRoad(roads.first()) },
                        colors = ButtonDefaults.buttonColors(containerColor = RoadRankColors.success)
                    ) {
                        Text("Rate")
                    }
                }
            }
        }

        Surface(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 120.dp, start = 20.dp, end = 20.dp)
                .shadow(12.dp, CircleShape),
            shape = CircleShape,
            color = RoadRankColors.backgroundSecondary
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "${roads.size} roads",
                        color = RoadRankColors.textPrimary,
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = if (isLoading) "Syncing updates..." else "Latest community ratings",
                        color = RoadRankColors.textSecondary,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .background(RoadRankColors.primary.copy(alpha = 0.2f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "⭐", color = Color.White)
                }
            }
        }
    }
}

@Composable
private fun MapContent(
    roads: List<Road>,
    cameraPositionState: CameraPositionState
) {
    GoogleMap(
        modifier = Modifier.fillMaxSize(),
        cameraPositionState = cameraPositionState,
        properties = MapProperties(isMyLocationEnabled = false),
        uiSettings = MapUiSettings(zoomControlsEnabled = false)
    ) {
        roads.forEach { road ->
            val polylineColor = ratingColorFor(road.overallRating)
            val coordinates = road.path.map { LatLng(it.lat, it.lng) }
            if (coordinates.isNotEmpty()) {
                Polyline(points = coordinates, color = polylineColor, width = 8f)
            }
        }
    }
}
