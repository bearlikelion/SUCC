# Add multiplayer

SUCC is transport-agnostic. It works with any `MultiplayerPeer`: ENet, WebSocket,
GodotSteam and the rest. There is no transport-specific code in the addon, so
nothing here is tied to one of them.

!!! note "Work in progress"

    Multiplayer support is still being built out. The authority checks and
    `SUCCPawn` described below work today, but a complete networked example is
    waiting on the [SUCC Demos](https://github.com/bearlikelion/SUCC-Demos)
    repository. Expect this page to grow once that lands.

## How authority works

Every player instance has one owning peer, its **multiplayer authority**. That peer
runs input, physics and the camera. Everyone else sees a read-only `SUCCPawn`.

```gdscript
const PLAYER_SCENE: PackedScene = preload("res://player.tscn")


func spawn_player(peer_id: int) -> SUCC:
	var player: SUCC = PLAYER_SCENE.instantiate()
	player.set_multiplayer_authority(peer_id)
	# Forced readable name so both peers resolve the same node path.
	add_child(player, true)
	return player
```

Two overridable checks decide what an instance does, and both default to `is_multiplayer_authority()`:

- `_is_simulating()` runs the movement tick in `_physics_process`.
- `_is_local_viewer()` takes mouse look and captures the mouse.

Left alone, a non-authority instance skips input and physics entirely, so it goes inert.

## Spawn a pawn for each remote player

`SUCCPawn` is the stripped-down remote representation. It runs no input and no
camera logic, only interpolating a synced transform and state from the authority.

```gdscript
const PAWN_SCENE: PackedScene = preload("res://my_pawn.tscn")


func spawn_pawn(peer_id: int) -> SUCCPawn:
	var pawn: SUCCPawn = PAWN_SCENE.instantiate()
	pawn.set_multiplayer_authority(peer_id)
	add_child(pawn, true)
	return pawn
```

By default the pawn's `MultiplayerSynchronizer` replicates position, yaw, pitch and
velocity every tick, plus movement state, game state and the crouch flag on change.

## Drive the pawn from the authority

Give each player a paired `(SUCC, SUCCPawn)`. The authority writes its state onto
its pawn every physics tick, and the synchronizer replicates that to other peers.

Most games keep the two in separate scene trees, so a peer sees only its own `SUCC`
and only pawns for everyone else.

```gdscript
class_name NetworkedPlayer
extends SUCC

@export var pawn: SUCCPawn


func _physics_process(delta: float) -> void:
	super(delta)
	if pawn == null or not is_multiplayer_authority():
		return
	pawn.synced_position = global_position
	pawn.synced_yaw = rotation.y
	pawn.synced_pitch = camera_rig.pitch
	pawn.synced_velocity = velocity
	pawn.synced_movement_state = movement_state
	pawn.synced_game_state = game_state
	pawn.synced_crouched = crouched
```

Call `super(delta)` first, or the base controller never runs.

## Run the movement on a dedicated server

The owner-authoritative setup above trusts each client with its own position.
For a server-authoritative game, the server simulates every player from the inputs clients send, and the owning client predicts its own player so movement still feels instant.
SUCC provides the pieces; the transport, tick numbering and RPCs stay in your game.

| Piece | Use |
|---|---|
| `command: SUCCInput` | When set, the tick reads it instead of `Input`. |
| `read_local_input() -> SUCCInput` | The owning client's input and view angles for this tick. |
| `simulate(delta)` | One tick. Call it directly to replay. |
| `get_move_state()` / `set_move_state(state)` | Rewind to a server state before replaying. |
| `add_impulse(impulse)` / `teleport(transform)` | Knockback and respawns that stay deterministic. |

The server's copy of a player needs no `CameraRig`.
Without one SUCC skips the camera work, logs nothing and simulates as normal.

### The server copy

Keep the client as the multiplayer authority so `_is_local_viewer()` stays false on the server, and make the server simulate:

```gdscript
class_name ServerPlayer
extends SUCC


func _is_simulating() -> bool:
	return multiplayer.is_server()


# Your RPC handler calls this with the client's command for the next tick.
func receive_command(input: SUCCInput) -> void:
	command = input
```

Validate commands at your trust boundary before assigning them, for example one per tick per player.
SUCC already ignores non-finite values and normalizes `move`, so a client cannot run faster by sending a longer vector.

### Prediction and reconciliation on the owning client

The client simulates its own command at once, keeps it by tick number, and when the server's state for an older tick arrives, rewinds to it and replays the newer commands:

```gdscript
class_name PredictedPlayer
extends SUCC

var _tick: int = 0
var _pending: Dictionary[int, SUCCInput] = {}
var _server_tick: int = -1
var _server_state: SUCCMoveState


func _physics_process(delta: float) -> void:
	if _server_state:
		_reconcile(delta)
	command = read_local_input()
	_pending[_tick] = command
	# Send _tick and command to the server with your own RPC here.
	super(delta)
	_tick += 1


# Your RPC handler calls this with the server's state after it simulated server_tick.
func receive_server_state(server_tick: int, state: SUCCMoveState) -> void:
	_server_tick = server_tick
	_server_state = state


func _reconcile(delta: float) -> void:
	set_move_state(_server_state)
	_server_state = null
	for tick: int in range(_server_tick + 1, _tick):
		command = _pending[tick]
		simulate(delta)
	for tick: int in _pending.keys():
		if tick <= _server_tick:
			_pending.erase(tick)
```

Things to know when replaying:

- Call `simulate()` from `_physics_process` with the physics step. `move_and_slide()` reads the engine's step, not the argument, so replaying from an RPC callback or `_process` drifts.
- `jumped`, `landed` and `movement_state_changed` fire again for replayed ticks. Set a flag around the replay loop if a sound or effect should play once.
- An impulse the client predicts, such as its own rocket jump, has to be queued again at the same tick during the replay. Impulses the server applies arrive in the server state.
- Camera offsets are not part of the state, so the view eases from where it is instead of snapping on every correction.
- Pack the `SUCCMoveState` fields you need into your own RPC; it is a `RefCounted` and does not serialize on its own.

## Add your own synced fields

On your subclass pawn scene:

1. Add properties to your `SUCCPawn` subclass, such as
   `@export var synced_health: int = 100`.
2. Open the `MultiplayerSynchronizer` node's **Replication** panel.
3. Add `./synced_health` and pick a replication mode, always or on change.

## What SUCC leaves to you

The addon ships no lobby, matchmaking or transport code, and none is planned. Those
belong in your game.

## Next steps

- [SUCCPawn reference](../reference/succ_pawn.md) for the full synced property list.
- [Extend SUCC for your game](extend-succ.md) for the subclassing pattern.
