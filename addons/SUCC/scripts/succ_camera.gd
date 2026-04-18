@tool
class_name SUCCCamera extends SpringArm3D

# Camera rig for SUCC. Wraps a SpringArm3D + Camera3D.
# First-person = spring_length 0, player model hidden.
# Third-person = spring_length from config.third_person_distance, player model visible.
# Mouse look rotates the owner SUCC around Y (yaw) and this node around X (pitch).


const PITCH_LIMIT_DEG: float = 89.0


@export var invert_mouse_y: bool = false
# Emits when the camera switches modes; consumers can toggle player model visibility.
signal mode_changed(mode: int)


var _accumulated: Vector2 = Vector2.ZERO


func handle_input(event: InputEvent, config: SUCCConfig) -> void:
	if not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion: InputEventMouseMotion = event
	var viewport_transform: Transform2D = get_tree().root.get_final_transform()
	var relative: Vector2 = motion.xformed_by(viewport_transform).relative
	relative *= config.mouse_sensitivity * deg_to_rad(config.degrees_per_unit)
	_accumulated += relative
	_apply_rotation()


func _apply_rotation() -> void:
	var parent: Node3D = get_parent() as Node3D
	if parent == null:
		return
	parent.rotate_object_local(Vector3.DOWN, _accumulated.x)
	parent.orthonormalize()

	var invert: float = -1.0 if invert_mouse_y else 1.0
	rotate_object_local(Vector3.RIGHT, invert * -_accumulated.y)
	rotation.x = clamp(rotation.x, deg_to_rad(-PITCH_LIMIT_DEG), deg_to_rad(PITCH_LIMIT_DEG))
	orthonormalize()
	_accumulated = Vector2.ZERO


func apply_mode(mode: int, config: SUCCConfig) -> void:
	match mode:
		SUCC.CameraMode.FIRST_PERSON:
			spring_length = 0.0
		SUCC.CameraMode.THIRD_PERSON:
			spring_length = config.third_person_distance
	mode_changed.emit(mode)
