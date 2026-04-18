@tool
class_name SUCCConfig extends Resource

# Physics and feel tuning for a SUCC character.
# Games swap this resource to create light/medium/heavy characters, low-gravity modes, etc.
# Defaults are Source-engine-inspired (metres where Source uses inches; 39.37 in/m).


@export_group("Gravity & Jump")

## Downward acceleration applied to the character in m/s^2.
## Lower values produce floatier movement (e.g. moon gravity).
@export var gravity: float = 20.32

## Apex height of a standing jump in metres.
## The actual jump impulse is derived from this and [member gravity].
@export var jump_height: float = 1.143

## Factor applied to horizontal velocity when jumping off a ramp (surf boost).
## 1.0 preserves all momentum; 0.0 kills it entirely.
@export_range(0.0, 1.0) var surf_jump_retention: float = 1.0

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

## Minimum speed at which friction applies its full stop contribution.
## Below this threshold friction clamps to stop_speed to prevent micro-sliding.
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
@export var step_height: float = 0.45


@export_group("Camera")

## Eye height above the character origin while standing (m).
@export var standing_view_offset: float = 1.711

## Eye height above the character origin while crouched (m).
@export var crouch_view_offset: float = 0.796

## Duration in seconds to tween the eye between standing and crouched heights.
## Lower values feel snappier; higher values feel weightier.
@export var crouch_time: float = 0.12

## Length of the SpringArm3D when the camera is in third-person mode (m).
@export var third_person_distance: float = 2.0

## When true, the camera lags briefly behind sudden vertical body snaps
## (stepping up stairs or snapping down onto a lower surface) so stair
## traversal feels smooth instead of teleporty. Disable for a rigid feel.
@export var smooth_vertical_step: bool = true

## Speed at which the camera catches up to the body's vertical position after
## a step. Used as a lerp factor per second - higher is snappier, lower is
## floatier. Only applies when [member smooth_vertical_step] is true.
@export_range(1.0, 40.0) var step_smoothing_speed: float = 15.0


@export_group("Mouse")

## Sensitivity multiplier applied to raw mouse motion before conversion.
## Expose this to players as the in-game sensitivity slider.
@export var mouse_sensitivity: float = 3.0

## Source-engine mouse scale: degrees of view rotation per mouse "unit".
## 0.022 is the Source default and makes sensitivity values portable from
## CS:GO / TF2 / Half-Life muscle memory.
@export var degrees_per_unit: float = 0.022
