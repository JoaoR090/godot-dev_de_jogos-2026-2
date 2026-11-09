
class_name Player
extends Node3D

const SPEED = 20.0

var _start_position: Vector3

func _ready() -> void:
	_start_position = global_position

func _physics_process(delta: float) -> void:
	_handle_movement(delta)


func _handle_movement(delta: float) -> void:
	var direction := Vector3.ZERO

	if Input.is_action_pressed("up"):
		direction.z -= 1

	if Input.is_action_pressed("down"):
		direction.z += 1

	if Input.is_action_pressed("left"):
		direction.x -= 1

	if Input.is_action_pressed("right"):
		direction.x += 1

	direction = direction.normalized()
	global_position += direction * SPEED * delta
