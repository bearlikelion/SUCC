# SUCC - SurfsUp Character Controller

[![Godot 4.6+](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/bearlikelion/SUCC?include_prereleases&sort=semver)](https://github.com/bearlikelion/SUCC/releases)

A Godot 4 character controller that feels like Quake, Half-Life, Quake 2, Half-Life 2 or SurfsUp, by swapping one resource file.

It covers bunnyhopping, surfing, air strafing, momentum-preserving stair stepping and
Source-style crouch jumping. Stair traversal is render-smoothed for both the first-person
camera and third-person model, and grounded crouching can be smooth or instant. Written in
statically typed GDScript, ported from the original engine source.

This is the controller from [**SurfsUp**](https://store.steampowered.com/app/3454830/SurfsUp/?utm_source=SUCC), open-sourced under the MIT License.

**Try it in your browser:** https://bearlikelion.com/succ

**Documentation:** https://bearlikelion.github.io/SUCC/

![The demo gym](docs/images/gym-overview.png)

## Features

- **Five movement presets.** Pick an engine's feel by assigning a resource, or swap at runtime with one call.
- **Smooth stairs in both views.** Walk or sprint up and down steps without losing momentum, snapping the camera or jolting the third-person model.
- **Source-style crouching.** Grounded crouches ease at a configurable speed or snap immediately; air crouches raise the legs while preserving head height.
- **Tuning without code.** Gravity, speed, friction, jump height, hull size, eye height, crouch transitions, head bob and view tilt are all properties on a resource you edit in the inspector.
- **A test gym.** Six lanes covering stairs, slopes, bhop, crouch, surf and slide, with a speedometer reading both metres and engine units.
- **Signals and hooks** for wiring up your own health, weapons and game states without editing the controller.
- **Multiplayer support.** Authority checks throughout, plus a lightweight `SUCCPawn` for remote players. Works with ENet, WebSocket, GodotSteam or anything else.
- **No autoloads or singletons.**

## The presets

| File | Feels like |
|---|---|
| `default_config.tres` | SurfsUp: fast and slidey, 400 u/s |
| `goldsrc.tres` | Half-Life and CS 1.6, 320 u/s |
| `quake.tres` | Quake and QuakeWorld, shorter body, lower camera |
| `quake2.tres` | Quake 2: heavier, grippier, no air strafing |
| `source.tres` | Half-Life 2: floaty jumps, 190 u/s until you sprint |

The values came from the engine source, and some differ from what gets quoted. Quake 2 runs at 300 u/s with friction 6, not 320 and 4. Half-Life 2 uses gravity 600, a hardcoded jump impulse of 160, and walks at 190. Each preset also carries its engine's own head bob and view tilt, so Quake bobs hard and Half-Life 2 has no strafe tilt at all.

See [preset values](https://bearlikelion.github.io/SUCC/reference/presets/) for the full table, or [how accurate are the presets?](https://bearlikelion.github.io/SUCC/explanation/engine-accuracy/) for the file and line numbers behind each one.

## Getting started

1. Copy `addons/SUCC/` into your project's `addons/` folder. Scripts register through `class_name`, so there's no plugin to enable.
2. Add seven input actions: `forward`, `back`, `left`, `right`, `jump`, `crouch`, `sprint`. Any you skip get a warning and are disabled individually, so the rest still works.
3. Drop `addons/SUCC/scenes/succ_character.tscn` into a scene with a floor, and press F6.
4. To add your own game logic, make an inherited scene and extend `SUCC`.

```gdscript
class_name MyPlayer
extends SUCC

signal died

var health: int = 100


func take_damage(amount: int) -> void:
	health -= amount
	if health > 0:
		return
	set_game_state(GameState.DISABLED)
	died.emit()


func _can_move() -> bool:
	return health > 0
```

To try a different engine's movement:

```gdscript
config = load("res://addons/SUCC/resources/quake.tres") as SUCCConfig
apply_config()
```

Then open `addons/SUCC/demo/test_level.tscn` and press **1** to **5** while playing to compare presets on the same obstacle.

The [tutorial](https://bearlikelion.github.io/SUCC/tutorial/) covers all of this in more detail.

## Where to go next

- [Use a movement preset](https://bearlikelion.github.io/SUCC/how-to/use-a-preset/)
- [Extend SUCC for your game](https://bearlikelion.github.io/SUCC/how-to/extend-succ/)
- [Tune your own movement](https://bearlikelion.github.io/SUCC/how-to/tune-movement/)
- [Add multiplayer](https://bearlikelion.github.io/SUCC/how-to/add-multiplayer/)
- [How the movement works](https://bearlikelion.github.io/SUCC/explanation/movement/), including why holding jump makes you faster

## What SUCC is not

SUCC is only the controller. There's no health, ammo, scoring, checkpoints, UI, chat, VOIP or leaderboards. Those belong in your game code.

Example games and game modes will be published in the separate [**SUCC Demos**](https://github.com/bearlikelion/SUCC-Demos) repository. That project is a work in progress; it will be open-sourced under the MIT License once it's ready, with attribution required.

## Games built with SUCC

- **[SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)** by **[Mark Arneman](https://bearlikelion.com/)** & **[Nerdiful](https://nerdiful.itch.io/)**, the surf and bhop game SUCC was extracted from.

Built something with SUCC? [Open an issue](https://github.com/bearlikelion/SUCC/issues/new) with the name, a link and the authors to have it added here.

## Credits

SUCC builds on id Software's [Quake](https://github.com/id-software/quake) movement code, Valve's [Source SDK 2013](https://github.com/ValveSoftware/source-sdk-2013) release, and [GoldGdt](https://github.com/ratmarrow/GoldGdt) by ratmarrow, which SUCC started as a fork of. [Full acknowledgements](https://bearlikelion.github.io/SUCC/acknowledgements/).

## License

MIT, see [LICENSE](LICENSE). Use it in commercial or non-commercial projects. Attribution appreciated but not required.

Issues and pull requests welcome, see [CONTRIBUTING.md](CONTRIBUTING.md).
