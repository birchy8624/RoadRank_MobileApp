package com.roadrank.app.services

import com.roadrank.app.data.NewRatingInput
import com.roadrank.app.data.NewRoadInput
import com.roadrank.app.data.Rating
import com.roadrank.app.data.RatingSummary
import com.roadrank.app.data.Road
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * API Client matching iOS
 */
object ApiClient {
    private const val BASE_URL = "https://road-rank-mobile-app.vercel.app"

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
    }

    private val client = HttpClient(Android) {
        install(ContentNegotiation) {
            json(json)
        }
        install(Logging) {
            level = LogLevel.INFO
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 30000
            connectTimeoutMillis = 30000
            socketTimeoutMillis = 30000
        }
        defaultRequest {
            contentType(ContentType.Application.Json)
            accept(ContentType.Application.Json)
            header("User-Agent", "RoadRank-Android/1.0")
        }
    }

    // Response wrappers matching iOS
    @Serializable
    private data class RatingsResponse(
        val ratings: List<Rating>,
        val summary: RatingSummary? = null
    )

    @Serializable
    private data class RatingResponse(
        val rating: Rating,
        val summary: RatingSummary? = null
    )

    suspend fun fetchRoads(): Result<List<Road>> = runCatching {
        client.get("$BASE_URL/api/roads").body<List<Road>>()
    }

    suspend fun createRoad(input: NewRoadInput): Result<Road> = runCatching {
        client.post("$BASE_URL/api/roads") {
            setBody(input.toPayload())
        }.body<Road>()
    }

    suspend fun fetchRatings(roadId: String): Result<List<Rating>> = runCatching {
        val response = client.get("$BASE_URL/api/roads/$roadId/ratings").body<RatingsResponse>()
        response.ratings
    }

    suspend fun submitRating(input: NewRatingInput): Result<Rating> = runCatching {
        val response = client.post("$BASE_URL/api/roads/${input.roadId}/ratings") {
            setBody(input.toPayload())
        }.body<RatingResponse>()
        response.rating
    }
}
