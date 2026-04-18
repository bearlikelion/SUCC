# SUCC - SurfsUp Character Controller

[![Godot 4.6+](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/bearlikelion/SUCC?include_prereleases&sort=semver)](https://github.com/bearlikelion/SUCC/releases)

A multiplayer-focused, inheritable, state-based first/third-person character controller for Godot 4, written in statically typed GDScript.

Based on the [Quake movement code](https://github.com/id-software/quake) and the physics/mouse-look feel of [Valve's Source SDK 2013](https://github.com/ValveSoftware/source-sdk-2013) - the same lineage that powers bhop, surf, and every Source-engine mod you've ever loved.

This is the character controller from [**SurfsUp**](https://store.steampowered.com/app/3454830/SurfsUp/?utm_source=SUCC), now open-sourced for anyone to use, learn from, and build on.

---

## Features

- **First-person and third-person cameras** with mouse look and smoothed step-up/down.
- **Source-engine-inspired physics**: ground acceleration, air acceleration/strafing, friction, step climbing, bhop, slope surf.
- **State system**: `MovementState` and `GameState` extension points with signals and overridable hooks.
- **Multiplayer-first**: built around `MultiplayerSynchronizer` and a stripped-down `SUCCPawn` for remote peers. Transport-agnostic (ENet, WebSocket, GodotSteam, etc.).
- **Fully configurable via a Resource**: swap `SUCCConfig` for light/heavy characters, low-gravity modes, bhop vs. surf profiles.
- **Editor warnings** for missing InputMap actions - no mystery silent failures.
- **Zero singleton coupling** - drop into any Godot project.

## Quickstart

1. Copy `addons/SUCC/` into your project's `addons/` folder (or install via the Godot Asset Library).
2. Enable the plugin in **Project Settings → Plugins**.
3. Add these input actions to your Input Map: `forward`, `back`, `left`, `right`, `jump`, `duck`, `crouch`, `sprint`. Missing actions produce editor warnings and are disabled at runtime.
4. Instance or inherit `addons/SUCC/scenes/succ_character.tscn` as your player.
5. Extend `class_name SUCC` to add your game-specific state (health, ammo, roles, etc.).

```gdscript
class_name MyPlayer extends SUCC

enum MyGameState { ALIVE, DEAD }

var health: int = 100
var my_state: MyGameState = MyGameState.ALIVE


func _can_move() -> bool:
	return my_state == MyGameState.ALIVE
```

Full docs: **[https://bearlikelion.github.io/SUCC/](https://bearlikelion.github.io/SUCC/)**

## What's included

```
addons/SUCC/
├── scripts/
│   ├── succ.gd           # class_name SUCC extends CharacterBody3D
│   ├── succ_pawn.gd      # class_name SUCCPawn - remote peer mirror
│   ├── succ_camera.gd    # class_name SUCCCamera - SpringArm3D + mouse look
│   └── succ_config.gd    # class_name SUCCConfig - physics/feel tuning Resource
├── scenes/
│   ├── succ_character.tscn
│   └── succ_pawn.tscn
├── resources/
│   └── default_config.tres
└── demo/
    ├── test_level.tscn   # gray-box: ramp, stairs, flat ground
    └── test_level.gd
```

## What SUCC is not

SUCC is **just the controller**. It does not provide health, ammo, scoring, checkpoints, UI, chat, VOIP, or leaderboards. Those live in your game code, extending `SUCC`.

Example games and game modes will be published in the separate [**SUCC Demos**](https://github.com/bearlikelion/SUCC-Demos) repository.

## Games built with SUCC

- **[SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)** by **[Mark Arneman](https://bearlikelion.com/)** & **[Nerdiful](https://nerdiful.itch.io/)** - the surf/bhop game whose controller SUCC was extracted from.

Shipped or working on something built with SUCC? [Open an issue](https://github.com/bearlikelion/SUCC/issues/new) with your game's name, a link, and the author(s), and it'll be added here.

## Heritage & credits

SUCC stands on the shoulders of:

- **Quake** - id Software's [original movement code](https://github.com/id-software/quake) defined the shape of FPS player physics.
- **Source SDK 2013** - Valve's [open-source engine release](https://github.com/ValveSoftware/source-sdk-2013) inspired the air acceleration, friction, and mouse-look math used here.
- **[GoldGdt](https://github.com/ratmarrow/GoldGdt)** by **ratmarrow** - the Godot port that SUCC began as a fork of.
- **[SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)** v1 by **[Mark Arneman](https://bearlikelion.com/)** - rewrote GoldGdt to ship the Steam release.
- **SurfsUp v2** by **[Nerdiful](https://nerdiful.itch.io/)** - refactored the controller for SurfsUp's 2.0 update.
- **SUCC** by **[Mark Arneman](https://bearlikelion.com/)** - overhauled, extended with state and pawn systems, documented, and open-sourced for everyone.

## License

SUCC is released under the **MIT License** - see [LICENSE](LICENSE). Use it freely in commercial or non-commercial projects, attribution appreciated but not required.

## Contributing

Issues, pull requests, and questions are welcome on [GitHub](https://github.com/bearlikelion/SUCC). See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
