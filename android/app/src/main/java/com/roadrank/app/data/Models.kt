package com.roadrank.app.data

import android.location.Location
import androidx.compose.ui.graphics.Color
import com.google.android.gms.maps.model.LatLng
import com.roadrank.app.ui.theme.RatingCategoryColors
import com.roadrank.app.ui.theme.RatingColor
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.intOrNull
import java.util.UUID

/**
 * Custom serializer to handle id as either Int or String from API
 */
object FlexibleIdSerializer : KSerializer<String> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("FlexibleId", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: String) {
        encoder.encodeString(value)
    }

    override fun deserialize(decoder: Decoder): String {
        return when (val jsonDecoder = decoder as? JsonDecoder) {
            null -> decoder.decodeString()
            else -> {
                val element = jsonDecoder.decodeJsonElement()
                when (element) {
                    is JsonPrimitive -> {
                        element.intOrNull?.toString() ?: element.content
                    }
                    else -> element.toString()
                }
            }
        }
    }
}

/**
 * Coordinate data class matching iOS
 */
@Serializable
data class Coordinate(
    val lat: Double,
    val lng: Double
) {
    val latLng: LatLng
        get() = LatLng(lat, lng)

    companion object {
        fun from(latLng: LatLng) = Coordinate(latLng.latitude, latLng.longitude)
        fun from(location: Location) = Coordinate(location.latitude, location.longitude)
    }
}

/**
 * Rating Summary matching iOS
 */
@Serializable
data class RatingSummary(
    @SerialName("rating_count")
    val ratingCount: Int? = null,
    @SerialName("avg_twistiness")
    val avgTwistiness: Double? = null,
    @SerialName("avg_surface_condition")
    val avgSurfaceCondition: Double? = null,
    @SerialName("avg_fun_factor")
    val avgFunFactor: Double? = null,
    @SerialName("avg_scenery")
    val avgScenery: Double? = null,
    @SerialName("avg_visibility")
    val avgVisibility: Double? = null,
    @SerialName("avg_overall")
    val avgOverall: Double? = null
)

/**
 * Road model matching iOS
 */
@Serializable
data class Road(
    @SerialName("id")
    @Serializable(with = FlexibleIdSerializer::class)
    val id: String,
    val name: String? = null,
    val path: List<Coordinate>,
    val twistiness: Int? = null,
    @SerialName("surface_condition")
    val surfaceCondition: Int? = null,
    @SerialName("fun_factor")
    val funFactor: Int? = null,
    val scenery: Int? = null,
    val visibility: Int? = null,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("rating_summary")
    val ratingSummary: RatingSummary? = null,
    @SerialName("device_id")
    val deviceId: String? = null
) {
    val displayName: String
        get() = name ?: "Unnamed Road"

    val ratingCount: Int?
        get() = ratingSummary?.ratingCount

    val avgTwistiness: Double?
        get() = ratingSummary?.avgTwistiness

    val avgSurfaceCondition: Double?
        get() = ratingSummary?.avgSurfaceCondition

    val avgFunFactor: Double?
        get() = ratingSummary?.avgFunFactor

    val avgScenery: Double?
        get() = ratingSummary?.avgScenery

    val avgVisibility: Double?
        get() = ratingSummary?.avgVisibility

    val overallRating: Double
        get() {
            ratingSummary?.avgOverall?.let { return it }
            val ratings = listOfNotNull(
                avgTwistiness, avgSurfaceCondition, avgFunFactor, avgScenery, avgVisibility
            )
            return if (ratings.isEmpty()) 0.0 else ratings.average()
        }

    val ratingColor: RatingColor
        get() = RatingColor.fromRating(overallRating)

    val coordinates: List<LatLng>
        get() = path.map { it.latLng }

    val centerCoordinate: LatLng?
        get() {
            if (path.isEmpty()) return null
            val midIndex = path.size / 2
            return path[midIndex].latLng
        }

    val distanceInKm: Double
        get() {
            if (path.size < 2) return 0.0
            var totalDistance = 0.0
            for (i in 0 until path.size - 1) {
                val results = FloatArray(1)
                Location.distanceBetween(
                    path[i].lat, path[i].lng,
                    path[i + 1].lat, path[i + 1].lng,
                    results
                )
                totalDistance += results[0]
            }
            return totalDistance / 1000.0
        }

    val formattedDistance: String
        get() = String.format("%.1f km", distanceInKm)

    fun isMyRoad(myDeviceId: String): Boolean = deviceId == myDeviceId

    val shareUrl: String
        get() = "roadrank://road/$id"
}

/**
 * Rating model matching iOS
 */
@Serializable
data class Rating(
    @Serializable(with = FlexibleIdSerializer::class)
    val id: String? = null,
    @SerialName("road_id")
    @Serializable(with = FlexibleIdSerializer::class)
    val roadId: String? = null,  // Made nullable - GET ratings API doesn't always return this
    val twistiness: Int,
    @SerialName("surface_condition")
    val surfaceCondition: Int,
    @SerialName("fun_factor")
    val funFactor: Int,
    val scenery: Int,
    val visibility: Int,
    val comment: String? = null,
    val warnings: List<RoadWarning>? = null,
    @SerialName("device_id")
    val deviceId: String? = null,
    @SerialName("created_at")
    val createdAt: String? = null
) {
    val overallRating: Double
        get() = (twistiness + surfaceCondition + funFactor + scenery + visibility) / 5.0

    fun isMyRating(myDeviceId: String): Boolean = deviceId == myDeviceId
}

/**
 * Rating Category enum matching iOS
 */
enum class RatingCategory(
    val title: String,
    val icon: String,
    val lowDescription: String,
    val highDescription: String
) {
    TWISTINESS("Twistiness", "swap_horiz", "Straight", "Very Twisty"),
    SURFACE_CONDITION("Surface Condition", "road", "Poor", "Excellent"),
    FUN_FACTOR("Fun Factor", "bolt", "Boring", "Thrilling"),
    SCENERY("Scenery", "landscape", "Plain", "Stunning"),
    VISIBILITY("Visibility", "visibility", "Limited", "Clear");

    val color: Color
        get() = when (this) {
            TWISTINESS -> RatingCategoryColors.Twistiness
            SURFACE_CONDITION -> RatingCategoryColors.SurfaceCondition
            FUN_FACTOR -> RatingCategoryColors.FunFactor
            SCENERY -> RatingCategoryColors.Scenery
            VISIBILITY -> RatingCategoryColors.Visibility
        }
}

/**
 * Road Warnings enum matching iOS
 */
@Serializable
enum class RoadWarning(val title: String, val icon: String) {
    @SerialName("speed_camera")
    SPEED_CAMERA("Speed Cameras", "camera"),
    @SerialName("potholes")
    POTHOLES("Potholes", "warning"),
    @SerialName("traffic")
    TRAFFIC("Traffic", "car")
}

/**
 * New Road Input matching iOS
 */
data class NewRoadInput(
    var name: String = "",
    var path: List<Coordinate> = emptyList(),
    var twistiness: Int = 3,
    var surfaceCondition: Int = 3,
    var funFactor: Int = 3,
    var scenery: Int = 3,
    var visibility: Int = 3,
    var comment: String = "",
    var warnings: List<RoadWarning> = emptyList(),
    var deviceId: String = ""
) {
    val isValid: Boolean
        get() = name.trim().isNotEmpty() && path.size >= 2

    fun toPayload(): Map<String, Any?> = mapOf(
        "name" to name,
        "path" to path.map { mapOf("lat" to it.lat, "lng" to it.lng) },
        "twistiness" to twistiness,
        "surface_condition" to surfaceCondition,
        "fun_factor" to funFactor,
        "scenery" to scenery,
        "visibility" to visibility,
        "comment" to comment.ifEmpty { null },
        "warnings" to warnings.map { it.name.lowercase() },
        "device_id" to deviceId
    )
}

/**
 * New Rating Input matching iOS
 */
data class NewRatingInput(
    val roadId: String,
    var twistiness: Int = 3,
    var surfaceCondition: Int = 3,
    var funFactor: Int = 3,
    var scenery: Int = 3,
    var visibility: Int = 3,
    var comment: String = "",
    var warnings: List<RoadWarning> = emptyList(),
    var deviceId: String = ""
) {
    fun toPayload(): Map<String, Any?> = mapOf(
        "twistiness" to twistiness,
        "surface_condition" to surfaceCondition,
        "fun_factor" to funFactor,
        "scenery" to scenery,
        "visibility" to visibility,
        "comment" to comment.ifEmpty { null },
        "warnings" to warnings.map { it.name.lowercase() },
        "device_id" to deviceId
    )
}

/**
 * Ride Point matching iOS
 */
data class RidePoint(
    val id: String = UUID.randomUUID().toString(),
    val coordinate: Coordinate,
    val timestamp: Long = System.currentTimeMillis(),
    val speed: Double = 0.0,  // meters per second
    val altitude: Double? = null,
    val horizontalAccuracy: Float = 0f
) {
    val speedKmh: Double
        get() = speed * 3.6

    val formattedSpeed: String
        get() = String.format("%.1f km/h", speedKmh)

    companion object {
        fun from(location: Location) = RidePoint(
            coordinate = Coordinate.from(location),
            timestamp = location.time,
            speed = location.speed.toDouble().coerceAtLeast(0.0),
            altitude = if (location.hasAltitude()) location.altitude else null,
            horizontalAccuracy = location.accuracy
        )
    }
}

/**
 * Ride model matching iOS
 */
data class Ride(
    val id: String = UUID.randomUUID().toString(),
    val startTime: Long = System.currentTimeMillis(),
    var endTime: Long? = null,
    val path: MutableList<RidePoint> = mutableListOf()
) {
    val duration: Long
        get() = (endTime ?: System.currentTimeMillis()) - startTime

    val formattedDuration: String
        get() {
            val seconds = duration / 1000
            val hours = seconds / 3600
            val minutes = (seconds % 3600) / 60
            val secs = seconds % 60
            return if (hours > 0) {
                String.format("%d:%02d:%02d", hours, minutes, secs)
            } else {
                String.format("%02d:%02d", minutes, secs)
            }
        }

    val distanceInMeters: Double
        get() {
            if (path.size < 2) return 0.0
            var totalDistance = 0.0
            for (i in 0 until path.size - 1) {
                val results = FloatArray(1)
                Location.distanceBetween(
                    path[i].coordinate.lat, path[i].coordinate.lng,
                    path[i + 1].coordinate.lat, path[i + 1].coordinate.lng,
                    results
                )
                totalDistance += results[0]
            }
            return totalDistance
        }

    val distanceInKm: Double
        get() = distanceInMeters / 1000.0

    val formattedDistance: String
        get() = if (distanceInKm < 1) {
            String.format("%.0f m", distanceInMeters)
        } else {
            String.format("%.2f km", distanceInKm)
        }

    val averageSpeedKmh: Double
        get() {
            if (duration <= 0) return 0.0
            val hours = duration / 3600000.0
            return distanceInKm / hours
        }

    val formattedAverageSpeed: String
        get() = String.format("%.1f km/h", averageSpeedKmh)

    val maxSpeedKmh: Double
        get() = path.maxOfOrNull { it.speedKmh } ?: 0.0

    val formattedMaxSpeed: String
        get() = String.format("%.1f km/h", maxSpeedKmh)

    val coordinates: List<Coordinate>
        get() = path.map { it.coordinate }

    val latLngCoordinates: List<LatLng>
        get() = path.map { it.coordinate.latLng }

    val centerCoordinate: LatLng?
        get() {
            if (path.isEmpty()) return null
            val midIndex = path.size / 2
            return path[midIndex].coordinate.latLng
        }
}

/**
 * Ride state enum matching iOS
 */
sealed class RideState {
    object Idle : RideState()
    object Tracking : RideState()
    object Paused : RideState()
    data class Finished(val ride: Ride) : RideState()
}

/**
 * Extension to calculate total distance of coordinates
 */
fun List<Coordinate>.totalDistanceInKm(): Double {
    if (size < 2) return 0.0
    var totalDistance = 0.0
    for (i in 0 until size - 1) {
        val results = FloatArray(1)
        Location.distanceBetween(
            this[i].lat, this[i].lng,
            this[i + 1].lat, this[i + 1].lng,
            results
        )
        totalDistance += results[0]
    }
    return totalDistance / 1000.0
}
