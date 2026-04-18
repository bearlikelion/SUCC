class_name SUCCTestLevel extends Node3D

# Minimal harness for standalone SUCC testing.
# Press V to toggle first/third person. ESC releases the mouse.


@onready var player: SUCC = %Player
@onready var speed_label: Label = %SpeedLabel
@onready var state_label: Label = %StateLabel


func _process(_delta: float) -> void:
	if InputMap.has_action("toggle_camera") and Input.is_action_just_pressed("toggle_camera"):
		player.toggle_camera_mode()
	speed_label.text = "Speed: %0.2f m/s" % Vector2(player.velocity.x, player.velocity.z).length()
	state_label.text = "State: %s" % SUCC.MovementState.keys()[player.movement_state]
