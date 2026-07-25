extends SceneTree


func _init() -> void:
	var presets: Array[String] = ["goldsrc", "quake", "quake2", "source", "default_config"]
	var mult: float = SUCCConfig.SOURCE_MULT
	print("source_units(400) = ", SUCCConfig.source_units(400.0))
	print("quake_units(400)  = ", SUCCConfig.quake_units(400.0))
	print("")
	for name: String in presets:
		var path: String = "res://addons/SUCC/resources/%s.tres" % name
		var cfg: SUCCConfig = load(path) as SUCCConfig
		if cfg == null:
			print("FAIL load: ", path)
			continue
		var impulse: float = sqrt(2.0 * cfg.gravity * cfg.jump_height)
		print("%-15s grav=%7.2fu speed=%7.2fu fric=%.1f jump=%8.3fu aircap=%7.2fu stand=%5.1fu duck=%5.1fu eye=%5.1fu" % [
			name,
			cfg.gravity * mult,
			cfg.max_speed * mult,
			cfg.friction,
			impulse * mult,
			cfg.max_air_speed * mult,
			cfg.stand_height * mult,
			cfg.crouch_height * mult,
			cfg.standing_view_offset * mult,
		])
	print("")
	print("source sprint top speed = ", (load("res://addons/SUCC/resources/source.tres") as SUCCConfig).max_speed * (load("res://addons/SUCC/resources/source.tres") as SUCCConfig).sprint_speed_modifier * mult, "u")
	quit()
