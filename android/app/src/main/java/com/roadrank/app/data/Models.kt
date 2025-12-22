package com.roadrank.app.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Coordinate(
    val lat: Double,
    val lng: Double
)

@Serializable
data class RatingSummary(
    @SerialName("rating_count") val ratingCount: Int? = null,
    @SerialName("avg_twistiness") val avgTwistiness: Double? = null,
    @SerialName("avg_surface_condition") val avgSurfaceCondition: Double? = null,
    @SerialName("avg_fun_factor") val avgFunFactor: Double? = null,
    @SerialName("avg_scenery") val avgScenery: Double? = null,
    @SerialName("avg_visibility") val avgVisibility: Double? = null,
    @SerialName("avg_overall") val avgOverall: Double? = null
)

@Serializable
data class Road(
    @Serializable(with = StringOrIntSerializer::class)
    val id: String,
    val name: String? = null,
    val path: List<Coordinate> = emptyList(),
    val twistiness: Int? = null,
    @SerialName("surface_condition") val surfaceCondition: Int? = null,
    @SerialName("fun_factor") val funFactor: Int? = null,
    val scenery: Int? = null,
    val visibility: Int? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("rating_summary") val ratingSummary: RatingSummary? = null,
    @SerialName("device_id") val deviceId: String? = null
) {
    val displayName: String = name ?: "Unnamed Road"

    val overallRating: Double
        get() = ratingSummary?.avgOverall
            ?: listOf(twistiness, surfaceCondition, funFactor, scenery, visibility)
                .filterNotNull()
                .takeIf { it.isNotEmpty() }
                ?.average()
            ?: 0.0

    val ratingCount: Int? = ratingSummary?.ratingCount

    val isMine: Boolean
        get() = deviceId == DeviceIdManager.deviceId
}

@Serializable
data class Rating(
    @Serializable(with = StringOrIntSerializer::class)
    val id: String? = null,
    @SerialName("road_id") @Serializable(with = StringOrIntSerializer::class)
    val roadId: String,
    val twistiness: Int,
    @SerialName("surface_condition") val surfaceCondition: Int,
    @SerialName("fun_factor") val funFactor: Int,
    val scenery: Int,
    val visibility: Int,
    val comment: String? = null,
    val warnings: List<RoadWarning>? = null,
    @SerialName("device_id") val deviceId: String? = null,
    @SerialName("created_at") val createdAt: String? = null
) {
    val overallRating: Double
        get() = (twistiness + surfaceCondition + funFactor + scenery + visibility) / 5.0
}

@Serializable
enum class RoadWarning {
    @SerialName("speed_camera") SPEED_CAMERA,
    @SerialName("potholes") POTHOLES,
    @SerialName("traffic") TRAFFIC
}

enum class RatingCategory(val title: String, val icon: String, val lowLabel: String, val highLabel: String) {
    TWISTINESS("Twistiness", "\uD83D\uDD01", "Straight", "Very Twisty"),
    SURFACE("Surface Condition", "\uD83D\uDEE3\uFE0F", "Poor", "Excellent"),
    FUN("Fun Factor", "\u26A1", "Boring", "Thrilling"),
    SCENERY("Scenery", "\uD83C\uDFD4\uFE0F", "Plain", "Stunning"),
    VISIBILITY("Visibility", "\uD83D\uDC41\uFE0F", "Limited", "Clear")
}
