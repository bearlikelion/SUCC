# `class_name SUCCConfig extends Resource`

All physics and feel tuning. Swap configs at runtime to change character weight, gravity, speed profile, etc. Exports are grouped in the inspector.

Call [`SUCC.apply_config()`](succ.md) after replacing `config` at runtime so the collider, floor snap length and camera height are re-derived.

Five presets ship with the addon - see [Preset values](presets.md).

## Unit helpers

All the engines SUCC draws from use 1 unit = 1 inch. These static methods keep authored values readable:

| Name | Signature | Description |
|---|---|---|
| `SOURCE_MULT` | `const float = 39.37` | Units per metre. |
| `source_units` | `static func (value: float) -> float` | Engine units to metres. |
| `quake_units` | `static func (value: float) -> float` | Alias for `source_units`. |

```gdscript
config.max_speed = SUCCConfig.source_units(320.0)   # 8.128 m/s
```

## Gravity & Jump

| Name | Type | Default | Description |
|---|---|---|---|
| `gravity` | `float` | `20.32` | m/s² downward. |
| `jump_height` | `float` | `1.143` | Apex height (m). |
| `bhop_buffered_jump` | `bool` | `true` | Queue jump on landing if held. Requires `SUCC.enable_bhop`; either flag being false falls back to just-pressed jumps. |

## Ground Movement

| Name | Type | Default | Description |
|---|---|---|---|
| `acceleration` | `float` | `7.5` | Ground accel coefficient. |
| `friction` | `float` | `4.0` | Ground friction. |
| `stop_speed` | `float` | `4.0` | Floor on the value friction is computed from, so slow movement still decelerates at a fixed rate. Source's `sv_stopspeed` is 100u (2.54 m). |
| `max_speed` | `float` | `10.16` | Max ground speed (m/s). |

## Air Movement

| Name | Type | Default | Description |
|---|---|---|---|
| `air_acceleration` | `float` | `100.0` | Air-strafe accel. Values ≥100 enable momentum gains. |
| `max_air_speed` | `float` | `0.762` | Per-frame air-accel speed cap. |
| `max_velocity` | `float` | `88.9` | Per-axis speed ceiling in m/s (`sv_maxvelocity`, 3500u). Only applied when `enforce_max_velocity` is true. |
| `enforce_max_velocity` | `bool` | `false` | Clamp each velocity axis to `max_velocity`. Source enforces this; surf and bhop usually leave it off so speed can climb freely. |

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
| `crouch_transition_mode` | `CrouchTransitionMode` | `SMOOTH` | Smooth or snap the grounded crouch camera. |
| `crouch_smoothing_speed` | `float` | `7.5` | Camera speed in m/s while crouching. |
| `uncrouch_smoothing_speed` | `float` | `7.5` | Camera speed in m/s while standing up. |
| `third_person_distance` | `float` | `2.0` | Spring arm length in 3rd person. |
| `smooth_vertical_step` | `bool` | `true` | Render-smooth the camera and model over step-up/down snaps. |
| `step_smoothing_speed` | `float` | `3.81` | Fallback stair catch-up rate near zero speed, in m/s. |

## Head Bob & Tilt

Cosmetic and first-person only. Every engine ships different values; see
[Preset values](presets.md).

| Name | Type | Default | Description |
|---|---|---|---|
| `bob_amount` | `float` | `0.01` | Bob amplitude per unit of speed (`cl_bob`). Set `0.0` to disable. |
| `bob_cycle` | `float` | `0.8` | Seconds per full bob cycle (`cl_bobcycle`). |
| `bob_up` | `float` | `0.5` | Fraction of the cycle spent moving up (`cl_bobup`). |
| `bob_max` | `float` | `0.102` | Ceiling on the bob offset in metres. |
| `tilt_angle` | `float` | `2.0` | Max view roll in degrees when strafing (`cl_rollangle`). Set `0.0` to disable. |
| `tilt_speed` | `float` | `5.08` | Sideways speed at which tilt maxes out (`cl_rollspeed`, 200u). |

## Mouse

| Name | Type | Default | Description |
|---|---|---|---|
| `mouse_sensitivity` | `float` | `3.0` | Sensitivity multiplier. |
| `degrees_per_unit` | `float` | `0.022` | Source-style mouse scale. |
