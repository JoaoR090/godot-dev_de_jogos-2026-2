
extends Node

const VELOCIDADE: float = 20.0

var jogador: Node3D
var grid_trilhos: Trilhos

var _movendo_grade: bool = false
var _alvo_grade: Vector3 = Vector3.ZERO


func mover_em_grade(delta: float) -> void:
	if not is_instance_valid(jogador):
		return

	if not is_instance_valid(grid_trilhos):
		return

	if _movendo_grade:
		jogador.global_position = jogador.global_position.move_toward(
			_alvo_grade,
			VELOCIDADE * delta
		)

		if jogador.global_position.distance_to(_alvo_grade) <= 0.001:
			jogador.global_position = _alvo_grade
			_movendo_grade = false

		return

	var direcao_grade := Vector3i.ZERO

	if Input.is_action_pressed("up"):
		direcao_grade.z -= 1

	if Input.is_action_pressed("down"):
		direcao_grade.z += 1

	if Input.is_action_pressed("left"):
		direcao_grade.x -= 1

	if Input.is_action_pressed("right"):
		direcao_grade.x += 1

	if direcao_grade == Vector3i.ZERO:
		return

	var celula_atual: Vector3i = celula_jogador()
	var celula_alvo: Vector3i = celula_atual + direcao_grade

	_alvo_grade = grid_trilhos.to_global(
		grid_trilhos.map_to_local(celula_alvo)
	)

	_alvo_grade.y = jogador.global_position.y
	_movendo_grade = true


func celula_jogador() -> Vector3i:
	return grid_trilhos.local_to_map(
		grid_trilhos.to_local(jogador.global_position)
	)
