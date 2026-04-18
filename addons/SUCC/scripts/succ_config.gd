@tool
class_name SUCCConfig extends Resource

# Physics and feel tuning for a SUCC character.
# Games swap this resource to create light/medium/heavy characters, low-gravity modes, etc.
# Defaults are Source-engine-inspired (metres where Source uses inches; 39.37 in/m).


# Gravity in m/s^2. Source default is 800 units/s^2 ≈ 20.32 m/s^2.
@export var gravity: float = 20.32

# Ground acceleration coefficient (how quickly you reach max speed on the ground).
@export var acceleration: float = 7.5

# Air acceleration coefficient. High values (>=100) enable air-strafe momentum gains.
@export var air_acceleration: float = 100.0

# Ground friction. Higher = stops faster.
@export var friction: float = 4.0

# Minimum speed at which friction applies its full stop contribution.
@export var stop_speed: float = 4.0

# Max ground speed (m/s).
@export var max_speed: float = 10.16

# Max speed the per-frame air-accel burst can add (m/s). Source default 30 units ≈ 0.762 m.
@export var max_air_speed: float = 0.762

# Speed modifier applied while crouched.
@export_range(0.1, 1.0) var crouch_speed_modifier: float = 1.0 / 3.0

# Speed modifier applied while sprinting (ground only).
@export_range(1.0, 3.0) var sprint_speed_modifier: float = 1.6

# Jump height in metres (vertical apex from ground).
@export var jump_height: float = 1.143

# Max step height the controller can climb without jumping.
@export var step_height: float = 0.45

# Standing collider height (m).
@export var stand_height: float = 1.829

# Crouched collider height (m).
@export var crouch_height: float = 0.914

# Collider width / radius (m).
@export var width: float = 0.813

# Seconds to tween between standing and crouched camera height.
@export var crouch_time: float = 0.12

# Camera eye height above the character origin while standing.
@export var standing_view_offset: float = 1.711

# Camera eye height above the character origin while crouched.
@export var crouch_view_offset: float = 0.796

# Mouse sensitivity multiplier. degrees_per_unit is the Source-engine-style scale factor.
@export var mouse_sensitivity: float = 3.0
@export var degrees_per_unit: float = 0.022

# Third-person camera spring length.
@export var third_person_distance: float = 2.0

# Allow holding jump to bunnyhop (queues a jump on next landing).
@export var bhop_buffered_jump: bool = true

# Factor applied to velocity when jumping off a ramp (surf). 1.0 = no dampening.
@export_range(0.0, 1.0) var surf_jump_retention: float = 1.0
