# Tune your own movement

Every number that decides how your character feels lives in a `SUCCConfig` resource. No
code required.

## Start from a copy

1. Right-click a file in `addons/SUCC/resources/` and choose **Duplicate**.
2. Save the copy in your own project, for example `res://resources/player/config.tres`.
3. Assign it to your character's **Config** property.

Duplicate rather than edit in place, so addon updates don't overwrite your tuning.

## What each knob actually does

The values are grouped in the Inspector. These are the ones worth reaching for first.

### Making it faster or slower

- **`max_speed`**, top speed on the ground, in metres per second. The single biggest
  lever on feel.
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

- **`air_acceleration`**, how strongly you can steer mid-air. Around 100 gives classic
  Quake and Source air control. Set it near 1 and you get Quake 2's near-total lack of
  air steering.
- **`max_air_speed`**, the per-frame cap on air acceleration, 0.762 m (30 units) in
  every Valve and id engine. **This small number is what makes bunnyhopping work.**
  Raising it does not make you faster; it makes air control feel mushy. Leave it alone
  unless you know what you're changing.

[How the movement works](../explanation/movement.md) explains why.

### Body size and camera height

- **`stand_height`** / **`crouch_height`**, total height of the collision box.
- **`width`**, how wide the character is.
- **`standing_view_offset`** / **`crouch_view_offset`**, eye height above the feet.
- **`step_height`**, the tallest ledge you can walk up without jumping. All four
  engines use 18 units (0.457 m). Much higher and you start climbing walls.

### Crouch timing

- **`crouch_time`** / **`uncrouch_time`**, seconds to ease the camera down and back up
  while on the ground. Air crouches are always instant, matching Source.

## Working in engine units

The presets were authored in Quake/Source units (1 unit ≈ 1 inch) because that's how the
original cvars are written. Two helpers convert:

```gdscript
config.max_speed = SUCCConfig.source_units(320.0)   # 8.128 m/s
config.gravity = SUCCConfig.quake_units(800.0)      # 20.32 m/s²
```

`quake_units()` is the same maths as `source_units()`; it exists so a Quake preset reads
as Quake. Both divide by `SUCCConfig.SOURCE_MULT` (39.37 units per metre).

## Two recipes

**A heavy, ponderous character**, duplicate any preset and set `gravity` to about
double, `max_speed` down, `jump_height` down:

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
demo tells you quickly whether a change broke something. The speed readout under the
crosshair shows both m/s and engine units.

See [The demo gym](../explanation/demo-level.md) for what each lane tests and the exact
dimensions.
