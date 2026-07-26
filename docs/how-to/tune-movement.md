# Tune your own movement

Every number that decides how your character feels lives in a `SUCCConfig` resource.

## Start from a copy

1. Right-click a file in `addons/SUCC/resources/` and choose **Duplicate**.
2. Save the copy in your own project, for example `res://resources/player/config.tres`.
3. Assign it to your character's **Config** property.

Duplicate rather than edit in place, so addon updates don't overwrite your tuning.

## What each value does

The values are grouped in the Inspector. These are the ones to reach for first.

### Making it faster or slower

- **`max_speed`**, top speed on the ground, in metres per second. The biggest lever on
  feel.
- **`acceleration`**, how quickly you reach that top speed. Higher is snappier. Source
  uses 10.
- **`friction`**, how quickly you stop when you let go. Higher is grippier. Quake and
  Source use 4; Quake 2 uses 6 and feels noticeably stickier.
- **`sprint_speed_modifier`**, multiplies `max_speed` while sprint is held.

### Making jumps higher or floatier

- **`jump_height`**, how high you jump, in metres. The impulse is worked out from this
  and gravity, so the height stays right if you change gravity.
- **`gravity`**, downward acceleration. Lower is floatier. Half-Life 2 uses 600 units
  (15.24 m/s²) rather than the usual 800, which is why it feels light.

### Air control, bunnyhopping and surfing

These two decide whether your game can bhop and surf at all:

- **`air_acceleration`**, how strongly you can steer mid-air. Around 100 gives Quake and
  Source air control. Set it near 1 for Quake 2's near-total lack of air steering.
- **`max_air_speed`**, the per-frame cap on air acceleration, 0.762 m (30 units) in
  every Valve and id engine. **This small number is what makes bunnyhopping work.**
  Raising it does not make you faster; it makes air control feel mushy.

[How the movement works](../explanation/movement.md) explains why.

### Body size and camera height

- **`stand_height`** / **`crouch_height`**, total height of the collision box.
- **`width`**, how wide the character is.
- **`standing_view_offset`** / **`crouch_view_offset`**, eye height above the feet.
- **`step_height`**, the tallest ledge you can walk up without jumping. All four
  engines use 18 units (0.457 m). Much higher and you start climbing walls.

### Stair smoothing

- **`smooth_vertical_step`**, smooths the rendered first-person camera and third-person
  model while the collision body takes discrete steps. Disable it for rigid snapping.
- **`visual_root_path`** on `SUCC`, the optional model pivot that receives the same
  render-smoothed offset as the camera. Keep collision shapes outside this node.
- **`step_smoothing_speed`**, the fallback vertical rate when horizontal speed is almost
  zero. During normal traversal SUCC derives the rate from movement speed and stair grade,
  so walking and sprinting remain smooth in both directions.

### Crouch timing

- **`crouch_transition_mode`**, whether grounded crouches move the camera smoothly or
  snap immediately. `SMOOTH` is the default.
- **`crouch_smoothing_speed`** / **`uncrouch_smoothing_speed`**, linear camera speed
  in metres per second. SurfsUp v2 uses 7.5 in both directions.
- Air crouches are always instant so the legs tuck upward without snapping the head,
  matching Source.

### Head bob and view tilt

These are cosmetic, first-person only, and every engine ships different values.

- **`bob_amount`**, how far the view bobs per unit of speed, the same idea as `cl_bob`.
  Quake uses 0.02 and is pronounced; Source uses 0.002 and is barely visible. Set it to
  0 to switch bob off.
- **`bob_cycle`**, seconds for one full bob. Quake 0.6, everything else 0.8.
- **`bob_up`**, how much of the cycle is spent moving up. Every engine ships 0.5.
- **`bob_max`**, a ceiling in metres so sprinting doesn't swing the view wildly.
- **`tilt_angle`**, how far the view rolls when you strafe, in degrees. Quake,
  Half-Life and Quake 2 use 2.0. Source ships 0, so Half-Life 2 has no tilt at all.
  Set it to 0 to switch tilt off.
- **`tilt_speed`**, the sideways speed at which the tilt maxes out. Every engine uses
  200 units, which is 5.08 m/s.

## Working in engine units

The presets were authored in Quake/Source units (1 unit ≈ 1 inch) because that's how the
original cvars are written. Two helpers convert:

```gdscript
config.max_speed = SUCCConfig.source_units(320.0)   # 8.128 m/s
config.gravity = SUCCConfig.quake_units(800.0)      # 20.32 m/s²
```

`quake_units()` is the same maths as `source_units()`, named so a Quake preset reads as
Quake. Both divide by `SUCCConfig.SOURCE_MULT` (39.37 units per metre).

## Two recipes

**A heavy character**, duplicate any preset and set `gravity` to about double,
`max_speed` down, `jump_height` down:

```
gravity = 40.0
max_speed = 6.0
jump_height = 0.7
```

**Low gravity**, keep the speed but drop gravity hard and raise air control:

```
gravity = 1.62
air_acceleration = 200.0
```

Swap either at runtime the same way as a preset:

```gdscript
const MOON: SUCCConfig = preload("res://resources/player/moon.tres")


func enter_low_gravity() -> void:
	config = MOON
	apply_config()
```

## Test your changes

Open `addons/SUCC/demo/test_level.tscn`, assign your config to the player, and run it.
The stairs, ramps, bhop blocks and surf ramp are all sized in engine units, so the
demo shows whether a change broke something. The speed readout under the crosshair
shows both m/s and engine units.

See [The demo gym](../explanation/demo-level.md) for what each lane tests and the exact
dimensions.
