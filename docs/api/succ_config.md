# `class_name SUCCConfig extends Resource`

All physics and feel tuning. Swap configs at runtime to change character weight, gravity, speed profile, etc.

| Name | Type | Default | Description |
|---|---|---|---|
| `gravity` | `float` | `20.32` | m/s² downward. |
| `acceleration` | `float` | `7.5` | Ground accel coefficient. |
| `air_acceleration` | `float` | `100.0` | Air-strafe accel. Values ≥100 enable momentum gains. |
| `friction` | `float` | `4.0` | Ground friction. |
| `stop_speed` | `float` | `4.0` | Min speed for full friction. |
| `max_speed` | `float` | `10.16` | Max ground speed (m/s). |
| `max_air_speed` | `float` | `0.762` | Per-frame air-accel speed cap. |
| `crouch_speed_modifier` | `float` | `0.333` | Multiplier applied while crouched. |
| `sprint_speed_modifier` | `float` | `1.6` | Multiplier applied while sprinting. |
| `jump_height` | `float` | `1.143` | Apex height (m). |
| `step_height` | `float` | `0.45` | Max step-up without jumping. |
| `stand_height` | `float` | `1.829` | Standing collider height. |
| `crouch_height` | `float` | `0.914` | Crouched collider height. |
| `width` | `float` | `0.813` | Collider width/radius. |
| `crouch_time` | `float` | `0.12` | Crouch camera tween duration. |
| `standing_view_offset` | `float` | `1.711` | Eye height standing. |
| `crouch_view_offset` | `float` | `0.796` | Eye height crouched. |
| `mouse_sensitivity` | `float` | `3.0` | Sensitivity multiplier. |
| `degrees_per_unit` | `float` | `0.022` | Source-style mouse scale. |
| `third_person_distance` | `float` | `2.0` | Spring arm length in 3rd person. |
| `bhop_buffered_jump` | `bool` | `true` | Queue jump on landing if held. |
| `surf_jump_retention` | `float` | `1.0` | Ramp-jump velocity retention. |
