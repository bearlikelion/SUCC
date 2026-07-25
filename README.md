# SUCC - SurfsUp Character Controller

[![Godot 4.6+](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/bearlikelion/SUCC?include_prereleases&sort=semver)](https://github.com/bearlikelion/SUCC/releases)

A first and third-person character controller for Godot 4 with Quake and Source engine movement: bunnyhopping, surfing, air strafing, stair stepping and crouch jumping. Written in statically typed GDScript.

Based on the [Quake movement code](https://github.com/id-software/quake) and the physics and mouse-look feel of [Valve's Source SDK 2013](https://github.com/ValveSoftware/source-sdk-2013), the same lineage that powers bhop, surf, and every Source-engine mod you've ever loved.

This is the character controller from [**SurfsUp**](https://store.steampowered.com/app/3454830/SurfsUp/?utm_source=SUCC), now open-sourced for anyone to use, learn from, and build on.

**Documentation:** https://bearlikelion.github.io/SUCC/

![The demo gym](docs/images/gym-overview.png)

---

## Why you might want it

- **Movement that feels right.** Air acceleration, bhop, surf and Source-accurate stair stepping, ported by reading the original engine source rather than approximating it.
- **Five movement presets.** Ship your game feeling like Half-Life, Quake, Quake 2, Half-Life 2 or SurfsUp by assigning a resource file. Swap at runtime with one call.
- **Tuning without code.** Gravity, speed, friction, jump height, hull size, eye height, head bob and view tilt all live in a `SUCCConfig` resource you edit in the inspector.
- **A test gym.** Six lanes covering stairs, slants, bhop, crouch, surf and slide, with a speedometer reading both metres and engine units.
- **Built to be extended.** Signals and override hooks for your game's health, weapons and states, without editing the controller.
- **Multiplayer-ready.** Authority checks throughout and a lightweight `SUCCPawn` for remote players. Transport-agnostic: ENet, WebSocket, GodotSteam, whatever you like.
- **No singletons.** Drop it into any project.

## Movement presets

| Preset | Feels like |
|---|---|
| `default_config.tres` | SurfsUp: fast and slidey, 400 u/s |
| `goldsrc.tres` | Half-Life and CS 1.6, 320 u/s |
| `quake.tres` | Quake and QuakeWorld, shorter character, lower camera |
| `quake2.tres` | Quake 2: heavier, grippier, no air strafing |
| `source.tres` | Half-Life 2: floaty jumps, 190 u/s until you sprint |

The numbers came from reading the engine source, which turned up some surprises. Quake 2 runs at 300 u/s with friction 6, not 320 and 4. Half-Life 2 uses gravity 600 and a hardcoded jump impulse of 160, and walks at 190 rather than the 320 everyone quotes. See [How accurate are the presets?](https://bearlikelion.github.io/SUCC/explanation/engine-accuracy/) for the file and line numbers.

## Quickstart

1. Copy `addons/SUCC/` into your project's `addons/` folder. Scripts register automatically via `class_name`, so there's no plugin to enable.
2. Add these input actions to your Input Map: `forward`, `back`, `left`, `right`, `jump`, `duck`, `crouch`, `sprint`. Any you skip are reported with `push_warning()` and disabled individually; the rest of the controller keeps working.
3. Instance or inherit `addons/SUCC/scenes/succ_character.tscn` as your player.
4. Extend `SUCC` to add your own game state.

```gdscript
class_name MyPlayer
extends SUCC

signal died

enum MyState { ALIVE, DEAD }

var health: int = 100
var my_state: MyState = MyState.ALIVE


func take_damage(amount: int) -> void:
	health -= amount
	if health > 0:
		return
	my_state = MyState.DEAD
	set_game_state(GameState.DISABLED)
	died.emit()


func _can_move() -> bool:
	return my_state == MyState.ALIVE
```

To try a preset:

```gdscript
config = load("res://addons/SUCC/resources/quake.tres") as SUCCConfig
apply_config()
```

Then walk the demo gym at `addons/SUCC/demo/test_level.tscn` and press **1** to **5** to feel the difference between engines on the same obstacle.

Full docs: **[https://bearlikelion.github.io/SUCC/](https://bearlikelion.github.io/SUCC/)**

## What's included

```
addons/SUCC/
├── scripts/
│   ├── succ.gd           # class_name SUCC extends CharacterBody3D
│   ├── succ_pawn.gd      # class_name SUCCPawn, remote peer mirror
│   ├── succ_camera.gd    # class_name SUCCCamera, SpringArm3D + mouse look
│   └── succ_config.gd    # class_name SUCCConfig, physics/feel tuning Resource
├── scenes/
│   ├── succ_character.tscn
│   └── succ_pawn.tscn
├── resources/
│   ├── default_config.tres   # SurfsUp
│   ├── goldsrc.tres          # Half-Life
│   ├── quake.tres            # Quake / QuakeWorld
│   ├── quake2.tres           # Quake 2
│   └── source.tres           # Half-Life 2
└── demo/
    ├── test_level.tscn   # six-lane gym: stairs, slants, bhop, crouch, surf, slide
    ├── test_level.gd
    └── demo.tres         # HUD theme
```

## What SUCC is not

SUCC is **just the controller**. It does not provide health, ammo, scoring, checkpoints, UI, chat, VOIP, or leaderboards. Those live in your game code, extending `SUCC`.

Example games and game modes will be published in the separate [**SUCC Demos**](https://github.com/bearlikelion/SUCC-Demos) repository. That project is a work in progress; it will be open-sourced under the MIT License once it's ready, with attribution required.

## Games built with SUCC

- **[SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)** by **[Mark Arneman](https://bearlikelion.com/)** & **[Nerdiful](https://nerdiful.itch.io/)**, the surf/bhop game whose controller SUCC was extracted from.

Shipped or working on something built with SUCC? [Open an issue](https://github.com/bearlikelion/SUCC/issues/new) with your game's name, a link, and the author(s), and it'll be added here.

## Heritage & credits

SUCC stands on the shoulders of:

- **Quake**, id Software's [original movement code](https://github.com/id-software/quake) defined the shape of FPS player physics.
- **Source SDK 2013**, Valve's [open-source engine release](https://github.com/ValveSoftware/source-sdk-2013) inspired the air acceleration, friction, and mouse-look math used here.
- **[GoldGdt](https://github.com/ratmarrow/GoldGdt)** by **ratmarrow**, the Godot port that SUCC began as a fork of.
- **[SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)** v1 by **[Mark Arneman](https://bearlikelion.com/)**, rewrote GoldGdt to ship the Steam release.
- **SurfsUp v2** by **[Nerdiful](https://nerdiful.itch.io/)**, refactored the controller for SurfsUp's 2.0 update.
- **SUCC** by **[Mark Arneman](https://bearlikelion.com/)**, overhauled, extended with state and pawn systems, documented, and open-sourced for everyone.

## License

SUCC is released under the **MIT License**, see [LICENSE](LICENSE). Use it freely in commercial or non-commercial projects, attribution appreciated but not required.

## Contributing

Issues, pull requests, and questions are welcome on [GitHub](https://github.com/bearlikelion/SUCC). See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
