extends Camera3D

# Emitido com o ponto 3D atingido quando o jogador clica em algo com colisão.
signal ponto_clicado(posicao: Vector3)

const RAY_LENGTH: float = 1000.0

# _unhandled_input: cliques em botões/menus (UI) não disparam o raio.
func _unhandled_input(event: InputEvent) -> void:
	var clique := event as InputEventMouseButton
	if clique == null or not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return

	# Evita que cliques no HUD também disparem a seleção 3D.
	if get_viewport().gui_get_hovered_control() != null:
		return

	# Raio da câmera até o ponto clicado (usa a posição do próprio evento).
	var origem: Vector3 = project_ray_origin(clique.position)
	var fim: Vector3 = origem + project_ray_normal(clique.position) * RAY_LENGTH

	var consulta := PhysicsRayQueryParameters3D.create(origem, fim)
	var resultado: Dictionary = get_world_3d().direct_space_state.intersect_ray(consulta)

	if resultado.is_empty():
		return

	print("Clicou no objeto em:", resultado["position"])
	ponto_clicado.emit(resultado["position"])
