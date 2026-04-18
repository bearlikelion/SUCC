# `class_name SUCCConfig extends Resource`

All physics and feel tuning. Swap configs at runtime to change character weight, gravity, speed profile, etc. Exports are grouped in the inspector for easier navigation.

## Gravity & Jump

| Name | Type | Default | Description |
|---|---|---|---|
| `gravity` | `float` | `20.32` | m/s² downward. |
| `jump_height` | `float` | `1.143` | Apex height (m). |
| `surf_jump_retention` | `float` | `1.0` | Velocity retention when jumping off a ramp. |
| `bhop_buffered_jump` | `bool` | `true` | Queue jump on landing if held. |

## Ground Movement

| Name | Type | Default | Description |
|---|---|---|---|
| `acceleration` | `float` | `7.5` | Ground accel coefficient. |
| `friction` | `float` | `4.0` | Ground friction. |
| `stop_speed` | `float` | `4.0` | Min speed for full friction. |
| `max_speed` | `float` | `10.16` | Max ground speed (m/s). |

## Air Movement

| Name | Type | Default | Description |
|---|---|---|---|
| `air_acceleration` | `float` | `100.0` | Air-strafe accel. Values ≥100 enable momentum gains. |
| `max_air_speed` | `float` | `0.762` | Per-frame air-accel speed cap. |

## Speed Modifiers

| Name | Type | Default | Description |
|---|---|---|---|
| `crouch_speed_modifier` | `float` | `0.333` | Multiplier while crouched. |
| `sprint_speed_modifier` | `float` | `1.6` | Multiplier while sprinting. |

## Collider

| Name | Type | Default | Description |
|---|---|---|---|
| `stand_height` | `float` | `1.829` | Standing collider height. |
| `crouch_height` | `float` | `0.914` | Crouched collider height. |
| `width` | `float` | `0.813` | Collider width/radius. |
| `step_height` | `float` | `0.45` | Max step-up without jumping. |

## Camera

| Name | Type | Default | Description |
|---|---|---|---|
| `standing_view_offset` | `float` | `1.711` | Eye height standing. |
| `crouch_view_offset` | `float` | `0.796` | Eye height crouched. |
| `crouch_time` | `float` | `0.12` | Crouch camera tween duration. |
| `third_person_distance` | `float` | `2.0` | Spring arm length in 3rd person. |
| `smooth_vertical_step` | `bool` | `true` | Lerp the camera after step-up/down snaps. |
| `step_smoothing_speed` | `float` | `15.0` | Catch-up speed for the step lerp. |

## Mouse

| Name | Type | Default | Description |
|---|---|---|---|
| `mouse_sensitivity` | `float` | `3.0` | Sensitivity multiplier. |
| `degrees_per_unit` | `float` | `0.022` | Source-style mouse scale. |
