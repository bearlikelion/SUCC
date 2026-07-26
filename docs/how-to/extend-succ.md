# Extend SUCC for your game

SUCC handles movement and the camera. It knows nothing about health, ammo, teams, scoring
or respawning. You add those by subclassing it.

## Make your own player class

1. Right-click `addons/SUCC/scenes/succ_character.tscn` in the FileSystem panel.
2. Choose **New Inherited Scene**.
3. Save it in your own project as `player.tscn`.
4. Select the root node, attach a new script, and make it extend `SUCC`.

```gdscript
class_name MyPlayer
extends SUCC


var health: int = 100
```

Inheriting rather than editing SUCC means addon updates never clobber your game code.

## Stop movement without breaking the character

Override `_can_move()` and `_can_look()`. Returning `false` freezes that behaviour and
leaves the rest intact: gravity still applies, the camera still renders.

```gdscript
func _can_move() -> bool:
	return health > 0


func _can_look() -> bool:
	return health > 0
```

For a cutscene or a menu, use the built-in game states instead:

```gdscript
set_game_state(GameState.FROZEN)     # stop moving, keep looking
set_game_state(GameState.DISABLED)   # stop moving and looking
set_game_state(GameState.ACTIVE)     # back to normal
```

## React to what the character does

Connect these from the parent, or override the matching hook inside your subclass.

| Signal | Fires when |
|---|---|
| `jumped` | A jump impulse was applied |
| `landed(fall_velocity)` | The character touched the floor after being airborne |
| `movement_state_changed(old, new)` | Idle, walking, sprinting, crouching, jumping, falling |
| `game_state_changed(old, new)` | Active, frozen or disabled |
| `camera_mode_changed(mode)` | First person or third person |

Landing damage, using the `fall_velocity` the signal passes:

```gdscript
func _ready() -> void:
	super()
	landed.connect(_on_landed)


func _on_landed(fall_velocity: float) -> void:
	if fall_velocity > -12.0:
		return
	health -= int(absf(fall_velocity) - 12.0) * 4
```

Call `super()` in `_ready()`, or SUCC never initialises.

## Play animations on state changes

Override `_on_movement_state_changed` instead of polling every frame:

```gdscript
func _on_movement_state_changed(_old: MovementState, new_state: MovementState) -> void:
	match new_state:
		MovementState.WALKING:
			%Anim.play("walk")
		MovementState.SPRINTING:
			%Anim.play("run")
		MovementState.CROUCHING:
			%Anim.play("crouch")
		MovementState.JUMPING:
			%Anim.play("jump")
```

## Report events upward, don't reach upward

Emit a signal and let whoever spawned the player decide what it means. A player that
calls `get_parent().on_player_died()` breaks when you move it in the tree or test the
scene on its own.

```gdscript
class_name FPSPlayer
extends SUCC

signal died

enum FPSState { ALIVE, DEAD, SPECTATING }

var health: int = 100
var fps_state: FPSState = FPSState.ALIVE


func take_damage(amount: int) -> void:
	health -= amount
	if health > 0:
		return
	fps_state = FPSState.DEAD
	set_game_state(GameState.DISABLED)
	died.emit()


func _can_move() -> bool:
	return fps_state == FPSState.ALIVE
```

Then in your level:

```gdscript
func _ready() -> void:
	%Player.died.connect(_on_player_died)
```

## Build a roster of character types

A "class" or "character" in your game is usually a subclass plus a config, not new
movement code. A `HeavyGunner` with `heavy.tres` and a `Scout` with `light.tres` share
every line of movement logic and still feel different.

The five shipped presets work the same way: they are configs, not subclasses.

## What not to override

`_physics_process`, `_move_body` and the acceleration functions are the movement solver.
Overriding them loses the stair stepping, ramp handling and air control. Change
`SUCCConfig` values instead; most feel questions are answerable there.

If you do need to extend `_physics_process`, call `super(delta)` first:

```gdscript
func _physics_process(delta: float) -> void:
	super(delta)
	_update_my_own_stuff(delta)
```

## Next steps

- [Tune your own movement](tune-movement.md) for the config side.
- [Add multiplayer](add-multiplayer.md) if other players need to see this character.
- [SUCC class reference](../reference/succ.md) for the full API.
