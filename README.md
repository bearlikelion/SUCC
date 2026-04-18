# SUCC — SurfsUp Character Controller

A multiplayer-focused, inheritable, state-based first/third-person character controller for Godot 4.

Released under the **MIT License** — use it freely in any project, commercial or otherwise.

## Quickstart

1. Copy `addons/SUCC/` into your project's `addons/` directory (or install via the Godot Asset Library).
2. Enable the plugin in Project Settings → Plugins.
3. Add these input actions to your project's Input Map: `forward`, `back`, `left`, `right`, `jump`, `duck`, `crouch`, `sprint`. Missing actions will produce editor warnings and disable the corresponding movement.
4. Instance or inherit `addons/SUCC/scenes/succ_character.tscn` as your player.
5. Extend `class_name SUCC` to add your game-specific state (health, ammo, roles, etc.).

See the full documentation at the project's GitHub Pages site.

## What SUCC provides

- First-person and third-person cameras with mouse look
- WASD movement, jump, duck, crouch, sprint
- Source-engine-inspired air acceleration, bunnyhopping, slope surfing
- `MovementState` and `GameState` extension points
- `MultiplayerSynchronizer`-based networking with a stripped-down `SUCCPawn` for remote peers
- Configurable physics tuning via `SUCCConfig` resource

## What SUCC intentionally does not provide

Game-specific systems (health, scoring, checkpoints, UI, chat, VOIP, leaderboards). Those live in *your* game code, extending SUCC.

## License

SUCC is MIT-licensed. The separate `SUCC_Demos` repository showcasing example game modes is CC-BY-4.0.
