class_name SUCCMoveState
extends RefCounted

# Everything SUCC.simulate carries between ticks, for rewind and replay.


var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var yaw: float = 0.0
var crouched: bool = false
var air_crouch_raised: bool = false
var air_crouch_raise: float = 0.0
var was_on_floor: bool = false
var on_floor: bool = false
var floor_type: SUCC.FloorType = SUCC.FloorType.NONE
var ground_normal: Vector3 = Vector3.UP
var skip_step_probe_once: bool = false
var jump_held: bool = false
var impulse: Vector3 = Vector3.ZERO
var movement_state: SUCC.MovementState = SUCC.MovementState.IDLE
