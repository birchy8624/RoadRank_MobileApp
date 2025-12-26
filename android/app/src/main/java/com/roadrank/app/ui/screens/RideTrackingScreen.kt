package com.roadrank.app.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import com.roadrank.app.data.Ride
import com.roadrank.app.data.RideState
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.components.*
import com.roadrank.app.ui.theme.Theme

/**
 * Ride Tracking Screen matching iOS RideTrackingView
 */
@Composable
fun RideTrackingScreen(
    currentRide: Ride?,
    rideState: RideState,
    currentSpeed: Double,
    elapsedTime: Long,
    rideDistance: Double,
    userLocation: LatLng?,
    onPauseRide: () -> Unit,
    onResumeRide: () -> Unit,
    onStopRide: () -> Unit,
    onCancelRide: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showStopConfirmation by remember { mutableStateOf(false) }
    var showCancelConfirmation by remember { mutableStateOf(false) }
    var showInsufficientPointsAlert by remember { mutableStateOf(false) }

    val isTracking = rideState is RideState.Tracking

    Box(modifier = modifier.fillMaxSize()) {
        // Map background
        RideMap(
            path = currentRide?.latLngCoordinates ?: emptyList(),
            userLocation = userLocation
        )

        // Gradient overlays
        Column(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Theme.Background.copy(alpha = 0.9f),
                                Theme.Background.copy(alpha = 0.3f),
                                Color.Transparent
                            )
                        )
                    )
            )
            Spacer(modifier = Modifier.weight(1f))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                Theme.Background.copy(alpha = 0.7f),
                                Theme.Background.copy(alpha = 0.95f)
                            )
                        )
                    )
            )
        }

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // Top bar
            TopBar(
                isTracking = isTracking,
                onCancel = { showCancelConfirmation = true },
                onCenterOnUser = {
                    HapticManager.buttonTap()
                }
            )

            Spacer(modifier = Modifier.weight(1f))

            // Stats display
            StatsDisplay(
                formattedTime = formatElapsedTime(elapsedTime),
                currentSpeed = currentSpeed,
                distance = rideDistance,
                pointsCount = currentRide?.path?.size ?: 0
            )

            // Control buttons
            ControlButtons(
                isTracking = isTracking,
                pointsCount = currentRide?.path?.size ?: 0,
                onPause = onPauseRide,
                onResume = onResumeRide,
                onStop = {
                    if ((currentRide?.path?.size ?: 0) < 2) {
                        showInsufficientPointsAlert = true
                    } else {
                        showStopConfirmation = true
                    }
                }
            )

            Spacer(modifier = Modifier.height(50.dp))
        }
    }

    // Dialogs
    if (showStopConfirmation) {
        AlertDialog(
            onDismissRequest = { showStopConfirmation = false },
            title = { Text("Stop Ride?") },
            text = { Text("Your ride will be saved and you can review the summary.") },
            confirmButton = {
                TextButton(onClick = {
                    showStopConfirmation = false
                    onStopRide()
                }) {
                    Text("Finish Ride")
                }
            },
            dismissButton = {
                TextButton(onClick = { showStopConfirmation = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showCancelConfirmation) {
        AlertDialog(
            onDismissRequest = { showCancelConfirmation = false },
            title = { Text("Cancel Ride?") },
            text = { Text("This will discard all ride data. This cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showCancelConfirmation = false
                        onCancelRide()
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = Theme.Danger)
                ) {
                    Text("Discard Ride")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCancelConfirmation = false }) {
                    Text("Keep Riding")
                }
            }
        )
    }

    if (showInsufficientPointsAlert) {
        AlertDialog(
            onDismissRequest = { showInsufficientPointsAlert = false },
            title = { Text("No Distance Travelled") },
            text = { Text("You need to travel at least a short distance before saving a road.") },
            confirmButton = {
                TextButton(onClick = { showInsufficientPointsAlert = false }) {
                    Text("Keep Riding")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showInsufficientPointsAlert = false
                        onCancelRide()
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = Theme.Danger)
                ) {
                    Text("Discard Ride")
                }
            }
        )
    }
}

@Composable
private fun RideMap(
    path: List<LatLng>,
    userLocation: LatLng?
) {
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            userLocation ?: LatLng(54.5, -3.5),
            15f
        )
    }

    LaunchedEffect(userLocation) {
        userLocation?.let {
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLng(it)
            )
        }
    }

    GoogleMap(
        modifier = Modifier.fillMaxSize(),
        cameraPositionState = cameraPositionState,
        properties = MapProperties(isMyLocationEnabled = true),
        uiSettings = MapUiSettings(
            zoomControlsEnabled = false,
            myLocationButtonEnabled = false,
            compassEnabled = false
        )
    ) {
        if (path.size >= 2) {
            Polyline(
                points = path,
                color = Theme.Primary,
                width = 10f
            )
        }
    }
}

@Composable
private fun TopBar(
    isTracking: Boolean,
    onCancel: () -> Unit,
    onCenterOnUser: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        BrandedIconButton(
            icon = Icons.Default.Close,
            onClick = onCancel,
            size = 44.dp,
            style = IconButtonStyle.GLASS
        )

        BrandedBadge(
            text = if (isTracking) "Recording" else "Paused",
            color = if (isTracking) Theme.Success else Theme.Warning,
            isAnimated = isTracking
        )

        BrandedIconButton(
            icon = Icons.Default.MyLocation,
            onClick = onCenterOnUser,
            size = 44.dp,
            style = IconButtonStyle.GLASS
        )
    }
}

@Composable
private fun StatsDisplay(
    formattedTime: String,
    currentSpeed: Double,
    distance: Double,
    pointsCount: Int
) {
    Column(
        modifier = Modifier.padding(bottom = 40.dp),
        verticalArrangement = Arrangement.spacedBy(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Time - Large central display
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = formattedTime,
                color = Theme.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 72.sp,
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            )
            Text(
                text = "Duration",
                color = Theme.TextSecondary,
                fontWeight = FontWeight.Medium,
                fontSize = 14.sp
            )
        }

        // Speed and Distance Cards
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            StatCard(
                value = String.format("%.1f", currentSpeed),
                unit = "km/h",
                label = "Speed",
                icon = Icons.Default.Speed,
                iconColor = Theme.Primary,
                modifier = Modifier.weight(1f)
            )

            val distanceValue: String
            val distanceUnit: String
            val km = distance / 1000.0
            if (km < 1) {
                distanceValue = String.format("%.0f", distance)
                distanceUnit = "m"
            } else {
                distanceValue = String.format("%.2f", km)
                distanceUnit = "km"
            }

            StatCard(
                value = distanceValue,
                unit = distanceUnit,
                label = "Distance",
                icon = Icons.Default.LinearScale,
                iconColor = Theme.Success,
                modifier = Modifier.weight(1f)
            )
        }

        // Points tracked
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .background(Theme.Surface.copy(alpha = 0.5f))
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Timeline,
                contentDescription = null,
                tint = Theme.TextMuted,
                modifier = Modifier.size(14.dp)
            )
            Text(
                text = "$pointsCount points tracked",
                color = Theme.TextMuted,
                fontSize = 12.sp
            )
        }
    }
}

@Composable
private fun StatCard(
    value: String,
    unit: String,
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    iconColor: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary.copy(alpha = 0.8f))
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = value,
                color = Theme.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 44.sp,
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            )
            Text(
                text = unit,
                color = Theme.TextSecondary,
                fontWeight = FontWeight.Medium,
                fontSize = 16.sp,
                modifier = Modifier.padding(bottom = 8.dp)
            )
        }
        Row(
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor,
                modifier = Modifier.size(14.dp)
            )
            Text(
                text = label,
                color = Theme.TextSecondary,
                fontSize = 14.sp
            )
        }
    }
}

@Composable
private fun ControlButtons(
    isTracking: Boolean,
    pointsCount: Int,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onStop: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Pause/Resume Button
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(70.dp)
                    .clip(CircleShape)
                    .background(Theme.BackgroundSecondary)
                    .border(1.dp, Theme.CardBorder, CircleShape)
                    .clickable {
                        if (isTracking) onPause() else onResume()
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isTracking) Icons.Default.Pause else Icons.Default.PlayArrow,
                    contentDescription = if (isTracking) "Pause" else "Resume",
                    tint = Theme.TextPrimary,
                    modifier = Modifier.size(28.dp)
                )
            }
            Text(
                text = if (isTracking) "Pause" else "Resume",
                color = Theme.TextSecondary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }

        Spacer(modifier = Modifier.width(32.dp))

        // Stop Button
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                // Glow effect
                Box(
                    modifier = Modifier
                        .size(100.dp)
                        .clip(CircleShape)
                        .background(Theme.Danger.copy(alpha = 0.3f))
                        .blur(20.dp)
                )

                Box(
                    modifier = Modifier
                        .size(90.dp)
                        .shadow(15.dp, CircleShape, spotColor = Theme.Danger.copy(alpha = 0.5f))
                        .clip(CircleShape)
                        .background(Theme.DangerGradient)
                        .border(2.dp, Color.White.copy(alpha = 0.2f), CircleShape)
                        .clickable(onClick = onStop),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Stop,
                        contentDescription = "Stop",
                        tint = Color.White,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
            Text(
                text = "Stop",
                color = Theme.TextSecondary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

private fun formatElapsedTime(elapsedTimeMs: Long): String {
    val seconds = elapsedTimeMs / 1000
    val hours = seconds / 3600
    val minutes = (seconds % 3600) / 60
    val secs = seconds % 60

    return if (hours > 0) {
        String.format("%d:%02d:%02d", hours, minutes, secs)
    } else {
        String.format("%02d:%02d", minutes, secs)
    }
}

private fun androidx.compose.ui.Modifier.clickable(onClick: () -> Unit): Modifier {
    return this.then(
        androidx.compose.foundation.clickable(onClick = onClick)
    )
}
