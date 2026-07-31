class_name SUCCConfig
extends Resource

# Physics and feel tuning for a SUCC character.
# Defaults are Source-engine-inspired; see source_units() for the unit conversion.

const SOURCE_MULT: float = 39.37


enum CrouchTransitionMode {
	SMOOTH,
	SNAP,
}


@export_group("Gravity & Jump")

## Downward acceleration applied to the character in m/s^2.
## Lower values produce floatier movement (e.g. moon gravity).
@export var gravity: float = 20.32

## Apex height of a standing jump in metres.
## The actual jump impulse is derived from this and [member gravity].
@export var jump_height: float = 1.143

## When true, holding jump queues a fresh jump on the next landing frame,
## enabling bunnyhop chains without pixel-perfect timing.
@export var bhop_buffered_jump: bool = true


@export_group("Ground Movement")

## Ground acceleration coefficient. Higher values reach [member max_speed] faster.
## Source default is 10 for sv_accelerate.
@export var acceleration: float = 7.5

## Ground friction coefficient. Higher values decelerate the character faster when
## no input is given. Source default is 4.0 for sv_friction.
@export var friction: float = 4.0

## Floor on the value friction is computed from, so slow movement still decelerates
## at a fixed rate instead of tapering off asymptotically. Source default is 100
## units (2.54 m) for sv_stopspeed.
@export var stop_speed: float = 4.0

## Maximum ground speed in m/s before walking. Sprinting multiplies this
## by [member sprint_speed_modifier].
@export var max_speed: float = 10.16


@export_group("Air Movement")

## Air acceleration coefficient. Values >= 100 enable classic Quake/Source
## air-strafe momentum gains (the core of bhop and surf).
@export var air_acceleration: float = 100.0

## Per-frame cap on how much velocity the air accelerate burst can add (m/s).
## Source default is 30 Hammer units (≈ 0.762 m). This is what makes air strafing
## work: small deltas per frame that accumulate into large directional turns.
@export var max_air_speed: float = 0.762

## Hard ceiling on speed per axis in m/s, as sv_maxvelocity. Source ships 3500
## units (88.9 m). Only applied when [member enforce_max_velocity] is true.
@export var max_velocity: float = 88.9

## When true, clamp each velocity axis to [member max_velocity]. Source enforces
## this; surf and bhop modes usually leave it off so speed can climb freely.
@export var enforce_max_velocity: bool = false


@export_group("Speed Modifiers")

## Multiplier on [member max_speed] while the crouched state is active.
@export_range(0.1, 1.0) var crouch_speed_modifier: float = 1.0 / 3.0

## Multiplier on [member max_speed] while the sprint action is held.
@export_range(1.0, 3.0) var sprint_speed_modifier: float = 1.6


@export_group("Collider")

## Total height of the character's collision shape while standing (m).
@export var stand_height: float = 1.829

## Total height of the character's collision shape while crouched (m).
## The controller tweens between this and [member stand_height].
@export var crouch_height: float = 0.914

## Width (diameter) of the character's collision shape (m).
## For capsule/cylinder colliders this is 2 * radius.
@export var width: float = 0.813

## Maximum vertical step the character can climb in a single move without
## needing to jump. Raising this helps clear taller ledges; too high produces
## climbing-up-walls artifacts.
@export var step_height: float = 0.45 :
	set(val):
		if step_height != val:
			step_height = val
			emit_changed()


@export_group("Camera")

## Eye height above the character origin while standing (m).
@export var standing_view_offset: float = 1.711

## Eye height above the character origin while crouched (m).
@export var crouch_view_offset: float = 0.796

## Whether grounded crouch camera transitions are smoothed or immediate.
@export var crouch_transition_mode: CrouchTransitionMode = \
		CrouchTransitionMode.SMOOTH

## Camera speed while entering a smooth crouch. SurfsUp v2 uses 7.5 m/s.
@export_range(0.1, 30.0, 0.1) var crouch_smoothing_speed: float = 7.5

## Camera speed while leaving a smooth crouch. SurfsUp v2 uses 7.5 m/s.
@export_range(0.1, 30.0, 0.1) var uncrouch_smoothing_speed: float = 7.5

## Length of the SpringArm3D when the camera is in third-person mode (m).
@export var third_person_distance: float = 2.0

## When true, the camera lags briefly behind sudden vertical body snaps
## (stepping up stairs or snapping down onto a lower surface) so stair
## traversal feels smooth instead of teleporty. Disable for a rigid feel.
@export var smooth_vertical_step: bool = true

## Fallback camera smoothing rate when horizontal traversal speed is near zero.
## Moving stair traversal derives its rate from speed and the latest step rise.
@export_range(0.5, 20.0) var step_smoothing_speed: float = 3.81


@export_group("Head Bob & Tilt")

## Vertical head bob amplitude per unit of horizontal speed, as cl_bob.
## Quake uses 0.02, Half-Life 0.01, Source 0.002. Set to 0.0 to disable.
@export_range(0.0, 0.05, 0.001) var bob_amount: float = 0.01

## Seconds for one full bob cycle, as cl_bobcycle. Quake uses 0.6,
## Half-Life and Source 0.8. Lower values bob faster.
@export_range(0.1, 2.0, 0.05) var bob_cycle: float = 0.8

## Fraction of the cycle spent moving up, as cl_bobup. 0.5 is symmetric;
## every engine ships 0.5.
@export_range(0.1, 0.9, 0.05) var bob_up: float = 0.5

## Ceiling on the bob offset in metres, so sprinting does not swing the view
## wildly. Quake clamps the raw bob to 4 units up and 7 down.
@export_range(0.0, 0.5, 0.005) var bob_max: float = 0.102

## Maximum view roll in degrees when strafing, as cl_rollangle / sv_rollangle.
## Quake, Half-Life and Quake 2 use 2.0; Source ships 0, i.e. no tilt.
## Set to 0.0 to disable.
@export_range(0.0, 15.0, 0.1) var tilt_angle: float = 2.0

## Sideways speed in m/s at which the tilt reaches [member tilt_angle], as
## cl_rollspeed. Every engine uses 200 units (5.08 m/s).
@export_range(0.5, 20.0, 0.1) var tilt_speed: float = 5.08


@export_group("Mouse")

## Sensitivity multiplier applied to raw mouse motion before conversion.
## Expose this to players as the in-game sensitivity slider.
@export var mouse_sensitivity: float = 3.0

## Source-engine mouse scale: degrees of view rotation per mouse "unit".
## 0.022 is the Source default and makes sensitivity values portable from
## CS:GO / TF2 / Half-Life muscle memory.
@export var degrees_per_unit: float = 0.022


# Convert Source/Hammer units to metres.
static func source_units(value: float) -> float:
	return value / SOURCE_MULT


# Quake, Quake 2 and GoldSrc share Source's inch-based unit scale.
static func quake_units(value: float) -> float:
	return source_units(value)
