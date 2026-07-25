# Use a movement preset

SUCC ships five ready-made movement feels in `addons/SUCC/resources/`. Each is a
`SUCCConfig` resource. Swapping one changes gravity, speed, friction, jump height, hull
size and eye height together.

## Pick one

| File | Feels like | Pick it when |
|---|---|---|
| `default_config.tres` | SurfsUp | You want fast, slidey surf movement. The quickest of the five. |
| `goldsrc.tres` | Half-Life, Counter-Strike 1.6 | You want the classic bhop feel most players recognise. |
| `quake.tres` | Quake, QuakeWorld | You want strafe-jumping and a shorter, lower-slung character. |
| `quake2.tres` | Quake 2 | You want heavier, grippier movement with no air control. |
| `source.tres` | Half-Life 2 | You want floaty jumps, a walk/sprint split, and slower ground speed. |

For the exact numbers see [Preset values](../reference/presets.md). For why they differ
in surprising ways, see [How accurate are the presets?](../explanation/engine-accuracy.md).

## Assign one in the editor

1. Select your SUCC character node.
2. In the Inspector, find the **Config** property.
3. Click the folder icon and choose one of the five `.tres` files.

Run the scene. That's it.

## Swap one while the game is running

Assign the new config, then call `apply_config()`. That second call matters: it rebuilds
the collision shape, the floor snap distance and the camera height from the new values.
Without it your character keeps the old body.

```gdscript
const QUAKE: SUCCConfig = preload("res://addons/SUCC/resources/quake.tres")


func switch_to_quake() -> void:
	config = QUAKE
	apply_config()
```

Swapping resets the crouch state, so a crouched character stands up.

## Offer presets as a menu

Presets are plain resources, so a settings screen is just a list of paths:

```gdscript
const PRESETS: Array[String] = [
	"res://addons/SUCC/resources/default_config.tres",
	"res://addons/SUCC/resources/goldsrc.tres",
	"res://addons/SUCC/resources/quake.tres",
	"res://addons/SUCC/resources/quake2.tres",
	"res://addons/SUCC/resources/source.tres",
]


func apply_preset(index: int) -> void:
	var picked: SUCCConfig = load(PRESETS[index]) as SUCCConfig
	if picked == null:
		push_error("Could not load preset %d" % index)
		return
	config = picked
	apply_config()
```

The demo level does exactly this on keys 1-5. Read
`addons/SUCC/demo/test_level.gd` for a working version with a HUD readout.

## One thing to turn off for authenticity

`enable_surf` is on by default. It adds the jump impulse along the floor's normal, so
jumping off a ramp launches you along the slope. That's a SurfsUp behaviour: no id or
Valve engine does it, they all jump straight up.

If you want engine-accurate jumps, turn it off:

```gdscript
enable_surf = false
```

Leave it on if you want surf ramps to work the way surf maps expect.

## Don't edit the shipped files

Editing `goldsrc.tres` in place means the next addon update overwrites your changes,
and the file no longer matches its name. Duplicate it first, then edit the copy - see
[Tune your own movement](tune-movement.md).
