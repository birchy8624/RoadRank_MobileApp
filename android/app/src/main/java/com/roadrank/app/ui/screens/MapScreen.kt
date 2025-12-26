package com.roadrank.app.ui.screens

import android.Manifest
import android.annotation.SuppressLint
import android.location.Address
import android.location.Geocoder
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.*
import com.google.maps.android.compose.*
import com.roadrank.app.data.*
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.components.*
import com.roadrank.app.ui.theme.Theme
import com.roadrank.app.ui.theme.ratingColor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.io.IOException
import java.util.Locale

/**
 * Map Screen matching iOS MapContainerView
 */
@OptIn(ExperimentalPermissionsApi::class, ExperimentalComposeUiApi::class)
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
    val scope = rememberCoroutineScope()
    val fusedLocationClient = remember { LocationServices.getFusedLocationProviderClient(context) }
    val geocoder = remember { Geocoder(context, Locale.getDefault()) }

    // Search state
    var isSearchActive by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<Address>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current

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

    // Perform search
    fun performSearch(query: String) {
        if (query.length < 3) return
        
        scope.launch {
            isSearching = true
            try {
                // Run geocoding on IO thread
                val results = withContext(Dispatchers.IO) {
                    try {
                        @Suppress("DEPRECATION")
                        geocoder.getFromLocationName(query, 5) ?: emptyList()
                    } catch (e: IOException) {
                        emptyList()
                    }
                }
                searchResults = results
            } catch (e: Exception) {
                searchResults = emptyList()
            } finally {
                isSearching = false
            }
        }
    }

    // Use rememberUpdatedState to ensure the content lambda always has the latest values
    val currentDrawnPath by rememberUpdatedState(drawnPath)
    val currentSnappedPath by rememberUpdatedState(snappedPath)
    val currentIsDrawingMode by rememberUpdatedState(isDrawingMode)

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
                if (currentIsDrawingMode) {
                    onAddPoint(Coordinate.from(latLng))
                    HapticManager.draw()
                } else if (isSearchActive) {
                    isSearchActive = false
                    keyboardController?.hide()
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
                            if (!isSearchActive) {
                                onRoadSelected(road)
                                HapticManager.buttonTap()
                            }
                        }
                    )
                }
            }

            // Render drawn path - use currentDrawnPath/currentSnappedPath for proper state updates
            val pathToRender = currentSnappedPath ?: currentDrawnPath
            val pathPoints = pathToRender.map { it.latLng }

            if (pathPoints.isNotEmpty()) {
                Polyline(
                    points = pathPoints,
                    color = Theme.Primary,
                    width = 10f,
                    pattern = if (currentSnappedPath == null) listOf(Dot(), Gap(10f)) else null
                )

                // Start marker
                Marker(
                    state = MarkerState(position = pathPoints.first()),
                    title = "Start",
                    icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_GREEN)
                )

                // End marker
                if (pathPoints.size > 1) {
                    Marker(
                        state = MarkerState(position = pathPoints.last()),
                        title = "End",
                        icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)
                    )
                }
            }
            
            // Search result marker
            if (isSearchActive && searchResults.isNotEmpty()) {
                searchResults.firstOrNull()?.let { address ->
                     Marker(
                        state = MarkerState(position = LatLng(address.latitude, address.longitude)),
                        title = address.featureName ?: address.getAddressLine(0),
                        icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE)
                    )
                }
            }
        }

        // Overlay Controls
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Top Bar with Search
            TopBar(
                isSearchActive = isSearchActive,
                searchQuery = searchQuery,
                onSearchQueryChange = { 
                    searchQuery = it
                    if (it.length > 2) performSearch(it)
                },
                onSearchActiveChange = { active ->
                    isSearchActive = active
                    if (active) {
                        // Clear previous search when activating
                        searchQuery = ""
                        searchResults = emptyList()
                    } else {
                        keyboardController?.hide()
                    }
                },
                focusRequester = focusRequester,
                onLocationClick = {
                    if (locationPermissions.allPermissionsGranted) {
                        scope.launch {
                            try {
                                @SuppressLint("MissingPermission")
                                val location = fusedLocationClient.lastLocation.await()
                                location?.let {
                                    cameraPositionState.animate(
                                        CameraUpdateFactory.newLatLngZoom(
                                            LatLng(it.latitude, it.longitude),
                                            15f
                                        )
                                    )
                                }
                                HapticManager.buttonTap()
                            } catch (e: Exception) {
                                // Handle error or ignore if location unavailable
                            }
                        }
                    } else {
                        locationPermissions.launchMultiplePermissionRequest()
                    }
                }
            )

            // Search Results List
            if (isSearchActive && (searchResults.isNotEmpty() || isSearching)) {
                SearchResultsList(
                    results = searchResults,
                    isSearching = isSearching,
                    onResultClick = { address ->
                        scope.launch {
                            val latLng = LatLng(address.latitude, address.longitude)
                            cameraPositionState.animate(
                                CameraUpdateFactory.newLatLngZoom(latLng, 15f)
                            )
                            // Keep search active but hide list or clear query? 
                            // Usually we might want to close search mode or just hide list
                            isSearchActive = false
                            keyboardController?.hide()
                            HapticManager.selection()
                        }
                    }
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom Controls (Hidden when searching)
            if (!isSearchActive) {
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
    isSearchActive: Boolean,
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit,
    onSearchActiveChange: (Boolean) -> Unit,
    focusRequester: FocusRequester,
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
        // Search Area
        Row(
            modifier = Modifier
                .weight(1f)
                .height(50.dp) // Fixed height to match buttons
                .clip(RoundedCornerShape(25.dp))
                .background(Theme.BackgroundSecondary.copy(alpha = 0.95f))
                .border(1.dp, Theme.CardBorder, RoundedCornerShape(25.dp))
                .clickable { if (!isSearchActive) onSearchActiveChange(true) }
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = Theme.Primary,
                modifier = Modifier.size(20.dp)
            )
            
            Spacer(modifier = Modifier.width(10.dp))

            if (isSearchActive) {
                // Active Search Field
                BasicTextField(
                    value = searchQuery,
                    onValueChange = onSearchQueryChange,
                    modifier = Modifier
                        .weight(1f)
                        .focusRequester(focusRequester),
                    textStyle = LocalTextStyle.current.copy(
                        color = Theme.TextPrimary,
                        fontSize = 16.sp
                    ),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = { /* Handled by auto-search */ }),
                    decorationBox = { innerTextField ->
                        Box(contentAlignment = Alignment.CenterStart) {
                            if (searchQuery.isEmpty()) {
                                Text(
                                    text = "Enter address or place...",
                                    color = Theme.TextSecondary,
                                    fontSize = 16.sp
                                )
                            }
                            innerTextField()
                        }
                    }
                )
                
                LaunchedEffect(Unit) {
                    focusRequester.requestFocus()
                }

                IconButton(
                    onClick = { onSearchActiveChange(false) },
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close Search",
                        tint = Theme.TextSecondary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            } else {
                // Inactive Search Placeholder
                Text(
                    text = "Search location...",
                    color = Theme.TextSecondary,
                    fontSize = 14.sp,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // Location Button (Only show when not searching or if there's room)
        if (!isSearchActive) {
            BrandedIconButton(
                icon = Icons.Default.MyLocation,
                onClick = onLocationClick,
                size = 50.dp, // Match height
                style = IconButtonStyle.SOLID
            )
        }
    }
}

@Composable
private fun SearchResultsList(
    results: List<Address>,
    isSearching: Boolean,
    onResultClick: (Address) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .heightIn(max = 300.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Theme.BackgroundSecondary),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        if (isSearching) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = Theme.Primary
                )
            }
        } else if (results.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No results found",
                    color = Theme.TextMuted,
                    fontSize = 14.sp
                )
            }
        } else {
            LazyColumn {
                items(results) { address ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onResultClick(address) }
                            .padding(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        Text(
                            text = address.featureName ?: address.getAddressLine(0),
                            color = Theme.TextPrimary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp,
                            maxLines = 1
                        )
                        val details = (0..address.maxAddressLineIndex).joinToString(", ") { address.getAddressLine(it) }
                        if (details.isNotEmpty() && details != address.featureName) {
                            Text(
                                text = details,
                                color = Theme.TextSecondary,
                                fontSize = 12.sp,
                                maxLines = 1
                            )
                        }
                    }
                    Divider(color = Theme.CardBorder)
                }
            }
        }
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
        modifier = Modifier.padding(bottom = 132.dp), // Increased padding to avoid overlap with tab bar
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
                    progress = 0.7f
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
