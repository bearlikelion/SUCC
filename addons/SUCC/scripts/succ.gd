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
const STEP_NORMAL_EPSILON: float = 0.001
const MIN_FLAT_STEP_NORMAL_Y: float = 0.99
const STEP_RAY_AHEAD: float = 0.1
# Below this the contact is a wall, not a ramp you could surf. Matches
# SourceMover.MIN_RAMP_NORMAL_Y in SurfsUp v2.
const MIN_RAMP_NORMAL_Y: float = 0.01


@export var config: SUCCConfig
# Maps logical action names to project InputMap action names.
@export var input_actions: Dictionary[String, String] = DEFAULT_INPUT_ACTIONS.duplicate()
@export var enable_bhop: bool = true
# Projects can disable ramp-aligned acceleration without changing the floor geometry.
@export var enable_surf: bool = true
@export var default_camera_mode: CameraMode = CameraMode.FIRST_PERSON
# Optional third-person model pivot. Keep collision outside this node: it receives a
# render-only vertical offset while the authoritative body steps immediately.
@export_node_path("Node3D") var visual_root_path: NodePath

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
# Applied eye offset, rate-limited so a one-tick step cannot jolt the view.
var _view_offset: float = 0.0
var _previous_view_offset: float = 0.0
var _visual_step_offset: float = 0.0
var _previous_visual_step_offset: float = 0.0
var _visual_root_base_y: float = 0.0
var _step_smoothing_grade: float = 0.0
var _skip_step_probe_once: bool = false
var _previous_physics_position: Vector3 = Vector3.ZERO
var _current_physics_position: Vector3 = Vector3.ZERO
var _manual_camera_interpolation: bool = false
var _clearance_shape: BoxShape3D = BoxShape3D.new()
var _clearance_params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()

@onready var collision: CollisionShape3D = get_node_or_null("Collision")
@onready var camera_rig: SUCCCamera = get_node_or_null("CameraRig")
@onready var visual_root: Node3D = get_node_or_null(visual_root_path)


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
	if visual_root:
		_visual_root_base_y = visual_root.position.y
	apply_config()
	if camera_rig:
		camera_rig.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if visual_root:
		visual_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_manual_camera_interpolation = not bool(
		ProjectSettings.get_setting("physics/common/physics_interpolation", false)
	)
	_reset_manual_camera_interpolation()
	# On web there has been no user gesture yet, so a capture here is rejected and
	# Firefox never recovers. The first click captures instead.
	if OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
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
	_view_offset = 0.0
	_previous_view_offset = 0.0
	_visual_step_offset = 0.0
	_previous_visual_step_offset = 0.0
	_step_smoothing_grade = config.step_height / _step_run_estimate()
	_skip_step_probe_once = false
	_set_visual_step_offset(0.0)
	if camera_rig:
		camera_rig.set_step_offset(0.0)
		camera_rig.view_height = config.standing_view_offset
		camera_rig.apply_mode(camera_mode, config)


func reset_camera_interpolation() -> void:
	reset_physics_interpolation()
	_reset_manual_camera_interpolation()


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if _can_look() and camera_rig:
		camera_rig.handle_input(event, config)
	# Browsers only grant pointer lock from a user gesture, and Firefox refuses to
	# re-grant it from the same Escape press that released it. Recapture on click.
	if event is InputEventMouseButton and event.pressed \
	and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("ui_cancel") \
	and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	if global_position.is_equal_approx(_current_physics_position):
		_previous_physics_position = _current_physics_position
	else:
		_reset_manual_camera_interpolation()
	if game_state == GameState.DISABLED or not _can_move():
		velocity = Vector3.ZERO
		move_and_slide()
		_current_physics_position = global_position
		return

	_previous_view_offset = _view_offset
	_previous_visual_step_offset = _visual_step_offset
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
	_smooth_view_on_stairs(delta)
	_current_physics_position = global_position


func _process(delta: float) -> void:
	_apply_render_offsets()
	if camera_rig == null:
		return
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

	# Surf ramps stay airborne. Jump input is ignored until a walkable floor is reached.
	if floor_type == FloorType.RAMP:
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
	var on_ramp: bool = floor_type == FloorType.RAMP and enable_surf
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
	var impulse: float = sqrt(2.0 * config.gravity * config.jump_height)
	velocity.y = impulse
	velocity.y -= config.gravity * delta * 0.5
	_separate_jump_from_floor()
	jumped.emit()


func _separate_jump_from_floor() -> void:
	var into_floor: float = velocity.dot(ground_normal)
	var horizontal_normal: Vector3 = Vector3(
		ground_normal.x,
		0.0,
		ground_normal.z
	)
	var horizontal_length_squared: float = horizontal_normal.length_squared()
	if into_floor >= 0.0 or horizontal_length_squared < 0.000001:
		return
	velocity -= horizontal_normal * into_floor / horizontal_length_squared


func _move_body(delta: float) -> void:
	var prev_vy: float = velocity.y
	var start_pos: Vector3 = global_position
	var start_vel: Vector3 = velocity
	var grounded: bool = is_on_floor() or was_on_floor

	# Climb before sliding. Sliding first means the hull hits the riser, and that contact
	# clips velocity along a near-vertical plane: a quarter of the speed gone at 15
	# degrees off-normal, all of it head-on. Probing down onto the step from above never
	# touches the riser, so there is no contact to clip and no damage to repair.
	if grounded and start_vel.y <= 0.0 and _step_up(delta):
		if not was_on_floor:
			landed.emit(prev_vy)
		was_on_floor = true
		return

	# Bunnyhopping a staircase puts the hull into a riser mid-arc, and clipping against
	# that near-vertical face costs the whole run-up. A riser within step_height is
	# something to clear, not a wall, so lift over it before the slide.
	if not grounded:
		_air_step_up(delta)

	move_and_slide()
	_clip_velocity_to_contacts()
	var flat_pos: Vector3 = global_position
	var flat_vel: Vector3 = velocity
	if grounded and start_vel.y <= 0.0 \
	and _retry_step_up(start_pos, start_vel, flat_pos, flat_vel, delta):
		if not was_on_floor:
			landed.emit(prev_vy)
		was_on_floor = true
		return

	# Descending, hold the body on the stairs. Without it every riser leaves the body
	# briefly airborne, floor_type drops to NONE and ground acceleration cuts out.
	var snapped_down: bool = false
	if grounded:
		snapped_down = _step_down()
	if not snapped_down:
		_smooth_automatic_floor_drop(start_pos.y)

	if is_on_floor() and not was_on_floor:
		landed.emit(prev_vy)
	was_on_floor = is_on_floor()


# Place the body on a step ahead by probing down onto it from above, so the hull never
# contacts the riser and horizontal velocity survives untouched. Returns false when
# there is no step, leaving the caller to slide normally.
func _step_up(delta: float) -> bool:
	if _skip_step_probe_once:
		_skip_step_probe_once = false
		return false
	var motion: Vector3 = Vector3(velocity.x, 0.0, velocity.z) * delta
	if motion.length() < 0.0001:
		return false
	# Only worth probing when something blocks the flat move, and only when that
	# something is too steep to walk. A walkable slope blocks a horizontal move too, but
	# move_and_slide climbs it correctly; stepping it instead teleports the body up the
	# whole ramp, which would wreck surf.
	var block: KinematicCollision3D = KinematicCollision3D.new()
	var block_motion: Vector3 = motion + motion.normalized() * FLOOR_COL_MARGIN * 2.0
	if not test_move(global_transform, block_motion, block):
		return false
	return _attempt_step_up(motion, _lowest_collision_normal_y(block), false)


# Airborne counterpart to _step_up. Applies through the whole arc, not just the rise:
# a hop across a staircase usually meets the next riser on the way down.
func _air_step_up(delta: float) -> bool:
	var motion: Vector3 = Vector3(velocity.x, 0.0, velocity.z) * delta
	if motion.length() < 0.0001:
		return false

	# A surf ramp is steeper than max_floor_angle, so is_on_floor() is false and this runs
	# every tick of a slide. Stepping then climbs the ramp face and kills the surf, so
	# riding one rules out the step entirely.
	if floor_type == FloorType.RAMP:
		return false

	# Only act on a true wall. Anything at or above MIN_RAMP_NORMAL_Y is a face to slide
	# down rather than lift over. Uses the lowest contact: a hop that clips a riser and
	# something shallower still has the riser as the thing actually blocking it.
	var block: KinematicCollision3D = KinematicCollision3D.new()
	var block_motion: Vector3 = motion + motion.normalized() * FLOOR_COL_MARGIN * 2.0
	if not test_move(global_transform, block_motion, block):
		return false
	if _lowest_collision_normal_y(block) > MIN_RAMP_NORMAL_Y:
		return false

	# Find the lowest lift that clears the obstruction, capped at one step.
	var probe: float = FLOOR_COL_MARGIN
	while probe <= config.step_height + FLOOR_COL_MARGIN:
		var raised: Transform3D = global_transform.translated(Vector3.UP * probe)
		if not test_move(raised, motion):
			global_position = raised.origin
			return true
		probe += config.step_height * 0.25

	return false


func _lowest_collision_normal_y(hit: KinematicCollision3D) -> float:
	var lowest: float = 1.0
	for i: int in hit.get_collision_count():
		lowest = minf(lowest, hit.get_normal(i).y)
	return lowest


func _retry_step_up(
		start_pos: Vector3,
		start_vel: Vector3,
		flat_pos: Vector3,
		flat_vel: Vector3,
		delta: float) -> bool:
	var entry_speed: float = Vector2(start_vel.x, start_vel.z).length()
	var flat_speed: float = Vector2(flat_vel.x, flat_vel.z).length()
	if entry_speed < 0.001 or flat_speed >= entry_speed - 0.001:
		return false
	if get_slide_collision_count() == 0:
		return false

	global_position = start_pos
	velocity = start_vel
	var motion: Vector3 = Vector3(start_vel.x, 0.0, start_vel.z) * delta
	if _attempt_step_up(motion, 1.0, true):
		return true
	global_position = flat_pos
	velocity = flat_vel
	return false


func _attempt_step_up(
		motion: Vector3,
		lowest_block_y: float,
		flat_landing_only: bool) -> bool:
	var clearance: float = config.step_height * 2.0 + FLOOR_COL_MARGIN
	var above: Transform3D = global_transform.translated(Vector3.UP * clearance)
	# The destination has to be clear at the raised height, or this is a wall.
	if test_move(above, motion):
		return false

	var landed_at: Transform3D = above.translated(motion)
	var hit: KinematicCollision3D = KinematicCollision3D.new()
	# Trace past the original height so a descent ending flush still registers.
	var descent: float = clearance + config.step_height + FLOOR_COL_MARGIN
	if not test_move(landed_at, Vector3.DOWN * descent, hit):
		return false

	var ray_result: Dictionary = _step_landing_ray(hit, motion)
	if ray_result.is_empty():
		return false
	var landing_normal: Vector3 = ray_result["normal"]
	if landing_normal.y < cos(max_floor_angle):
		return false

	var target_position: Vector3 = landed_at.origin + hit.get_travel()
	if landing_normal.y < MIN_FLAT_STEP_NORMAL_Y:
		# A ramp's low edge can be a small vertical lip. Permit that one transition
		# from flat ground, then leave the entire slope to move_and_slide.
		if flat_landing_only or ground_normal.y < MIN_FLAT_STEP_NORMAL_Y:
			return false
		if landing_normal.y - lowest_block_y <= STEP_NORMAL_EPSILON:
			return false
		_skip_step_probe_once = true
	else:
		target_position.y = (ray_result["position"] as Vector3).y + safe_margin

	var rise: float = target_position.y - global_position.y
	if rise <= 0.0001 or rise > config.step_height:
		return false

	global_position = target_position
	apply_floor_snap()
	if config.smooth_vertical_step:
		_absorb_body_rise(global_position.y - rise)
	return true


# Keep contact when running down stairs, so the body does not float off each riser.
func _step_down() -> bool:
	if is_on_floor() or velocity.y > 0.0:
		return false
	var hit: KinematicCollision3D = KinematicCollision3D.new()
	if not test_move(global_transform, Vector3.DOWN * config.step_height, hit):
		return false
	if hit.get_normal().y < cos(max_floor_angle):
		return false
	var drop: float = hit.get_travel().y
	if drop >= -0.0001:
		return false
	global_position.y += drop
	velocity.y = 0.0
	apply_floor_snap()
	if config.smooth_vertical_step:
		_absorb_body_rise(global_position.y - drop)
	return true


func _smooth_automatic_floor_drop(previous_y: float) -> void:
	var drop: float = previous_y - global_position.y
	if drop <= 0.0 or drop > config.step_height + FLOOR_COL_MARGIN:
		return
	if not is_on_floor() or get_floor_normal().y < MIN_FLAT_STEP_NORMAL_Y:
		return
	if not config.smooth_vertical_step:
		return
	if drop < FLOOR_COL_MARGIN * 2.0:
		_absorb_upward_step_settle(drop)
		return
	_absorb_body_rise(previous_y)


func _absorb_upward_step_settle(drop: float) -> void:
	if _view_offset < -0.001:
		_view_offset = minf(_view_offset + drop, 0.0)
	if _visual_step_offset < -0.001:
		_visual_step_offset = minf(_visual_step_offset + drop, 0.0)


func _step_landing_ray(
		landing: KinematicCollision3D,
		motion: Vector3) -> Dictionary:
	var ahead_distance: float = config.width * 0.5 + STEP_RAY_AHEAD
	var ahead: Vector3 = motion.normalized() * ahead_distance
	var ray_origin: Vector3 = landing.get_position() + ahead
	var ray_start: Vector3 = ray_origin + Vector3.UP * (
		config.step_height + FLOOR_COL_MARGIN
	)
	var ray_end: Vector3 = ray_origin + Vector3.DOWN * FLOOR_COL_MARGIN
	var exclude: Array[RID] = [get_rid()]
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		collision_mask,
		exclude
	)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	return space.intersect_ray(query)


# After Source SmoothViewOnStairs (baseplayer_shared.cpp), but decaying the outstanding
# offset rather than chasing an absolute height: a step arriving mid-decay just adds to
# the offset, so consecutive risers never restart the easing.
func _smooth_view_on_stairs(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var smoothing_speed: float = horizontal_speed * _step_smoothing_grade
	if smoothing_speed < 0.001:
		smoothing_speed = config.step_smoothing_speed
	if config.smooth_vertical_step:
		_visual_step_offset = move_toward(
			_visual_step_offset, 0.0, smoothing_speed * delta
		)
	else:
		_visual_step_offset = 0.0

	# A crouch ease owns the eye height outright, so drop any step lag rather than let
	# the two fight. Leaving the ground is not a reason to discard it: zeroing mid-climb
	# snaps the eye by whatever was outstanding, which is what a jump off a stair did.
	if not config.smooth_vertical_step or _crouch_view_tween_active():
		_view_offset = 0.0
		return

	# Speed matching avoids a rise-pause cycle between treads.
	_view_offset = move_toward(_view_offset, 0.0, smoothing_speed * delta)


# Preserve the eye's world height when stair stepping teleports the body.
func _absorb_body_rise(previous_y: float) -> void:
	var rise: float = global_position.y - previous_y
	if absf(rise) < 0.001:
		return
	_step_smoothing_grade = absf(rise) / _step_run_estimate()
	_absorb_view_shift(rise)
	_visual_step_offset = clampf(
		_visual_step_offset - rise, -config.step_height * 2.0, config.step_height * 2.0
	)


func _absorb_view_shift(shift: float) -> void:
	if absf(shift) < 0.001:
		return
	_view_offset = clampf(
		_view_offset - shift, -config.step_height * 2.0, config.step_height * 2.0
	)


func _apply_render_offsets() -> void:
	var fraction: float = Engine.get_physics_interpolation_fraction()
	if camera_rig:
		var physics_offset: Vector3 = Vector3.ZERO
		if _manual_camera_interpolation:
			var render_position: Vector3 = _previous_physics_position.lerp(
				_current_physics_position,
				fraction,
			)
			physics_offset = global_basis.inverse() * (
				render_position - global_position
			)
		camera_rig.set_physics_offset(physics_offset)
		var eye_offset: float = lerpf(
			_previous_view_offset,
			_view_offset,
			fraction,
		)
		camera_rig.set_step_offset(eye_offset)
	if visual_root:
		var model_offset: float = lerpf(
			_previous_visual_step_offset,
			_visual_step_offset,
			fraction,
		)
		_set_visual_step_offset(model_offset)


func _set_visual_step_offset(offset: float) -> void:
	if visual_root == null:
		return
	visual_root.position.y = _visual_root_base_y + offset


func _step_run_estimate() -> float:
	return maxf(config.width + STEP_RAY_AHEAD * 2.0, 0.001)


# Source skips stair smoothing while the view offset itself is animating, so a crouch
# ease and the step chaser cannot fight over the same eye height.
func _crouch_view_tween_active() -> bool:
	return _crouch_tween != null and _crouch_tween.is_running()


func _set_floor_type(_delta: float) -> void:
	if is_on_floor():
		ground_normal = get_floor_normal()
		# Anything the body can stand on but not hold is a ramp; keyed off
		# ramp_angle_threshold so it can never disagree with floor_max_angle.
		var angle: float = get_floor_angle()
		floor_type = FloorType.RAMP if angle >= ramp_angle_threshold else FloorType.FLOOR
		return

	# Too steep to stand on is still a surface you can surf, so look for a ramp face
	# among the contacts rather than calling it plain airborne.
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
	var raised_origin: bool = false
	var old_view_height: float = camera_rig.view_height if camera_rig else 0.0
	if floor_type != FloorType.FLOOR and not _air_crouch_raised:
		_air_crouch_raise = config.stand_height - config.crouch_height
		global_position.y += _air_crouch_raise
		_air_crouch_raised = true
		raised_origin = true
	_apply_collider_size(config.crouch_height)
	if camera_rig:
		if floor_type == FloorType.FLOOR:
			_set_crouch_view(
				config.crouch_view_offset,
				config.crouch_smoothing_speed
			)
		else:
			# The origin raise and the instant view drop cancel out, holding the
			# camera at its world height; easing here would bob.
			if _crouch_tween:
				_crouch_tween.kill()
			camera_rig.view_height = config.crouch_view_offset
	crouched = true
	if raised_origin:
		if camera_rig and config.smooth_vertical_step:
			var view_shift: float = _air_crouch_raise \
				+ camera_rig.view_height - old_view_height
			_absorb_view_shift(view_shift)
		reset_camera_interpolation()


func _uncrouch() -> void:
	# A raised air duck stands by dropping the origin back down as the legs extend,
	# so the standing hull has to fit below rather than overhead.
	var origin_drop: float = _air_crouch_raise if _air_crouch_raised else 0.0
	var old_view_height: float = camera_rig.view_height if camera_rig else 0.0
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
			_set_crouch_view(
				config.standing_view_offset,
				config.uncrouch_smoothing_speed
			)
	crouched = false
	if origin_drop > 0.0:
		if camera_rig and config.smooth_vertical_step:
			var view_shift: float = -origin_drop \
				+ camera_rig.view_height - old_view_height
			_absorb_view_shift(view_shift)
		reset_camera_interpolation()


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
		_set_crouch_view(
			config.crouch_view_offset,
			config.crouch_smoothing_speed
		)


func _apply_collider_size(height: float) -> void:
	if collision == null or collision.shape == null:
		return
	var shape: Shape3D = collision.shape
	if shape is BoxShape3D:
		(shape as BoxShape3D).size.y = height
	elif shape is CapsuleShape3D:
		(shape as CapsuleShape3D).height = height
	collision.position.y = height / 2.0


# The duration scales with the distance left to travel so an interrupted duck does not
# restart the full easing.
func _set_crouch_view(new_y: float, smoothing_speed: float) -> void:
	if _crouch_tween:
		_crouch_tween.kill()
	if config.crouch_transition_mode == SUCCConfig.CrouchTransitionMode.SNAP \
	or smoothing_speed <= 0.0:
		camera_rig.view_height = new_y
		return
	var remaining: float = absf(camera_rig.view_height - new_y)
	if remaining <= 0.0:
		return
	_crouch_tween = create_tween()
	_crouch_tween.set_trans(Tween.TRANS_LINEAR)
	_crouch_tween.tween_property(
		camera_rig,
		"view_height",
		new_y,
		remaining / smoothing_speed
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
	if floor_type == FloorType.RAMP:
		new_state = MovementState.FALLING
	elif floor_type == FloorType.NONE:
		new_state = MovementState.JUMPING if velocity.y > 0.0 else MovementState.FALLING
	elif crouched:
		new_state = MovementState.CROUCHING
	elif velocity.length() > 0.1:
		new_state = MovementState.SPRINTING if sprinting else MovementState.WALKING
	_set_movement_state(new_state)


func _reset_manual_camera_interpolation() -> void:
	_previous_physics_position = global_position
	_current_physics_position = global_position
	if camera_rig:
		camera_rig.set_physics_offset(Vector3.ZERO)


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
