class_name SUCC
extends CharacterBody3D

# SurfsUp Character Controller.
# Multiplayer-focused, inheritable, state-based first/third-person controller.
# Extend this class to build your game's player. Physics tuning lives in SUCCConfig.
#
# Required input actions (rebindable via input_actions export):
#   forward, back, left, right, jump, crouch, sprint
# Missing actions are disabled at runtime and reported via push_warning.


signal movement_state_changed(old_state: MovementState, new_state: MovementState)
signal game_state_changed(old_state: GameState, new_state: GameState)
signal jumped
signal landed(fall_velocity: float)
signal camera_mode_changed(mode: CameraMode)


enum CameraMode { FIRST_PERSON, THIRD_PERSON }
enum FloorType { NONE, FLOOR, RAMP }
enum MovementState { IDLE, WALKING, SPRINTING, CROUCHING, JUMPING, FALLING, AIR }
enum GameState { ACTIVE, FROZEN, DISABLED }


const DEFAULT_INPUT_ACTIONS: Dictionary[String, String] = {
	"forward": "forward",
	"back": "back",
	"left": "left",
	"right": "right",
	"jump": "jump",
	"crouch": "crouch",
	"sprint": "sprint",
}
const FLOOR_COL_MARGIN: float = 0.02
# Fraction of the requested move below which the body counts as blocked.
const BLOCKED_TRAVEL_FRACTION: float = 0.9
# Below this the contact is a wall, not a ramp you could surf. Matches
# SourceMover.MIN_RAMP_NORMAL_Y in SurfsUp v2.
const MIN_RAMP_NORMAL_Y: float = 0.01


@export var config: SUCCConfig
# Maps logical action names to project InputMap action names.
@export var input_actions: Dictionary[String, String] = DEFAULT_INPUT_ACTIONS.duplicate()
@export var enable_bhop: bool = true
# Adds the jump impulse along the floor normal for surf ramp boosts.
# Turn off for engine-authentic jumps, which are always straight up.
@export var enable_surf: bool = true
@export var default_camera_mode: CameraMode = CameraMode.FIRST_PERSON

## Slope angle at or above which a walkable floor counts as a ramp.
@export_range(0.0, 89.0, 0.5, "radians_as_degrees") var ramp_angle_threshold: float = \
		deg_to_rad(45.0)
## Steepest slope the body can stand on at all. Steeper surfaces leave it airborne.
@export_range(0.0, 89.0, 0.5, "radians_as_degrees") var max_floor_angle: float = \
		deg_to_rad(50.0)


var movement_state: MovementState = MovementState.IDLE
var game_state: GameState = GameState.ACTIVE
var camera_mode: CameraMode = CameraMode.FIRST_PERSON
var floor_type: FloorType = FloorType.NONE

var move_input: Vector2 = Vector2.ZERO
var move_dir: Vector3 = Vector3.ZERO
var wish_sprint: bool = false
var wish_jump: bool = false
var wish_crouch: bool = false
var crouched: bool = false
var was_on_floor: bool = false
## Normal of the floor or ramp underfoot; Vector3.UP when airborne.
var ground_normal: Vector3 = Vector3.UP

var _action_available: Dictionary[String, bool] = {}
var _crouch_tween: Tween
# Source FinishDuck raises the origin for an air duck; tracked so the matching
# unduck drops it again and a landing can absorb it.
var _air_crouch_raised: bool = false
var _air_crouch_raise: float = 0.0
# Decayed toward 0 in _process so the camera lags behind abrupt body Y snaps.
var _camera_step_offset: float = 0.0
var _clearance_shape: BoxShape3D = BoxShape3D.new()
var _clearance_params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()

@onready var collision: CollisionShape3D = get_node_or_null("Collision")
@onready var camera_rig: SUCCCamera = get_node_or_null("CameraRig")


func _ready() -> void:
	if collision == null:
		push_error("SUCC: missing child CollisionShape3D named 'Collision'.")
	if camera_rig == null:
		push_error("SUCC: missing child SUCCCamera named 'CameraRig'.")
	if config == null:
		config = load("res://addons/SUCC/resources/default_config.tres") as SUCCConfig
	_validate_input_actions()
	floor_max_angle = max_floor_angle
	floor_block_on_wall = false
	camera_mode = default_camera_mode
	apply_config()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Re-derive collider, snap length and camera from config. Call after swapping config.
func apply_config() -> void:
	if config == null:
		return
	crouched = false
	_air_crouch_raised = false
	_air_crouch_raise = 0.0
	if _crouch_tween:
		_crouch_tween.kill()
	_apply_collider_size(config.stand_height)
	# Snap far enough to hold the floor when descending a full step.
	floor_snap_length = config.step_height + FLOOR_COL_MARGIN
	_camera_step_offset = 0.0
	if camera_rig:
		camera_rig.set_step_offset(0.0)
		camera_rig.view_height = config.standing_view_offset
		camera_rig.apply_mode(camera_mode, config)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if _can_look() and camera_rig:
		camera_rig.handle_input(event, config)
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _gather_movement_input() -> void:
	var fwd: float = _action_strength("forward")
	var back: float = _action_strength("back")
	var left: float = _action_strength("left")
	var right: float = _action_strength("right")
	move_input = Vector2(right - left, back - fwd).normalized()

	wish_sprint = _action_pressed("sprint")
	var buffered: bool = enable_bhop and config.bhop_buffered_jump
	wish_jump = _action_pressed("jump") if buffered else _action_just_pressed("jump")
	wish_crouch = _action_pressed("crouch")

	move_dir = Vector3(move_input.x, 0.0, move_input.y)
	move_dir = move_dir.normalized() * _wish_speed()
	move_dir = move_dir.rotated(Vector3.UP, global_rotation.y)


# Crouch and sprint scale the speed cap itself, not the acceleration rate.
func _wish_speed() -> float:
	if crouched:
		return config.max_speed * config.crouch_speed_modifier
	if wish_sprint and _action_available.get("sprint", false):
		return config.max_speed * config.sprint_speed_modifier
	return config.max_speed


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if game_state == GameState.DISABLED or not _can_move():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_gather_movement_input()
	_set_floor_type(delta)
	_apply_gravity(delta)
	_set_velocity(delta)
	_clamp_velocity()
	_move_body(delta)
	# Re-categorise after moving, the way Quake and Source do. Reading it only at the
	# top of the tick leaves floor_type a frame stale, so the landing frame still
	# looks airborne: gravity gets skipped, then reapplied, and the body bounces.
	_set_floor_type(delta)
	# After the move, so the landing frame sees FLOOR and can absorb an air duck's
	# origin raise. Running it pre-move left floor_type a frame stale, and the raise
	# survived the landing to drop the eye 0.58 m a few frames later.
	_land_air_crouch()
	_update_movement_state()


func _process(delta: float) -> void:
	if camera_rig == null:
		return
	if config.smooth_vertical_step and not is_equal_approx(_camera_step_offset, 0.0):
		# Source closes this gap at a constant rate (150 u/s in SmoothViewOnStairs);
		# a lerp fraction is framerate-dependent and jitters on consecutive lips.
		_camera_step_offset = move_toward(
			_camera_step_offset, 0.0, config.step_smoothing_speed * delta
		)
		camera_rig.set_step_offset(_camera_step_offset)

	if camera_mode != CameraMode.FIRST_PERSON:
		return
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	camera_rig.update_bob(delta, horizontal_speed, floor_type != FloorType.NONE, config)
	camera_rig.update_tilt(delta, velocity, config)


# Source ClipVelocity (gamemovement.cpp): strip the component heading into each
# contact plane so the body travels along the surface instead of pressing through it.
# Without this a surf ramp keeps accumulating downward velocity and you slide off
# rather than riding the face, and there is nothing left to convert into air time.
func _clip_velocity_to_contacts() -> void:
	for i: int in get_slide_collision_count():
		var normal: Vector3 = get_slide_collision(i).get_normal()
		var into: float = velocity.dot(normal)
		if into < 0.0:
			velocity -= normal * into


# sv_maxvelocity: Source clamps each axis independently, not the magnitude.
func _clamp_velocity() -> void:
	if not config.enforce_max_velocity:
		return
	var limit: float = config.max_velocity
	velocity.x = clampf(velocity.x, -limit, limit)
	velocity.y = clampf(velocity.y, -limit, limit)
	velocity.z = clampf(velocity.z, -limit, limit)


func _apply_gravity(delta: float) -> void:
	# Ramps are too steep to stand on, so gravity keeps pulling; that downhill pull
	# is what makes a surf ramp slide instead of holding you in place.
	if floor_type != FloorType.FLOOR:
		velocity.y -= config.gravity * delta


func _set_velocity(delta: float) -> void:
	# Retried every tick: releasing crouch under a ceiling must not leave the body
	# stuck crouched once the ceiling clears.
	if wish_crouch and not crouched:
		_crouch()
	elif crouched and not wish_crouch:
		_uncrouch()

	# Ramps are too steep to walk, so they take air acceleration like being airborne,
	# but you can still jump off one. That transfer jump is the core of surf.
	if floor_type == FloorType.RAMP:
		if wish_jump:
			_jump(delta)
		_air_accelerate(delta, move_dir)
		return

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
	# Horizontal speed only; a 3D length would inflate drop while falling.
	var temp_speed: float = Vector3(velocity.x, 0.0, velocity.z).length()
	if temp_speed <= 0.0:
		return
	var control: float = config.stop_speed if temp_speed < config.stop_speed else temp_speed
	var drop: float = control * config.friction * strength * delta
	var new_speed: float = max(temp_speed - drop, 0.0) / temp_speed
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
	velocity += accel_speed * wish_dir


func _air_accelerate(delta: float, wish_dir: Vector3) -> void:
	var wish_speed: float = wish_dir.length()
	if wish_speed <= 0.0:
		return
	wish_dir = wish_dir.normalized()

	# On a ramp, strafing points straight into the face, and move_and_slide strips
	# that whole component right back out, so speed never grows. Sliding the wish
	# direction along the surface first is what lets a surf ramp build speed.
	# The alignment then has to use full 3D velocity, because the ramp-aligned wish
	# has a vertical component that a horizontal-only dot would ignore.
	var on_ramp: bool = floor_type == FloorType.RAMP
	if on_ramp:
		var along: Vector3 = wish_dir.slide(ground_normal)
		if along.length() > 0.001:
			wish_dir = along.normalized()

	var reference: Vector3 = velocity if on_ramp else Vector3(velocity.x, 0.0, velocity.z)
	var speed_alignment: float = reference.dot(wish_dir)
	var max_accel: float = config.max_air_speed - speed_alignment
	if max_accel <= 0.0:
		return
	var accel_speed: float = min(config.air_acceleration * wish_speed * delta, max_accel)
	velocity += accel_speed * wish_dir


func _jump(delta: float) -> void:
	# ground_normal is tracked for ramps too, so a surf jump launches along the face
	# rather than straight up. get_floor_normal() is zero on a ramp and cannot.
	var floor_normal: Vector3 = ground_normal if enable_surf else Vector3.UP
	if floor_normal == Vector3.ZERO:
		floor_normal = Vector3.UP
	var impulse: float = sqrt(2.0 * config.gravity * config.jump_height)
	velocity += floor_normal * impulse * config.surf_jump_retention
	velocity.y -= config.gravity * delta * 0.5
	jumped.emit()


func _move_body(delta: float) -> void:
	var prev_vy: float = velocity.y
	var start_pos: Vector3 = global_position
	var start_vel: Vector3 = velocity
	var wanted: float = Vector2(start_vel.x, start_vel.z).length() * delta
	var grounded: bool = is_on_floor() or was_on_floor

	move_and_slide()
	_clip_velocity_to_contacts()

	# Source WalkMove only reaches StepMove when the plain move was blocked
	# (gamemovement.cpp:1986); stepping unconditionally lifts and drops the body
	# every frame, which stalls flat-ground movement.
	var moved: Vector3 = global_position - start_pos
	var blocked: bool = wanted > 0.001 \
		and Vector2(moved.x, moved.z).length() < wanted * BLOCKED_TRAVEL_FRACTION

	# Source StepMove: keep the plain slide result, then retry the whole move from a
	# step height up and commit whichever covered more ground. Re-running the move
	# rather than teleporting is what stops ramps from flinging the body forward.
	if blocked and grounded and floor_type != FloorType.NONE:
		var flat_pos: Vector3 = global_position
		var flat_vel: Vector3 = velocity
		var stepped: bool = _try_step_move(start_pos, start_vel)
		var flat_dist: float = Vector2(
			flat_pos.x - start_pos.x, flat_pos.z - start_pos.z
		).length_squared()
		var step_dist: float = Vector2(
			global_position.x - start_pos.x, global_position.z - start_pos.z
		).length_squared()
		# Falling back to the plain move means restoring its result, not the position
		# from before it ran, or the frame's movement is thrown away.
		if not stepped or flat_dist > step_dist:
			global_position = flat_pos
			velocity = flat_vel
		else:
			# Vertical velocity comes from the plain move; the step is a position fix.
			velocity.y = flat_vel.y
			if config.smooth_vertical_step:
				_add_camera_step_offset(start_pos.y - global_position.y)

	# Stair descent via floor_snap_length drops Y without a collision, so seed the
	# camera offset from the drop itself.
	if config.smooth_vertical_step and was_on_floor and is_on_floor():
		var y_drop: float = start_pos.y - global_position.y
		if y_drop > 0.05:
			_add_camera_step_offset(y_drop)

	if is_on_floor() and not was_on_floor:
		landed.emit(prev_vy)
	was_on_floor = is_on_floor()


# Re-runs the move from one step height up, then drops back down onto the tread.
# Mirrors Quake SV_WalkMove / Source StepMove: the slide move itself produces the
# velocity, so no momentum is synthesised and ramps cannot fling the body.
# Returns false when the stepped attempt found no walkable ground.
func _try_step_move(start_pos: Vector3, start_vel: Vector3) -> bool:
	# Nothing to step onto if what blocked us is a slope rather than a lip. Bailing
	# here keeps the body from lifting and dropping every frame at a ramp's foot.
	if not _blocked_by_steppable_surface():
		return false

	global_position = start_pos
	velocity = start_vel

	var up_hit: KinematicCollision3D = move_and_collide(
		Vector3.UP * (config.step_height + FLOOR_COL_MARGIN), true
	)
	var up_dist: float = config.step_height + FLOOR_COL_MARGIN
	if up_hit != null:
		up_dist = up_hit.get_travel().y
	if up_dist <= FLOOR_COL_MARGIN:
		return false
	global_position += Vector3(0.0, up_dist, 0.0)

	# Horizontal only: a downward component here would cancel the step we just took.
	velocity.y = 0.0
	move_and_slide()

	var down_hit: KinematicCollision3D = move_and_collide(
		Vector3.DOWN * (up_dist + FLOOR_COL_MARGIN), true
	)
	# Rejecting has to undo the lift as well. Leaving the body raised strands it in
	# mid-air, and at the foot of a surf ramp that reads as an uncommanded bounce.
	if down_hit == null or down_hit.get_normal().y < cos(max_floor_angle):
		global_position = start_pos
		velocity = start_vel
		return false
	global_position += down_hit.get_travel()
	return true


# Takes the largest single step rather than summing: climbing consecutive risers adds
# faster than the offset decays, and accumulated lag reads as the camera sinking.
# True when at least one contact from the last move is a near-vertical face, i.e. a
# step or lip. A surf ramp blocks horizontally too, but stepping onto it is never
# valid, so the whole attempt can be skipped.
func _blocked_by_steppable_surface() -> bool:
	for i: int in get_slide_collision_count():
		var normal: Vector3 = get_slide_collision(i).get_normal()
		# Walls and lips have a near-zero vertical component; slopes do not.
		if absf(normal.y) < cos(max_floor_angle):
			return true
	return false


func _add_camera_step_offset(amount: float) -> void:
	var limit: float = config.step_height
	if absf(amount) > absf(_camera_step_offset):
		_camera_step_offset = clamp(amount, -limit, limit)


func _set_floor_type(_delta: float) -> void:
	if is_on_floor():
		ground_normal = get_floor_normal()
		# Anything the body can stand on but not hold is a ramp; keyed off
		# ramp_angle_threshold so it can never disagree with floor_max_angle.
		var angle: float = get_floor_angle()
		floor_type = FloorType.RAMP if angle >= ramp_angle_threshold else FloorType.FLOOR
		return

	# Too steep to stand on is still a surface you can surf and jump off, so look for
	# a ramp face among the contacts rather than calling it plain airborne.
	# Mirrors SourceMover.classify_floor_normals in SurfsUp v2.
	var best: Vector3 = Vector3.ZERO
	for i: int in get_slide_collision_count():
		var normal: Vector3 = get_slide_collision(i).get_normal()
		if normal.y > MIN_RAMP_NORMAL_Y and normal.y > best.y:
			best = normal
	if best == Vector3.ZERO:
		ground_normal = Vector3.UP
		floor_type = FloorType.NONE
		return
	ground_normal = best
	floor_type = FloorType.RAMP


func _crouch() -> void:
	# Source air duck (gamemovement.cpp FinishDuck): instant, and raises the origin
	# by the full hull difference so the head holds its world height and the feet
	# tuck up. The raised hull sits inside the standing one, so no clearance test is
	# needed. Ramps count as air, so boarding a surf ramp ducks the same way.
	if floor_type != FloorType.FLOOR and not _air_crouch_raised:
		_air_crouch_raise = config.stand_height - config.crouch_height
		global_position.y += _air_crouch_raise
		_air_crouch_raised = true
	_apply_collider_size(config.crouch_height)
	if camera_rig:
		if floor_type == FloorType.FLOOR:
			_set_crouch_view(config.crouch_view_offset, config.crouch_time)
		else:
			# The origin raise and the instant view drop cancel out, holding the
			# camera at its world height; easing here would bob.
			if _crouch_tween:
				_crouch_tween.kill()
			camera_rig.view_height = config.crouch_view_offset
	crouched = true


func _uncrouch() -> void:
	# A raised air duck stands by dropping the origin back down as the legs extend,
	# so the standing hull has to fit below rather than overhead.
	var origin_drop: float = _air_crouch_raise if _air_crouch_raised else 0.0
	if not _has_clearance(config.stand_height, -origin_drop):
		return

	if origin_drop > 0.0:
		global_position.y -= origin_drop
		_air_crouch_raised = false
		_air_crouch_raise = 0.0
	_apply_collider_size(config.stand_height)
	if camera_rig:
		if origin_drop > 0.0:
			# Source air unduck: the origin drop and the instant view rise cancel.
			if _crouch_tween:
				_crouch_tween.kill()
			camera_rig.view_height = config.standing_view_offset
		else:
			_set_crouch_view(config.standing_view_offset, config.uncrouch_time)
	crouched = false


# Landing absorbs an air duck's origin raise (the feet met the floor), so a later
# grounded uncrouch must not drop the origin again.
func _land_air_crouch() -> void:
	if not crouched or floor_type != FloorType.FLOOR:
		return
	if not _air_crouch_raised:
		return
	_air_crouch_raised = false
	_air_crouch_raise = 0.0
	if camera_rig:
		_set_crouch_view(config.crouch_view_offset, config.crouch_time)


func _apply_collider_size(height: float) -> void:
	if collision == null or collision.shape == null:
		return
	var shape: Shape3D = collision.shape
	if shape is BoxShape3D:
		(shape as BoxShape3D).size.y = height
	elif shape is CapsuleShape3D:
		(shape as CapsuleShape3D).height = height
	collision.position.y = height / 2.0


# Source eases the grounded duck view with SimpleSpline; cubic in-out is the closest
# Tween equivalent. The duration scales with the distance left to travel so an
# interrupted duck does not restart the full easing.
func _set_crouch_view(new_y: float, base_time: float) -> void:
	if _crouch_tween:
		_crouch_tween.kill()
	var span: float = absf(config.standing_view_offset - config.crouch_view_offset)
	if span <= 0.0 or base_time <= 0.0:
		camera_rig.view_height = new_y
		return
	var remaining: float = absf(camera_rig.view_height - new_y)
	_crouch_tween = create_tween()
	_crouch_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_crouch_tween.tween_property(
		camera_rig, "view_height", new_y, base_time * (remaining / span)
	)


func _has_clearance(height: float, y_offset: float = 0.0) -> bool:
	# Inset on every axis: a box at exactly the hull size grazes the wall the body is
	# already touching, which would report the ceiling as blocked while standing.
	var inset: float = FLOOR_COL_MARGIN * 2.0
	_clearance_shape.size = Vector3(
		config.width - inset, height - inset, config.width - inset
	)
	_clearance_params.set_shape(_clearance_shape)
	_clearance_params.transform.origin = global_position \
		+ Vector3(0.0, height / 2.0 + y_offset, 0.0)
	_clearance_params.exclude = [get_rid()]
	_clearance_params.collision_mask = collision_mask
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	return space.collide_shape(_clearance_params, 1).is_empty()


func _update_movement_state() -> void:
	var new_state: MovementState = MovementState.IDLE
	var sprinting: bool = wish_sprint and _action_available.get("sprint", false)
	if floor_type == FloorType.NONE:
		new_state = MovementState.JUMPING if velocity.y > 0.0 else MovementState.FALLING
	elif crouched:
		new_state = MovementState.CROUCHING
	elif velocity.length() > 0.1:
		new_state = MovementState.SPRINTING if sprinting else MovementState.WALKING
	_set_movement_state(new_state)


func _set_movement_state(new_state: MovementState) -> void:
	if new_state == movement_state:
		return
	var old_state: MovementState = movement_state
	movement_state = new_state
	movement_state_changed.emit(old_state, new_state)
	_on_movement_state_changed(old_state, new_state)


func set_game_state(new_state: GameState) -> void:
	if new_state == game_state:
		return
	var old_state: GameState = game_state
	game_state = new_state
	game_state_changed.emit(old_state, new_state)
	_on_game_state_changed(old_state, new_state)


# Override to run logic on movement state transitions (e.g. play anim).
func _on_movement_state_changed(_old: MovementState, _new: MovementState) -> void:
	pass


# Override to run logic on game state transitions.
func _on_game_state_changed(_old: GameState, _new: GameState) -> void:
	pass


# Override to gate movement (return false while dead, stunned, frozen, etc.).
func _can_move() -> bool:
	return game_state == GameState.ACTIVE


# Override to gate mouse look.
func _can_look() -> bool:
	return game_state != GameState.DISABLED


func toggle_camera_mode() -> void:
	if camera_mode == CameraMode.FIRST_PERSON:
		set_camera_mode(CameraMode.THIRD_PERSON)
	else:
		set_camera_mode(CameraMode.FIRST_PERSON)


func set_camera_mode(mode: CameraMode) -> void:
	if mode == camera_mode:
		return
	camera_mode = mode
	if camera_rig:
		camera_rig.apply_mode(camera_mode, config)
	camera_mode_changed.emit(camera_mode)


func _validate_input_actions() -> void:
	for logical: String in DEFAULT_INPUT_ACTIONS.keys():
		var action: String = input_actions.get(logical, DEFAULT_INPUT_ACTIONS[logical])
		var ok: bool = InputMap.has_action(action)
		_action_available[logical] = ok
		if not ok:
			push_warning("SUCC: input action '%s' (logical '%s') not defined; disabling."
				% [action, logical])


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
