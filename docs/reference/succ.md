# `class_name SUCC extends CharacterBody3D`

The main controller. Extend this class for your game's player.

## Exports

| Name | Type | Description |
|---|---|---|
| `config` | `SUCCConfig` | Physics tuning resource. Falls back to `default_config.tres` if unset. |
| `input_actions` | `Dictionary` | Maps logical names (`"jump"`, `"forward"`, ...) to project InputMap actions. |
| `enable_bhop` | `bool` | Hold-jump buffered jumping. Default `true`. |
| `enable_surf` | `bool` | Project air acceleration along surf ramps. Default `true`. |
| `default_camera_mode` | `CameraMode` | Starting camera mode (`FIRST_PERSON` / `THIRD_PERSON`). |
| `visual_root_path` | `NodePath` | Optional model pivot that receives render-smoothed stair offsets. Keep collision outside it. |
| `ramp_angle_threshold` | `float` | Slope angle at or above which a walkable floor counts as a ramp. Default 45°. |
| `max_floor_angle` | `float` | Steepest slope the body can stand on. Steeper surfaces leave it airborne, which is what makes surfing work. Default 50°. |

Both angle properties are shown in degrees in the Inspector and stored in radians.
Setting `max_floor_angle` also updates Godot's built-in `floor_max_angle`.

## Enums

- `CameraMode { FIRST_PERSON, THIRD_PERSON }`
- `FloorType { NONE, FLOOR, RAMP }`
- `MovementState { IDLE, WALKING, SPRINTING, CROUCHING, JUMPING, FALLING, AIR }`
- `GameState { ACTIVE, FROZEN, DISABLED }`

## State (read-only in most cases)

| Name | Type |
|---|---|
| `movement_state` | `MovementState` |
| `game_state` | `GameState` |
| `camera_mode` | `CameraMode` |
| `floor_type` | `FloorType` |
| `crouched` | `bool` |

## Signals

- `movement_state_changed(old_state: MovementState, new_state: MovementState)`
- `game_state_changed(old_state: GameState, new_state: GameState)`
- `jumped`
- `landed(fall_velocity: float)`
- `camera_mode_changed(mode: CameraMode)`

## Methods

### `set_game_state(new_state: GameState) -> void`
Change the game state; fires `game_state_changed` and calls `_on_game_state_changed`.

### `toggle_camera_mode() -> void` / `set_camera_mode(mode: CameraMode) -> void`
Switch between first- and third-person.

## Overridable hooks

```gdscript
func _on_movement_state_changed(old: MovementState, new: MovementState) -> void
func _on_game_state_changed(old: GameState, new: GameState) -> void
func _can_move() -> bool
func _can_look() -> bool
```

## Runtime validation

Missing input actions are reported with `push_warning()` and disabled individually; the rest of the controller keeps working. A missing `Collision` or `CameraRig` child reports via `push_error()` in `_ready()`.

## Swapping config at runtime

```gdscript
func apply_config() -> void
```

Re-derives collider size, `floor_snap_length` and camera height from the current `config`. Call it after assigning a new `SUCCConfig`; `_ready()` calls it for you on startup. See [Preset values](presets.md).

## Teleports and respawns

```gdscript
func reset_camera_interpolation() -> void
```

Call after changing `global_position` directly. It resets both Godot physics interpolation
and SUCC's local camera interpolation so the view does not streak from the old position.
