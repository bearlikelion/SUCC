class_name SUCCReplayTest
extends SceneTree

# godot --headless --path . -s res://tests/succ_replay_test.gd


const CHARACTER: PackedScene = preload("res://addons/SUCC/scenes/succ_character.tscn")
const QUAKE: SUCCConfig = preload("res://addons/SUCC/resources/quake.tres")
const SURFSUP: SUCCConfig = preload("res://addons/SUCC/resources/default_config.tres")
const SPAWN: Vector3 = Vector3(0.0, 0.1, 0.0)
const TICKS: int = 420
const IMPULSE_TICK: int = 252
const IMPULSE: Vector3 = Vector3(3.0, 5.0, -2.0)
const TOLERANCE: float = 0.0001
const WALL_X: float = 50.0

var _delta: float = 0.0
var _failed: int = 0


func _initialize() -> void:
	_delta = 1.0 / Engine.physics_ticks_per_second
	_build_course()
	_run.call_deferred()


func _run() -> void:
	await _check_config("quake", QUAKE, true)
	await _check_config("surfsup without bhop", SURFSUP, false)
	await _check_wall_stairs("quake", QUAKE)
	await _check_wall_stairs("surfsup", SURFSUP)
	await _check_pitch_limit()
	print("%s" % ("FAILED %d" % _failed if _failed > 0 else "ALL PASSED"))
	quit(1 if _failed > 0 else 0)


func _check_config(label: String, config: SUCCConfig, bhop: bool) -> void:
	var player: SUCC = _spawn(config, bhop)
	var jumps: Array[int] = [0]
	player.jumped.connect(func() -> void: jumps[0] += 1)
	await physics_frame

	var commands: Array[SUCCInput] = _script_commands()
	var states: Array[SUCCMoveState] = [player.get_move_state()]
	var highest: float = 0.0
	var surfed: bool = false
	for tick: int in TICKS:
		await physics_frame
		_step(player, commands[tick], tick)
		states.append(player.get_move_state())
		highest = maxf(highest, player.global_position.y)
		surfed = surfed or player.floor_type == SUCC.FloorType.RAMP
	var final: SUCCMoveState = states[TICKS]
	_expect(highest > 1.4, "%s climbs the stairs" % label)
	_expect(surfed, "%s reaches the surf ramp" % label)
	_expect(jumps[0] >= 2, "%s jumps (%d)" % [label, jumps[0]])

	# Replays share one physics frame, as a reconciling client would.
	await physics_frame
	var restore_points: Array[int] = [IMPULSE_TICK]
	for tick: int in range(5, TICKS, 5):
		restore_points.append(tick)
	for from: int in restore_points:
		player.set_move_state(states[from])
		for tick: int in range(from, TICKS):
			_step(player, commands[tick], tick)
		_expect_state(final, player.get_move_state(), "%s replay from tick %d" % [label, from])

	# Keys go down a tick early, as real events land before the step that reads them.
	player.set_move_state(states[0])
	_press(commands[0])
	var local_input_matches: bool = true
	for tick: int in TICKS:
		await physics_frame
		player.basis = Basis(Vector3.UP, commands[tick].yaw)
		local_input_matches = local_input_matches \
		and _same_input(player.read_local_input(), commands[tick])
		_step(player, null, tick)
		_press(commands[tick + 1] if tick + 1 < TICKS else SUCCInput.new())
	_expect(local_input_matches, "%s read_local_input matches the commands" % label)
	_expect_state(final, player.get_move_state(), "%s Input path matches commands" % label)

	player.queue_free()
	await process_frame


# Issue #5: walking up stairs while pressed against a wall stalled on the first riser.
func _check_wall_stairs(label: String, config: SUCCConfig) -> void:
	var player: SUCC = _spawn(config, false)
	player.position = Vector3(WALL_X - config.width * 0.5 - 0.01, 0.1, -6.0)
	await physics_frame
	var input: SUCCInput = SUCCInput.new()
	input.move = Vector2(0.3, -1.0).normalized()
	var highest: float = 0.0
	for tick: int in 120:
		await physics_frame
		_step(player, input, -1)
		highest = maxf(highest, player.global_position.y)
	_expect(highest > 1.4, "%s climbs the stairs along a wall (%.2f)" % [label, highest])
	player.queue_free()
	await process_frame


# Issue #6: looking straight up with view tilt flipped the view around.
func _check_pitch_limit() -> void:
	var player: SUCC = CHARACTER.instantiate()
	player.config = QUAKE
	player.position = Vector3(0.0, 0.1, 10.0)
	root.add_child(player)
	await physics_frame
	var rig: SUCCCamera = player.camera_rig
	var yaw: float = 0.7
	for look_up: float in [-10.0, 10.0]:
		rig.turn(Vector2(0.0, look_up))
		rig.update_tilt(0.1, Vector3(-8.0, 0.0, 3.0), QUAKE)
		rig.place(player.global_position, yaw)
		var forward: Vector3 = -rig.global_basis.z
		var body_forward: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, yaw)
		_expect(
			is_equal_approx(absf(rig.pitch), deg_to_rad(SUCCCamera.PITCH_LIMIT_DEG)) \
			and Vector3(forward.x, 0.0, forward.z).dot(body_forward) > 0.0,
			"view stays facing forward at the pitch limit under tilt (%.0f)" % look_up
		)
	player.queue_free()
	await process_frame


func _spawn(config: SUCCConfig, bhop: bool) -> SUCC:
	var player: SUCC = CHARACTER.instantiate()
	var rig: Node = player.get_node("CameraRig")
	player.remove_child(rig)
	rig.free()
	player.config = config
	player.enable_bhop = bhop
	# Owned by another peer, like a server's copy of a client's player.
	player.set_multiplayer_authority(2)
	player.position = SPAWN
	root.add_child(player)
	return player


func _step(player: SUCC, command: SUCCInput, tick: int) -> void:
	player.command = command
	player.simulate(_delta)
	if tick + 1 == IMPULSE_TICK:
		player.add_impulse(IMPULSE)


# Strafe-jumps across the floor, up the stairs and down the ramp, then into the surf ramp.
func _script_commands() -> Array[SUCCInput]:
	var commands: Array[SUCCInput] = []
	var yaw: float = 0.0
	for tick: int in TICKS:
		var input: SUCCInput = SUCCInput.new()
		var strafe: float = 0.0
		var forward: float = -1.0 if tick >= 30 else 0.0
		if tick >= 90 and tick < 210:
			strafe = 1.0 if posmod(tick, 80) < 40 else -1.0
			forward = 0.0
			yaw -= strafe * 0.03
		input.move = Vector2(strafe, forward).normalized()
		input.jump = (tick >= 90 and tick < 210) or (tick >= 240 and tick < 246) \
		or (tick >= 330 and tick < 360)
		input.crouch = tick >= 150 and tick < 170
		input.sprint = tick >= 60 and tick < 90
		input.yaw = yaw
		commands.append(input)
	return commands


func _press(input: SUCCInput) -> void:
	_set_action("right", input.move.x > 0.0)
	_set_action("left", input.move.x < 0.0)
	_set_action("forward", input.move.y < 0.0)
	_set_action("back", input.move.y > 0.0)
	_set_action("jump", input.jump)
	_set_action("crouch", input.crouch)
	_set_action("sprint", input.sprint)


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _same_input(a: SUCCInput, b: SUCCInput) -> bool:
	return a.move.is_equal_approx(b.move) and a.jump == b.jump and a.crouch == b.crouch \
	and a.sprint == b.sprint and is_equal_approx(a.yaw, b.yaw)


func _expect_state(expected: SUCCMoveState, actual: SUCCMoveState, label: String) -> void:
	var position_error: float = expected.position.distance_to(actual.position)
	var velocity_error: float = expected.velocity.distance_to(actual.velocity)
	_expect(
		position_error <= TOLERANCE and velocity_error <= TOLERANCE,
		"%s (position off %.6f, velocity off %.6f)" % [label, position_error, velocity_error]
	)


func _expect(condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		_failed += 1


func _build_course() -> void:
	_add_box(Vector3(200.0, 1.0, 200.0), Vector3(0.0, -0.5, -60.0), 0.0)
	for step: int in 6:
		var height: float = 0.25 * (step + 1)
		_add_box(Vector3(200.0, height, 0.6), Vector3(0.0, height * 0.5, -10.3 - 0.6 * step), 0.0)
	_add_box(Vector3(200.0, 1.5, 6.4), Vector3(0.0, 0.75, -16.8), 0.0)
	_add_slope(Vector3(0.0, 1.5, -20.0), Vector3(0.0, 0.0, -26.0))
	_add_slope(Vector3(0.0, 0.0, -33.0), Vector3(0.0, 6.93, -37.0))
	_add_box(Vector3(1.0, 4.0, 20.0), Vector3(WALL_X + 0.5, 2.0, -12.0), 0.0)


func _add_slope(top_start: Vector3, top_end: Vector3) -> void:
	var run: Vector3 = top_end - top_start
	var tilt: float = atan2(run.y, -run.z)
	var normal: Vector3 = Vector3(0.0, cos(tilt), sin(tilt))
	var center: Vector3 = (top_start + top_end) * 0.5 - normal * 0.2
	_add_box(Vector3(200.0, 0.4, run.length()), center, tilt)


func _add_box(size: Vector3, center: Vector3, tilt: float) -> void:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	var body: StaticBody3D = StaticBody3D.new()
	body.add_child(collision)
	body.position = center
	body.rotation.x = tilt
	root.add_child(body)
