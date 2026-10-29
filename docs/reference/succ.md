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
| `command` | `SUCCInput` |

`command` is the one you write.
When it is set, the next tick reads movement, jump, crouch, sprint, yaw and pitch from it instead of `Input`.
Leave it `null` for normal local play.

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

### `simulate(delta: float) -> void`
Runs one movement tick.
`_physics_process` calls it when `_is_simulating()` is true, and you can call it yourself, several times in one physics frame, to replay commands.
Call it inside a physics frame with the physics step as `delta`, because `move_and_slide()` uses the engine's step rather than the argument.

### `read_local_input() -> SUCCInput`
Builds a command from the local `Input` actions, the body's `rotation.y` and the camera rig's pitch.
The owning client sends it to the server and assigns it to `command` to predict with.

### `get_move_state() -> SUCCMoveState` / `set_move_state(state: SUCCMoveState) -> void`
Capture and restore everything the tick carries between ticks, for rewind and replay.
`set_move_state` also re-establishes the body's floor contact, so a replay from a restored state matches the original run.
Camera offsets, crouch view easing and head bob are not part of the state; after a replay the view eases from wherever it was.

### `add_impulse(impulse: Vector3) -> void`
Queues a velocity change for the start of the next simulated tick.
An impulse with an upward component lifts a grounded body off the floor for that tick, so knockback and jump pads work while standing.
Impulses queued while the body is `DISABLED` or `_can_move()` is false are dropped.

### `teleport(new_transform: Transform3D) -> void`
Moves the body, drops queued impulses and resets camera interpolation.
Velocity is kept.

## Overridable hooks

```gdscript
func _on_movement_state_changed(old: MovementState, new: MovementState) -> void
func _on_game_state_changed(old: GameState, new: GameState) -> void
func _can_move() -> bool
func _can_look() -> bool
func _is_simulating() -> bool
func _is_local_viewer() -> bool
```

`_is_simulating()` decides whether `_physics_process` runs the tick, and `_is_local_viewer()` decides whether this instance takes mouse look and captures the mouse.
Both default to `is_multiplayer_authority()`.
Override `_is_simulating()` to run the tick on a dedicated server or to predict on the owning client.

## `SUCCInput`

A `RefCounted` holding one tick of player intent.

| Name | Type | Description |
|---|---|---|
| `move` | `Vector2` | x is right, y is back, normalized or zero. |
| `jump` | `bool` | Held this tick. A press is detected against the previous tick, so a jump never repeats while held unless bhop buffering is on. |
| `crouch` | `bool` | Held this tick. |
| `sprint` | `bool` | Held this tick. |
| `yaw` | `float` | Body `rotation.y` in radians. |
| `pitch` | `float` | Camera rig `rotation.x` in radians. Ignored without a `CameraRig`. |

Non-finite `move`, `yaw` or `pitch` values are ignored, since commands can come off the network.

## `SUCCMoveState`

A `RefCounted` snapshot returned by `get_move_state()`: `position`, `velocity`, `yaw`, `crouched`, `air_crouch_raised`, `air_crouch_raise`, `was_on_floor`, `on_floor`, `floor_type`, `ground_normal`, `skip_step_probe_once`, `jump_held`, `impulse` and `movement_state`.
The collider height follows from `crouched`.

## Runtime validation

Missing input actions are reported with `push_warning()` and disabled individually; the rest of the controller keeps working. A missing `Collision` child reports via `push_error()` in `_ready()`.
A missing `CameraRig` is reported only when `_is_local_viewer()` is true.
Without one, SUCC skips the camera work and the movement runs as normal, which is what a dedicated server's copy of a player needs.

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
`teleport()` does this for you.
