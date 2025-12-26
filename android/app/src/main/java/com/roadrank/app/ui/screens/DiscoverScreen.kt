package com.roadrank.app.ui.screens

import android.location.Location
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import com.roadrank.app.data.Road
import com.roadrank.app.data.RatingCategory
import com.roadrank.app.services.DeviceManager
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.components.RatingCategoryIcon
import com.roadrank.app.ui.theme.Theme
import com.roadrank.app.ui.theme.ratingColor

/**
 * Sort options matching iOS
 */
enum class SortOption(val title: String) {
    NEWEST("Newest"),
    HIGHEST_RATED("Highest Rated"),
    MOST_RATED("Most Rated"),
    NEAREST("Nearest")
}

/**
 * Road filter matching iOS
 */
enum class RoadFilter(val title: String) {
    MY_ROADS("My Roads"),
    ALL_ROADS("All Roads")
}

/**
 * Discover Screen matching iOS
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiscoverScreen(
    roads: List<Road>,
    userLocation: Location?,
    onRoadSelected: (Road) -> Unit,
    onDrawRoadClick: () -> Unit,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier
) {
    var searchText by remember { mutableStateOf("") }
    var sortOption by remember { mutableStateOf(SortOption.NEWEST) }
    var filterRating by remember { mutableFloatStateOf(0f) }
    var roadFilter by remember { mutableStateOf(RoadFilter.MY_ROADS) }

    val deviceId = try { DeviceManager.deviceId } catch (e: Exception) { "" }

    val filteredRoads = remember(roads, searchText, sortOption, filterRating, roadFilter, userLocation) {
        var result = roads.toMutableList()

        // Filter by ownership
        when (roadFilter) {
            RoadFilter.MY_ROADS -> result = result.filter { it.isMyRoad(deviceId) }.toMutableList()
            RoadFilter.ALL_ROADS -> { /* Show all */ }
        }

        // Filter by search text
        if (searchText.isNotEmpty()) {
            result = result.filter {
                it.displayName.contains(searchText, ignoreCase = true)
            }.toMutableList()
        }

        // Filter by minimum rating
        if (filterRating > 0) {
            result = result.filter { it.overallRating >= filterRating }.toMutableList()
        }

        // Sort
        when (sortOption) {
            SortOption.NEWEST -> result.sortByDescending { it.createdAt ?: "" }
            SortOption.HIGHEST_RATED -> result.sortByDescending { it.overallRating }
            SortOption.MOST_RATED -> result.sortByDescending { it.ratingCount ?: 0 }
            SortOption.NEAREST -> {
                userLocation?.let { loc ->
                    result.sortBy { road ->
                        road.centerCoordinate?.let { center ->
                            val results = FloatArray(1)
                            Location.distanceBetween(
                                loc.latitude, loc.longitude,
                                center.latitude, center.longitude,
                                results
                            )
                            results[0]
                        } ?: Float.MAX_VALUE
                    }
                }
            }
        }

        result
    }

    val myRoadsCount = roads.count { it.isMyRoad(deviceId) }

    val averageRating = remember(filteredRoads) {
        val ratingsWithValues = filteredRoads.filter { it.overallRating > 0 }
        if (ratingsWithValues.isEmpty()) 0.0 else ratingsWithValues.map { it.overallRating }.average()
    }

    val topRating = remember(filteredRoads) {
        filteredRoads.maxOfOrNull { it.overallRating } ?: 0.0
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Discover") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Theme.Background,
                    titleContentColor = Theme.TextPrimary
                )
            )
        },
        containerColor = Theme.Background
    ) { padding ->
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Search bar
            item {
                OutlinedTextField(
                    value = searchText,
                    onValueChange = { searchText = it },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    placeholder = { Text("Search roads...") },
                    leadingIcon = {
                        Icon(Icons.Default.Search, contentDescription = null)
                    },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Theme.Primary,
                        unfocusedBorderColor = Theme.Surface
                    ),
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp)
                )
            }

            // Stats Header
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    StatCard(
                        title = if (roadFilter == RoadFilter.MY_ROADS) "My Roads" else "All Roads",
                        value = "${filteredRoads.size}",
                        icon = if (roadFilter == RoadFilter.MY_ROADS) Icons.Default.Person else Icons.Default.LinearScale,
                        color = Color(0xFF3B82F6),
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        title = "Avg Rating",
                        value = String.format("%.1f", averageRating),
                        icon = Icons.Default.Star,
                        color = Color(0xFFEAB308),
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        title = "Top Rated",
                        value = String.format("%.1f", topRating),
                        icon = Icons.Default.EmojiEvents,
                        color = Theme.Orange,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // Filter Pills
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Road Filter
                    RoadFilter.entries.forEach { filter ->
                        val title = if (filter == RoadFilter.MY_ROADS) {
                            "${filter.title} ($myRoadsCount)"
                        } else filter.title
                        FilterPill(
                            title = title,
                            isSelected = roadFilter == filter,
                            icon = if (filter == RoadFilter.MY_ROADS) Icons.Default.Person else Icons.Default.Public,
                            onClick = {
                                roadFilter = filter
                                HapticManager.selection()
                            }
                        )
                    }

                    Divider(
                        modifier = Modifier
                            .height(24.dp)
                            .width(1.dp)
                            .padding(horizontal = 4.dp),
                        color = Theme.Surface
                    )

                    // Sort Options
                    SortOption.entries.forEach { option ->
                        FilterPill(
                            title = option.title,
                            isSelected = sortOption == option,
                            onClick = {
                                sortOption = option
                                HapticManager.selection()
                            }
                        )
                    }

                    Divider(
                        modifier = Modifier
                            .height(24.dp)
                            .width(1.dp)
                            .padding(horizontal = 4.dp),
                        color = Theme.Surface
                    )

                    // Rating Filter
                    FilterPill(
                        title = if (filterRating > 0) "${filterRating.toInt()}+ Stars" else "All Ratings",
                        isSelected = filterRating > 0,
                        icon = Icons.Default.Star,
                        onClick = {
                            filterRating = if (filterRating >= 4) 0f else filterRating + 1
                            HapticManager.selection()
                        }
                    )
                }
            }

            // Road Cards or Empty State
            if (filteredRoads.isEmpty()) {
                item {
                    EmptyState(
                        isMyRoads = roadFilter == RoadFilter.MY_ROADS,
                        onDrawRoadClick = onDrawRoadClick
                    )
                }
            } else {
                items(filteredRoads, key = { it.id }) { road ->
                    RoadCard(
                        road = road,
                        isMyRoad = road.isMyRoad(deviceId),
                        onClick = { onRoadSelected(road) },
                        onMapClick = {
                            // When map is clicked, navigate to map via onDrawRoadClick to switch tabs
                            // In a real implementation we'd pass the specific road ID to center on
                            // For now, we'll just switch to map tab
                            onDrawRoadClick()
                        },
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun StatCard(
    title: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Theme.Surface.copy(alpha = 0.5f))
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(24.dp)
        )
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

@Composable
private fun FilterPill(
    title: String,
    isSelected: Boolean,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(if (isSelected) Theme.Primary else Theme.Surface.copy(alpha = 0.5f))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (isSelected) Color.White else Theme.TextPrimary,
                modifier = Modifier.size(14.dp)
            )
        }
        Text(
            text = title,
            color = if (isSelected) Color.White else Theme.TextPrimary,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            fontSize = 14.sp
        )
    }
}

@Composable
private fun EmptyState(
    isMyRoads: Boolean,
    onDrawRoadClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = if (isMyRoads) Icons.Default.PersonSearch else Icons.Default.LinearScale,
            contentDescription = null,
            tint = Theme.TextMuted,
            modifier = Modifier.size(60.dp)
        )
        Text(
            text = if (isMyRoads) "No Roads Yet" else "No Roads Found",
            color = Theme.TextPrimary,
            fontWeight = FontWeight.SemiBold,
            fontSize = 20.sp
        )
        Text(
            text = if (isMyRoads)
                "You haven't added any roads yet. Start by drawing your first road!"
            else
                "Try adjusting your filters or be the first to add a road!",
            color = Theme.TextSecondary,
            fontSize = 14.sp,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
        Button(
            onClick = {
                onDrawRoadClick()
                HapticManager.buttonTap()
            },
            colors = ButtonDefaults.buttonColors(containerColor = Theme.Primary)
        ) {
            Icon(Icons.Default.Edit, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Draw a Road")
        }
    }
}

@Composable
private fun RoadCard(
    road: Road,
    isMyRoad: Boolean,
    onClick: () -> Unit,
    onMapClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Theme.BackgroundSecondary)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onClick), // Make header clickable
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = road.displayName,
                            color = Theme.TextPrimary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 16.sp
                        )
                        if (isMyRoad) {
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(50))
                                    .background(Theme.Primary)
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = "My Road",
                                    color = Color.White,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    }
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.LinearScale,
                                contentDescription = null,
                                tint = Theme.TextSecondary,
                                modifier = Modifier.size(14.dp)
                            )
                            Text(
                                text = road.formattedDistance,
                                color = Theme.TextSecondary,
                                fontSize = 12.sp
                            )
                        }
                        road.ratingCount?.takeIf { it > 0 }?.let { count ->
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.People,
                                    contentDescription = null,
                                    tint = Theme.TextSecondary,
                                    modifier = Modifier.size(14.dp)
                                )
                                Text(
                                    text = "$count",
                                    color = Theme.TextSecondary,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }
                }

                // Rating Badge
                if (road.overallRating > 0) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        Text(
                            text = String.format("%.1f", road.overallRating),
                            color = road.ratingColor.color,
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(1.dp)) {
                            repeat(5) { index ->
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .clip(CircleShape)
                                        .background(
                                            if (index < road.overallRating.toInt())
                                                road.ratingColor.color
                                            else
                                                Theme.Surface
                                        )
                                )
                            }
                        }
                    }
                }
            }

            // Rating Categories Preview
            if ((road.ratingCount ?: 0) > 0) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(onClick = onClick), // Make stats clickable
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    CategoryPreview(RatingCategory.TWISTINESS, road.avgTwistiness ?: 0.0)
                    CategoryPreview(RatingCategory.SURFACE_CONDITION, road.avgSurfaceCondition ?: 0.0)
                    CategoryPreview(RatingCategory.FUN_FACTOR, road.avgFunFactor ?: 0.0)
                    CategoryPreview(RatingCategory.SCENERY, road.avgScenery ?: 0.0)
                    CategoryPreview(RatingCategory.VISIBILITY, road.avgVisibility ?: 0.0)
                }
            }

            // Mini Map Preview
            // Map click takes you to map tab
            Box(modifier = Modifier.clickable(onClick = onMapClick)) {
                MiniMapView(
                    coordinates = road.coordinates,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(100.dp)
                        .clip(RoundedCornerShape(12.dp))
                )
            }
        }
    }
}

@Composable
private fun CategoryPreview(
    category: RatingCategory,
    value: Double
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        RatingCategoryIcon(category = category, size = 14)
        Text(
            text = String.format("%.1f", value),
            color = Theme.TextPrimary,
            fontWeight = FontWeight.SemiBold,
            fontSize = 10.sp
        )
    }
}

@Composable
private fun MiniMapView(
    coordinates: List<LatLng>,
    modifier: Modifier = Modifier
) {
    if (coordinates.size < 2) {
        Box(
            modifier = modifier.background(Theme.Surface),
            contentAlignment = Alignment.Center
        ) {
            Text("No path data", color = Theme.TextMuted, fontSize = 12.sp)
        }
        return
    }

    val center = coordinates[coordinates.size / 2]
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(center, 12f)
    }

    GoogleMap(
        modifier = modifier,
        cameraPositionState = cameraPositionState,
        uiSettings = MapUiSettings(
            zoomControlsEnabled = false,
            scrollGesturesEnabled = false,
            zoomGesturesEnabled = false,
            tiltGesturesEnabled = false,
            rotationGesturesEnabled = false,
            compassEnabled = false,
            mapToolbarEnabled = false,
            myLocationButtonEnabled = false
        )
    ) {
        Polyline(
            points = coordinates,
            color = Theme.Primary,
            width = 6f
        )
    }
}
