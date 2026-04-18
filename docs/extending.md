# Extending SUCC

SUCC is designed to be extended via inheritance. The base class is intentionally minimal - movement, camera, state hooks, and nothing else.

## Overridable methods

```gdscript
func _on_movement_state_changed(old: int, new: int) -> void
func _on_game_state_changed(old: int, new: int) -> void
func _can_move() -> bool     # return false to freeze movement
func _can_look() -> bool     # return false to freeze mouse look
```

## Signals

- `movement_state_changed(old, new)`
- `game_state_changed(old, new)`
- `jumped`
- `landed(fall_velocity)`
- `camera_mode_changed(mode)`

## Patterns

### Heavy character (2× gravity, slower)

Duplicate `default_config.tres` → `heavy_config.tres`. Set `gravity = 40.64`, `max_speed = 6.0`, `jump_height = 0.7`. Assign to your player's `config` export. No code required.

### Low-gravity mode

Create `moon_config.tres` with `gravity = 1.62`, `air_acceleration = 200.0`. Swap `config` at runtime:

```gdscript
player.config = preload("res://configs/moon_config.tres")
```

### Bhop-only vs surf-only

Toggle the `enable_bhop` and `enable_surf` exports. Both default to `true` for Source-engine feel.

### Game-specific state (health, ammo, roles)

Extend in your subclass - SUCC doesn't prescribe how you model game state:

```gdscript
class_name FPSPlayer extends SUCC

enum FPSGameState { ALIVE, DEAD, SPECTATING }

var health: int = 100
var ammo: int = 30
var fps_state: FPSGameState = FPSGameState.ALIVE


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		fps_state = FPSGameState.DEAD
		set_game_state(GameState.DISABLED)


func _can_move() -> bool:
	return fps_state == FPSGameState.ALIVE
```

### Character variants in a roster

Each variant is just a subclass + config combo. A `LightSurfer extends SUCC` with `light_config.tres` and a `HeavySurfer extends SUCC` with `heavy_config.tres` share all movement logic but feel totally different.
