package com.roadrank.app

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.roadrank.app.data.Road
import com.roadrank.app.ui.components.BrandedTabBar
import com.roadrank.app.ui.components.BrandedToast
import com.roadrank.app.ui.components.RatingSheet
import com.roadrank.app.ui.screens.DiscoverScreen
import com.roadrank.app.ui.screens.MapScreen
import com.roadrank.app.ui.screens.ProfileScreen
import com.roadrank.app.ui.screens.RoadViewModel
import com.roadrank.app.ui.theme.RoadRankColors

enum class RoadRankTab(val label: String, val icon: String) {
    MAP("Map", "\uD83D\uDDFA\uFE0F"),
    DISCOVER("Discover", "\uD83D\uDD0D"),
    PROFILE("Profile", "\uD83D\uDC64")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RoadRankApp(roadViewModel: RoadViewModel = viewModel()) {
    var selectedTab by remember { mutableStateOf(RoadRankTab.MAP) }
    var showRatingSheet by remember { mutableStateOf(false) }
    var roadToRate by remember { mutableStateOf<Road?>(null) }
    var toastMessage by remember { mutableStateOf<String?>(null) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(RoadRankColors.background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            when (selectedTab) {
                RoadRankTab.MAP -> MapScreen(
                    viewModel = roadViewModel,
                    onRateRoad = { road ->
                        roadToRate = road
                        showRatingSheet = true
                    },
                    onToast = { toastMessage = it }
                )
                RoadRankTab.DISCOVER -> DiscoverScreen(
                    viewModel = roadViewModel,
                    onRateRoad = { road ->
                        roadToRate = road
                        showRatingSheet = true
                    }
                )
                RoadRankTab.PROFILE -> ProfileScreen(viewModel = roadViewModel)
            }
        }

        BrandedTabBar(
            selectedTab = selectedTab,
            onTabSelected = { selectedTab = it },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 12.dp)
        )

        AnimatedVisibility(
            visible = toastMessage != null,
            modifier = Modifier.align(Alignment.TopCenter)
        ) {
            BrandedToast(
                message = toastMessage.orEmpty(),
                onDismiss = { toastMessage = null }
            )
        }
    }

    if (showRatingSheet) {
        ModalBottomSheet(
            onDismissRequest = { showRatingSheet = false },
            sheetState = sheetState,
            containerColor = RoadRankColors.backgroundSecondary
        ) {
            RatingSheet(
                road = roadToRate,
                onSubmit = { twistiness, surfaceCondition, funFactor, scenery, visibility, comment, warnings ->
                    val roadId = roadToRate?.id ?: return@RatingSheet
                    roadViewModel.submitRating(
                        roadId = roadId,
                        twistiness = twistiness,
                        surfaceCondition = surfaceCondition,
                        funFactor = funFactor,
                        scenery = scenery,
                        visibility = visibility,
                        comment = comment,
                        warnings = warnings
                    ) { ratingSubmitted ->
                        showRatingSheet = false
                        toastMessage = if (ratingSubmitted) {
                            "Thanks for rating!"
                        } else {
                            "Unable to submit rating."
                        }
                    }
                }
            )
        }
    }
}
