# Contributing to SUCC

Thanks for your interest. SUCC aims to be a small, focused character controller, so contributions that keep it that way are especially welcome.

## What belongs in SUCC

- Movement, camera, state, and multiplayer-sync fundamentals that most 3D Godot games would want.
- Bug fixes, performance improvements, and clearer documentation.
- Editor-time ergonomics: better warnings, inspector groupings, helpful defaults.

## What belongs elsewhere (SUCC Demos / your own game)

- Health, ammo, weapons, scoring, leaderboards, chat, VOIP, UI.
- Checkpoint / save-loc systems.
- Game-mode-specific logic (hunter-vs-prop, surf timer, etc.).

If you're unsure, open an issue first.

## GDScript style

- Always `class_name`.
- Static types everywhere (`-> void`, `var x: int`, `Array[T]`, etc.).
- Tabs for indentation; two blank lines between top-level functions.
- Comments use `#`, never `"""..."""`. Put comments above the thing they describe, not inline.
- UI nodes are accessed via `%UniqueName`; give Control nodes unique names.

## Running the demo

Open `/` (the repo root) in Godot 4.6+. The demo scene is the project's main scene.

## Pull requests

1. Fork & branch from `main`.
2. Keep PRs focused - one concern per PR.
3. Include a CHANGELOG entry under `## [Unreleased]` describing user-visible changes.
4. If you add or change an exported property, update the docs in `docs/api/`.

## Licensing

By contributing, you agree your work is released under the [MIT License](LICENSE) like the rest of SUCC.
