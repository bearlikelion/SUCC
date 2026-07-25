# Engine Presets

SUCC ships five `SUCCConfig` resources in `addons/SUCC/resources/`. Four reproduce the movement
of a specific id/Valve engine; `default_config.tres` is SurfsUp's own tuning.

Assign one to a `SUCC` node's `config` property, or swap at runtime:

```gdscript
player.config = load("res://addons/SUCC/resources/quake.tres") as SUCCConfig
player.apply_config()
```

`apply_config()` re-derives the collider, floor snap length and camera height. Call it whenever
you replace `config` after `_ready()`.

## Unit helpers

All four engines use 1 unit = 1 inch. `SUCCConfig` exposes the conversion as static methods so
preset values stay auditable:

```gdscript
const SOURCE_MULT: float = 39.37

static func source_units(value: float) -> float:
	return value / SOURCE_MULT


static func quake_units(value: float) -> float:
	return source_units(value)
```

`quake_units()` is an alias; it exists to document intent at the call site. Use them when
authoring values in engine units:

```gdscript
config.max_speed = SUCCConfig.source_units(320.0)   # 8.128 m/s
```

## What each preset encodes

| | GoldSrc | Quake | Quake 2 | Source (HL2) |
|---|---|---|---|---|
| gravity | 800 | 800 | 800 | **600** |
| max ground speed | 320 | 320 | **300** | **190** (sprint 320) |
| acceleration | 10 | 10 | 10 | 10 |
| air acceleration | 10 | 10 | **1.0** | 10 |
| air speed cap | 30 | 30 | **full wishspeed** | 30 |
| friction | 4 | 4 | **6** | 4 |
| stop speed | 100 | 100 | 100 | 100 |
| jump impulse | 268.33 | 270 | 270 | **160** |
| step height | 18 | 18 | 18 | 18 |
| stand hull | 72 | 56 | 56 | 72 |
| duck hull | 36 | none | 28 | 36 |
| eye height | 64 | 46 | 46 | 64 |
| ducked eye | 30 | none | 22 | 28 |

Values are in engine units. Jump impulse is derived by SUCC as `sqrt(2 * gravity * jump_height)`,
so `jump_height` is back-solved from each engine's real impulse rather than copied from its
nominal jump-height constant.

## Caveats worth knowing

These are the places where the shipped values disagree with commonly cited numbers. Each was
read from the engine source rather than from documentation.

### Quake 2 is not Quake 1 with a new coat of paint

`pm_maxspeed` is **300**, not 320, and `pm_friction` is **6**, not 4
(`qcommon/pmove.c:54,59`). Ducked view height is **-2** (`:1020`); the commonly quoted `4` is the
ducked hull top, not the eye.

More importantly, Quake 2 **cannot air-strafe**. `pm_airaccelerate` defaults to 0
(`qcommon/pmove.c:57`) and is hard-forced to 0 outside deathmatch
(`server/sv_init.c:197-205`). When it is 0, Quake 2 does not skip air acceleration - it falls
through to ground-style `PM_Accelerate(wishdir, wishspeed, 1)` (`:654-657`), which has no
30-unit clamp. That missing clamp is precisely what prevents speed gain from strafing.

SUCC's `_air_accelerate()` returns early once the cap is reached, so a literal
`air_acceleration = 0.0` would give *zero* air control - stricter than the real game. The
preset therefore uses `air_acceleration = 1.0` with `max_air_speed` raised to full `max_speed`,
which reproduces the observed behaviour: weak air control that dies at ~300 u/s.

### Half-Life 2 walks at 190, not 320

`sv_maxspeed` is 320, but it is only a ceiling. `CHL2_Player::SetupMove` sets
`m_flClientMaxSpeed` from `hl2_normspeed` (**190**), `hl2_walkspeed` (150) or `hl2_sprintspeed`
(320) (`game/server/hl2/hl2_player.cpp:86-88`), and `CheckParameters` takes the minimum of the
two (`gamemovement.cpp:996-999`).

Gravity is **600** under `HL2_DLL`, not 800 (`movevars_shared.cpp:19-20`), and the jump impulse
is a hardcoded **160.0** - about 0.8% above `sqrt(2 * 600 * 21)` = 158.745
(`gamemovement.cpp:2435`).

`source.tres` encodes this as `max_speed` 190u with `sprint_speed_modifier` 1.6842, so sprint
lands on 320u. The 150u slow-walk has no SUCC equivalent.

### QuakeWorld's sv_airaccelerate is dead code

QuakeWorld registers `sv_airaccelerate` with a default of 0.7 (`QW/server/sv_phys.c:49`) and
transmits it to clients, but `PM_AirMove` passes `movevars.accelerate` (10) into
`PM_AirAccelerate` (`QW/client/pmove.c:548`). `movevars.airaccelerate` is never read. Quake 2
has the same bug (`qcommon/pmove.c:655`). `quake.tres` uses 10.

Note also that NetQuake *does* have the 30-unit air clamp (`WinQuake/sv_user.c:207-226`); it is
not a QuakeWorld addition. The only difference is the unused cvar.

### GoldSrc values are engine-side

The Half-Life engine is closed-source. Only gravity (800) and step size (18) are set by the
game DLL (`dlls/world.cpp:482-483`); `sv_maxspeed`, `sv_accelerate`, `sv_airaccelerate`,
`sv_friction` and `sv_stopspeed` are read through `pmove->movevars->*` and have no default in
the SDK. The 320/10/10/4/100 values in `goldsrc.tres` are the well-known engine defaults, not
values quoted from this source tree.

`goldsrc.tres` also does not model two GoldSrc specifics: `PM_PreventMegaBunnyJumping`, which
crops velocity to 0.65x once you exceed 1.7x `maxspeed` (`pm_shared.c:2436-2466`), and the
`PLAYER_DUCKING_MULTIPLIER` of 0.333 applied to move input rather than to the speed cap
(`:123`).

### Origin conventions differ

Quake, QuakeWorld, Quake 2 and GoldSrc put the player origin at mid-body, so their hull minimums
are negative. Source moved it to the feet. SUCC's collider is centre-anchored with the body
origin at the feet, so eye heights in the presets are converted:
`view_offset + abs(hull_min_z)`. GoldSrc's 28 becomes 64; Quake's 22 becomes 46.

### enable_surf changes jump behaviour

`SUCC._jump()` adds the impulse along the floor normal when `enable_surf` is true, which is a
SurfsUp surf behaviour - no id or Valve engine does this. All four set or add to the vertical
axis only. For engine-authentic jumps on ramps, set `enable_surf = false`. The demo binds `F`
to toggle it so you can feel the difference on the same ramp.

## Trying them out

The demo level (`addons/SUCC/demo/test_level.tscn`) is a parkour gym built for exactly this.
Keys **1-5** swap presets live and the HUD shows the current one with its headline cvars. The
speedometer reads both m/s and engine u/s, so you can check a preset against its source
numbers directly.

Obstacles are sized in engine units: stair risers from 8u to 40u plus one 20u step that exceeds
the 18u limit and must be jumped, slants at 15/30/44 degrees, a bhop ladder with 96/112/128/144u
gaps, a 55 degree surf trough, a 40 degree slide, and a 40u crouch corridor that blocks a
standing 72u hull but passes a ducked 36u one.
