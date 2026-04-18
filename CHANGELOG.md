# Changelog

All notable changes to SUCC are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

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
