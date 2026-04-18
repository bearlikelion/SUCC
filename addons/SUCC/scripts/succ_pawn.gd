class_name SUCCPawn extends CharacterBody3D

# Remote-peer representation of a SUCC character.
# Non-authority: receives synced transform and state, does not run input or physics.
# Extend to add game-specific synced fields (health, ammo, team, etc.) by editing the
# SceneReplicationConfig on your subclass pawn scene.


@export var interpolate: bool = true
@export var interpolation_speed: float = 15.0


# Synced from the authority SUCC via MultiplayerSynchronizer.
@export var synced_position: Vector3 = Vector3.ZERO
@export var synced_yaw: float = 0.0
@export var synced_pitch: float = 0.0
@export var synced_velocity: Vector3 = Vector3.ZERO
@export var synced_movement_state: int = 0
@export var synced_game_state: int = 0
@export var synced_crouched: bool = false


@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot")


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	velocity = synced_velocity
	if interpolate:
		global_position = global_position.lerp(synced_position, clamp(interpolation_speed * delta, 0.0, 1.0))
		rotation.y = lerp_angle(rotation.y, synced_yaw, clamp(interpolation_speed * delta, 0.0, 1.0))
		if camera_pivot:
			camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, synced_pitch, clamp(interpolation_speed * delta, 0.0, 1.0))
	else:
		global_position = synced_position
		rotation.y = synced_yaw
		if camera_pivot:
			camera_pivot.rotation.x = synced_pitch
