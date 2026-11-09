extends GridMap
var ID_TERRA: int = 3
func _ready() -> void:
	criar_terreno_quadrado(100)


func criar_terreno_quadrado(espaco: int)-> void:
	var posicao: Vector3i = Vector3i.ZERO
	for i in range(espaco):
		posicao.z = i - espaco/2
		for j in range(100):
			posicao.x = j - espaco/2
			set_cell_item(posicao, ID_TERRA)
