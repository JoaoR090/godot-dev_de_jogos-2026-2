class_name Trilhos
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

func remover_trilho(posicao: Vector3i)->void:
	set_cell_item(posicao, -1)

func mudar_curva(posicao: Vector3i)->void:
	var orientacaoAtual: int = get_cell_item_orientation(posicao)
	var item: int = get_cell_item(posicao)

	if item != ID_CURVO:
		return

	var angulo: float = _orientacao_para_angulo(orientacaoAtual)
	var sentidoOriginal: Sentido
	
	match roundi(angulo):
		0:
			sentidoOriginal = Sentido.CIMA
		90:
			sentidoOriginal = Sentido.DIREITA
		180:
			sentidoOriginal = Sentido.BAIXO
		270:
			sentidoOriginal = Sentido.ESQUERDA
		_:
			return

	var sentido: Sentido = sentidoOriginal
	var trilhosAdjacentes: Array[Sentido] = []
	for i in range(2):
		sentido = _proximo_sentido(sentido)
		if tem_trilho(posicao, sentido):
			trilhosAdjacentes.push_back(sentido)

	if trilhosAdjacentes.is_empty():
		print("Sem trilhos adjacentes")
		return

	if trilhosAdjacentes[0] == _proximo_sentido(sentidoOriginal):
		sentido = trilhosAdjacentes[0]
	elif trilhosAdjacentes[0] == _proximo_sentido_n(sentidoOriginal, 2):
		sentido = _proximo_sentido_n(sentidoOriginal, 3)
	else:
		return

	match sentido:
		Sentido.CIMA:
			angulo = 0
		Sentido.DIREITA:
			angulo = 90
		Sentido.BAIXO:
			angulo = 180
		Sentido.ESQUERDA:
			angulo = 270

	var novaOrientacao: int = _angulo_para_orientacao(angulo)

	set_cell_item(posicao, item, novaOrientacao)

func _mudar_curva(posicao: Vector3i) -> void:
	var item: int = get_cell_item(posicao)

	if item != ID_CURVO:
		return

	var orientacao: int = get_cell_item_orientation(posicao)
	var sentidoAtual: int = _obter_sentido(orientacao)

	if sentidoAtual == -1:
		return

	var novoSentido: int = _calcular_sentido_curva(
		posicao,
		sentidoAtual
	)

	if novoSentido == -1:
		return

	var novaOrientacao: int = _sentido_para_orientacao(novoSentido)

	set_cell_item(posicao, item, novaOrientacao)


func _obter_sentido(orientacao: int) -> int:
	var angulo: float = _orientacao_para_angulo(orientacao)

	match roundi(angulo):
		0:
			return Sentido.CIMA
		90:
			return Sentido.DIREITA
		180:
			return Sentido.BAIXO
		270:
			return Sentido.ESQUERDA
		_:
			return -1


func _calcular_sentido_curva(posicao: Vector3i, sentidoAtual: int) -> int:
	var sentidosAdjacentes: Array[Sentido] = []
	var sentido: int = sentidoAtual

	for i in range(2):
		sentido = _proximo_sentido(sentido)

		if tem_trilho(posicao, sentido):
			sentidosAdjacentes.push_back(sentido)

	if sentidosAdjacentes.is_empty():
		print("Sem trilhos adjacentes")
		return -1

	if sentidosAdjacentes[0] == _proximo_sentido(sentidoAtual):
		return sentidosAdjacentes[0]

	if sentidosAdjacentes[0] == _proximo_sentido_n(sentidoAtual, 2):
		return _proximo_sentido_n(sentidoAtual, 3)

	return -1


func _sentido_para_orientacao(sentido: int) -> int:
	var angulo: float

	match sentido:
		Sentido.CIMA:
			angulo = 0.0
		Sentido.DIREITA:
			angulo = 90.0
		Sentido.BAIXO:
			angulo = 180.0
		Sentido.ESQUERDA:
			angulo = 270.0
		_:
			return -1

	return _angulo_para_orientacao(angulo)

func configurar(posicao: Vector3i, eixoTrilho: Eixo, tipoTrilho: Tipo, sentidos: Array[Sentido]) -> void:
	match tipoTrilho:
		Tipo.RETO:
			var rotacao: float = 0.0
			if eixoTrilho == Eixo.EIXO_X:
				rotacao = -90.0
			_colocar_peca(posicao, ID_RETO, rotacao)

		Tipo.CURVA:
			if sentidos.is_empty():
				print("Informe o sentido da curva.")
				return

			var resultado: float
			var combinacao_valida: bool = true

			match eixoTrilho:
				Eixo.EIXO_Z:
					match sentidos[0]:
						Sentido.DIREITA:
							resultado = 90.0
						Sentido.ESQUERDA:
							resultado = 270.0
						_:
							combinacao_valida = false

				Eixo.EIXO_X:
					match sentidos[0]:
						Sentido.CIMA:
							resultado = 0.0
						Sentido.BAIXO:
							resultado = 180.0
						_:
							combinacao_valida = false
				_:
					combinacao_valida = false

			if not combinacao_valida:
				print("Combinação de eixo e sentido inválida.")
				return

			_colocar_peca(posicao, ID_CURVO, resultado)

func _orientacao_para_angulo(orientacao: int) -> float:
	var base := get_basis_with_orthogonal_index(orientacao)
	var angulo: float = rad_to_deg(base.get_euler().y)
	return fposmod(angulo, 360.0)

func _angulo_para_orientacao(angulo: float) -> int:
	var base := Basis(Vector3.UP, deg_to_rad(angulo))
	return get_orthogonal_index_from_basis(base)

func _colocar_peca(posicao: Vector3i, idPeca: int, rotacaoY: float) -> void:
	var baseRotacao := Basis(Vector3.UP, deg_to_rad(rotacaoY))
	var orientacao := get_orthogonal_index_from_basis(baseRotacao)
	set_cell_item(posicao, idPeca, orientacao)

func _proximo_sentido_n(sentido: Sentido, n_vezes: int) -> Sentido:
	for i  in range(n_vezes):
		sentido = _proximo_sentido(sentido)
	return sentido

func _proximo_sentido(sentido: Sentido) -> Sentido:
	match sentido:
		Sentido.CIMA:
			return Sentido.DIREITA
		Sentido.DIREITA:
			return Sentido.BAIXO
		Sentido.BAIXO:
			return Sentido.ESQUERDA
		Sentido.ESQUERDA:
			return Sentido.CIMA
	return sentido

func tem_trilho(posicao: Vector3i, sentido: Sentido) -> bool:
	var vizinha: Vector3i = posicao
	match sentido:
		Sentido.CIMA:
			vizinha.z -= 1
		Sentido.DIREITA:
			vizinha.x += 1
		Sentido.BAIXO:
			vizinha.z += 1
		Sentido.ESQUERDA:
			vizinha.x -= 1
	return get_cell_item(vizinha) == ID_CURVO or get_cell_item(vizinha) == ID_RETO
