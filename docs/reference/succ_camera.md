# `class_name SUCCCamera extends SpringArm3D`

Camera rig used by `SUCC`. Handles mouse look (yaw rotates the parent `SUCC`; pitch rotates this node) and first/third-person switching via `spring_length`.
The rig is `top_level`: the owning `SUCC` places it every frame from its interpolated position, so do not move it yourself.

## Properties

| Name | Type | Description |
|---|---|---|
| `pitch` | `float` | View pitch in radians, clamped to `PITCH_LIMIT_DEG`. Set this rather than `rotation.x`, which is overwritten every frame. |

## Exports

| Name | Type | Default | Description |
|---|---|---|---|
| `invert_mouse_y` | `bool` | `false` | Flip vertical mouse look. |
| `yaw_target` | `Node3D` | `null` | Node that receives mouse yaw. Falls back to the parent when unset. |

## Signals

`mode_changed(mode: SUCC.CameraMode)` fires on a camera mode switch. Hook it to
hide or show the player model.

`SUCC.camera_mode_changed` fires for the same transition, so connect one or the
other, not both.

## Methods

### `turn(radians: Vector2) -> void`
Turns the view by radians as mouse motion does, for look sources such as a gamepad stick.

### `place(origin: Vector3, yaw: float) -> void`
Moves the rig to eye height above `origin`, facing `yaw`. Called by the owning `SUCC` from `_process`.

### `handle_input(event: InputEvent, config: SUCCConfig) -> void`
Processes mouse motion. Called by the owning `SUCC` from `_unhandled_input`.

### `apply_mode(mode: SUCC.CameraMode, config: SUCCConfig) -> void`
Sets `spring_length` based on camera mode.
