package com.roadrank.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.roadrank.app.data.Road
import com.roadrank.app.data.RoadWarning
import com.roadrank.app.data.RatingCategory
import com.roadrank.app.ui.theme.RoadRankColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RatingSheet(
    road: Road?,
    onSubmit: (
        twistiness: Int,
        surfaceCondition: Int,
        funFactor: Int,
        scenery: Int,
        visibility: Int,
        comment: String,
        warnings: List<RoadWarning>
    ) -> Unit,
    modifier: Modifier = Modifier
) {
    var twistiness by remember { mutableFloatStateOf(3f) }
    var surface by remember { mutableFloatStateOf(3f) }
    var funFactor by remember { mutableFloatStateOf(3f) }
    var scenery by remember { mutableFloatStateOf(3f) }
    var visibility by remember { mutableFloatStateOf(3f) }
    var comment by remember { mutableStateOf("") }
    var selectedWarnings by remember { mutableStateOf(setOf<RoadWarning>()) }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = road?.displayName ?: "Rate this road",
            style = MaterialTheme.typography.titleMedium,
            color = RoadRankColors.textPrimary
        )

        RatingSlider(
            title = RatingCategory.TWISTINESS.title,
            value = twistiness,
            onValueChange = { twistiness = it }
        )
        RatingSlider(
            title = RatingCategory.SURFACE.title,
            value = surface,
            onValueChange = { surface = it }
        )
        RatingSlider(
            title = RatingCategory.FUN.title,
            value = funFactor,
            onValueChange = { funFactor = it }
        )
        RatingSlider(
            title = RatingCategory.SCENERY.title,
            value = scenery,
            onValueChange = { scenery = it }
        )
        RatingSlider(
            title = RatingCategory.VISIBILITY.title,
            value = visibility,
            onValueChange = { visibility = it }
        )

        Text(
            text = "Warnings",
            style = MaterialTheme.typography.titleMedium,
            color = RoadRankColors.textPrimary
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            RoadWarning.values().forEach { warning ->
                FilterChip(
                    selected = selectedWarnings.contains(warning),
                    onClick = {
                        selectedWarnings = if (selectedWarnings.contains(warning)) {
                            selectedWarnings - warning
                        } else {
                            selectedWarnings + warning
                        }
                    },
                    label = {
                        Text(
                            text = warning.name.replace('_', ' ').lowercase().replaceFirstChar { it.uppercase() },
                            color = RoadRankColors.textPrimary
                        )
                    }
                )
            }
        }

        OutlinedTextField(
            value = comment,
            onValueChange = { comment = it },
            label = { Text("Comment") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Text),
            modifier = Modifier.fillMaxWidth()
        )

        Button(
            onClick = {
                onSubmit(
                    twistiness.toInt(),
                    surface.toInt(),
                    funFactor.toInt(),
                    scenery.toInt(),
                    visibility.toInt(),
                    comment,
                    selectedWarnings.toList()
                )
            },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = RoadRankColors.primary)
        ) {
            Text("Submit Rating")
        }

        Spacer(modifier = Modifier.height(12.dp))
    }
}

@Composable
private fun RatingSlider(
    title: String,
    value: Float,
    onValueChange: (Float) -> Unit
) {
    Column {
        Text(text = title, color = RoadRankColors.textSecondary)
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = 1f..5f,
            steps = 3
        )
    }
}
