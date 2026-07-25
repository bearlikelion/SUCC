# Changelog

All notable changes to SUCC are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

### Added
- `SUCCConfig.source_units()` and `SUCCConfig.quake_units()` - static helpers converting engine units (1 unit = 1 inch) to metres via `SOURCE_MULT` (39.37). Ported from SurfsUp v2's `SourceMovementConfig`.
- Four engine movement presets in `addons/SUCC/resources/`: `goldsrc.tres`, `quake.tres`, `quake2.tres`, `source.tres`. Values verified against the Quake, Half-Life SDK, Quake 2 and Source SDK 2013 sources. See [Presets](docs/presets.md).
- `SUCC.apply_config()` - re-derives collider size, floor snap length and camera height after swapping `config` at runtime.
- Parkour gym demo level: stairs (8-40u risers plus a 20u step that must be jumped), 15/30/44 degree slants, a progressive bhop ladder (96-144u gaps), a 55 degree surf trough, a 40 degree slide, and a 40u crouch corridor. Number keys 1-5 swap presets live; `F` toggles surf, `R` respawns.
- Dual-unit speedometer HUD centred under the crosshair, reading both m/s and engine u/s.

### Changed
- `_friction()` now derives speed from horizontal velocity only. Previously it used `velocity.length()`, so vertical motion inflated the friction drop that was then applied to X/Z alone.
- Crouch and sprint modifiers now scale the speed cap rather than the per-frame acceleration increment, so sprinting actually raises top speed. This is what makes `source.tres` reach HL2's 320u sprint from its 190u walk.
- `floor_snap_length` now tracks `config.step_height` instead of `max(step_height, 0.5)`, which silently pinned it to 0.5 for every shipped config.
- `bhop_buffered_jump` is now honoured; it was previously a dead export documented as functional.
- Movement/game/camera/floor state now use their declared enum types instead of `int` across signals, fields and method signatures.
- Dropped `@tool` from `SUCC`, `SUCCCamera` and `SUCCConfig`. Every editor entry point immediately returned on `Engine.is_editor_hint()`, so the annotation only cost guard clauses. Missing `Collision`/`CameraRig` children now report via `push_error()` in `_ready()`.

### Fixed
- `duck` and `sprint` demo bindings were swapped: `KEY_SHIFT` is 4194325 and `KEY_CTRL` is 4194326, so duck was on Shift and sprint on Ctrl, contrary to the documented Ctrl-duck/Shift-sprint scheme.
- `_has_clearance()` no longer allocates a `BoxShape3D` and query parameters on every call.

### Removed
- `_get_configuration_warnings()` and `_action_exists_in_project()`, along with the `@tool` annotation they supported.

## [0.1.0] - 2026-04-17

First public release. Extracted from [SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/) and refactored into a standalone, open-source Godot 4 addon.

### Added
- `SUCC` (`extends CharacterBody3D`) - base character controller with WASD, jump, crouch/duck, sprint, air acceleration, bhop, slope surf, and step climbing.
- `SUCCCamera` (`extends SpringArm3D`) - first/third-person camera with mouse look and smoothed step-up/down transitions.
- `SUCCPawn` (`extends CharacterBody3D`) - lightweight remote-peer representation driven by `MultiplayerSynchronizer` + `SceneReplicationConfig`.
- `SUCCConfig` (`extends Resource`) - grouped, inspector-friendly physics/feel tuning (gravity, acceleration, friction, jump height, mouse sensitivity, step smoothing, etc.).
- Editor configuration warnings for missing InputMap actions via `@tool` + `_get_configuration_warnings()`.
- Overridable hooks: `_on_movement_state_changed`, `_on_game_state_changed`, `_can_move`, `_can_look`.
- Signals: `movement_state_changed`, `game_state_changed`, `jumped`, `landed`, `camera_mode_changed`.
- Gray-box demo scene (`addons/SUCC/demo/test_level.tscn`) with dynamic input-hint HUD reading from the project's InputMap.
- MkDocs Material documentation site (deployed to GitHub Pages via Actions).

[Unreleased]: https://github.com/bearlikelion/SUCC/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bearlikelion/SUCC/releases/tag/v0.1.0
