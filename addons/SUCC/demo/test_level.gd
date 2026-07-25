class_name SUCCTestLevel
extends Node3D

# Parkour gym for standalone SUCC testing.
# Number keys swap movement presets; the speedometer reads in both m/s and engine units.


const SPAWN_POSITION: Vector3 = Vector3(0.0, 1.0, 0.0)

# Label, resource path, and the cvar summary shown in the HUD.
const PRESETS: Array[Dictionary] = [
	{
		"name": "SurfsUp",
		"path": "res://addons/SUCC/resources/default_config.tres",
		"detail": "400u  accel 7.5  fric 4.0  air 100",
	},
	{
		"name": "GoldSrc",
		"path": "res://addons/SUCC/resources/goldsrc.tres",
		"detail": "320u  grav 800  fric 4.0  jump 45u",
	},
	{
		"name": "Quake",
		"path": "res://addons/SUCC/resources/quake.tres",
		"detail": "320u  grav 800  fric 4.0  no duck",
	},
	{
		"name": "Quake 2",
		"path": "res://addons/SUCC/resources/quake2.tres",
		"detail": "300u  fric 6.0  no air strafe",
	},
	{
		"name": "Source",
		"path": "res://addons/SUCC/resources/source.tres",
		"detail": "190u  grav 600  sprint 320u",
	},
]

@onready var player: SUCC = %Player
@onready var units_label: Label = %UnitsLabel
@onready var metric_label: Label = %MetricLabel
@onready var state_label: Label = %StateLabel
@onready var preset_label: Label = %PresetLabel
@onready var preset_detail: Label = %PresetDetail
@onready var flags_label: Label = %FlagsLabel
@onready var hint_label: Label = %Hint


func _ready() -> void:
	hint_label.text = _build_hint()
	_apply_preset(0)


func _process(_delta: float) -> void:
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	units_label.text = "%d u/s" % roundi(speed * SUCCConfig.SOURCE_MULT)
	metric_label.text = "%0.2f m/s" % speed
	state_label.text = SUCC.MovementState.keys()[player.movement_state]


func _unhandled_input(_event: InputEvent) -> void:
	for i: int in PRESETS.size():
		if Input.is_action_just_pressed("preset_%d" % (i + 1)):
			_apply_preset(i)
			return
	if Input.is_action_just_pressed("toggle_surf"):
		player.enable_surf = not player.enable_surf
		_refresh_flags()
	elif Input.is_action_just_pressed("toggle_camera"):
		player.toggle_camera_mode()
	elif Input.is_action_just_pressed("reset_player"):
		_respawn()


func _apply_preset(index: int) -> void:
	var preset: Dictionary = PRESETS[index]
	var config: SUCCConfig = load(preset["path"]) as SUCCConfig
	if config == null:
		push_error("SUCCTestLevel: could not load %s" % preset["path"])
		return
	player.config = config
	player.apply_config()
	preset_label.text = "%d. %s" % [index + 1, preset["name"]]
	preset_detail.text = preset["detail"]
	_refresh_flags()
	_respawn()


func _respawn() -> void:
	player.velocity = Vector3.ZERO
	player.global_position = SPAWN_POSITION


func _refresh_flags() -> void:
	flags_label.text = "bhop %s   surf %s" % [
		"on" if player.enable_bhop else "off",
		"on" if player.enable_surf else "off",
	]


func _build_hint() -> String:
	var parts: PackedStringArray = []

	var move_label: String = _movement_label()
	if not move_label.is_empty():
		parts.append("%s move" % move_label)

	var actions: Dictionary[String, String] = {
		"jump": "jump",
		"duck": "duck",
		"sprint": "sprint",
		"toggle_camera": "camera",
		"toggle_surf": "surf",
		"reset_player": "respawn",
	}
	for action: String in actions:
		var key: String = _first_key_for_action(action)
		if not key.is_empty():
			parts.append("%s %s" % [key, actions[action]])

	parts.append("Esc mouse")
	return " | ".join(parts) + "\n1-5 swap movement preset"


# If forward/left/back/right bind to W/A/S/D, show "WASD". Otherwise list the individual keys.
func _movement_label() -> String:
	var order: Array[String] = ["forward", "left", "back", "right"]
	var keys: PackedStringArray = []
	for action: String in order:
		var key: String = _first_key_for_action(action)
		if key.is_empty():
			return ""
		keys.append(key)
	if keys[0] == "W" and keys[1] == "A" and keys[2] == "S" and keys[3] == "D":
		return "WASD"
	return "/".join(keys)


func _first_key_for_action(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return _key_event_name(event)
		if event is InputEventMouseButton:
			return _mouse_button_name((event as InputEventMouseButton).button_index)
		if event is InputEventJoypadButton:
			return "Pad %d" % (event as InputEventJoypadButton).button_index
	return ""


func _key_event_name(event: InputEventKey) -> String:
	var keycode: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	var name: String = OS.get_keycode_string(keycode)
	return name if not name.is_empty() else "Key"


func _mouse_button_name(index: MouseButton) -> String:
	match index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
	return "Mouse %d" % index
