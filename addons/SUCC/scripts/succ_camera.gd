class_name SUCCCamera
extends SpringArm3D

# Camera rig for SUCC, wrapping a SpringArm3D and Camera3D.
# Mouse look yaws the owner SUCC around Y and pitches this node around X.


# SUCC.camera_mode_changed fires for the same transition; connect either, not both.
signal mode_changed(mode: SUCC.CameraMode)


const PITCH_LIMIT_DEG: float = 89.0


@export var invert_mouse_y: bool = false
# Node that receives mouse yaw. Falls back to the parent when unset.
@export var yaw_target: Node3D


var _accumulated: Vector2 = Vector2.ZERO
var _physics_offset: Vector3 = Vector3.ZERO
var _step_offset: float = 0.0
var _bob_offset: float = 0.0
var _bob_time: float = 0.0

@onready var camera: Camera3D = _find_camera()
# Eye height before bob and step offsets. A SpringArm3D overwrites its child
# camera's transform every frame, so the offsets have to move the arm itself.
@onready var view_height: float = position.y:
	set(value):
		view_height = value
		_apply_offsets()


func _find_camera() -> Camera3D:
	for child: Node in get_children():
		if child is Camera3D:
			return child
		for grandchild: Node in child.get_children():
			if grandchild is Camera3D:
				return grandchild
	return null


func set_step_offset(offset: float) -> void:
	_step_offset = offset
	_apply_offsets()


func set_physics_offset(offset: Vector3) -> void:
	_physics_offset = offset
	_apply_offsets()


# Quake V_CalcBob: a sine over a fixed cycle, scaled by horizontal speed.
func update_bob(delta: float, horizontal_speed: float, grounded: bool,
		config: SUCCConfig) -> void:
	if config.bob_amount <= 0.0:
		if not is_zero_approx(_bob_offset):
			_bob_offset = 0.0
			_apply_offsets()
		return

	# Airborne bob would fight the jump arc, so ease it out instead of freezing it.
	if not grounded:
		_bob_offset = move_toward(_bob_offset, 0.0, config.bob_max * 4.0 * delta)
		_apply_offsets()
		return

	_bob_time = fmod(_bob_time + delta, config.bob_cycle)
	var cycle: float = _bob_time / config.bob_cycle
	if cycle < config.bob_up:
		cycle = PI * cycle / config.bob_up
	else:
		cycle = PI + PI * (cycle - config.bob_up) / (1.0 - config.bob_up)

	var bob: float = horizontal_speed * config.bob_amount
	bob = bob * 0.3 + bob * 0.7 * sin(cycle)
	_bob_offset = clampf(bob, -config.bob_max, config.bob_max)
	_apply_offsets()


# Quake V_CalcRoll: tilt proportional to sideways velocity, capped at tilt_angle.
# Positive rotation.z leans left, so strafing right needs a negative angle.
func update_tilt(delta: float, velocity: Vector3, config: SUCCConfig) -> void:
	if config.tilt_angle <= 0.0:
		if not is_zero_approx(rotation.z):
			rotation.z = move_toward(rotation.z, 0.0, deg_to_rad(60.0) * delta)
		return
	var side: float = velocity.dot(global_transform.basis.x)
	var lean: float = 1.0 if side < 0.0 else -1.0
	side = absf(side)
	var value: float = config.tilt_angle
	if side < config.tilt_speed:
		value = side * value / config.tilt_speed
	rotation.z = deg_to_rad(value * lean)


func _apply_offsets() -> void:
	position = _physics_offset + Vector3(
		0.0,
		view_height + _step_offset + _bob_offset,
		0.0,
	)


func handle_input(event: InputEvent, config: SUCCConfig) -> void:
	if not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion: InputEventMouseMotion = event
	# screen_relative skips the content scale factor, so sensitivity does not shift
	# with window size; relative also drifts right under Firefox pointer lock.
	var relative: Vector2 = motion.screen_relative
	relative *= config.mouse_sensitivity * deg_to_rad(config.degrees_per_unit)
	_accumulated += relative
	_apply_rotation()


func _apply_rotation() -> void:
	var body: Node3D = yaw_target if yaw_target else get_parent() as Node3D
	if body == null:
		return

	if body is SUCC and body.config.left_right_steer:
		rotate_object_local(Vector3.DOWN, _accumulated.x)
		orthonormalize()
	else:
		body.rotate_object_local(Vector3.DOWN, _accumulated.x)
		body.orthonormalize()

	var invert: float = -1.0 if invert_mouse_y else 1.0
	rotate_object_local(Vector3.RIGHT, invert * -_accumulated.y)
	rotation.x = clampf(
		rotation.x, deg_to_rad(-PITCH_LIMIT_DEG), deg_to_rad(PITCH_LIMIT_DEG)
	)
	orthonormalize()
	_accumulated = Vector2.ZERO


func apply_mode(mode: SUCC.CameraMode, config: SUCCConfig) -> void:
	match mode:
		SUCC.CameraMode.FIRST_PERSON:
			spring_length = 0.0
		SUCC.CameraMode.THIRD_PERSON:
			spring_length = config.third_person_distance
	mode_changed.emit(mode)
