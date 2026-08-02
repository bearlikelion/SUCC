# `class_name SUCCCamera extends SpringArm3D`

Camera rig used by `SUCC`. Handles mouse look (yaw rotates the parent `SUCC`; pitch rotates this node) and first/third-person switching via `spring_length`.

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

### `handle_input(event: InputEvent, config: SUCCConfig) -> void`
Processes mouse motion. Called by the owning `SUCC` from `_unhandled_input`.

### `apply_mode(mode: SUCC.CameraMode, config: SUCCConfig) -> void`
Sets `spring_length` based on camera mode.
