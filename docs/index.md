# SUCC - SurfsUp Character Controller

A multiplayer-focused, inheritable, state-based first/third-person character controller for Godot 4, written in statically typed GDScript.

Based on the [Quake movement code](https://github.com/id-software/quake) and the physics/mouse-look feel of [Valve's Source SDK 2013](https://github.com/ValveSoftware/source-sdk-2013) - the lineage behind bhop, surf, and every Source-engine mod you've loved.

This is the character controller from [**SurfsUp**](https://store.steampowered.com/app/3454830/SurfsUp/), now open-sourced under the MIT License for anyone to use, learn from, and build on.

## What SUCC is

- Source-engine-inspired movement: WASD, jump, duck, crouch, sprint, air acceleration, bunnyhopping, slope surfing, step climbing.
- First-person and third-person cameras with mouse look and smoothed step transitions.
- `MovementState` and `GameState` extension enums with signals and override hooks.
- `MultiplayerSynchronizer`-based networking via a stripped-down `SUCCPawn` for remote peers.
- Physics tuning via a swappable `SUCCConfig` resource - no subclassing required to make a "heavy" or "low-gravity" character.

## What SUCC is not

SUCC is **just the controller**. It does not provide health, ammo, scoring, checkpoints, UI, chat, VOIP, or leaderboards. Those live in your game code extending `SUCC`.

Example games and modes (hunter-vs-prop, surf, bhop, climb) will live in the separate **SUCC Demos** repo.

## Install

**Godot Asset Library** (recommended): search for "SUCC" in the Godot editor's AssetLib tab.

**Manual**: download the latest release zip from [GitHub Releases](https://github.com/bearlikelion/SUCC/releases), copy `addons/SUCC/` into your project's `addons/` folder, then enable the plugin in Project Settings → Plugins.

Continue to the [Quickstart](quickstart.md).
