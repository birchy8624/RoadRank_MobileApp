package com.roadrank.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.maps.model.CameraPosition
import com.google.maps.android.compose.*
import com.roadrank.app.data.*
import com.roadrank.app.services.ApiClient
import com.roadrank.app.services.HapticManager
import com.roadrank.app.ui.components.*
import com.roadrank.app.ui.theme.Theme
import kotlinx.coroutines.launch

/**
 * Rating Sheet matching iOS RatingSheetView
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RatingSheet(
    road: Road?,
    drawnPath: List<Coordinate>,
    isLoading: Boolean,
    onSubmit: (
        name: String?,
        twistiness: Int,
        surfaceCondition: Int,
        funFactor: Int,
        scenery: Int,
        visibility: Int,
        warnings: List<RoadWarning>,
        comment: String
    ) -> Unit,
    onDismiss: () -> Unit
) {
    val isNewRoad = road == null
    var roadName by remember { mutableStateOf("") }
    var twistiness by remember { mutableIntStateOf(3) }
    var surfaceCondition by remember { mutableIntStateOf(3) }
    var funFactor by remember { mutableIntStateOf(3) }
    var scenery by remember { mutableIntStateOf(3) }
    var visibility by remember { mutableIntStateOf(3) }
    var selectedWarnings by remember { mutableStateOf(setOf<RoadWarning>()) }
    var comment by remember { mutableStateOf("") }

    // Fetch ratings if it's an existing road
    var roadRatings by remember { mutableStateOf<List<Rating>>(emptyList()) }
    var isLoadingRatings by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(road) {
        if (road != null) {
            isLoadingRatings = true
            scope.launch {
                ApiClient.fetchRatings(road.id)
                    .onSuccess { ratings ->
                        roadRatings = ratings
                    }
                    .onFailure {
                        // Handle failure silently or show error
                    }
                isLoadingRatings = false
            }
        }
    }

    val isValid = if (isNewRoad) {
        roadName.trim().isNotEmpty() && drawnPath.size >= 2
    } else true

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Theme.Background,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isNewRoad) "New Road" else "Add Rating",
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 24.sp
                )
                IconButton(onClick = onDismiss) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Close",
                        tint = Theme.TextSecondary
                    )
                }
            }

            // Preview Section
            if (isNewRoad && drawnPath.isNotEmpty()) {
                MiniMapPreview(drawnPath = drawnPath)
            } else if (road != null) {
                RoadInfoHeader(road = road)
            }

            // Road Name (for new roads)
            if (isNewRoad) {
                RoadNameSection(
                    roadName = roadName,
                    onNameChange = { roadName = it }
                )
            }

            var isRatingMode by remember { mutableStateOf(isNewRoad) }

            if (!isRatingMode && road != null) {
                // VIEW MODE
                
                // Average Ratings Display
                AverageRatingsSection(road)

                // Comments List
                CommentsListSection(roadRatings, isLoadingRatings)

                // Button to switch to Rating Mode
                BrandedFullWidthButton(
                    text = "Rate this Road",
                    icon = Icons.Default.Star,
                    style = ButtonStyle.PRIMARY,
                    onClick = { 
                        isRatingMode = true 
                        HapticManager.selection()
                    }
                )
            } else {
                // RATING / CREATE MODE
                
                // Rating Sliders
                RatingSection(
                    twistiness = twistiness,
                    onTwistinessChange = { twistiness = it },
                    surfaceCondition = surfaceCondition,
                    onSurfaceConditionChange = { surfaceCondition = it },
                    funFactor = funFactor,
                    onFunFactorChange = { funFactor = it },
                    scenery = scenery,
                    onSceneryChange = { scenery = it },
                    visibility = visibility,
                    onVisibilityChange = { visibility = it }
                )

                // Warnings Section
                WarningsSection(
                    selectedWarnings = selectedWarnings,
                    onToggleWarning = { warning ->
                        selectedWarnings = if (selectedWarnings.contains(warning)) {
                            selectedWarnings - warning
                        } else {
                            selectedWarnings + warning
                        }
                        HapticManager.selection()
                    }
                )

                // Comment Input
                CommentSection(
                    comment = comment,
                    onCommentChange = { comment = it }
                )

                // Submit Button
                BrandedFullWidthButton(
                    text = if (isNewRoad) "Create Road" else "Submit Rating",
                    icon = if (isNewRoad) Icons.Default.Add else Icons.Default.Star,
                    style = if (isValid) ButtonStyle.PRIMARY else ButtonStyle.SECONDARY,
                    isLoading = isLoading,
                    enabled = isValid && !isLoading,
                    onClick = {
                        HapticManager.impact(HapticManager.ImpactStyle.MEDIUM)
                        onSubmit(
                            if (isNewRoad) roadName else null,
                            twistiness,
                            surfaceCondition,
                            funFactor,
                            scenery,
                            visibility,
                            selectedWarnings.toList(),
                            comment
                        )
                    }
                )
            }
        }
    }
}

@Composable
private fun AverageRatingsSection(road: Road) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.ShowChart,
                contentDescription = null,
                tint = Theme.Primary,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "Average Ratings",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }

        // Display average values (readonly)
        RatingDisplayRow(RatingCategory.TWISTINESS, road.avgTwistiness ?: 0.0)
        RatingDisplayRow(RatingCategory.SURFACE_CONDITION, road.avgSurfaceCondition ?: 0.0)
        RatingDisplayRow(RatingCategory.FUN_FACTOR, road.avgFunFactor ?: 0.0)
        RatingDisplayRow(RatingCategory.SCENERY, road.avgScenery ?: 0.0)
        RatingDisplayRow(RatingCategory.VISIBILITY, road.avgVisibility ?: 0.0)
    }
}

@Composable
private fun RatingDisplayRow(category: RatingCategory, value: Double) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            RatingCategoryIcon(category = category, size = 16)
            Text(
                text = category.title,
                color = Theme.TextSecondary,
                fontSize = 14.sp
            )
        }
        Text(
            text = String.format("%.1f", value),
            color = Theme.TextPrimary,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp
        )
    }
}

@Composable
private fun CommentsListSection(ratings: List<Rating>, isLoading: Boolean) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Comment,
                contentDescription = null,
                tint = Theme.Secondary,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "Comments",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }

        if (isLoading) {
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
        } else {
            val comments = ratings.filter { !it.comment.isNullOrBlank() }
            
            if (comments.isEmpty()) {
                 Text(
                    text = "No comments yet. Be the first to review!",
                    color = Theme.TextMuted,
                    fontSize = 14.sp,
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                )
            } else {
                 comments.forEachIndexed { index, rating ->
                     Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                         Row(
                             modifier = Modifier.fillMaxWidth(),
                             horizontalArrangement = Arrangement.SpaceBetween,
                             verticalAlignment = Alignment.Top
                         ) {
                             // Star rating for this comment
                             Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                                 repeat(5) { starIndex ->
                                     Icon(
                                         imageVector = if (starIndex < rating.overallRating.toInt()) Icons.Default.Star else Icons.Default.StarBorder,
                                         contentDescription = null,
                                         tint = if (starIndex < rating.overallRating.toInt()) Theme.Warning else Theme.TextMuted.copy(alpha = 0.3f),
                                         modifier = Modifier.size(12.dp)
                                     )
                                 }
                             }
                             
                             // Date (if available) - Assuming createdAt is a string
                             rating.createdAt?.let { dateStr ->
                                 // Simple date format or just show string
                                 // Ideally parse ISO string to readable date
                                 Text(
                                     text = dateStr.take(10), // Simple truncation for now
                                     color = Theme.TextMuted,
                                     fontSize = 10.sp
                                 )
                             }
                         }
                         
                         Text(
                             text = rating.comment ?: "",
                             color = Theme.TextPrimary,
                             fontSize = 14.sp
                         )
                     }
                     
                     if (index < comments.size - 1) {
                         Divider(color = Theme.CardBorder, modifier = Modifier.padding(vertical = 8.dp))
                     }
                 }
            }
        }
    }
}


@Composable
private fun MiniMapPreview(drawnPath: List<Coordinate>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
    ) {
        val center = drawnPath[drawnPath.size / 2]
        val cameraPositionState = rememberCameraPositionState {
            position = CameraPosition.fromLatLngZoom(center.latLng, 12f)
        }

        GoogleMap(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
                .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)),
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
                points = drawnPath.map { it.latLng },
                color = Theme.Primary,
                width = 8f
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.LinearScale,
                    contentDescription = null,
                    tint = Theme.Primary,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = String.format("%.2f km", drawnPath.totalDistanceInKm()),
                    color = Theme.TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp
                )
            }
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Timeline,
                    contentDescription = null,
                    tint = Theme.Secondary,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = "${drawnPath.size} points",
                    color = Theme.TextSecondary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp
                )
            }
        }
    }
}

@Composable
private fun RoadInfoHeader(road: Road) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = road.displayName,
            color = Theme.TextPrimary,
            fontWeight = FontWeight.Bold,
            fontSize = 20.sp
        )

        if (road.overallRating > 0) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = String.format("%.1f", road.overallRating),
                    color = road.ratingColor.color,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                )
                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                    repeat(5) { index ->
                        Icon(
                            imageVector = if (index < road.overallRating.toInt()) Icons.Default.Star else Icons.Default.StarBorder,
                            contentDescription = null,
                            tint = if (index < road.overallRating.toInt()) Theme.Warning else Theme.Surface,
                            modifier = Modifier.size(12.dp)
                        )
                    }
                }
                road.ratingCount?.let { count ->
                    Text(
                        text = "($count ratings)",
                        color = Theme.TextMuted,
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun RoadNameSection(
    roadName: String,
    onNameChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.TextFormat,
                contentDescription = null,
                tint = Theme.Primary,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "Road Name",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }

        OutlinedTextField(
            value = roadName,
            onValueChange = onNameChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Enter road name...") },
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Theme.Primary,
                unfocusedBorderColor = Theme.Surface,
                focusedContainerColor = Theme.Surface,
                unfocusedContainerColor = Theme.Surface
            ),
            singleLine = true,
            shape = RoundedCornerShape(12.dp)
        )

        Text(
            text = "Give your road a memorable name",
            color = Theme.TextMuted,
            fontSize = 12.sp
        )
    }
}

@Composable
private fun RatingSection(
    twistiness: Int,
    onTwistinessChange: (Int) -> Unit,
    surfaceCondition: Int,
    onSurfaceConditionChange: (Int) -> Unit,
    funFactor: Int,
    onFunFactorChange: (Int) -> Unit,
    scenery: Int,
    onSceneryChange: (Int) -> Unit,
    visibility: Int,
    onVisibilityChange: (Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Star,
                contentDescription = null,
                tint = Theme.Warning,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "Ratings",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }

        BrandedRatingSliderRow(
            category = RatingCategory.TWISTINESS,
            value = twistiness,
            onValueChange = onTwistinessChange
        )

        BrandedRatingSliderRow(
            category = RatingCategory.SURFACE_CONDITION,
            value = surfaceCondition,
            onValueChange = onSurfaceConditionChange
        )

        BrandedRatingSliderRow(
            category = RatingCategory.FUN_FACTOR,
            value = funFactor,
            onValueChange = onFunFactorChange
        )

        BrandedRatingSliderRow(
            category = RatingCategory.SCENERY,
            value = scenery,
            onValueChange = onSceneryChange
        )

        BrandedRatingSliderRow(
            category = RatingCategory.VISIBILITY,
            value = visibility,
            onValueChange = onVisibilityChange
        )
    }
}

@Composable
private fun WarningsSection(
    selectedWarnings: Set<RoadWarning>,
    onToggleWarning: (RoadWarning) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Warning,
                contentDescription = null,
                tint = Theme.Warning,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "Warnings",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }

        Text(
            text = "Tap any warnings that apply to this road.",
            color = Theme.TextMuted,
            fontSize = 12.sp
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            RoadWarning.entries.forEach { warning ->
                WarningToggleButton(
                    warning = warning,
                    isSelected = selectedWarnings.contains(warning),
                    onClick = { onToggleWarning(warning) }
                )
            }
        }
    }
}

@Composable
private fun WarningToggleButton(
    warning: RoadWarning,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val icon = when (warning) {
        RoadWarning.SPEED_CAMERA -> Icons.Default.CameraAlt
        RoadWarning.POTHOLES -> Icons.Default.Warning
        RoadWarning.TRAFFIC -> Icons.Default.DirectionsCar
    }

    Column(
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(if (isSelected) Theme.Warning.copy(alpha = 0.15f) else Theme.Surface),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = warning.title,
                tint = if (isSelected) Theme.Warning else Theme.TextMuted,
                modifier = Modifier.size(18.dp)
            )
        }
        Text(
            text = warning.title,
            color = if (isSelected) Theme.TextPrimary else Theme.TextMuted,
            fontSize = 10.sp,
            maxLines = 2,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}

@Composable
private fun CommentSection(
    comment: String,
    onCommentChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Theme.BackgroundSecondary)
            .border(1.dp, Theme.CardBorder, RoundedCornerShape(20.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Chat,
                contentDescription = null,
                tint = Theme.Secondary,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "Comment (Optional)",
                color = Theme.TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
        }

        OutlinedTextField(
            value = comment,
            onValueChange = onCommentChange,
            modifier = Modifier
                .fillMaxWidth()
                .height(100.dp),
            placeholder = { Text("Share your experience...") },
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Theme.Primary,
                unfocusedBorderColor = Theme.Surface,
                focusedContainerColor = Theme.Surface,
                unfocusedContainerColor = Theme.Surface
            ),
            shape = RoundedCornerShape(12.dp)
        )

        Text(
            text = "Share your experience driving this road",
            color = Theme.TextMuted,
            fontSize = 12.sp
        )
    }
}
