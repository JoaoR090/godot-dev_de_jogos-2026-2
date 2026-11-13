extends Camera3D

const RAY_LENGTH = 1000.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Evita que cliques no HUD também disparem a seleção 3D.
		if get_viewport().gui_get_hovered_control() != null:
			return

		var mouse_pos = get_viewport().get_mouse_position()
		var space_state = get_world_3d().direct_space_state
		
		# Cria os pontos de início e fim do raio
		var origin = project_ray_origin(mouse_pos)
		var end = origin + project_ray_normal(mouse_pos) * RAY_LENGTH
		
		# Configura a consulta de física (PhysicsRayQueryParameters3D)
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var result = space_state.intersect_ray(query)
		
		if result:
			# result["position"] contém o Vector3 exato do ponto atingido no objeto 3D
			print("Clicou no objeto em:", result["position"])
