# Preset values

Five `SUCCConfig` resources ship in `addons/SUCC/resources/`.

Values are given in engine units (1 unit ≈ 1 inch, 39.37 units per metre) because that is
how the source engines specify them. The `.tres` files store metres.

| | `default_config` | `goldsrc` | `quake` | `quake2` | `source` |
|---|---|---|---|---|---|
| Models | SurfsUp | Half-Life | Quake / QuakeWorld | Quake 2 | Half-Life 2 |
| `gravity` | 800 | 800 | 800 | 800 | 600 |
| `max_speed` | 400 | 320 | 320 | 300 | 190 |
| `acceleration` | 7.5 | 10 | 10 | 10 | 10 |
| `friction` | 4.0 | 4.0 | 4.0 | 6.0 | 4.0 |
| `stop_speed` | 157 | 100 | 100 | 100 | 100 |
| `air_acceleration` | 100 | 10 | 10 | 1.0 | 10 |
| `max_air_speed` | 30 | 30 | 30 | 300 | 30 |
| Jump impulse | 268.33 | 268.33 | 270 | 270 | 160 |
| `jump_height` | 45 | 45 | 45.5625 | 45.5625 | 21.333 |
| `step_height` | 17.7 | 18 | 18 | 18 | 18 |
| `stand_height` | 72 | 72 | 56 | 56 | 72 |
| `crouch_height` | 36 | 36 | 56 | 28 | 36 |
| `width` | 32 | 32 | 32 | 32 | 32 |
| `standing_view_offset` | 67.4 | 64 | 46 | 46 | 64 |
| `crouch_view_offset` | 31 | 30 | 46 | 22 | 28 |
| `crouch_speed_modifier` | 0.333 | 0.333 | 1.0 | 0.333 | 0.333 |
| `sprint_speed_modifier` | 1.6 | 1.0 | 1.0 | 1.0 | 1.6842 |
| `crouch_transition_mode` | Smooth | Smooth | Snap | Snap | Smooth |
| `crouch_smoothing_speed` | 7.5 m/s | 2.159 m/s | n/a | n/a | 2.286 m/s |
| `uncrouch_smoothing_speed` | 7.5 m/s | 4.318 m/s | n/a | n/a | 4.572 m/s |
| `bob_amount` | 0.01 | 0.01 | 0.02 | 0.005 | 0.002 |
| `bob_cycle` | 0.8 s | 0.8 s | 0.6 s | 0.8 s | 0.8 s |
| `tilt_angle` | 2.0° | 2.0° | 2.0° | 2.0° | 0° |
| `tilt_speed` | 200 | 200 | 200 | 200 | 200 |

## Notes on individual cells

**`jump_height` versus jump impulse.** SUCC takes a height and derives the impulse as
`sqrt(2 * gravity * jump_height)`. The engines specify the impulse. The heights above are
back-solved so the impulse matches.

**`quake` has no crouch.** Quake 1 has no duck at all, so `crouch_height` equals
`stand_height`, the view offsets match, and `crouch_speed_modifier` is 1.0. Pressing crouch
does nothing.

**`quake2` air movement.** Vanilla Quake 2 defaults `pm_airaccelerate` to 0, which routes
air movement through ground-style acceleration with no 30-unit clamp. The preset
reproduces that with `air_acceleration` 1.0 and the air cap raised to full `max_speed`
(300), rather than the literal 0 that would remove air control entirely.

**`source` speeds.** 190 is HL2's `hl2_normspeed`. `sprint_speed_modifier` of 1.6842 takes
that to 320, which is `hl2_sprintspeed`. HL2's 150-unit slow walk has no equivalent.

**Head bob and tilt.** `bob_amount` is `cl_bob`, `bob_cycle` is `cl_bobcycle` and
`tilt_angle` is `cl_rollangle` (or `sv_rollangle` in Quake 2 and Source). Source ships
`sv_rollangle` at 0, so Half-Life 2 has no strafe tilt; the other three use 2 degrees.
Quake bobs hardest at 0.02 on the shortest cycle; Source is barely visible at 0.002. Bob
and tilt are first-person only.

**`default_config` stop speed.** 157 units is SurfsUp's own tuning, not an engine value;
the four engine presets all use 100.

For where these values come from, see
[How accurate are the presets?](../explanation/engine-accuracy.md).

## Metric equivalents

For reference when reading the `.tres` files directly:

| Units | Metres |
|---|---|
| 800 | 20.320 |
| 600 | 15.240 |
| 400 | 10.160 |
| 320 | 8.128 |
| 300 | 7.620 |
| 190 | 4.826 |
| 100 | 2.540 |
| 72 | 1.829 |
| 56 | 1.422 |
| 40 | 1.016 |
| 36 | 0.914 |
| 30 | 0.762 |
| 18 | 0.457 |

Convert in code with `SUCCConfig.source_units(value)` or `SUCCConfig.quake_units(value)`.

## Full property list

Every property on the resource, with defaults and descriptions:
[SUCCConfig reference](succ_config.md).
