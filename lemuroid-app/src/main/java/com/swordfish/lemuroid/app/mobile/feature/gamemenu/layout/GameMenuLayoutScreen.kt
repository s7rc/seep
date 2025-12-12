package com.swordfish.lemuroid.app.mobile.feature.gamemenu.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.swordfish.lemuroid.app.mobile.feature.gamemenu.GameMenuActivity
import com.swordfish.lemuroid.app.shared.GameMenuContract

@Composable
fun GameMenuLayoutScreen(
    gameMenuRequest: GameMenuActivity.GameMenuRequest,
    onResult: (android.content.Intent.() -> Unit) -> Unit,
) {
    val scale = remember { mutableFloatStateOf(gameMenuRequest.controlsScale) }
    val opacity = remember { mutableFloatStateOf(gameMenuRequest.controlsOpacity) }

    androidx.compose.material3.Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background,
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Scale Setting
            Column {
                Text(
                    text = "Button Scale: ${String.format("%.2f", scale.floatValue)}",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Slider(
                    value = scale.floatValue,
                    onValueChange = {
                        scale.floatValue = it
                        onResult {
                            putExtra(GameMenuContract.RESULT_CHANGE_LAYOUT_SETTINGS, true)
                            putExtra(GameMenuContract.EXTRA_CONTROLS_SCALE, it)
                            putExtra(GameMenuContract.EXTRA_CONTROLS_OPACITY, opacity.floatValue)
                        }
                    },
                    valueRange = 0.2f..2.0f,
                    steps = 17
                )
            }

            // Opacity Setting
            Column {
                Text(
                    text = "Button Opacity: ${String.format("%.0f", opacity.floatValue * 100)}%",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Slider(
                    value = opacity.floatValue,
                    onValueChange = {
                        opacity.floatValue = it
                        onResult {
                            putExtra(GameMenuContract.RESULT_CHANGE_LAYOUT_SETTINGS, true)
                            putExtra(GameMenuContract.EXTRA_CONTROLS_SCALE, scale.floatValue)
                            putExtra(GameMenuContract.EXTRA_CONTROLS_OPACITY, it)
                        }
                    },
                    valueRange = 0.1f..1.0f,
                    steps = 9
                )
            }
        }
    }
}
