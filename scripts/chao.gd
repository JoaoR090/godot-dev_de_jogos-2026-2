extends GridMap

const ID_TERRA: int = 3

func _ready() -> void:
	criar_terreno_quadrado(100)

# Preenche um quadrado `lado` x `lado` de terra, centrado na origem.
func criar_terreno_quadrado(lado: int) -> void:
	var metade: int = lado / 2
	for z in range(-metade, lado - metade):
		for x in range(-metade, lado - metade):
			set_cell_item(Vector3i(x, 0, z), ID_TERRA)
