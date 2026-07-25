# How accurate are the presets?

The four engine presets were built by reading the original engine source, not by copying
numbers from wikis. Several of the values that came out surprised us, and they look like
mistakes until you see where they come from. This page is the receipts.

Every citation below is a file and line in the published source for that engine.

## Quake 2 is not "Quake 1 but newer"

Three values differ from what almost every reference says:

| | Commonly quoted | Actually in the source |
|---|---|---|
| Max speed | 320 | **300** (`qcommon/pmove.c:54`) |
| Friction | 4 | **6** (`qcommon/pmove.c:59`) |
| Ducked view height | 4 | **-2** (`qcommon/pmove.c:1020`) |

The ducked view height is a mix-up worth naming: `4` is the ducked hull's *top*
(`maxs[2]`, line 1019). The eye height on the next line is `-2`.

The friction difference is the one you feel. Quake 2 at 6 is visibly stickier than Quake
or Half-Life at 4.

### Quake 2 cannot air-strafe, and it's deliberate

`pm_airaccelerate` defaults to `0` (`qcommon/pmove.c:57`), and the server forces it to
`0` outside deathmatch regardless of the cvar (`server/sv_init.c:197-205`). Single-player
Quake 2 has no strafe-jumping at all.

But `0` doesn't mean "no air control". When air acceleration is off, Quake 2 falls through
to ordinary ground-style acceleration with a coefficient of 1
(`qcommon/pmove.c:654-657`):

```c
if (pm_airaccelerate)
    PM_AirAccelerate (wishdir, wishspeed, pm_accelerate);
else
    PM_Accelerate (wishdir, wishspeed, 1);
```

The difference between those two functions is a single line: `PM_AirAccelerate` clamps the
target to 30 units, `PM_Accelerate` does not. That clamp is exactly what makes
strafe-jumping possible ([why](movement.md#why-holding-jump-makes-you-faster)), so
without it you get weak air steering that dies once you're at full speed.

SUCC's air acceleration returns early once its cap is reached, so setting
`air_acceleration = 0.0` would give *zero* air control, stricter than the real game. The
preset therefore uses `air_acceleration = 1.0` with the air cap raised to full
`max_speed`, which reproduces what Quake 2 actually does.

## Half-Life 2 walks at 190, not 320

`sv_maxspeed` is 320 in Source, and that's the number everyone cites. It's only a ceiling.

`CHL2_Player::SetupMove` picks the real speed from one of three cvars
(`game/server/hl2/hl2_player.cpp:86-88`):

- `hl2_walkspeed`, 150
- `hl2_normspeed`, **190**
- `hl2_sprintspeed`, 320

then `CheckParameters` takes the smaller of that and `sv_maxspeed`
(`game/shared/gamemovement.cpp:996-999`). So ordinary HL2 walking is 190 units per
second, and 320 is what you get holding sprint.

Two more HL2 surprises:

- **Gravity is 600, not 800** (`game/shared/movevars_shared.cpp:19-20`). This is why HL2
  feels floaty.
- **The jump impulse is a hardcoded `160.0`** (`game/shared/gamemovement.cpp:2435`), not
  the `sqrt(2 * gravity * 21)` the surrounding code implies, that would be 158.745. The
  160 is a deliberate rounding up.

`source.tres` encodes all three: `max_speed` 190 units, `sprint_speed_modifier` 1.6842 so
sprint lands exactly on 320, gravity 600, jump 160. The 150-unit slow walk has no SUCC
equivalent.

## QuakeWorld's air acceleration setting does nothing

QuakeWorld registers `sv_airaccelerate` with a default of 0.7
(`QW/server/sv_phys.c:49`) and even sends it to clients over the network. Nothing ever
reads it. `PM_AirMove` passes the *ground* acceleration value instead
(`QW/client/pmove.c:548`):

```c
PM_AirAccelerate (wishdir, wishspeed, movevars.accelerate);
```

Quake 2 has the same bug (`qcommon/pmove.c:655`). Source is the only one of the four that
genuinely uses its own air acceleration cvar. `quake.tres` therefore uses 10, the ground
value, because that's what the engine really applies.

Also worth correcting a common claim: NetQuake **does** have the 30-unit air clamp
(`WinQuake/sv_user.c:207-226`). Strafe-jumping is not a QuakeWorld addition. The only
difference is the unused cvar.

## GoldSrc values come from the engine, not the SDK

The Half-Life engine is closed source. Only two movement values are set by the game DLL
(`dlls/world.cpp:482-483`): gravity 800 and step size 18.

`sv_maxspeed`, `sv_accelerate`, `sv_airaccelerate`, `sv_friction` and `sv_stopspeed` are
read through `pmove->movevars->*` and have no default anywhere in the published SDK. The
320 / 10 / 10 / 4 / 100 in `goldsrc.tres` are the well-known engine defaults, and we're
labelling them as such rather than pretending they came from this source tree.

Two GoldSrc specifics `goldsrc.tres` does **not** model:

- `PM_PreventMegaBunnyJumping` crops your velocity to 65% once you exceed 1.7× max speed
  (`pm_shared/pm_shared.c:2436-2466`). Half-Life actively punishes bunnyhopping; SUCC
  doesn't reproduce that.
- `PLAYER_DUCKING_MULTIPLIER` of 0.333 is applied to the move *input* rather than the
  speed cap (`pm_shared/pm_shared.c:123`).

## Everything is measured in inches

All four engines use 1 unit ≈ 1 inch, though only two places in the source say so
outright: `halflife/dlls/world.cpp:482` comments gravity 800 as "67ft/sec", and
`source-sdk-2013/src/game/shared/shareddefs.h:409-410` writes a fall speed as
`sqrt(2 * gravity * 60 * 12)`, the `* 12` being twelve inches to the foot.

SUCC uses 39.37 units per metre, which is Source's own approximation. The exact value
would be 39.3701; the difference is 0.03% and Valve's number is the one the original
cvars were tuned against.

## The origin sits in a different place

Quake, QuakeWorld, Quake 2 and GoldSrc put the player's origin at mid-body, so their hull
minimums are negative. Source moved it to the feet.

SUCC's collision box is anchored at the feet like Source, so eye heights for the older
engines are converted: `view_offset + abs(hull_min_z)`. GoldSrc's 28 becomes 64; Quake's
22 becomes 46. If you compare `quake.tres` against a Quake source dump and the eye
heights look wrong, that's why.

## Jump heights are back-solved

SUCC's config takes a jump *height* and works out the impulse as
`sqrt(2 * gravity * jump_height)`. The engines specify the impulse directly. So each
preset's `jump_height` is solved backwards from the real impulse rather than copied from
the engine's nominal jump-height constant:

| Preset | Real impulse | Back-solved height |
|---|---|---|
| `goldsrc.tres` | 268.33 (`sqrt(2*800*45)`) | 45 units |
| `quake.tres` | 270 | 45.5625 units |
| `quake2.tres` | 270 | 45.5625 units |
| `source.tres` | 160 | 21.333 units |

Note the last row: HL2's hardcoded 160 does not correspond to its own
`GAMEMOVEMENT_JUMP_HEIGHT` of 21, so the real height is 21.33.

## Checking it yourself

Every preset's values round-trip back to these engine numbers exactly. If you want to
verify, load a config and multiply by `SUCCConfig.SOURCE_MULT`:

```gdscript
var cfg: SUCCConfig = load("res://addons/SUCC/resources/goldsrc.tres")
print(cfg.max_speed * SUCCConfig.SOURCE_MULT)                        # 320
print(sqrt(2.0 * cfg.gravity * cfg.jump_height) * SUCCConfig.SOURCE_MULT)  # 268.33
```
