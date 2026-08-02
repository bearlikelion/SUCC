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
| `synced_movement_state` | `SUCC.MovementState` | `IDLE` | Mirrors authority's `MovementState`. |
| `synced_game_state` | `SUCC.GameState` | `ACTIVE` | Mirrors authority's `GameState`. |
| `synced_crouched` | `bool` | - | Mirrors authority's crouch flag. |

## Extending

Subclass `SUCCPawn` and add your own `synced_*` fields for health, team, weapon and
so on. Then add them to the `MultiplayerSynchronizer` node's replication config on
your subclass scene.

See [Add multiplayer](../how-to/add-multiplayer.md) for the authority and pawn
pattern these fit into.
