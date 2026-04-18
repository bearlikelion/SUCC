# SUCC — SurfsUp Character Controller

A multiplayer-focused, inheritable, state-based first/third-person character controller for Godot 4.

Released under the **MIT License** — use it freely in any project, commercial or otherwise.

## What SUCC is

- Source-engine-inspired movement: WASD, jump, duck, crouch, sprint, air accel, bunnyhop, slope surf.
- First-person and third-person cameras with mouse look.
- `MovementState` and `GameState` extension enums.
- `MultiplayerSynchronizer`-based networking via a stripped-down `SUCCPawn` for remote peers.
- Physics tuning via a swappable `SUCCConfig` resource — no subclassing required to make a "heavy" or "low-gravity" character.

## What SUCC is not

SUCC is **just the controller**. It does not provide health, ammo, scoring, checkpoints, UI, chat, VOIP, leaderboards, or game modes. Those live in *your* game code extending `SUCC`.

Example games/modes (hunter-vs-prop, surf, bhop, climb) are in the separate **SUCC Demos** repo.

## Install

**Godot Asset Library** (recommended):
search for "SUCC" in the Godot editor's AssetLib tab.

**Manual**:
copy `addons/SUCC/` into your project's `addons/` folder, then enable the plugin in Project Settings → Plugins.

Continue to the [Quickstart](quickstart.md).
