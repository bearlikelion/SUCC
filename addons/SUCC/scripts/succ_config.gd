class_name SUCCConfig
extends Resource

# Physics and feel tuning for a SUCC character. Defaults are Source-inspired.

const SOURCE_MULT: float = 39.37


enum CrouchTransitionMode {
	SMOOTH,
	SNAP,
}

@export_group("Control Options")

## Steer with left and right instead of look direction
@export var left_right_steer := false
@export var left_right_steer_speed := 10

@export_group("Gravity & Jump")

## Downward acceleration in m/s^2. Lower values feel floatier.
@export var gravity: float = 20.32

## Apex height of a standing jump in metres. The impulse derives from this
## and [member gravity].
@export var jump_height: float = 1.143

## When true, holding jump queues a fresh jump on the next landing frame,
## so bunnyhop chains need no pixel-perfect timing.
@export var bhop_buffered_jump: bool = true


@export_group("Ground Movement")

## Ground acceleration coefficient (sv_accelerate). Higher reaches
## [member max_speed] faster. Source default 10.
@export var acceleration: float = 7.5

## Ground friction coefficient (sv_friction). Source default 4.0.
@export var friction: float = 4.0

## Rotation acceleration coefficient for use with left/right move. Higher values reach [member max_speed] faster.
## Source default is 10 for sv_accelerate.
@export var rotation_acceleration: float = 1

## Floor on the value friction is computed from, so slow movement still stops
## instead of tapering off (sv_stopspeed). Source default 100u (2.54 m).
@export var stop_speed: float = 4.0

## Maximum ground speed in m/s. Sprinting multiplies this by
## [member sprint_speed_modifier].
@export var max_speed: float = 10.16


@export_group("Air Movement")

## Air acceleration coefficient. Values >= 100 give classic Quake/Source
## air-strafe momentum gains, the core of bhop and surf.
@export var air_acceleration: float = 100.0

## Per-frame cap on the air accelerate burst (m/s). Source ships 30u (0.762 m);
## the small per-frame deltas are what make air strafing work.
@export var max_air_speed: float = 0.762

## Per-axis speed ceiling in m/s (sv_maxvelocity). Source ships 3500u.
## Applied only when [member enforce_max_velocity] is true.
@export var max_velocity: float = 88.9

## Hard ceiling on the rotational speed when using left/right turn
@export var max_turn_velocity: float = 10.0

## When true, clamp each velocity axis to [member max_velocity]. Surf and bhop
## modes usually leave it off so speed can climb freely.
@export var enforce_max_velocity: bool = false


@export_group("Speed Modifiers")

## Multiplier on [member max_speed] while the crouched state is active.
@export_range(0.1, 1.0) var crouch_speed_modifier: float = 1.0 / 3.0

## Multiplier on [member max_speed] while the sprint action is held.
@export_range(1.0, 3.0) var sprint_speed_modifier: float = 1.6


@export_group("Collider")

## Total height of the character's collision shape while standing (m).
@export var stand_height: float = 1.829

## Crouched collision height (m). The controller tweens between this and
## [member stand_height].
@export var crouch_height: float = 0.914

## Collider width in metres, so 2 * radius for a capsule or cylinder.
@export var width: float = 0.813

## Tallest step climbable without jumping. Too high and the body climbs walls.
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

## When true, the camera lags briefly behind vertical body snaps so stairs feel
## smooth instead of teleporty. Disable for a rigid feel.
@export var smooth_vertical_step: bool = true

## Fallback smoothing rate when horizontal speed is near zero; moving traversal
## derives its rate from speed and the latest step rise.
@export_range(0.5, 20.0) var step_smoothing_speed: float = 3.81


@export_group("Head Bob & Tilt")

## Bob amplitude per unit of horizontal speed (cl_bob). Quake 0.02,
## Half-Life 0.01, Source 0.002. Set 0.0 to disable.
@export_range(0.0, 0.05, 0.001) var bob_amount: float = 0.01

## Seconds per bob cycle (cl_bobcycle). Quake 0.6, Half-Life and Source 0.8.
@export_range(0.1, 2.0, 0.05) var bob_cycle: float = 0.8

## Fraction of the cycle spent moving up (cl_bobup). Every engine ships 0.5.
@export_range(0.1, 0.9, 0.05) var bob_up: float = 0.5

## Ceiling on the bob offset in metres, so sprinting cannot swing the view wildly.
@export_range(0.0, 0.5, 0.005) var bob_max: float = 0.102

## Max view roll in degrees when strafing (cl_rollangle). Quake, Half-Life and
## Quake 2 use 2.0; Source ships 0. Set 0.0 to disable.
@export_range(0.0, 15.0, 0.1) var tilt_angle: float = 2.0

## Sideways speed at which tilt reaches [member tilt_angle] (cl_rollspeed).
## Every engine uses 200u (5.08 m/s).
@export_range(0.5, 20.0, 0.1) var tilt_speed: float = 5.08


@export_group("Mouse")

## Sensitivity multiplier on raw mouse motion. Expose as the in-game slider.
@export var mouse_sensitivity: float = 3.0

## Degrees of view rotation per mouse unit. The Source default 0.022 keeps
## sensitivity values portable from CS:GO / TF2 / Half-Life.
@export var degrees_per_unit: float = 0.022


# Convert Source/Hammer units to metres.
static func source_units(value: float) -> float:
	return value / SOURCE_MULT


# Quake, Quake 2 and GoldSrc share Source's inch-based unit scale.
static func quake_units(value: float) -> float:
	return source_units(value)
