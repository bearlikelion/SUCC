@tool
class_name SUCC extends CharacterBody3D

# SurfsUp Character Controller.
# Multiplayer-focused, inheritable, state-based first/third-person controller.
# Extend this class to build your game's player. Physics tuning lives in SUCCConfig.
#
# Required input actions (rebindable via input_actions export):
#   forward, back, left, right, jump, duck, crouch, sprint
# Missing actions produce editor configuration warnings and are disabled at runtime.


signal movement_state_changed(old_state: int, new_state: int)
signal game_state_changed(old_state: int, new_state: int)
signal jumped
signal landed(fall_velocity: float)
signal camera_mode_changed(mode: int)


enum CameraMode { FIRST_PERSON, THIRD_PERSON }
enum FloorType { NONE, FLOOR, RAMP }
enum MovementState { IDLE, WALKING, SPRINTING, CROUCHING, DUCKING, JUMPING, FALLING, AIR }
enum GameState { ACTIVE, FROZEN, DISABLED }


const DEFAULT_INPUT_ACTIONS: Dictionary = {
	"forward": "forward",
	"back": "back",
	"left": "left",
	"right": "right",
	"jump": "jump",
	"duck": "duck",
	"crouch": "crouch",
	"sprint": "sprint",
}
const FLOOR_COL_MARGIN: float = 0.02


@export var config: SUCCConfig
# Maps logical action names to project InputMap action names.
# Override in the inspector to use different bindings (e.g. "jump" -> "ui_accept").
@export var input_actions: Dictionary = DEFAULT_INPUT_ACTIONS.duplicate()
@export var enable_bhop: bool = true
@export var enable_surf: bool = true
@export var default_camera_mode: CameraMode = CameraMode.FIRST_PERSON


@onready var collision: CollisionShape3D = $Collision
@onready var camera_rig: SUCCCamera = $CameraRig


var movement_state: int = MovementState.IDLE
var game_state: int = GameState.ACTIVE
var camera_mode: int = CameraMode.FIRST_PERSON
var floor_type: int = FloorType.NONE

var move_input: Vector2 = Vector2.ZERO
var move_dir: Vector3 = Vector3.ZERO
var wish_sprint: bool = false
var wish_jump: bool = false
var wish_crouch: bool = false
var crouched: bool = false
var was_on_floor: bool = false
var _action_available: Dictionary = {}
var _crouch_tween: Tween


# ------------------------------------------------------------------ lifecycle

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if config == null:
		config = load("res://addons/SUCC/resources/default_config.tres") as SUCCConfig
	_validate_input_actions()
	_apply_collider_size(config.stand_height)
	camera_mode = default_camera_mode
	if camera_rig:
		camera_rig.apply_mode(camera_mode, config)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	for logical: String in DEFAULT_INPUT_ACTIONS.keys():
		var action: String = input_actions.get(logical, DEFAULT_INPUT_ACTIONS[logical])
		if not InputMap.has_action(action):
			warnings.append("Input action '%s' (logical '%s') is not in the project's InputMap. This movement will be disabled at runtime." % [action, logical])
	if not has_node("Collision"):
		warnings.append("Missing child CollisionShape3D named 'Collision'.")
	if not has_node("CameraRig"):
		warnings.append("Missing child SUCCCamera node named 'CameraRig'.")
	return warnings


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_multiplayer_authority():
		return
	if _can_look() and camera_rig:
		camera_rig.handle_input(event, config)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _gather_movement_input() -> void:
	var fwd: float = _action_strength("forward")
	var back: float = _action_strength("back")
	var left: float = _action_strength("left")
	var right: float = _action_strength("right")
	move_input = Vector2(right - left, back - fwd).normalized()

	move_dir = Vector3(move_input.x, 0.0, move_input.y)
	move_dir = move_dir.normalized() * config.max_speed
	move_dir = move_dir.rotated(Vector3.UP, global_rotation.y)

	wish_sprint = _action_pressed("sprint")
	wish_jump = _action_pressed("jump") if enable_bhop else _action_just_pressed("jump")
	wish_crouch = _action_pressed("duck") or _action_pressed("crouch")


# ------------------------------------------------------------------ physics

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not is_multiplayer_authority():
		return
	if game_state == GameState.DISABLED or not _can_move():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_gather_movement_input()
	_set_floor_type(delta)
	_apply_gravity(delta)
	_set_velocity(delta)
	_move_body()
	_update_movement_state()


func _apply_gravity(delta: float) -> void:
	if floor_type == FloorType.NONE:
		velocity.y -= config.gravity * delta


func _set_velocity(delta: float) -> void:
	if wish_crouch and not crouched:
		_crouch()
	elif crouched and not wish_crouch:
		_uncrouch()

	if floor_type == FloorType.NONE:
		_air_accelerate(delta, move_dir)
		return

	if wish_jump:
		_jump(delta)
		_air_accelerate(delta, move_dir)
	else:
		_friction(delta, 1.0)
		_accelerate(delta, move_dir)


func _friction(delta: float, strength: float) -> void:
	var temp_speed: float = velocity.length()
	var control: float = config.stop_speed if temp_speed < config.stop_speed else temp_speed
	var drop: float = control * config.friction * strength * delta
	var new_speed: float = max(temp_speed - drop, 0.0)
	if temp_speed > 0.0:
		new_speed /= temp_speed
	velocity.x *= new_speed
	velocity.z *= new_speed


func _accelerate(delta: float, wish_dir: Vector3) -> void:
	var wish_speed: float = wish_dir.length()
	if wish_speed <= 0.0:
		return
	wish_dir = wish_dir.normalized()

	var h_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed_alignment: float = h_velocity.dot(wish_dir)
	var add_speed: float = wish_speed - speed_alignment
	if add_speed <= 0.0:
		return

	var accel_speed: float = config.acceleration * wish_speed * delta
	if accel_speed > add_speed:
		accel_speed = add_speed
	if crouched:
		accel_speed *= config.crouch_speed_modifier
	elif wish_sprint and _action_available.get("sprint", false):
		accel_speed *= config.sprint_speed_modifier
	velocity += accel_speed * wish_dir


func _air_accelerate(delta: float, wish_dir: Vector3) -> void:
	var wish_speed: float = wish_dir.length()
	if wish_speed <= 0.0:
		return
	wish_dir = wish_dir.normalized()

	var h_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed_alignment: float = h_velocity.dot(wish_dir)
	var max_accel: float = config.max_air_speed - speed_alignment
	if max_accel <= 0.0:
		return
	var accel_speed: float = min(config.air_acceleration * wish_speed * delta, max_accel)
	velocity += accel_speed * wish_dir


func _jump(delta: float) -> void:
	var floor_normal: Vector3 = get_floor_normal() if enable_surf else Vector3.UP
	if floor_normal == Vector3.ZERO:
		floor_normal = Vector3.UP
	velocity += floor_normal * sqrt(2.0 * config.gravity * config.jump_height) * config.surf_jump_retention
	velocity.y -= config.gravity * delta * 0.5
	jumped.emit()


func _move_body() -> void:
	var prev_vy: float = velocity.y
	var collided: bool = move_and_slide()
	if collided and not get_floor_normal():
		var slide_direction: Vector3 = get_last_slide_collision().get_normal()
		velocity = velocity.slide(slide_direction)

	if is_on_floor() and not was_on_floor:
		landed.emit(prev_vy)
	was_on_floor = is_on_floor()


# ------------------------------------------------------------------ floor detection

func _set_floor_type(_delta: float) -> void:
	if is_on_floor():
		var angle: float = get_floor_angle()
		floor_type = FloorType.RAMP if angle >= PI / 4.0 else FloorType.FLOOR
	else:
		floor_type = FloorType.NONE


# ------------------------------------------------------------------ crouch

func _crouch() -> void:
	_apply_collider_size(config.crouch_height)
	if camera_rig:
		_tween_camera_height(config.crouch_view_offset)
	crouched = true


func _uncrouch() -> void:
	if not _has_clearance(config.stand_height):
		return
	_apply_collider_size(config.stand_height)
	if camera_rig:
		_tween_camera_height(config.standing_view_offset)
	crouched = false


func _apply_collider_size(height: float) -> void:
	if collision == null or collision.shape == null:
		return
	var shape: Shape3D = collision.shape
	if shape is BoxShape3D:
		(shape as BoxShape3D).size.y = height
	elif shape is CapsuleShape3D:
		(shape as CapsuleShape3D).height = height
	collision.position.y = height / 2.0


func _tween_camera_height(new_y: float) -> void:
	if _crouch_tween:
		_crouch_tween.kill()
	_crouch_tween = create_tween()
	_crouch_tween.tween_property(camera_rig, "position:y", new_y, config.crouch_time)


func _has_clearance(height: float) -> bool:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(config.width, height - FLOOR_COL_MARGIN, config.width)
	var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform.origin = global_position + Vector3(0.0, height / 2.0, 0.0)
	params.exclude = [get_rid()]
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	return space.collide_shape(params, 1).is_empty()


# ------------------------------------------------------------------ state

func _update_movement_state() -> void:
	var new_state: int = MovementState.IDLE
	if floor_type == FloorType.NONE:
		new_state = MovementState.JUMPING if velocity.y > 0.0 else MovementState.FALLING
	elif crouched:
		new_state = MovementState.CROUCHING
	elif velocity.length() > 0.1:
		new_state = MovementState.SPRINTING if (wish_sprint and _action_available.get("sprint", false)) else MovementState.WALKING
	_set_movement_state(new_state)


func _set_movement_state(new_state: int) -> void:
	if new_state == movement_state:
		return
	var old_state: int = movement_state
	movement_state = new_state
	movement_state_changed.emit(old_state, new_state)
	_on_movement_state_changed(old_state, new_state)


func set_game_state(new_state: int) -> void:
	if new_state == game_state:
		return
	var old_state: int = game_state
	game_state = new_state
	game_state_changed.emit(old_state, new_state)
	_on_game_state_changed(old_state, new_state)


# ------------------------------------------------------------------ overridable hooks

# Override to run logic on movement state transitions (e.g. play anim).
func _on_movement_state_changed(_old: int, _new: int) -> void:
	pass


# Override to run logic on game state transitions.
func _on_game_state_changed(_old: int, _new: int) -> void:
	pass


# Override to gate movement (return false while dead, stunned, frozen, etc.).
func _can_move() -> bool:
	return game_state == GameState.ACTIVE


# Override to gate mouse look.
func _can_look() -> bool:
	return game_state != GameState.DISABLED


# ------------------------------------------------------------------ camera

func toggle_camera_mode() -> void:
	var new_mode: int = CameraMode.THIRD_PERSON if camera_mode == CameraMode.FIRST_PERSON else CameraMode.FIRST_PERSON
	set_camera_mode(new_mode)


func set_camera_mode(mode: int) -> void:
	if mode == camera_mode:
		return
	camera_mode = mode
	if camera_rig:
		camera_rig.apply_mode(camera_mode, config)
	camera_mode_changed.emit(camera_mode)


# ------------------------------------------------------------------ input helpers

func _validate_input_actions() -> void:
	for logical: String in DEFAULT_INPUT_ACTIONS.keys():
		var action: String = input_actions.get(logical, DEFAULT_INPUT_ACTIONS[logical])
		var ok: bool = InputMap.has_action(action)
		_action_available[logical] = ok
		if not ok:
			push_warning("SUCC: input action '%s' (logical '%s') not defined; disabling." % [action, logical])


func _action_strength(logical: String) -> float:
	if not _action_available.get(logical, false):
		return 0.0
	return Input.get_action_raw_strength(input_actions[logical])


func _action_pressed(logical: String) -> bool:
	if not _action_available.get(logical, false):
		return false
	return Input.is_action_pressed(input_actions[logical])


func _action_just_pressed(logical: String) -> bool:
	if not _action_available.get(logical, false):
		return false
	return Input.is_action_just_pressed(input_actions[logical])
