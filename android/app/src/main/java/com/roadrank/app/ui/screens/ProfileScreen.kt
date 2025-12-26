package com.roadrank.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.content.Intent
import android.net.Uri
import com.roadrank.app.data.Road
import com.roadrank.app.services.DeviceManager
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.theme.Theme

/**
 * Profile Screen matching iOS
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    roads: List<Road>,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showSettings by remember { mutableStateOf(false) }
    var showAbout by remember { mutableStateOf(false) }

    val deviceId = try { DeviceManager.deviceId } catch (e: Exception) { "" }
    val myRoads = roads.filter { it.isMyRoad(deviceId) }

    val totalDistance = remember(myRoads) {
        val total = myRoads.sumOf { it.distanceInKm }
        if (total >= 1000) String.format("%.0f km", total)
        else String.format("%.1f km", total)
    }

    val totalRatings = myRoads.sumOf { it.ratingCount ?: 0 }
    val topRoadRating = myRoads.maxOfOrNull { it.overallRating } ?: 0.0

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profile") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Theme.Background,
                    titleContentColor = Theme.TextPrimary
                )
            )
        },
        containerColor = Theme.Background
    ) { padding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Profile Header
            ProfileHeader()

            // Quick Stats
            StatsSection(
                myRoadsCount = myRoads.size,
                totalDistance = totalDistance,
                totalRatings = totalRatings,
                topRoadRating = topRoadRating
            )

            // Menu Items
            MenuSection(
                onSettingsClick = { showSettings = true },
                onLocationClick = {
                    val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:${context.packageName}")
                    context.startActivity(intent)
                },
                onRateAppClick = {
                    HapticManager.success()
                    // Would open Play Store
                },
                onShareAppClick = {
                    HapticManager.buttonTap()
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, "Check out RoadRank - Rate the roads you love!")
                    }
                    context.startActivity(Intent.createChooser(shareIntent, "Share RoadRank"))
                },
                onAboutClick = { showAbout = true }
            )

            // App Info
            AppInfoSection()
        }
    }

    // Settings Sheet
    if (showSettings) {
        SettingsSheet(onDismiss = { showSettings = false })
    }

    // About Sheet
    if (showAbout) {
        AboutSheet(onDismiss = { showAbout = false })
    }
}

@Composable
private fun ProfileHeader() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Avatar
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(
                        colors = listOf(Theme.Primary, Theme.Secondary)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.DirectionsCar,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(40.dp)
            )
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = "Road Explorer",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )
            Text(
                text = "Finding the best driving roads",
                color = Theme.TextSecondary,
                fontSize = 14.sp
            )
        }
    }
}

@Composable
private fun StatsSection(
    myRoadsCount: Int,
    totalDistance: String,
    totalRatings: Int,
    topRoadRating: Double
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(
            text = "Your Activity",
            color = Theme.TextPrimary,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ProfileStatCard(
                title = "My Roads",
                value = "$myRoadsCount",
                icon = Icons.Default.Map,
                color = Theme.Primary,
                modifier = Modifier.weight(1f)
            )
            ProfileStatCard(
                title = "Total Distance",
                value = totalDistance,
                icon = Icons.Default.LinearScale,
                color = Theme.Success,
                modifier = Modifier.weight(1f)
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ProfileStatCard(
                title = "Total Ratings",
                value = "$totalRatings",
                icon = Icons.Default.Star,
                color = Color(0xFFEAB308),
                modifier = Modifier.weight(1f)
            )
            ProfileStatCard(
                title = "Best Road",
                value = String.format("%.1f", topRoadRating),
                icon = Icons.Default.EmojiEvents,
                color = Theme.Orange,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun ProfileStatCard(
    title: String,
    value: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Theme.Surface.copy(alpha = 0.5f))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(24.dp)
        )
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = value,
                color = Theme.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )
            Text(
                text = title,
                color = Theme.TextSecondary,
                fontSize = 12.sp
            )
        }
    }
}

@Composable
private fun MenuSection(
    onSettingsClick: () -> Unit,
    onLocationClick: () -> Unit,
    onRateAppClick: () -> Unit,
    onShareAppClick: () -> Unit,
    onAboutClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Theme.Surface.copy(alpha = 0.5f))
    ) {
        MenuRow(
            icon = Icons.Default.Settings,
            title = "Settings",
            color = Theme.TextMuted,
            onClick = onSettingsClick
        )
        Divider(modifier = Modifier.padding(start = 56.dp), color = Theme.Surface)

        MenuRow(
            icon = Icons.Default.LocationOn,
            title = "Location Permissions",
            color = Theme.Primary,
            onClick = onLocationClick
        )
        Divider(modifier = Modifier.padding(start = 56.dp), color = Theme.Surface)

        MenuRow(
            icon = Icons.Default.Star,
            title = "Rate App",
            color = Color(0xFFEAB308),
            onClick = onRateAppClick
        )
        Divider(modifier = Modifier.padding(start = 56.dp), color = Theme.Surface)

        MenuRow(
            icon = Icons.Default.Share,
            title = "Share App",
            color = Theme.Success,
            onClick = onShareAppClick
        )
        Divider(modifier = Modifier.padding(start = 56.dp), color = Theme.Surface)

        MenuRow(
            icon = Icons.Default.Info,
            title = "About",
            color = Theme.Secondary,
            onClick = onAboutClick
        )
    }
}

@Composable
private fun MenuRow(
    icon: ImageVector,
    title: String,
    color: Color,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                onClick()
                HapticManager.buttonTap()
            }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(20.dp)
        )
        Text(
            text = title,
            color = Theme.TextPrimary,
            modifier = Modifier.weight(1f)
        )
        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = Theme.TextMuted,
            modifier = Modifier.size(16.dp)
        )
    }
}

@Composable
private fun AppInfoSection() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = Icons.Default.DirectionsCar,
            contentDescription = null,
            tint = Theme.Primary,
            modifier = Modifier.size(32.dp)
        )
        Text(
            text = "RoadRank",
            color = Theme.TextPrimary,
            fontWeight = FontWeight.SemiBold
        )
        Text(
            text = "Version 1.0.0",
            color = Theme.TextSecondary,
            fontSize = 12.sp
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsSheet(onDismiss: () -> Unit) {
    var hapticFeedback by remember { mutableStateOf(true) }
    var autoSnapToRoad by remember { mutableStateOf(true) }
    var distanceUnit by remember { mutableStateOf("km") }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Theme.Background
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Settings",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )

            // General Section
            Text(
                text = "General",
                color = Theme.TextSecondary,
                fontSize = 12.sp,
                modifier = Modifier.padding(top = 8.dp)
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Icon(Icons.Default.TouchApp, contentDescription = null, tint = Theme.TextSecondary)
                    Text("Haptic Feedback", color = Theme.TextPrimary)
                }
                Switch(
                    checked = hapticFeedback,
                    onCheckedChange = { hapticFeedback = it },
                    colors = SwitchDefaults.colors(checkedTrackColor = Theme.Primary)
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Icon(Icons.Default.Route, contentDescription = null, tint = Theme.TextSecondary)
                    Text("Auto-snap to Road", color = Theme.TextPrimary)
                }
                Switch(
                    checked = autoSnapToRoad,
                    onCheckedChange = { autoSnapToRoad = it },
                    colors = SwitchDefaults.colors(checkedTrackColor = Theme.Primary)
                )
            }

            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Theme.Primary)
            ) {
                Text("Done")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AboutSheet(onDismiss: () -> Unit) {
    val context = LocalContext.current

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Theme.Background
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Logo
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(CircleShape)
                    .background(Theme.PrimaryGradient),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.DirectionsCar,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(40.dp)
                )
            }

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "RoadRank",
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 28.sp
                )
                Text(
                    text = "Version 1.0.0",
                    color = Theme.TextSecondary
                )
            }

            Text(
                text = "RoadRank helps driving enthusiasts find, rate, and share their favorite roads.",
                color = Theme.TextSecondary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                modifier = Modifier.padding(horizontal = 16.dp)
            )

            TextButton(
                onClick = {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/birchy8624/RoadRank"))
                    context.startActivity(intent)
                }
            ) {
                Icon(Icons.Default.Link, contentDescription = null, tint = Theme.Primary)
                Spacer(modifier = Modifier.width(8.dp))
                Text("View on GitHub", color = Theme.Primary)
            }

            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Theme.Primary)
            ) {
                Text("Done")
            }
        }
    }
}
