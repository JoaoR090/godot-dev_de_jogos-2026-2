extends Node3D

@onready var trilhos: Trilhos = $Trilhos

func _ready() -> void:
	var pos := Vector3i.ZERO

	# Confere a colocacao e a remocao de um trilho reto.
	trilhos.remover_trilho(pos)
	trilhos.configurar(
		pos,
		Trilhos.Eixo.EIXO_Z,
		Trilhos.Tipo.RETO,
		Trilhos.Sentido.CIMA
	)
	assert(trilhos.get_cell_item(pos) == trilhos.ID_RETO)

	trilhos.remover_trilho(pos)
	assert(trilhos.get_cell_item(pos) == -1)

	_testar_configuracao(pos)
	_testar_conexoes_retas(pos)
	_testar_conexoes_curvas(pos)
	_testar_mudar_curva(pos)

	print("Todos os testes passaram.")

func _testar_configuracao(pos: Vector3i) -> void:
	print("Testando configuracao de trilhos...")

	_testar_configuracao_reta(pos, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.CIMA)
	_testar_configuracao_reta(pos, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.DIREITA)
	_testar_configuracao_curva(
		pos, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.DIREITA
	)
	_testar_configuracao_curva(
		pos, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.ESQUERDA
	)
	_testar_configuracao_curva(
		pos, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.CIMA
	)
	_testar_configuracao_curva(
		pos, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.BAIXO
	)

	_testar_configuracao_curva_invalida(pos, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.CIMA)
	_testar_configuracao_curva_invalida(pos, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.BAIXO)
	_testar_configuracao_curva_invalida(pos, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.DIREITA)
	_testar_configuracao_curva_invalida(pos, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.ESQUERDA)

	trilhos.remover_trilho(pos)
	trilhos.configurar(pos, Trilhos.Eixo.EIXO_Z, Trilhos.Tipo.RETO, Trilhos.Sentido.CIMA)
	trilhos.configurar(
		pos,
		Trilhos.Eixo.EIXO_Z,
		Trilhos.Tipo.CURVA,
		Trilhos.Sentido.CIMA
	)
	assert(
		trilhos.get_cell_item(pos) == trilhos.ID_RETO,
		"Uma configuracao invalida substituiu a peca que ja estava na celula."
	)
	trilhos.remover_trilho(pos)

func _testar_configuracao_reta(
	pos: Vector3i,
	eixo: Trilhos.Eixo,
	orientacao: Trilhos.Sentido
) -> void:
	trilhos.remover_trilho(pos)
	trilhos.configurar(pos, eixo, Trilhos.Tipo.RETO, Trilhos.Sentido.CIMA)
	assert(
		trilhos.get_cell_item(pos) == trilhos.ID_RETO,
		"Nao foi colocado o trilho reto."
	)
	assert(
		trilhos.get_cell_item_orientation(pos) == _orientacao_para_sentido(orientacao),
		"Orientacao incorreta para trilho reto no eixo %s." % eixo
	)

func _testar_configuracao_curva(
	pos: Vector3i,
	eixo: Trilhos.Eixo,
	sentido: Trilhos.Sentido
) -> void:
	trilhos.remover_trilho(pos)
	trilhos.configurar(pos, eixo, Trilhos.Tipo.CURVA, sentido)
	assert(
		trilhos.get_cell_item(pos) == trilhos.ID_CURVO,
		"Nao foi colocada a curva para eixo %s e sentido %s." % [eixo, sentido]
	)
	assert(
		trilhos.get_cell_item_orientation(pos) == _orientacao_para_sentido(sentido),
		"Orientacao incorreta para curva no eixo %s e sentido %s."
		% [eixo, sentido]
	)
	trilhos.remover_trilho(pos)

func _testar_configuracao_curva_invalida(
	pos: Vector3i,
	eixo: Trilhos.Eixo,
	sentido: Trilhos.Sentido
) -> void:
	trilhos.remover_trilho(pos)
	trilhos.configurar(pos, eixo, Trilhos.Tipo.CURVA, sentido)
	assert(
		trilhos.get_cell_item(pos) == -1,
		"Foi colocada curva com combinacao invalida: eixo %s e sentido %s."
		% [eixo, sentido]
	)

func _testar_conexoes_retas(pos: Vector3i) -> void:
	print("Testando conexoes com trilhos retos...")
	var celula_acima := _posicao_vizinha(pos, Trilhos.Sentido.CIMA)
	trilhos.remover_trilho(celula_acima)
	assert(
		not trilhos.tem_conexao(pos, Trilhos.Sentido.CIMA),
		"Foi indicada conexao apesar de nao haver trilho vizinho."
	)

	_testar_conexao_reta(pos, Trilhos.Sentido.CIMA, Trilhos.Eixo.EIXO_Z, true)
	_testar_conexao_reta(pos, Trilhos.Sentido.CIMA, Trilhos.Eixo.EIXO_X, false)
	_testar_conexao_reta(pos, Trilhos.Sentido.BAIXO, Trilhos.Eixo.EIXO_Z, true)
	_testar_conexao_reta(pos, Trilhos.Sentido.BAIXO, Trilhos.Eixo.EIXO_X, false)
	_testar_conexao_reta(pos, Trilhos.Sentido.DIREITA, Trilhos.Eixo.EIXO_X, true)
	_testar_conexao_reta(pos, Trilhos.Sentido.DIREITA, Trilhos.Eixo.EIXO_Z, false)
	_testar_conexao_reta(pos, Trilhos.Sentido.ESQUERDA, Trilhos.Eixo.EIXO_X, true)
	_testar_conexao_reta(pos, Trilhos.Sentido.ESQUERDA, Trilhos.Eixo.EIXO_Z, false)

func _testar_conexoes_curvas(pos: Vector3i) -> void:
	print("Testando conexoes com trilhos curvos...")
	_testar_conexao_curva(pos, Trilhos.Sentido.CIMA, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.BAIXO, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.CIMA, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.ESQUERDA, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.CIMA, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.CIMA, false)
	_testar_conexao_curva(pos, Trilhos.Sentido.CIMA, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.DIREITA, false)

	_testar_conexao_curva(pos, Trilhos.Sentido.DIREITA, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.ESQUERDA, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.DIREITA, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.CIMA, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.DIREITA, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.DIREITA, false)
	_testar_conexao_curva(pos, Trilhos.Sentido.DIREITA, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.BAIXO, false)

	_testar_conexao_curva(pos, Trilhos.Sentido.BAIXO, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.CIMA, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.BAIXO, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.DIREITA, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.BAIXO, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.BAIXO, false)
	_testar_conexao_curva(pos, Trilhos.Sentido.BAIXO, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.ESQUERDA, false)

	_testar_conexao_curva(pos, Trilhos.Sentido.ESQUERDA, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.DIREITA, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.ESQUERDA, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.BAIXO, true)
	_testar_conexao_curva(pos, Trilhos.Sentido.ESQUERDA, Trilhos.Eixo.EIXO_Z, Trilhos.Sentido.ESQUERDA, false)
	_testar_conexao_curva(pos, Trilhos.Sentido.ESQUERDA, Trilhos.Eixo.EIXO_X, Trilhos.Sentido.CIMA, false)

func _testar_conexao_reta(
	pos: Vector3i,
	sentido: Trilhos.Sentido,
	eixo: Trilhos.Eixo,
	esperado: bool
) -> void:
	var vizinha := _posicao_vizinha(pos, sentido)

	trilhos.remover_trilho(vizinha)
	trilhos.configurar(vizinha, eixo, Trilhos.Tipo.RETO, Trilhos.Sentido.CIMA)

	var resultado: bool = trilhos.tem_conexao(pos, sentido)
	assert(
		resultado == esperado,
		"Conexao reta incorreta: sentido %s, eixo %s, esperado %s, recebido %s"
		% [sentido, eixo, esperado, resultado]
	)
	trilhos.remover_trilho(vizinha)

func _testar_conexao_curva(
	pos: Vector3i,
	sentidoVizinho: Trilhos.Sentido,
	eixoCurva: Trilhos.Eixo,
	orientacaoCurva: Trilhos.Sentido,
	esperado: bool
) -> void:
	var vizinha := _posicao_vizinha(pos, sentidoVizinho)

	trilhos.remover_trilho(vizinha)
	trilhos.configurar(vizinha, eixoCurva, Trilhos.Tipo.CURVA, orientacaoCurva)

	var resultado: bool = trilhos.tem_conexao(pos, sentidoVizinho)
	assert(
		resultado == esperado,
		"Conexao curva incorreta: sentido vizinho %s, orientacao %s, esperado %s, recebido %s"
		% [sentidoVizinho, orientacaoCurva, esperado, resultado]
	)
	trilhos.remover_trilho(vizinha)

func _testar_mudar_curva(pos: Vector3i) -> void:
	print("Testando rotacao de curvas...")
	var vizinha_direita := _posicao_vizinha(pos, Trilhos.Sentido.DIREITA)
	var vizinha_abaixo := _posicao_vizinha(pos, Trilhos.Sentido.BAIXO)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)
	trilhos.mudar_curva(pos)
	assert(
		trilhos.get_cell_item(pos) == -1,
		"mudar_curva colocou uma peca em uma celula vazia."
	)

	trilhos.configurar(pos, Trilhos.Eixo.EIXO_Z, Trilhos.Tipo.RETO, Trilhos.Sentido.CIMA)
	var orientacao_reta: int = trilhos.get_cell_item_orientation(pos)
	trilhos.mudar_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == orientacao_reta,
		"mudar_curva alterou a orientacao de um trilho reto."
	)

	trilhos.configurar(pos, Trilhos.Eixo.EIXO_X, Trilhos.Tipo.CURVA, Trilhos.Sentido.CIMA)
	trilhos.configurar(
		vizinha_direita,
		Trilhos.Eixo.EIXO_X,
		Trilhos.Tipo.CURVA,
		Trilhos.Sentido.CIMA
	)
	trilhos.mudar_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == _orientacao_para_sentido(Trilhos.Sentido.DIREITA),
		"A curva nao girou em direcao ao trilho da direita."
	)

	trilhos.configurar(pos, Trilhos.Eixo.EIXO_X, Trilhos.Tipo.CURVA, Trilhos.Sentido.CIMA)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.configurar(
		vizinha_abaixo,
		Trilhos.Eixo.EIXO_X,
		Trilhos.Tipo.CURVA,
		Trilhos.Sentido.CIMA
	)
	trilhos.mudar_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == _orientacao_para_sentido(Trilhos.Sentido.ESQUERDA),
		"A curva nao girou para o lado oposto ao trilho abaixo."
	)

	trilhos.configurar(pos, Trilhos.Eixo.EIXO_X, Trilhos.Tipo.CURVA, Trilhos.Sentido.CIMA)
	trilhos.remover_trilho(vizinha_abaixo)
	var orientacao_sem_vizinhos: int = trilhos.get_cell_item_orientation(pos)
	trilhos.mudar_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == orientacao_sem_vizinhos,
		"A curva mudou de orientacao sem trilhos vizinhos."
	)

	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.CIMA, Trilhos.Sentido.DIREITA, Trilhos.Sentido.DIREITA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.CIMA, Trilhos.Sentido.BAIXO, Trilhos.Sentido.ESQUERDA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.DIREITA, Trilhos.Sentido.BAIXO, Trilhos.Sentido.BAIXO
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.DIREITA, Trilhos.Sentido.ESQUERDA, Trilhos.Sentido.CIMA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.BAIXO, Trilhos.Sentido.ESQUERDA, Trilhos.Sentido.ESQUERDA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.BAIXO, Trilhos.Sentido.CIMA, Trilhos.Sentido.DIREITA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.ESQUERDA, Trilhos.Sentido.CIMA, Trilhos.Sentido.CIMA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Trilhos.Sentido.ESQUERDA, Trilhos.Sentido.DIREITA, Trilhos.Sentido.BAIXO
	)
	_testar_rotacao_curva_com_dois_vizinhos(pos)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)

func _testar_rotacao_curva_com_vizinho(
	pos: Vector3i,
	orientacaoInicial: Trilhos.Sentido,
	ladoVizinho: Trilhos.Sentido,
	orientacaoEsperada: Trilhos.Sentido
) -> void:
	var celulaVizinha := _posicao_vizinha(pos, ladoVizinho)
	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(celulaVizinha)

	_configurar_curva(pos, orientacaoInicial)
	_configurar_curva(celulaVizinha, _sentido_de_entrada(ladoVizinho))
	trilhos.mudar_curva(pos)

	assert(
		trilhos.get_cell_item_orientation(pos) == _orientacao_para_sentido(orientacaoEsperada),
		"Com orientacao inicial %s e vizinho em %s, esperava orientacao %s."
		% [orientacaoInicial, ladoVizinho, orientacaoEsperada]
	)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(celulaVizinha)

func _testar_rotacao_curva_com_dois_vizinhos(pos: Vector3i) -> void:
	var vizinha_direita := _posicao_vizinha(pos, Trilhos.Sentido.DIREITA)
	var vizinha_abaixo := _posicao_vizinha(pos, Trilhos.Sentido.BAIXO)
	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)

	_configurar_curva(pos, Trilhos.Sentido.CIMA)
	_configurar_curva(vizinha_direita, _sentido_de_entrada(Trilhos.Sentido.DIREITA))
	_configurar_curva(vizinha_abaixo, _sentido_de_entrada(Trilhos.Sentido.BAIXO))
	trilhos.mudar_curva(pos)

	assert(
		trilhos.get_cell_item_orientation(pos) == _orientacao_para_sentido(Trilhos.Sentido.DIREITA),
		"Com duas conexoes candidatas, a curva deveria priorizar a direita."
	)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)

func _configurar_curva(pos: Vector3i, sentido: Trilhos.Sentido) -> void:
	var eixo: Trilhos.Eixo
	match sentido:
		Trilhos.Sentido.CIMA, Trilhos.Sentido.BAIXO:
			eixo = Trilhos.Eixo.EIXO_X
		Trilhos.Sentido.DIREITA, Trilhos.Sentido.ESQUERDA:
			eixo = Trilhos.Eixo.EIXO_Z

	trilhos.configurar(pos, eixo, Trilhos.Tipo.CURVA, sentido)

func _sentido_de_entrada(ladoVizinho: Trilhos.Sentido) -> Trilhos.Sentido:
	match ladoVizinho:
		Trilhos.Sentido.CIMA:
			return Trilhos.Sentido.BAIXO
		Trilhos.Sentido.DIREITA:
			return Trilhos.Sentido.ESQUERDA
		Trilhos.Sentido.BAIXO:
			return Trilhos.Sentido.CIMA
		Trilhos.Sentido.ESQUERDA:
			return Trilhos.Sentido.DIREITA
	return Trilhos.Sentido.CIMA

func _posicao_vizinha(pos: Vector3i, sentido: Trilhos.Sentido) -> Vector3i:
	match sentido:
		Trilhos.Sentido.CIMA:
			pos.z -= 1
		Trilhos.Sentido.DIREITA:
			pos.x += 1
		Trilhos.Sentido.BAIXO:
			pos.z += 1
		Trilhos.Sentido.ESQUERDA:
			pos.x -= 1
	return pos

func _orientacao_para_sentido(sentido: Trilhos.Sentido) -> int:
	var angulo: float = 0.0
	match sentido:
		Trilhos.Sentido.CIMA:
			angulo = 0.0
		Trilhos.Sentido.DIREITA:
			angulo = 90.0
		Trilhos.Sentido.BAIXO:
			angulo = 180.0
		Trilhos.Sentido.ESQUERDA:
			angulo = 270.0
		_:
			return -1
	return trilhos.get_orthogonal_index_from_basis(Basis(Vector3.UP, deg_to_rad(angulo)))
