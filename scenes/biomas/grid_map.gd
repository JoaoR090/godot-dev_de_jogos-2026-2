extends GridMap

# Isso cria uma lista no painel Inspector do Godot!
@export var blocos_para_girar: Array[int] = []

func _ready() -> void:
	embaralhar_blocos_especificos()

func embaralhar_blocos_especificos() -> void:
	var celulas_usadas: Array[Vector3i] = get_used_cells()
	var angulos: Array[float] = [0.0, PI/2.0, PI, 3.0*PI/2.0]
	
	for posicao in celulas_usadas:
		var item: int = get_cell_item(posicao)
		
		# A mágica acontece aqui: Só gira SE o item estiver na sua lista
		if item in blocos_para_girar:
			var angulo_sorteado: float = angulos.pick_random()
			var base_rotacao: Basis = Basis().rotated(Vector3.UP, angulo_sorteado)
			var orientacao: int = get_orthogonal_index_from_basis(base_rotacao)
			
			set_cell_item(posicao, item, orientacao)
