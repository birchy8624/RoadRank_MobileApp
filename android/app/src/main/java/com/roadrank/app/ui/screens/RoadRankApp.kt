package com.roadrank.app.ui.screens

import android.location.Location
import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.model.LatLng
import com.roadrank.app.data.*
import com.roadrank.app.services.*
import com.roadrank.app.ui.components.*
import com.roadrank.app.ui.theme.Theme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.Timer
import kotlin.concurrent.fixedRateTimer

/**
 * App Screen enum
 */
enum class AppScreen {
    SPLASH,
    ONBOARDING,
    MAIN,
    RIDE_TRACKING
}

/**
 * Toast data class
 */
data class ToastData(
    val message: String,
    val type: ToastType
)

/**
 * Main RoadRank App Composable - matching iOS ContentView
 */
@Composable
fun RoadRankApp() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // Initialize services
    LaunchedEffect(Unit) {
        DeviceManager.init(context)
        HapticManager.init(context)
    }

    // App state
    var currentScreen by remember { mutableStateOf(AppScreen.SPLASH) }
    var selectedTab by remember { mutableStateOf(Tab.MAP) }

    // Road data
    var roads by remember { mutableStateOf<List<Road>>(emptyList()) }
    var isLoadingRoads by remember { mutableStateOf(false) }
    var selectedRoad by remember { mutableStateOf<Road?>(null) }

    // Drawing state
    var isDrawingMode by remember { mutableStateOf(false) }
    var drawnPath by remember { mutableStateOf<List<Coordinate>>(emptyList()) }
    var snappedPath by remember { mutableStateOf<List<Coordinate>?>(null) }
    var isSnapping by remember { mutableStateOf(false) }
    var showRatingSheet by remember { mutableStateOf(false) }
    var isSubmittingRating by remember { mutableStateOf(false) }

    // Ride tracking state
    var currentRide by remember { mutableStateOf<Ride?>(null) }
    var rideState by remember { mutableStateOf<RideState>(RideState.Idle) }
    var currentSpeed by remember { mutableDoubleStateOf(0.0) }
    var elapsedTime by remember { mutableLongStateOf(0L) }
    var rideDistance by remember { mutableDoubleStateOf(0.0) }
    var rideTimer by remember { mutableStateOf<Timer?>(null) }
    var rideStartTime by remember { mutableLongStateOf(0L) }

    // Location
    var userLocation by remember { mutableStateOf<Location?>(null) }
    val fusedLocationClient = remember { LocationServices.getFusedLocationProviderClient(context) }

    // Toast
    var currentToast by remember { mutableStateOf<ToastData?>(null) }

    // Fetch roads on start
    LaunchedEffect(Unit) {
        isLoadingRoads = true
        ApiClient.fetchRoads()
            .onSuccess { roads = it }
            .onFailure { /* Handle error */ }
        isLoadingRoads = false
    }

    // Fetch user location
    LaunchedEffect(Unit) {
        try {
            userLocation = fusedLocationClient.lastLocation.await()
        } catch (e: Exception) {
            // Location not available
        }
    }

    // Toast auto-dismiss
    LaunchedEffect(currentToast) {
        if (currentToast != null) {
            delay(3000)
            currentToast = null
        }
    }

    fun showToast(message: String, type: ToastType) {
        currentToast = ToastData(message, type)
    }

    fun refreshRoads() {
        scope.launch {
            isLoadingRoads = true
            ApiClient.fetchRoads()
                .onSuccess { roads = it }
                .onFailure { showToast("Failed to load roads", ToastType.ERROR) }
            isLoadingRoads = false
        }
    }

    fun startDrawing() {
        isDrawingMode = true
        drawnPath = emptyList()
        snappedPath = null
        HapticManager.buttonTap()
    }

    fun stopDrawing() {
        isDrawingMode = false
    }

    fun clearDrawing() {
        drawnPath = emptyList()
        snappedPath = null
    }

    fun addPoint(coordinate: Coordinate) {
        drawnPath = drawnPath + coordinate
    }

    fun snapAndRate() {
        scope.launch {
            isSnapping = true
            RoadSnappingService.snapToRoad(drawnPath)
                .onSuccess {
                    snappedPath = it
                    isSnapping = false
                    showRatingSheet = true
                }
                .onFailure {
                    isSnapping = false
                    showToast("Failed to snap road", ToastType.ERROR)
                }
        }
    }

    fun submitNewRoad(
        name: String,
        twistiness: Int,
        surfaceCondition: Int,
        funFactor: Int,
        scenery: Int,
        visibility: Int,
        warnings: List<RoadWarning>,
        comment: String
    ) {
        scope.launch {
            isSubmittingRating = true
            val input = NewRoadInput(
                name = name,
                path = snappedPath ?: drawnPath,
                twistiness = twistiness,
                surfaceCondition = surfaceCondition,
                funFactor = funFactor,
                scenery = scenery,
                visibility = visibility,
                comment = comment,
                warnings = warnings,
                deviceId = DeviceManager.deviceId
            )

            ApiClient.createRoad(input)
                .onSuccess {
                    HapticManager.success()
                    showToast("Road created successfully!", ToastType.SUCCESS)
                    showRatingSheet = false
                    stopDrawing()
                    clearDrawing()
                    refreshRoads()
                }
                .onFailure {
                    HapticManager.error()
                    showToast("Failed to create road", ToastType.ERROR)
                }
            isSubmittingRating = false
        }
    }

    fun submitRating(
        road: Road,
        twistiness: Int,
        surfaceCondition: Int,
        funFactor: Int,
        scenery: Int,
        visibility: Int,
        warnings: List<RoadWarning>,
        comment: String
    ) {
        scope.launch {
            isSubmittingRating = true
            val input = NewRatingInput(
                roadId = road.id,
                twistiness = twistiness,
                surfaceCondition = surfaceCondition,
                funFactor = funFactor,
                scenery = scenery,
                visibility = visibility,
                comment = comment,
                warnings = warnings,
                deviceId = DeviceManager.deviceId
            )

            ApiClient.submitRating(input)
                .onSuccess {
                    HapticManager.success()
                    showToast("Rating submitted!", ToastType.SUCCESS)
                    showRatingSheet = false
                    selectedRoad = null
                    refreshRoads()
                }
                .onFailure {
                    HapticManager.error()
                    showToast("Failed to submit rating", ToastType.ERROR)
                }
            isSubmittingRating = false
        }
    }

    fun startRide() {
        rideStartTime = System.currentTimeMillis()
        currentRide = Ride(startTime = rideStartTime)
        rideState = RideState.Tracking
        currentSpeed = 0.0
        elapsedTime = 0L
        rideDistance = 0.0

        rideTimer = fixedRateTimer(period = 1000L) {
            elapsedTime = System.currentTimeMillis() - rideStartTime
        }

        currentScreen = AppScreen.RIDE_TRACKING
        HapticManager.success()
    }

    fun pauseRide() {
        rideState = RideState.Paused
        rideTimer?.cancel()
        rideTimer = null
        HapticManager.impact(HapticManager.ImpactStyle.MEDIUM)
    }

    fun resumeRide() {
        rideState = RideState.Tracking
        rideTimer = fixedRateTimer(period = 1000L) {
            elapsedTime = System.currentTimeMillis() - rideStartTime
        }
        HapticManager.impact(HapticManager.ImpactStyle.MEDIUM)
    }

    fun stopRide() {
        rideTimer?.cancel()
        rideTimer = null
        currentRide?.let {
            it.endTime = System.currentTimeMillis()
            // Could save ride or transition to summary
            rideState = RideState.Finished(it)
        }

        // For now, just return to main
        currentScreen = AppScreen.MAIN
        currentRide = null
        rideState = RideState.Idle
        HapticManager.success()
        showToast("Ride saved!", ToastType.SUCCESS)
    }

    fun cancelRide() {
        rideTimer?.cancel()
        rideTimer = null
        currentRide = null
        rideState = RideState.Idle
        currentSpeed = 0.0
        elapsedTime = 0L
        rideDistance = 0.0
        currentScreen = AppScreen.MAIN
        HapticManager.warning()
    }

    // Main UI
    Box(modifier = Modifier.fillMaxSize()) {
        when (currentScreen) {
            AppScreen.SPLASH -> {
                SplashScreen(
                    onSplashComplete = {
                        // Check if onboarding needed (first launch)
                        val prefs = context.getSharedPreferences("roadrank_prefs", 0)
                        val hasSeenOnboarding = prefs.getBoolean("has_seen_onboarding", false)
                        currentScreen = if (hasSeenOnboarding) AppScreen.MAIN else AppScreen.ONBOARDING
                    }
                )
            }

            AppScreen.ONBOARDING -> {
                OnboardingScreen(
                    onOnboardingComplete = {
                        val prefs = context.getSharedPreferences("roadrank_prefs", 0)
                        prefs.edit().putBoolean("has_seen_onboarding", true).apply()
                        currentScreen = AppScreen.MAIN
                    }
                )
            }

            AppScreen.MAIN -> {
                MainContent(
                    selectedTab = selectedTab,
                    onTabSelected = { selectedTab = it },
                    roads = roads,
                    userLocation = userLocation,
                    isDrawingMode = isDrawingMode,
                    drawnPath = drawnPath,
                    snappedPath = snappedPath,
                    isSnapping = isSnapping,
                    onStartDrawing = ::startDrawing,
                    onStopDrawing = ::stopDrawing,
                    onClearDrawing = ::clearDrawing,
                    onAddPoint = ::addPoint,
                    onSnapAndRate = ::snapAndRate,
                    onStartRide = ::startRide,
                    onRoadSelected = { road ->
                        selectedRoad = road
                        showRatingSheet = true
                    },
                    onDrawRoadClick = {
                        selectedTab = Tab.MAP
                        startDrawing()
                    },
                    onRefresh = ::refreshRoads
                )
            }

            AppScreen.RIDE_TRACKING -> {
                RideTrackingScreen(
                    currentRide = currentRide,
                    rideState = rideState,
                    currentSpeed = currentSpeed,
                    elapsedTime = elapsedTime,
                    rideDistance = rideDistance,
                    userLocation = userLocation?.let { LatLng(it.latitude, it.longitude) },
                    onPauseRide = ::pauseRide,
                    onResumeRide = ::resumeRide,
                    onStopRide = ::stopRide,
                    onCancelRide = ::cancelRide
                )
            }
        }

        // Rating Sheet
        if (showRatingSheet) {
            RatingSheet(
                road = selectedRoad,
                drawnPath = snappedPath ?: drawnPath,
                isLoading = isSubmittingRating,
                onSubmit = { name, twistiness, surfaceCondition, funFactor, scenery, visibility, warnings, comment ->
                    if (selectedRoad != null) {
                        submitRating(selectedRoad!!, twistiness, surfaceCondition, funFactor, scenery, visibility, warnings, comment)
                    } else if (name != null) {
                        submitNewRoad(name, twistiness, surfaceCondition, funFactor, scenery, visibility, warnings, comment)
                    }
                },
                onDismiss = {
                    showRatingSheet = false
                    selectedRoad = null
                }
            )
        }

        // Toast
        AnimatedVisibility(
            visible = currentToast != null,
            enter = slideInVertically { -it } + fadeIn(),
            exit = slideOutVertically { -it } + fadeOut(),
            modifier = Modifier
                .align(Alignment.TopCenter)
                .statusBarsPadding()
        ) {
            currentToast?.let { toast ->
                BrandedToast(
                    message = toast.message,
                    type = toast.type
                )
            }
        }
    }
}

@Composable
private fun MainContent(
    selectedTab: Tab,
    onTabSelected: (Tab) -> Unit,
    roads: List<Road>,
    userLocation: Location?,
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
    onDrawRoadClick: () -> Unit,
    onRefresh: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Screen content based on selected tab
        when (selectedTab) {
            Tab.MAP -> MapScreen(
                roads = roads,
                isDrawingMode = isDrawingMode,
                drawnPath = drawnPath,
                snappedPath = snappedPath,
                isSnapping = isSnapping,
                onStartDrawing = onStartDrawing,
                onStopDrawing = onStopDrawing,
                onClearDrawing = onClearDrawing,
                onAddPoint = onAddPoint,
                onSnapAndRate = onSnapAndRate,
                onStartRide = onStartRide,
                onRoadSelected = onRoadSelected,
                onSearchClick = { /* TODO: Implement search */ }
            )

            Tab.DISCOVER -> DiscoverScreen(
                roads = roads,
                userLocation = userLocation,
                onRoadSelected = onRoadSelected,
                onDrawRoadClick = onDrawRoadClick,
                onRefresh = onRefresh
            )

            Tab.PROFILE -> ProfileScreen(
                roads = roads
            )
        }

        // Tab Bar
        BrandedTabBar(
            selectedTab = selectedTab,
            onTabSelected = onTabSelected,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
        )
    }
}
