extends Node


var _p: SUCC
var _level: Node3D
var _out: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_level = (load("res://addons/SUCC/demo/test_level.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(_level)
	await get_tree().physics_frame
	_p = _level.get_node("Player") as SUCC
	var space: PhysicsDirectSpaceState3D = _p.get_world_3d().direct_space_state
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	q.exclude = [_p.get_rid()]

	_out.append("=== cross-section at z=-2 (Surf centre x=24) ===")
	for dx: float in [-6.0, -5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]:
		q.from = Vector3(24.0 + dx, 30, -2)
		q.to = Vector3(24.0 + dx, -5, -2)
		var h: Dictionary = space.intersect_ray(q)
		if h.is_empty():
			_out.append("  dx=%+5.1f  none" % dx)
			continue
		var n: Vector3 = h["normal"]
		var a: float = rad_to_deg(acos(clampf(n.y, -1, 1)))
		var y: float = (h["position"] as Vector3).y
		var bar: String = "#".rjust(int(maxf(y, 0.0) * 3.0) + 1, "#")
		_out.append("  dx=%+5.1f  y=%5.2f  %4.1fdeg  nx=%+.2f  %s" % [dx, y, a, n.x, bar])
	_out.append("  (peak = y highest at dx=0 and normals pointing OUTWARD)")

	# Ride test: drop onto the left face and strafe INTO the slope (leftward, -X).
	_level.call("_apply_preset", 0)
	for a2: String in ["forward","back","left","right","jump","duck","sprint"]:
		Input.action_release(a2)
	_p.global_position = Vector3(21.5, 5.5, 10.0)
	_p.rotation.y = 0.0
	_p.velocity = Vector3(0.0, 0.0, -9.0)
	for _i: int in 3:
		await get_tree().physics_frame
	Input.action_press("right", 1.0)
	var peak: float = 0.0
	var ride: int = 0
	var minx: float = 999.0
	for _i: int in 160:
		await get_tree().physics_frame
		peak = maxf(peak, Vector2(_p.velocity.x, _p.velocity.z).length())
		if _p.get_slide_collision_count() > 0:
			ride += 1
		minx = minf(minx, _p.global_position.x)
	Input.action_release("right")
	_out.append("")
	_out.append("=== ride the LEFT face, strafing +X into the slope ===")
	_out.append("  peak=%.0f u/s  touching %d/160 frames  end=(%.1f, %.2f, %.1f)" % [
		peak * SUCCConfig.SOURCE_MULT, ride,
		_p.global_position.x, _p.global_position.y, _p.global_position.z])

	var f: FileAccess = FileAccess.open("user://v.txt", FileAccess.WRITE)
	f.store_string("\n".join(_out))
	f.close()
	get_tree().quit()
