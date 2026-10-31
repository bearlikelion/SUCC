class_name SUCCInput
extends RefCounted

# One tick of player intent; set SUCC.command to simulate from it instead of Input.


# x is right, y is back; normalized or zero.
var move: Vector2 = Vector2.ZERO
var jump: bool = false
var crouch: bool = false
var sprint: bool = false
# Radians: yaw is the body's rotation.y, pitch the CameraRig's pitch.
var yaw: float = 0.0
var pitch: float = 0.0
