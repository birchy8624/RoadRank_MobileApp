package com.roadrank.app.ui.screens

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.roadrank.app.data.ApiClient
import com.roadrank.app.data.DeviceIdManager
import com.roadrank.app.data.NewRatingInput
import com.roadrank.app.data.NewRoadInput
import com.roadrank.app.data.Rating
import com.roadrank.app.data.Road
import com.roadrank.app.data.RoadWarning
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class RoadViewModel(application: Application) : AndroidViewModel(application) {
    private val apiClient = ApiClient()

    private val _roads = MutableStateFlow<List<Road>>(emptyList())
    val roads: StateFlow<List<Road>> = _roads

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    init {
        DeviceIdManager.init(application)
        fetchRoads()
    }

    fun fetchRoads() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                _roads.value = apiClient.fetchRoads()
            } catch (error: Exception) {
                _errorMessage.value = error.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun createRoad(
        name: String,
        path: List<com.roadrank.app.data.Coordinate>,
        twistiness: Int,
        surfaceCondition: Int,
        funFactor: Int,
        scenery: Int,
        visibility: Int,
        comment: String,
        warnings: List<RoadWarning>
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                val road = apiClient.createRoad(
                    NewRoadInput(
                        name = name,
                        path = path,
                        twistiness = twistiness,
                        surfaceCondition = surfaceCondition,
                        funFactor = funFactor,
                        scenery = scenery,
                        visibility = visibility,
                        comment = comment.ifBlank { null },
                        warnings = warnings,
                        deviceId = DeviceIdManager.deviceId
                    )
                )
                _roads.value = listOf(road) + _roads.value
            } catch (error: Exception) {
                _errorMessage.value = error.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun submitRating(
        roadId: String,
        twistiness: Int,
        surfaceCondition: Int,
        funFactor: Int,
        scenery: Int,
        visibility: Int,
        comment: String,
        warnings: List<RoadWarning>,
        onComplete: (Boolean) -> Unit
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            val result = try {
                apiClient.submitRating(
                    NewRatingInput(
                        roadId = roadId,
                        twistiness = twistiness,
                        surfaceCondition = surfaceCondition,
                        funFactor = funFactor,
                        scenery = scenery,
                        visibility = visibility,
                        comment = comment.ifBlank { null },
                        warnings = warnings,
                        deviceId = DeviceIdManager.deviceId
                    )
                )
                true
            } catch (error: Exception) {
                _errorMessage.value = error.message
                false
            } finally {
                _isLoading.value = false
            }
            if (result) {
                fetchRoads()
            }
            onComplete(result)
        }
    }

    fun fetchRatings(roadId: String, onComplete: (List<Rating>) -> Unit) {
        viewModelScope.launch {
            try {
                onComplete(apiClient.fetchRatings(roadId))
            } catch (error: Exception) {
                _errorMessage.value = error.message
                onComplete(emptyList())
            }
        }
    }
}
