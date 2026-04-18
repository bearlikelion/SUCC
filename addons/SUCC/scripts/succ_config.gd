@tool
class_name SUCCConfig extends Resource

# Physics and feel tuning for a SUCC character.
# Games swap this resource to create light/medium/heavy characters, low-gravity modes, etc.
# Defaults are Source-engine-inspired (metres where Source uses inches; 39.37 in/m).


@export_group("Gravity & Jump")
@export var gravity: float = 20.32
@export var jump_height: float = 1.143
# Factor applied to velocity when jumping off a ramp (surf). 1.0 = no dampening.
@export_range(0.0, 1.0) var surf_jump_retention: float = 1.0
# Allow holding jump to bunnyhop (queues a jump on next landing).
@export var bhop_buffered_jump: bool = true


@export_group("Ground Movement")
# Ground acceleration coefficient (how quickly you reach max speed on the ground).
@export var acceleration: float = 7.5
# Ground friction. Higher = stops faster.
@export var friction: float = 4.0
# Minimum speed at which friction applies its full stop contribution.
@export var stop_speed: float = 4.0
# Max ground speed (m/s).
@export var max_speed: float = 10.16


@export_group("Air Movement")
# Air acceleration coefficient. Values >= 100 enable air-strafe momentum gains.
@export var air_acceleration: float = 100.0
# Max speed the per-frame air-accel burst can add (m/s). Source default 30 units ≈ 0.762 m.
@export var max_air_speed: float = 0.762


@export_group("Speed Modifiers")
@export_range(0.1, 1.0) var crouch_speed_modifier: float = 1.0 / 3.0
@export_range(1.0, 3.0) var sprint_speed_modifier: float = 1.6


@export_group("Collider")
# Standing collider height (m).
@export var stand_height: float = 1.829
# Crouched collider height (m).
@export var crouch_height: float = 0.914
# Collider width / radius (m).
@export var width: float = 0.813
# Max step height the controller can climb without jumping.
@export var step_height: float = 0.45


@export_group("Camera")
# Camera eye height above the character origin while standing.
@export var standing_view_offset: float = 1.711
# Camera eye height above the character origin while crouched.
@export var crouch_view_offset: float = 0.796
# Seconds to tween between standing and crouched camera height.
@export var crouch_time: float = 0.12
# Third-person camera spring length.
@export var third_person_distance: float = 2.0
# When true, the camera lags behind sudden vertical body snaps (step-up/down)
# so stair traversal feels smooth rather than teleporty.
@export var smooth_vertical_step: bool = true
# How fast the camera catches up to the body's vertical position after a step.
# Higher = snappier; lower = floatier. Used as a lerp factor per second.
@export_range(1.0, 40.0) var step_smoothing_speed: float = 15.0


@export_group("Mouse")
# Mouse sensitivity multiplier.
@export var mouse_sensitivity: float = 3.0
# Source-style mouse scale factor.
@export var degrees_per_unit: float = 0.022
