# `class_name SUCCCamera extends SpringArm3D`

Camera rig used by `SUCC`. Handles mouse look (yaw rotates the parent `SUCC`; pitch rotates this node) and first/third-person switching via `spring_length`.

## Exports

| Name | Type | Default | Description |
|---|---|---|---|
| `invert_mouse_y` | `bool` | `false` | Flip vertical mouse look. |

## Signals

- `mode_changed(mode: int)` — emitted on camera mode switch. Consumers can hook this to hide/show the player model in first/third person.

## Methods

### `handle_input(event: InputEvent, config: SUCCConfig) -> void`
Processes mouse motion. Called by the owning `SUCC` from `_unhandled_input`.

### `apply_mode(mode: int, config: SUCCConfig) -> void`
Sets `spring_length` based on camera mode.
