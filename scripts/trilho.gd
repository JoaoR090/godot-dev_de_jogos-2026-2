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

func configurar(posicao: Vector3i, eixoTrilho: Eixo, tipoTrilho: Tipo, sentidos: Array[Sentido]) -> void:
	match tipoTrilho:
		Tipo.RETO:
			var rotacao: float = 0.0
			if eixoTrilho == Eixo.EIXO_X:
				rotacao = 90.0
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

func remover_trilho(posicao: Vector3i)->void:
	set_cell_item(posicao, -1)

func mudar_curva(posicao: Vector3i) -> void:
	var item: int = get_cell_item(posicao)

	if item != ID_CURVO:
		return

	var orientacao: int = get_cell_item_orientation(posicao)
	var sentidoAtual: int = _orientacao_para_sentido(orientacao)

	if sentidoAtual == -1:
		return

	var novoSentido: int = _calcular_sentido_curva(posicao, sentidoAtual)

	if novoSentido == -1:
		return

	var novaOrientacao: int = _sentido_para_orientacao(novoSentido)

	set_cell_item(posicao, item, novaOrientacao)

func tem_conexao(posicao: Vector3i, sentido: Sentido) -> bool:
	var posicaoVizinha: Vector3i = posicao
	match sentido:
		Sentido.CIMA:
			posicaoVizinha.z -= 1
		Sentido.DIREITA:
			posicaoVizinha.x += 1
		Sentido.BAIXO:
			posicaoVizinha.z += 1
		Sentido.ESQUERDA:
			posicaoVizinha.x -= 1

	var itemVizinho = get_cell_item(posicaoVizinha)

	if itemVizinho == -1:
		return false

	var sentidoVizinho: int = _orientacao_para_sentido(get_cell_item_orientation(posicaoVizinha))

	var ehConectavel: bool = false

	if itemVizinho == ID_RETO:
		var eixoVizinho: Eixo = _sentido_para_eixo(Sentido, Tipo.RETO)
		if (sentido == Sentido.CIMA or sentido == Sentido.BAIXO) and eixoVizinho == Eixo.EIXO_Z:
			ehConectavel = true
		elif (sentido == Sentido.DIREITA or sentido == Sentido.ESQUERDA) and eixoVizinho == Eixo.EIXO_Z:
			ehConectavel = true

	elif itemVizinho == ID_CURVO:
		match sentido:
			Sentido.CIMA:
				if sentidoVizinho == Sentido.BAIXO or sentidoVizinho == Sentido.ESQUERDA:
					ehConectavel = true
			Sentido.DIREITA:
				if sentidoVizinho == Sentido.ESQUERDA or sentidoVizinho == Sentido.CIMA:
					ehConectavel = true
			Sentido.BAIXO:
				if sentidoVizinho == Sentido.CIMA or sentidoVizinho == Sentido.DIREITA:
					ehConectavel = true
			Sentido.ESQUERDA:
				if sentidoVizinho == Sentido.DIREITA or sentidoVizinho == Sentido.BAIXO:
					ehConectavel = true

	return ehConectavel

func _sentido_para_eixo(sentido: Sentido, tipo: Tipo) -> Eixo:
	var eixo: Eixo
	match tipo:
		Tipo.RETO:
			if sentido == Sentido.CIMA or sentido == Sentido.BAIXO:
				eixo = Eixo.EIXO_Z
			else:
				eixo = Eixo.EIXO_X
		Tipo.CURVA:
			if sentido == Sentido.CIMA or sentido == Sentido.BAIXO:
				eixo = Eixo.EIXO_X
			else:
				eixo = Eixo.EIXO_Z
	return eixo

func _orientacao_para_sentido(orientacao: int) -> int:
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

func _orientacao_para_angulo(orientacao: int) -> float:
	var base := get_basis_with_orthogonal_index(orientacao)
	var angulo: float = rad_to_deg(base.get_euler().y)
	return fposmod(angulo, 360.0)

func _angulo_para_orientacao(angulo: float) -> int:
	var base := Basis(Vector3.UP, deg_to_rad(angulo))
	return get_orthogonal_index_from_basis(base)

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

func _calcular_sentido_curva(posicao: Vector3i, sentidoAtual: int) -> int:
	var trilhosAdjacentes: Array[Sentido] = []
	var sentido: int = sentidoAtual

	for i in range(2):
		sentido = _proximo_sentido(sentido)

		if tem_conexao(posicao, sentido):
			trilhosAdjacentes.push_back(sentido)

	if trilhosAdjacentes.is_empty():
		print("Sem trilhos adjacentes")
		return -1

	if trilhosAdjacentes[0] == _proximo_sentido(sentidoAtual):
		return trilhosAdjacentes[0]

	if trilhosAdjacentes[0] == _proximo_sentido_n(sentidoAtual, 2):
		return _proximo_sentido_n(sentidoAtual, 3)

	return -1

func _colocar_peca(posicao: Vector3i, idPeca: int, rotacaoY: float) -> void:
	var baseRotacao := Basis(Vector3.UP, deg_to_rad(rotacaoY))
	var orientacao := get_orthogonal_index_from_basis(baseRotacao)
	set_cell_item(posicao, idPeca, orientacao)
