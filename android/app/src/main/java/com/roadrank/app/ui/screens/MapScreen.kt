package com.roadrank.app.ui.screens

import android.Manifest
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.*
import com.google.maps.android.compose.*
import com.roadrank.app.data.*
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.components.*
import com.roadrank.app.ui.theme.Theme
import com.roadrank.app.ui.theme.ratingColor

/**
 * Map Screen matching iOS MapContainerView
 */
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun MapScreen(
    roads: List<Road>,
    isDrawingMode: Boolean,
    drawnPath: List<Coordinate>,
    snappedPath: List<Coordinate>?,
    isSnapping: Boolean,
    onStartDrawing: () -> Unit,
    onStopDrawing: () -> Unit,
    onClearDrawing: () -> Unit,
    onAddPoint: (Coordinate) -> Unit,
    onSnapAndRate: () -> Unit,
    onStartRide: () -> Unit,
    onRoadSelected: (Road) -> Unit,
    onSearchClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    // Location permissions
    val locationPermissions = rememberMultiplePermissionsState(
        listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
    )

    // Map state - default to UK region like iOS
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(54.5, -3.5), 6f)
    }

    // Map properties
    val mapProperties by remember {
        mutableStateOf(
            MapProperties(
                isMyLocationEnabled = locationPermissions.allPermissionsGranted,
                mapStyleOptions = MapStyleOptions(darkMapStyle)
            )
        )
    }

    val uiSettings by remember {
        mutableStateOf(
            MapUiSettings(
                zoomControlsEnabled = false,
                myLocationButtonEnabled = false,
                compassEnabled = false
            )
        )
    }

    // Request permissions on first launch
    LaunchedEffect(Unit) {
        if (!locationPermissions.allPermissionsGranted) {
            locationPermissions.launchMultiplePermissionRequest()
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        // Google Map
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = mapProperties.copy(
                isMyLocationEnabled = locationPermissions.allPermissionsGranted
            ),
            uiSettings = uiSettings,
            onMapClick = { latLng ->
                if (isDrawingMode) {
                    onAddPoint(Coordinate.from(latLng))
                    HapticManager.draw()
                }
            }
        ) {
            // Render existing roads
            roads.forEach { road ->
                if (road.coordinates.isNotEmpty()) {
                    Polyline(
                        points = road.coordinates,
                        color = ratingColor(road.overallRating),
                        width = 8f,
                        clickable = true,
                        onClick = {
                            onRoadSelected(road)
                            HapticManager.buttonTap()
                        }
                    )
                }
            }

            // Render drawn path
            val pathToRender = snappedPath ?: drawnPath
            if (pathToRender.isNotEmpty()) {
                Polyline(
                    points = pathToRender.map { it.latLng },
                    color = Theme.Primary,
                    width = 10f,
                    pattern = if (snappedPath == null) listOf(Dot(), Gap(10f)) else null
                )

                // Start marker
                Marker(
                    state = MarkerState(position = pathToRender.first().latLng),
                    title = "Start",
                    icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_GREEN)
                )

                // End marker
                if (pathToRender.size > 1) {
                    Marker(
                        state = MarkerState(position = pathToRender.last().latLng),
                        title = "End",
                        icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)
                    )
                }
            }
        }

        // Overlay Controls
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Top Bar
            TopBar(
                onSearchClick = onSearchClick,
                onLocationClick = {
                    if (locationPermissions.allPermissionsGranted) {
                        // Center on user location would be implemented here
                        HapticManager.buttonTap()
                    } else {
                        locationPermissions.launchMultiplePermissionRequest()
                    }
                }
            )

            Spacer(modifier = Modifier.weight(1f))

            // Bottom Controls
            BottomControls(
                isDrawingMode = isDrawingMode,
                drawnPath = drawnPath,
                onStartDrawing = onStartDrawing,
                onStopDrawing = onStopDrawing,
                onClearDrawing = onClearDrawing,
                onSnapAndRate = onSnapAndRate,
                onStartRide = onStartRide
            )
        }

        // Snapping Overlay
        AnimatedVisibility(
            visible = isSnapping,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            SnappingOverlay()
        }
    }
}

@Composable
private fun TopBar(
    onSearchClick: () -> Unit,
    onLocationClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .statusBarsPadding(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Search Button
        Row(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(25.dp))
                .background(Theme.BackgroundSecondary.copy(alpha = 0.95f))
                .border(1.dp, Theme.CardBorder, RoundedCornerShape(25.dp))
                .clickable(onClick = onSearchClick)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = Theme.Primary,
                modifier = Modifier.size(16.dp)
            )
            Text(
                text = "Search location...",
                color = Theme.TextSecondary,
                fontSize = 14.sp
            )
        }

        // Location Button
        BrandedIconButton(
            icon = Icons.Default.MyLocation,
            onClick = onLocationClick,
            size = 44.dp,
            style = IconButtonStyle.SOLID
        )
    }
}

@Composable
private fun BottomControls(
    isDrawingMode: Boolean,
    drawnPath: List<Coordinate>,
    onStartDrawing: () -> Unit,
    onStopDrawing: () -> Unit,
    onClearDrawing: () -> Unit,
    onSnapAndRate: () -> Unit,
    onStartRide: () -> Unit
) {
    Column(
        modifier = Modifier.padding(bottom = 120.dp), // Space for tab bar
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Drawing Mode Card
        AnimatedVisibility(
            visible = isDrawingMode,
            enter = slideInVertically { it } + fadeIn(),
            exit = slideOutVertically { it } + fadeOut()
        ) {
            DrawingModeCard(drawnPath = drawnPath)
        }

        // Action Buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (isDrawingMode) {
                // Cancel Button
                BrandedButton(
                    text = "Cancel",
                    icon = Icons.Default.Close,
                    style = ButtonStyle.DANGER,
                    onClick = {
                        onStopDrawing()
                        onClearDrawing()
                    }
                )

                // Clear Path Button
                if (drawnPath.isNotEmpty()) {
                    BrandedIconButton(
                        icon = Icons.Default.Undo,
                        onClick = {
                            onClearDrawing()
                            HapticManager.buttonTap()
                        },
                        size = 50.dp,
                        style = IconButtonStyle.SOLID
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Done/Save Button
                if (drawnPath.size >= 2) {
                    BrandedButton(
                        text = "Done",
                        icon = Icons.Default.Check,
                        style = ButtonStyle.SUCCESS,
                        onClick = onSnapAndRate
                    )
                }
            } else {
                // Start Ride Button
                BrandedButton(
                    text = "Start Ride",
                    icon = Icons.Default.MyLocation,
                    style = ButtonStyle.SUCCESS,
                    onClick = onStartRide
                )

                Spacer(modifier = Modifier.weight(1f))

                // Draw Road Button
                BrandedButton(
                    text = "Draw Road",
                    icon = Icons.Default.Edit,
                    style = ButtonStyle.PRIMARY,
                    onClick = onStartDrawing
                )
            }
        }
    }
}

@Composable
private fun DrawingModeCard(drawnPath: List<Coordinate>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .shadow(10.dp, RoundedCornerShape(16.dp), spotColor = Theme.CardShadow)
            .clip(RoundedCornerShape(16.dp))
            .background(Theme.BackgroundSecondary.copy(alpha = 0.95f))
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Draw,
                    contentDescription = null,
                    tint = Theme.Primary,
                    modifier = Modifier.size(18.dp)
                )
                Text(
                    text = "Drawing Mode",
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                )
            }

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(Theme.Surface)
                    .padding(horizontal = 10.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "${drawnPath.size} points",
                    color = Theme.TextSecondary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        if (drawnPath.isNotEmpty()) {
            val distance = drawnPath.totalDistanceInKm()
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.LinearScale,
                    contentDescription = null,
                    tint = Theme.TextMuted,
                    modifier = Modifier.size(14.dp)
                )
                Text(
                    text = "Distance:",
                    color = Theme.TextSecondary,
                    fontSize = 14.sp
                )
                Text(
                    text = String.format("%.2f km", distance),
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )

                if (distance > 20) {
                    Spacer(modifier = Modifier.weight(1f))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = Theme.Danger,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = "Max 20km",
                            color = Theme.Danger,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        } else {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.TouchApp,
                    contentDescription = null,
                    tint = Theme.TextMuted,
                    modifier = Modifier.size(14.dp)
                )
                Text(
                    text = "Tap on the map to draw your road path",
                    color = Theme.TextSecondary,
                    fontSize = 14.sp
                )
            }
        }
    }
}

@Composable
private fun SnappingOverlay() {
    val infiniteTransition = rememberInfiniteTransition(label = "snapping")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing)
        ),
        label = "rotation"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Theme.Background.copy(alpha = 0.7f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .shadow(20.dp, RoundedCornerShape(24.dp), spotColor = Theme.CardShadow)
                .clip(RoundedCornerShape(24.dp))
                .background(Theme.BackgroundSecondary)
                .border(1.dp, Theme.CardBorder, RoundedCornerShape(24.dp))
                .padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Loading indicator
            Box(contentAlignment = Alignment.Center) {
                CircularProgressIndicator(
                    modifier = Modifier.size(60.dp),
                    color = Theme.Surface,
                    strokeWidth = 4.dp
                )
                CircularProgressIndicator(
                    modifier = Modifier.size(60.dp),
                    color = Theme.Primary,
                    strokeWidth = 4.dp,
                    progress = { 0.7f }
                )
            }

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Snapping to road...",
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                )
                Text(
                    text = "Finding the best match for your path",
                    color = Theme.TextSecondary,
                    fontSize = 14.sp
                )
            }
        }
    }
}

// Dark map style JSON for Google Maps
private val darkMapStyle = """
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1d2c4d"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8ec3b9"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1a3646"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#304a7d"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#255763"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  }
]
""".trimIndent()
