# Networking

SUCC is transport-agnostic — it works with any `MultiplayerPeer` (ENet, WebSocket, GodotSteam, etc.).

## Authority model

Each player instance has a **multiplayer authority** (the peer that controls it). The authority runs input, physics, and camera. All other peers see a read-only `SUCCPawn`.

```gdscript
# when spawning a player for a peer_id:
var player: SUCC = preload("res://player.tscn").instantiate()
player.set_multiplayer_authority(peer_id)
add_child(player, true)
```

If `is_multiplayer_authority()` is `false`, SUCC skips input gathering and physics — it becomes inert.

## Pawn pattern

`SUCCPawn` is a stripped-down remote-peer representation. It doesn't run input or camera logic — it just interpolates a synced transform and state from the authority.

Spawn one pawn per remote peer, with the pawn's authority set to the owning peer:

```gdscript
var pawn: SUCCPawn = preload("res://my_pawn.tscn").instantiate()
pawn.set_multiplayer_authority(peer_id)
add_child(pawn, true)
```

## What's synced (default)

The pawn's `MultiplayerSynchronizer` replicates:

- `synced_position` (every tick)
- `synced_yaw`, `synced_pitch` (every tick)
- `synced_velocity` (every tick)
- `synced_movement_state`, `synced_game_state`, `synced_crouched` (on change)

## Adding your own synced fields

On your subclass pawn scene:

1. Add properties to your `SUCCPawn` subclass (e.g. `@export var synced_health: int = 100`).
2. Open the `MultiplayerSynchronizer` node's **Replication** panel.
3. Add `./synced_health` with the desired replication mode (always / on change).

## Driving the pawn from the authority

The authority is responsible for pushing its state onto the matching remote pawn. Most games keep the authority SUCC and the remote SUCCPawn in separate scene trees (the authority sees *only* its own SUCC; remotes see *only* pawns for others). The authority RPCs its state to peers; the synchronizer handles the actual transport.

A simple pattern: give each player a paired `(SUCC, SUCCPawn)` — authority updates its pawn's `synced_*` fields every physics tick, and the synchronizer replicates them to non-authority peers.

## Integrations

- **ENet** — works out of the box.
- **GodotSteam** (`SteamMultiplayerPeer`) — works; SUCC has no Steam-specific code.
- **WebRTC / WebSocket** — works.

SUCC deliberately ships no lobby, matchmaking, or transport code. Those are the consuming game's responsibility.
