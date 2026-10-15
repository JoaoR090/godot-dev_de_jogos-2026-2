class_name Trilho
extends GridMap

enum Eixo {
	EIXO_Z,
	EIXO_X
}

enum Tipo {
	CURVA,
	RETO
}

enum Sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA
}

@export var ID_RETO: int = 0
@export var ID_CURVO: int = 1

var angulo: float = 0.0

func mudar_curva()->void:
	pass

func configurar(posicao: Vector3i, eixo_trilho: Eixo, tipo_trilho: Tipo, sentidos: Array[Sentido]) -> void:
	match tipo_trilho:
		Tipo.RETO:
			var rotacao := 0.0
			if eixo_trilho == Eixo.EIXO_X:
				rotacao = -90.0
			_colocar_peca(posicao, ID_RETO, angulo + rotacao)

		Tipo.CURVA:
			if sentidos.is_empty():
				print("Informe o sentido da curva.")
				return
			var resultado = 1000
			match eixo_trilho:
				Eixo.EIXO_Z:
					match sentidos[0]:
						Sentido.DIREITA:
							resultado = -90.0

						Sentido.ESQUERDA:
							resultado = 90.0

				Eixo.EIXO_X:
					match sentidos[0]:
						Sentido.CIMA:
							resultado = 0.0

						Sentido.BAIXO:
							resultado = 180.0
			if resultado == 1000:
				print("Combinação de eixo e sentido inválida.")
				return

			_colocar_peca(posicao, ID_CURVO, angulo + resultado)


func _colocar_peca(posicao: Vector3i, id_peca: int, rotacao_y: float) -> void:
	var base_rotacao := Basis(Vector3.UP, deg_to_rad(rotacao_y))

	var orientacao := get_orthogonal_index_from_basis(base_rotacao)

	set_cell_item(posicao, id_peca, orientacao)
