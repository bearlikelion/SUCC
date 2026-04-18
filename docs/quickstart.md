# Quickstart

## 1. Install the addon

Copy `addons/SUCC/` into your project's `addons/` folder. SUCC's scripts use `class_name`, so Godot picks them up automatically - no Project Settings step required.

## 2. Add the required input actions

SUCC expects these actions in your project's Input Map:

| Logical name | Suggested key |
|---|---|
| `forward` | W |
| `back` | S |
| `left` | A |
| `right` | D |
| `jump` | Space |
| `duck` | Ctrl |
| `crouch` | C |
| `sprint` | Shift |

Missing actions produce a configuration warning on the `SUCC` node in the editor and are disabled at runtime (the rest of the controller keeps working). You can remap action names per-node via the `input_actions` dictionary export.

## 3. Instance or inherit the base scene

**Option A - Instance** (quickest): drop `addons/SUCC/scenes/succ_character.tscn` into your level.

**Option B - Inherit** (recommended for games):

1. Right-click `succ_character.tscn` → **New Inherited Scene**.
2. Save as `player.tscn` in your project.
3. Attach a new script extending `SUCC`:

```gdscript
class_name MyPlayer extends SUCC

enum MyGameState { ALIVE, DEAD, RESPAWNING }

var health: int = 100
var my_state: MyGameState = MyGameState.ALIVE


func _on_movement_state_changed(_old: int, new_state: int) -> void:
	if new_state == MovementState.JUMPING:
		# play jump anim, etc.
		pass


func _can_move() -> bool:
	return my_state != MyGameState.DEAD
```

## 4. Tune the physics

Duplicate `addons/SUCC/resources/default_config.tres` into your project and edit in the inspector. Assign it to your player's `config` export. Common tweaks: `gravity`, `max_speed`, `jump_height`, `mouse_sensitivity`.

## 5. Hook up multiplayer (optional)

Use `addons/SUCC/scenes/succ_pawn.tscn` (or an inherited scene) as the remote-peer representation. Give each player's SUCC node `set_multiplayer_authority(peer_id)` on spawn. See [Networking](networking.md) for details.
