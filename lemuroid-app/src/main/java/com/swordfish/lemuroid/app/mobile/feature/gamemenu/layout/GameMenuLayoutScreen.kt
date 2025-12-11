package com.swordfish.lemuroid.app.mobile.feature.gamemenu.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Opacity
import androidx.compose.material.icons.filled.ZoomOutMap
import androidx.compose.material3.Slider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.swordfish.lemuroid.R
import com.swordfish.lemuroid.app.mobile.feature.gamemenu.GameMenuActivity
import com.swordfish.lemuroid.app.shared.GameMenuContract
import com.swordfish.lemuroid.app.utils.android.settings.LemuroidSettingsIcon
import com.swordfish.lemuroid.app.utils.android.settings.LemuroidSettingsTitle

@Composable
fun GameMenuLayoutScreen(
    gameMenuRequest: GameMenuActivity.GameMenuRequest,
    onResult: (android.content.Intent.() -> Unit) -> Unit,
) {
    val scale = remember { mutableFloatStateOf(gameMenuRequest.controlsScale) }
    val opacity = remember { mutableFloatStateOf(gameMenuRequest.controlsOpacity) }

    Column(
        modifier = Modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // Scale Setting
        Column {
            LemuroidSettingsTitle(text = "Button Scale: \${String.format(\"%.2f\", scale.floatValue)}")
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
                valueRange = 0.5f..2.0f,
                steps = 14
            )
        }

        // Opacity Setting
        Column {
            LemuroidSettingsTitle(text = "Button Opacity: \${String.format(\"%.2f\", opacity.floatValue * 100)}%")
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
