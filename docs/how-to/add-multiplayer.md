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

When `is_multiplayer_authority()` returns `false`, SUCC skips input gathering and
physics entirely, so the instance goes inert.

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
	pawn.synced_pitch = camera_rig.rotation.x
	pawn.synced_velocity = velocity
	pawn.synced_movement_state = movement_state
	pawn.synced_game_state = game_state
	pawn.synced_crouched = crouched
```

Call `super(delta)` first, or the base controller never runs.

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
