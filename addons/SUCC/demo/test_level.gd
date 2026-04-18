class_name SUCCTestLevel extends Node3D

# Minimal harness for standalone SUCC testing.


const HINT_ACTIONS: Array[Array] = [
	["forward", "move"],
	["jump", "jump"],
	["duck", "duck"],
	["crouch", "crouch"],
	["sprint", "sprint"],
	["toggle_camera", "camera"],
]


@onready var player: SUCC = %Player
@onready var speed_label: Label = %SpeedLabel
@onready var state_label: Label = %StateLabel
@onready var hint_label: Label = %Hint


func _ready() -> void:
	hint_label.text = _build_hint()


func _process(_delta: float) -> void:
	if InputMap.has_action("toggle_camera") and Input.is_action_just_pressed("toggle_camera"):
		player.toggle_camera_mode()
	speed_label.text = "Speed: %0.2f m/s" % Vector2(player.velocity.x, player.velocity.z).length()
	state_label.text = "State: %s" % SUCC.MovementState.keys()[player.movement_state]


func _build_hint() -> String:
	var parts: PackedStringArray = []
	for entry: Array in HINT_ACTIONS:
		var action: String = entry[0]
		var label: String = entry[1]
		var key: String = _first_key_for_action(action)
		if key.is_empty():
			continue
		parts.append("%s %s" % [key, label])
	parts.append("Esc mouse")
	return " | ".join(parts)


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
		_:
			return "Mouse%d" % index
