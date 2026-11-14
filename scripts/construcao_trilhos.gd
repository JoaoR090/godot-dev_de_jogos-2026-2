
extends Node

var jogador: Node3D
var grid_trilhos: Trilhos
var inventario: Node

var raio_colocacao: int = 1


func celula_alvo_colocacao() -> Dictionary:
	if not is_instance_valid(grid_trilhos):
		return {"valida": false, "celula": Vector3i.ZERO}

	var centro: Vector3i = _celula_jogador()

	var camera := jogador.get_viewport().get_camera_3d()

	if camera == null:
		return {"valida": false, "celula": centro}

	var mouse: Vector2 = jogador.get_viewport().get_mouse_position()

	var origem: Vector3 = camera.project_ray_origin(mouse)
	var direcao: Vector3 = camera.project_ray_normal(mouse)

	var centro_mundo: Vector3 = grid_trilhos.to_global(
		grid_trilhos.map_to_local(centro)
	)

	var plano := Plane(Vector3.UP, centro_mundo.y)
	var ponto = plano.intersects_ray(origem, direcao)

	if ponto == null:
		return {"valida": true, "celula": centro}

	var alvo: Vector3i = grid_trilhos.local_to_map(
		grid_trilhos.to_local(ponto)
	)

	var dx: int = clampi(
		alvo.x - centro.x,
		-raio_colocacao,
		raio_colocacao
	)

	var dz: int = clampi(
		alvo.z - centro.z,
		-raio_colocacao,
		raio_colocacao
	)

	alvo = centro + Vector3i(dx, 0, dz)

	return {"valida": true, "celula": alvo}


func colocar_trilho() -> void:
	if not Input.is_action_pressed("place"):
		return

	if jogador.get_viewport().gui_get_hovered_control() != null:
		return

	if not is_instance_valid(grid_trilhos):
		return

	var alvo: Dictionary = celula_alvo_colocacao()

	if not alvo.get("valida", false):
		return

	var posicao: Vector3i = alvo.get(
		"celula",
		_celula_jogador()
	)

	if grid_trilhos.tem_trilho(posicao):
		return

	match inventario.item_atual():
		"Trilho_Reto":
			grid_trilhos.colocar_reto(
				posicao,
				Direcao.eixo_do_sentido(
					inventario.sentido_trilho
				)
			)

		"Trilho_Curvo":
			grid_trilhos.colocar_curva(
				posicao,
				inventario.sentido_trilho
			)


func remover_trilho() -> void:
	if not Input.is_action_pressed("break"):
		return

	if jogador.get_viewport().gui_get_hovered_control() != null:
		return

	if not is_instance_valid(grid_trilhos):
		return

	var alvo: Dictionary = celula_alvo_colocacao()

	if not alvo.get("valida", false):
		return

	var posicao: Vector3i = alvo.get(
		"celula",
		_celula_jogador()
	)

	grid_trilhos.remover_trilho(posicao)


func _celula_jogador() -> Vector3i:
	return grid_trilhos.local_to_map(
		grid_trilhos.to_local(jogador.global_position)
	)
