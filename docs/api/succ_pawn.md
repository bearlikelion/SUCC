# `class_name SUCCPawn extends CharacterBody3D`

Remote-peer representation. Receives synced transform/state; runs no input or physics.

## Exports

| Name | Type | Default | Description |
|---|---|---|---|
| `interpolate` | `bool` | `true` | Lerp toward synced pose for smoothing. |
| `interpolation_speed` | `float` | `15.0` | Lerp factor per second. |
| `synced_position` | `Vector3` | - | Replicated world position. |
| `synced_yaw` | `float` | - | Replicated body rotation (Y axis). |
| `synced_pitch` | `float` | - | Replicated camera pitch. |
| `synced_velocity` | `Vector3` | - | For anim blending. |
| `synced_movement_state` | `int` | - | Mirrors authority's `MovementState`. |
| `synced_game_state` | `int` | - | Mirrors authority's `GameState`. |
| `synced_crouched` | `bool` | - | Mirrors authority's crouch flag. |

## Extending

Subclass `SUCCPawn` and add your own `synced_*` fields (health, team, weapon, etc.). Then edit the `MultiplayerSynchronizer` node's replication config on your subclass scene to include them.
