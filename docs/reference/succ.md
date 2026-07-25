# `class_name SUCC extends CharacterBody3D`

The main controller. Extend this class for your game's player.

## Exports

| Name | Type | Description |
|---|---|---|
| `config` | `SUCCConfig` | Physics tuning resource. Falls back to `default_config.tres` if unset. |
| `input_actions` | `Dictionary` | Maps logical names (`"jump"`, `"forward"`, ...) to project InputMap actions. |
| `enable_bhop` | `bool` | Hold-jump buffered jumping. Default `true`. |
| `enable_surf` | `bool` | Use floor normal for jump direction (slope surfing). Default `true`. |
| `default_camera_mode` | `CameraMode` | Starting camera mode (`FIRST_PERSON` / `THIRD_PERSON`). |

## Enums

- `CameraMode { FIRST_PERSON, THIRD_PERSON }`
- `FloorType { NONE, FLOOR, RAMP }`
- `MovementState { IDLE, WALKING, SPRINTING, CROUCHING, DUCKING, JUMPING, FALLING, AIR }`
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

- `movement_state_changed(old: int, new: int)`
- `game_state_changed(old: int, new: int)`
- `jumped`
- `landed(fall_velocity: float)`
- `camera_mode_changed(mode: int)`

## Methods

### `set_game_state(new_state: int) -> void`
Change the game state; fires `game_state_changed` and calls `_on_game_state_changed`.

### `toggle_camera_mode() -> void` / `set_camera_mode(mode: int) -> void`
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
