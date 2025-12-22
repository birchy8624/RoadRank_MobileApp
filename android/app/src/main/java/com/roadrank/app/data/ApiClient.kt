package com.roadrank.app.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

class ApiClient(
    private val baseUrl: String = "https://road-rank-mobile-app.vercel.app",
    private val httpClient: OkHttpClient = OkHttpClient()
) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun fetchRoads(): List<Road> = request("/api/roads")

    suspend fun createRoad(input: NewRoadInput): Road = request(
        path = "/api/roads",
        method = "POST",
        body = json.encodeToString(NewRoadInput.serializer(), input)
    )

    suspend fun fetchRatings(roadId: String): List<Rating> {
        val response: RatingsResponse = request("/api/roads/$roadId/ratings")
        return response.ratings
    }

    suspend fun submitRating(input: NewRatingInput): Rating {
        val response: RatingResponse = request(
            path = "/api/roads/${input.roadId}/ratings",
            method = "POST",
            body = json.encodeToString(NewRatingInput.serializer(), input)
        )
        return response.rating
    }

    private suspend inline fun <reified T> request(
        path: String,
        method: String = "GET",
        body: String? = null
    ): T = withContext(Dispatchers.IO) {
        val requestBuilder = Request.Builder()
            .url("$baseUrl$path")
            .addHeader("Accept", "application/json")
            .addHeader("Content-Type", "application/json")
            .addHeader("User-Agent", "RoadRank-Android/1.0")

        if (method != "GET" && body != null) {
            requestBuilder.method(method, body.toRequestBody("application/json".toMediaType()))
        }

        val response = httpClient.newCall(requestBuilder.build()).execute()
        if (!response.isSuccessful) {
            throw IOException("Server error: ${response.code} ${response.message}")
        }

        val payload = response.body?.string() ?: throw IOException("Empty response")
        json.decodeFromString(payload)
    }
}

@Serializable
data class NewRoadInput(
    val name: String,
    val path: List<Coordinate>,
    val twistiness: Int,
    @SerialName("surface_condition") val surfaceCondition: Int,
    @SerialName("fun_factor") val funFactor: Int,
    val scenery: Int,
    val visibility: Int,
    val comment: String? = null,
    val warnings: List<RoadWarning> = emptyList(),
    @SerialName("device_id") val deviceId: String
)

@Serializable
data class NewRatingInput(
    @SerialName("road_id") val roadId: String,
    val twistiness: Int,
    @SerialName("surface_condition") val surfaceCondition: Int,
    @SerialName("fun_factor") val funFactor: Int,
    val scenery: Int,
    val visibility: Int,
    val comment: String? = null,
    val warnings: List<RoadWarning> = emptyList(),
    @SerialName("device_id") val deviceId: String
)

@Serializable
data class RatingsResponse(
    val ratings: List<Rating> = emptyList(),
    val summary: RatingSummary? = null
)

@Serializable
data class RatingResponse(
    val rating: Rating,
    val summary: RatingSummary? = null
)
