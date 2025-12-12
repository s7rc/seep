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
import androidx.compose.material3.Switch
import com.swordfish.lemuroid.app.mobile.feature.gamemenu.GameMenuActivity
import com.swordfish.lemuroid.app.shared.GameMenuContract

@Composable
fun GameMenuLayoutScreen(
    gameMenuRequest: GameMenuActivity.GameMenuRequest,
    onSettingsParamsChanged: (Float, Float, Boolean) -> Unit,
) {
    val scale = remember { mutableFloatStateOf(gameMenuRequest.controlsScale) }
    val opacity = remember { mutableFloatStateOf(gameMenuRequest.controlsOpacity) }
    val isFastForwardEnabled = remember { androidx.compose.runtime.mutableStateOf(gameMenuRequest.isFastForwardEnabled) }

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
                        onSettingsParamsChanged(it, opacity.floatValue, isFastForwardEnabled.value)
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
                        onSettingsParamsChanged(scale.floatValue, it, isFastForwardEnabled.value)
                    },
                    valueRange = 0.1f..1.0f,
                    steps = 9
                )
            }

            // Fast Forward Setting
            if (gameMenuRequest.fastForwardSupported) {
                androidx.compose.foundation.layout.Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                ) {
                    Text(
                        text = "Show Fast Forward",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Switch(
                        checked = isFastForwardEnabled.value,
                        onCheckedChange = {
                            isFastForwardEnabled.value = it
                            onSettingsParamsChanged(scale.floatValue, opacity.floatValue, it)
                        }
                    )
                }
            }
            }
        }
    }
}
