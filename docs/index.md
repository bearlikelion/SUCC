# SUCC - SurfsUp Character Controller

A first and third-person character controller for Godot 4 with Quake and Source engine
movement: bunnyhopping, surfing, air strafing, smoothly rendered stair stepping and
crouch-jumping.

Written in statically typed GDScript, based on the [Quake movement
code](https://github.com/id-software/quake) and [Valve's Source SDK
2013](https://github.com/ValveSoftware/source-sdk-2013).

This is the controller from [**SurfsUp**](https://store.steampowered.com/app/3454830/SurfsUp/),
open-sourced under the MIT License.

![The demo gym](images/gym-overview.png)

## Features

- **Quake-lineage movement.** Air acceleration, bunnyhopping, slope surfing and
  Source-accurate stair stepping, ported from the original engine source.
- **Smooth first- and third-person traversal.** The camera and player model glide up and
  down stairs at walking or sprint speed instead of following the body's discrete steps.
- **Configurable crouch transitions.** Linear smoothing or an immediate snap. Air crouches
  raise the legs without moving the head.
- **Five movement presets.** Half-Life, Quake, Quake 2, Half-Life 2 or SurfsUp, assigned as
  a resource file. Swap at runtime with one call.
- **Tuning without code.** Gravity, speed, friction, jump height, hull size, eye height and
  crouch smoothing all live in a `SUCCConfig` resource you edit in the Inspector.
- **A test gym.** A demo level that exercises every feature, with a speedometer reading
  both metres and engine units.
- **Extension points.** Signals and override hooks for your game's health, weapons and
  states, without editing the controller.
- **Multiplayer-ready.** Authority checks throughout and a lightweight `SUCCPawn` for
  remote players.

## What it isn't

SUCC is **only** the controller. There's no health, ammo, scoring, checkpoints, UI, chat,
VOIP or leaderboards - those belong in your game code extending `SUCC`.

Example games and game modes will live in the separate **SUCC Demos** repository. That
project is a work in progress. It will be open-sourced under the MIT License once it's
ready, with attribution required.

## Install

**Godot Asset Store** (recommended): install
[SUCC](https://store.godotengine.org/asset/bearlikelion/succ/) from the asset store, or
search for "SUCC" in the editor's AssetLib tab.

**Manual**: download the latest [release zip](https://github.com/bearlikelion/SUCC/releases)
and copy `addons/SUCC/` into your project's `addons/` folder.

Either way, the scripts use `class_name`, so Godot registers them automatically. There is
no Plugins toggle.

Requires Godot 4.6 or newer.

## Where to start

**New to SUCC?** Work through the [tutorial](tutorial.md). It gets a character walking, then
compares the five engine presets.

**Know what you want?**

- [Use a movement preset](how-to/use-a-preset.md)
- [Extend SUCC for your game](how-to/extend-succ.md)
- [Tune your own movement](how-to/tune-movement.md)
- [Add multiplayer](how-to/add-multiplayer.md)

**Want to understand it?**

- [How the movement works](explanation/movement.md) - why holding jump makes you faster
- [How accurate are the presets?](explanation/engine-accuracy.md) - where the values come from
- [The demo gym](explanation/demo-level.md) - what each lane tests

**Looking up a value?**

- [Preset values](reference/presets.md)
- [SUCC](reference/succ.md) · [SUCCConfig](reference/succ_config.md) ·
  [SUCCCamera](reference/succ_camera.md) · [SUCCPawn](reference/succ_pawn.md)
