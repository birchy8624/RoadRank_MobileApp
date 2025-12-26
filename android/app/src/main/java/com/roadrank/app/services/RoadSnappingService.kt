package com.roadrank.app.services

import com.roadrank.app.data.Coordinate
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Road Snapping Service using OSRM
 */
object RoadSnappingService {
    private const val OSRM_BASE_URL = "https://router.project-osrm.org"

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val client = HttpClient(Android) {
        install(ContentNegotiation) {
            json(json)
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 30000
            connectTimeoutMillis = 30000
        }
    }

    @Serializable
    private data class OSRMResponse(
        val code: String,
        val matchings: List<Matching>? = null
    )

    @Serializable
    private data class Matching(
        val geometry: Geometry? = null
    )

    @Serializable
    private data class Geometry(
        val coordinates: List<List<Double>>? = null
    )

    suspend fun snapToRoad(path: List<Coordinate>): Result<List<Coordinate>> = runCatching {
        if (path.size < 2) {
            return@runCatching path
        }

        // Build coordinates string for OSRM
        val coordsString = path.joinToString(";") { "${it.lng},${it.lat}" }

        val response: OSRMResponse = client.get(
            "$OSRM_BASE_URL/match/v1/driving/$coordsString"
        ) {
            parameter("overview", "full")
            parameter("geometries", "geojson")
            parameter("radiuses", path.joinToString(";") { "50" })
        }.body()

        if (response.code != "Ok") {
            return@runCatching path // Return original path if snapping fails
        }

        val coordinates = response.matchings?.firstOrNull()?.geometry?.coordinates

        if (coordinates.isNullOrEmpty()) {
            return@runCatching path
        }

        // Convert [lng, lat] to Coordinate
        coordinates.map { coord ->
            Coordinate(lat = coord[1], lng = coord[0])
        }
    }
}
