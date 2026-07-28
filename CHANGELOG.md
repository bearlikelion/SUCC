# Changelog

All notable changes to SUCC are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

### Changed

- Surf ramps are always airborne: they report `FALLING` and ignore jump input until the
  player reaches a walkable floor. `enable_surf` now controls ramp-aligned air
  acceleration.
- Camera translation now interpolates the controller's fixed-tick positions locally when
  project-wide physics interpolation is disabled. Mouse look remains render-rate
  responsive.

### Removed

- `SUCCConfig.surf_jump_retention`, because jumping from a surf ramp is no longer
  supported.

## [0.1.1] - 2026-07-26

### Changed

- Stair traversal now render-interpolates the first-person camera and optional
  `visual_root_path` independently from the fixed-tick collision body. Walking and
  sprinting up or down stairs follow one smooth grade without sacrificing momentum.
- Grounded crouch transitions now use `crouch_transition_mode`. `SMOOTH` moves linearly at
  `crouch_smoothing_speed` and `uncrouch_smoothing_speed`; `SNAP` applies the view height
  immediately. The SurfsUp default uses 7.5 m/s in both directions.
- Air crouches remain immediate and raise the legs while holding the head at the same
  world height, matching Source-style crouch jumping.

### Notes if you were using 0.1.0

- `crouch_time` and `uncrouch_time` are replaced by `crouch_smoothing_speed` and
  `uncrouch_smoothing_speed`, which are rates in m/s rather than durations in seconds. The
  bundled presets are updated; a hand-authored `SUCCConfig` falls back to the 7.5 m/s
  default. To convert, divide the eye travel distance (`standing_view_offset` minus
  `crouch_view_offset`) by your old time.

## [0.1.0] - 2026-07-25

First real release. SUCC is the character controller from [SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/), pulled out into a standalone Godot 4 addon.

It gives you Quake and Source style movement: bunnyhopping, surfing, air strafing, stair stepping and crouch jumping. Tuning lives in a resource file, so you can change how the character feels without touching code.

### What's in it

- **`SUCC`** (extends `CharacterBody3D`), the controller. WASD, jump, crouch, sprint, air acceleration, bhop, surf, stair stepping. Subclass it and override `_can_move()`, `_can_look()` or the state-change hooks to add your own game logic.
- **`SUCCConfig`** (extends `Resource`), every number that decides how movement feels: gravity, speed, friction, jump height, hull size, eye height, head bob, view tilt, mouse sensitivity. Grouped in the inspector.
- **`SUCCCamera`** (extends `SpringArm3D`), first and third person with mouse look, and stair-step smoothing so climbing steps doesn't jolt the view.
- **`SUCCPawn`** (extends `CharacterBody3D`), a stripped-down stand-in for remote players in multiplayer. It interpolates a synced transform and runs no input or physics of its own.
- **Five movement presets** in `addons/SUCC/resources/`. Four reproduce a specific engine, one is SurfsUp's own tuning:

  | Preset | Feels like |
  |---|---|
  | `default_config.tres` | SurfsUp: fast and slidey, 400 u/s |
  | `goldsrc.tres` | Half-Life and CS 1.6, 320 u/s |
  | `quake.tres` | Quake and QuakeWorld, shorter character, lower camera |
  | `quake2.tres` | Quake 2: heavier, grippier, no air strafing |
  | `source.tres` | Half-Life 2: floaty jumps, 190 u/s until you sprint |

  The values came from reading the actual engine source, not from wikis, which turned up some surprises. Quake 2 runs at 300 u/s with friction 6, not 320 and 4. Half-Life 2 uses gravity 600 and a hardcoded jump impulse of 160, and walks at 190 rather than the 320 everyone quotes. [How accurate are the presets?](https://bearlikelion.github.io/SUCC/explanation/engine-accuracy/) has the file and line numbers.

- **Head bob and view tilt**, off Quake's `V_CalcBob` and `V_CalcRoll`. Each preset carries its engine's own values: Quake bobs hardest (`cl_bob` 0.02 on a 0.6 second cycle), Source barely at all (0.002), and Source has no strafe tilt because Valve ships `sv_rollangle` at 0. First person only, and both switch off by setting their amount to 0.
- **`SUCCConfig.source_units()`** and **`quake_units()`**, so you can write config values in engine units (1 unit is about 1 inch) instead of converting to metres by hand.
- **`SUCC.apply_config()`**, for swapping presets at runtime. Rebuilds the collider, floor snap distance and camera height from the new values.
- **A demo gym** (`addons/SUCC/demo/test_level.tscn`) with six lanes: stairs, three slants, a bunnyhop ladder with widening gaps, a crouch corridor, a 55 degree surf ramp and a slide. Number keys 1 to 5 swap presets while you play, so you can feel the difference on the same obstacle. `F` toggles surf handling, `R` respawns.
- **A speedometer** under the crosshair reading both m/s and engine units per second, because Source players think in units and Godot thinks in metres.
- **Documentation** at [bearlikelion.github.io/SUCC](https://bearlikelion.github.io/SUCC/), including an explanation of why holding jump makes you go faster.

### Notes if you were using the pre-release code

- The `duck` input action is gone. It and `crouch` were OR'd into the same flag and did exactly the same thing, so there is one action now: `crouch`, bound to Ctrl in the demo project. `MovementState.DUCKING` was declared but never assigned, and has been removed from the enum.
- Movement state, game state, camera mode and floor type are now their enum types (`MovementState`, `GameState`, `CameraMode`, `FloorType`) rather than plain `int`. If you override `_on_movement_state_changed` or connect to the state signals, update your signatures.
- `@tool` is gone from `SUCC`, `SUCCCamera` and `SUCCConfig`. Every editor entry point bailed out immediately anyway, so it bought nothing. Missing `Collision` or `CameraRig` children now report with `push_error()` when the scene runs, instead of as an inspector warning.
- `step_smoothing_speed` changed meaning. It used to be a lerp factor; it's now a rate in m/s, defaulting to 3.81 (Source's 150 units per second). If you tuned it, retune it.
- `crouch_time` now has a matching `uncrouch_time`, and both scale with how far the camera still has to travel, so interrupting a crouch no longer restarts the whole animation.

### Fixed along the way

Most of these were found by running the movement against the original engine source rather than by playing:

- **Ramps launched you.** Walking up a slope re-applied full speed along your input direction every frame, discarding the slope-projected velocity, so speed ratcheted up and flung you to the top. Stair stepping now works the way Quake's `SV_WalkMove` and Source's `StepMove` do: run the move twice, once normally and once from a step height up, and keep whichever went further. The move produces the velocity, so nothing is synthesised.
- **Stairs didn't step at all** in some cases. The blocked-move check read velocity after `move_and_slide()` had already zeroed it against the riser, so it always measured zero and gave up.
- **Stair stepping stuttered.** The camera offset accumulated across consecutive steps faster than it decayed, and used a framerate-dependent lerp. It now takes the largest single step and closes the gap at a constant rate, like Source's `SmoothViewOnStairs`.
- **Surfing lost momentum.** Velocity was being projected along the collision plane a second time after `move_and_slide()` had already done it, which stripped the along-ramp component every frame you touched a ramp.
- **You couldn't stand up while touching a wall.** The headroom check used the full hull width, so brushing a wall made the ceiling read as blocked.
- **Crouching didn't match Source.** Ducking in mid-air now raises the origin by the hull difference so your head holds its height and your feet tuck up, which is what makes crouch-jumping reach higher ledges. Landing absorbs the raise, and standing up afterwards checks for room below rather than overhead.
- **Friction depended on how fast you were falling.** It measured 3D speed but only applied the result horizontally, so landing hard braked harder than landing gently.
- **Sprinting didn't make you faster.** The sprint and crouch multipliers scaled the per-frame acceleration instead of the speed cap, so you reached the same top speed sooner. This is also what makes `source.tres` able to sprint from 190 to 320 u/s.
- **`floor_snap_length` ignored your config.** It was `max(step_height, 0.5)`, and every shipped config has a step height under 0.5, so it was always 0.5.
- **`bhop_buffered_jump` did nothing**, despite being documented as working.
- **Floor classification disagreed with itself.** Slope handling used a hardcoded 45 degrees while the body's standing limit was 50, leaving a 5 degree band where a surface was walkable but treated as a ramp. Both are now exports (`ramp_angle_threshold`, `max_floor_angle`).
- **Crouch and sprint were bound to the wrong keys** in the demo project. `KEY_SHIFT` is 4194325 and `KEY_CTRL` is 4194326, and they were the wrong way round, so crouch sat on Shift.
- **Camera offsets never reached the screen.** Step smoothing wrote `camera.position.y`, but the camera is a child of a `SpringArm3D`, which overwrites its child's transform every frame. Offsets now move the arm itself through a `view_height` property, so stair smoothing works for the first time, and head bob works at all.
- `_has_clearance()` allocated a shape and query parameters on every call.

[Unreleased]: https://github.com/bearlikelion/SUCC/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/bearlikelion/SUCC/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/bearlikelion/SUCC/releases/tag/v0.1.0
