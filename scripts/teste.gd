extends Node3D

@onready var trilhos: Trilhos = $Trilhos

# Executa os testes de direções, configuração, conexões e rotação das curvas.
func _ready() -> void:
	var pos := Vector3i.ZERO

	_testar_direcoes()

	# Confere a colocacao e a remocao de um trilho reto.
	trilhos.remover_trilho(pos)
	trilhos.configurar_trilho(
		pos,
		Direcao.Eixo.Z,
		Trilhos.TipoTrilho.RETO,
		Direcao.Sentido.CIMA
	)
	assert(trilhos.get_cell_item(pos) == trilhos.ID_RETO)

	trilhos.remover_trilho(pos)
	assert(trilhos.get_cell_item(pos) == -1)

	_testar_configuracao(pos)
	_testar_conexoes_retas(pos)
	_testar_conexoes_curvas(pos)
	_testar_atualizar_orientacao_curva(pos)

	print("Todos os testes passaram.")

# Confere os deslocamentos, a ordem dos sentidos, o oposto e o eixo de uma peça.
func _testar_direcoes() -> void:
	assert(Direcao.deslocamento(Direcao.Sentido.CIMA) == Vector3i(0, 0, -1))
	assert(Direcao.deslocamento(Direcao.Sentido.DIREITA) == Vector3i(1, 0, 0))
	assert(Direcao.deslocamento(Direcao.Sentido.BAIXO) == Vector3i(0, 0, 1))
	assert(Direcao.deslocamento(Direcao.Sentido.ESQUERDA) == Vector3i(-1, 0, 0))
	assert(
		Direcao.proximo_sentido(Direcao.Sentido.CIMA) == Direcao.Sentido.DIREITA
	)
	assert(
		Direcao.sentido_oposto(Direcao.Sentido.CIMA) == Direcao.Sentido.BAIXO
	)
	assert(
		Trilhos.eixo_da_peca(
			Trilhos.TipoTrilho.RETO,
			Direcao.Sentido.CIMA
		) == Direcao.Eixo.Z
	)

# Executa casos válidos e inválidos de configuração de trilhos.
func _testar_configuracao(pos: Vector3i) -> void:
	print("Testando configuracao de trilhos...")

	_testar_configuracao_reta(pos, Direcao.Eixo.Z, Direcao.Sentido.CIMA)
	_testar_configuracao_reta(pos, Direcao.Eixo.X, Direcao.Sentido.DIREITA)
	_testar_configuracao_curva(
		pos, Direcao.Eixo.Z, Direcao.Sentido.DIREITA
	)
	_testar_configuracao_curva(
		pos, Direcao.Eixo.Z, Direcao.Sentido.ESQUERDA
	)
	_testar_configuracao_curva(
		pos, Direcao.Eixo.X, Direcao.Sentido.CIMA
	)
	_testar_configuracao_curva(
		pos, Direcao.Eixo.X, Direcao.Sentido.BAIXO
	)

	_testar_configuracao_curva_invalida(pos, Direcao.Eixo.Z, Direcao.Sentido.CIMA)
	_testar_configuracao_curva_invalida(pos, Direcao.Eixo.Z, Direcao.Sentido.BAIXO)
	_testar_configuracao_curva_invalida(pos, Direcao.Eixo.X, Direcao.Sentido.DIREITA)
	_testar_configuracao_curva_invalida(pos, Direcao.Eixo.X, Direcao.Sentido.ESQUERDA)

	trilhos.remover_trilho(pos)
	trilhos.configurar_trilho(pos, Direcao.Eixo.Z, Trilhos.TipoTrilho.RETO, Direcao.Sentido.CIMA)
	trilhos.configurar_trilho(
		pos,
		Direcao.Eixo.Z,
		Trilhos.TipoTrilho.CURVA,
		Direcao.Sentido.CIMA
	)
	assert(
		trilhos.get_cell_item(pos) == trilhos.ID_RETO,
		"Uma configuracao invalida substituiu a peca que ja estava na celula."
	)
	trilhos.remover_trilho(pos)

# Verifica se o trilho reto é colocado com a orientação esperada para seu eixo.
func _testar_configuracao_reta(
	pos: Vector3i,
	eixo: Direcao.Eixo,
	orientacao: Direcao.Sentido
) -> void:
	trilhos.remover_trilho(pos)
	trilhos.configurar_trilho(pos, eixo, Trilhos.TipoTrilho.RETO, Direcao.Sentido.CIMA)
	assert(
		trilhos.get_cell_item(pos) == trilhos.ID_RETO,
		"Nao foi colocado o trilho reto."
	)
	assert(
		trilhos.get_cell_item_orientation(pos) == Direcao.orientacao_do_sentido(orientacao, trilhos),
		"Orientacao incorreta para trilho reto no eixo %s." % eixo
	)

# Verifica a colocação e a orientação de uma curva com eixo e sentido compatíveis.
func _testar_configuracao_curva(
	pos: Vector3i,
	eixo: Direcao.Eixo,
	sentido: Direcao.Sentido
) -> void:
	trilhos.remover_trilho(pos)
	trilhos.configurar_trilho(pos, eixo, Trilhos.TipoTrilho.CURVA, sentido)
	assert(
		trilhos.get_cell_item(pos) == trilhos.ID_CURVO,
		"Nao foi colocada a curva para eixo %s e sentido %s." % [eixo, sentido]
	)
	assert(
		trilhos.get_cell_item_orientation(pos) == Direcao.orientacao_do_sentido(sentido, trilhos),
		"Orientacao incorreta para curva no eixo %s e sentido %s."
		% [eixo, sentido]
	)
	trilhos.remover_trilho(pos)

# Confirma que uma curva com eixo e sentido incompatíveis não é colocada.
func _testar_configuracao_curva_invalida(
	pos: Vector3i,
	eixo: Direcao.Eixo,
	sentido: Direcao.Sentido
) -> void:
	trilhos.remover_trilho(pos)
	trilhos.configurar_trilho(pos, eixo, Trilhos.TipoTrilho.CURVA, sentido)
	assert(
		trilhos.get_cell_item(pos) == -1,
		"Foi colocada curva com combinacao invalida: eixo %s e sentido %s."
		% [eixo, sentido]
	)

# Testa conexões de trilhos retos em todas as direções e nos dois eixos.
func _testar_conexoes_retas(pos: Vector3i) -> void:
	print("Testando conexoes com trilhos retos...")
	var celula_acima := _posicao_vizinha(pos, Direcao.Sentido.CIMA)
	trilhos.remover_trilho(celula_acima)
	assert(
		not trilhos.tem_conexao(pos, Direcao.Sentido.CIMA),
		"Foi indicada conexao apesar de nao haver trilho vizinho."
	)

	_testar_conexao_reta(pos, Direcao.Sentido.CIMA, Direcao.Eixo.Z, true)
	_testar_conexao_reta(pos, Direcao.Sentido.CIMA, Direcao.Eixo.X, false)
	_testar_conexao_reta(pos, Direcao.Sentido.BAIXO, Direcao.Eixo.Z, true)
	_testar_conexao_reta(pos, Direcao.Sentido.BAIXO, Direcao.Eixo.X, false)
	_testar_conexao_reta(pos, Direcao.Sentido.DIREITA, Direcao.Eixo.X, true)
	_testar_conexao_reta(pos, Direcao.Sentido.DIREITA, Direcao.Eixo.Z, false)
	_testar_conexao_reta(pos, Direcao.Sentido.ESQUERDA, Direcao.Eixo.X, true)
	_testar_conexao_reta(pos, Direcao.Sentido.ESQUERDA, Direcao.Eixo.Z, false)

# Testa combinações de conexão válidas e inválidas para curvas vizinhas.
func _testar_conexoes_curvas(pos: Vector3i) -> void:
	print("Testando conexoes com trilhos curvos...")
	_testar_conexao_curva(pos, Direcao.Sentido.CIMA, Direcao.Eixo.X, Direcao.Sentido.BAIXO, true)
	_testar_conexao_curva(pos, Direcao.Sentido.CIMA, Direcao.Eixo.Z, Direcao.Sentido.ESQUERDA, true)
	_testar_conexao_curva(pos, Direcao.Sentido.CIMA, Direcao.Eixo.X, Direcao.Sentido.CIMA, false)
	_testar_conexao_curva(pos, Direcao.Sentido.CIMA, Direcao.Eixo.Z, Direcao.Sentido.DIREITA, false)

	_testar_conexao_curva(pos, Direcao.Sentido.DIREITA, Direcao.Eixo.Z, Direcao.Sentido.ESQUERDA, true)
	_testar_conexao_curva(pos, Direcao.Sentido.DIREITA, Direcao.Eixo.X, Direcao.Sentido.CIMA, true)
	_testar_conexao_curva(pos, Direcao.Sentido.DIREITA, Direcao.Eixo.Z, Direcao.Sentido.DIREITA, false)
	_testar_conexao_curva(pos, Direcao.Sentido.DIREITA, Direcao.Eixo.X, Direcao.Sentido.BAIXO, false)

	_testar_conexao_curva(pos, Direcao.Sentido.BAIXO, Direcao.Eixo.X, Direcao.Sentido.CIMA, true)
	_testar_conexao_curva(pos, Direcao.Sentido.BAIXO, Direcao.Eixo.Z, Direcao.Sentido.DIREITA, true)
	_testar_conexao_curva(pos, Direcao.Sentido.BAIXO, Direcao.Eixo.X, Direcao.Sentido.BAIXO, false)
	_testar_conexao_curva(pos, Direcao.Sentido.BAIXO, Direcao.Eixo.Z, Direcao.Sentido.ESQUERDA, false)

	_testar_conexao_curva(pos, Direcao.Sentido.ESQUERDA, Direcao.Eixo.Z, Direcao.Sentido.DIREITA, true)
	_testar_conexao_curva(pos, Direcao.Sentido.ESQUERDA, Direcao.Eixo.X, Direcao.Sentido.BAIXO, true)
	_testar_conexao_curva(pos, Direcao.Sentido.ESQUERDA, Direcao.Eixo.Z, Direcao.Sentido.ESQUERDA, false)
	_testar_conexao_curva(pos, Direcao.Sentido.ESQUERDA, Direcao.Eixo.X, Direcao.Sentido.CIMA, false)

# Configura um trilho reto vizinho e compara a conexão obtida com o resultado esperado.
func _testar_conexao_reta(
	pos: Vector3i,
	sentido: Direcao.Sentido,
	eixo: Direcao.Eixo,
	esperado: bool
) -> void:
	var vizinha := _posicao_vizinha(pos, sentido)

	trilhos.remover_trilho(vizinha)
	trilhos.configurar_trilho(vizinha, eixo, Trilhos.TipoTrilho.RETO, Direcao.Sentido.CIMA)

	var resultado: bool = trilhos.tem_conexao(pos, sentido)
	assert(
		resultado == esperado,
		"Conexao reta incorreta: sentido %s, eixo %s, esperado %s, recebido %s"
		% [sentido, eixo, esperado, resultado]
	)
	trilhos.remover_trilho(vizinha)

# Configura uma curva vizinha e compara a conexão obtida com o resultado esperado.
func _testar_conexao_curva(
	pos: Vector3i,
	sentidoVizinho: Direcao.Sentido,
	eixoCurva: Direcao.Eixo,
	orientacaoCurva: Direcao.Sentido,
	esperado: bool
) -> void:
	var vizinha := _posicao_vizinha(pos, sentidoVizinho)

	trilhos.remover_trilho(vizinha)
	trilhos.configurar_trilho(vizinha, eixoCurva, Trilhos.TipoTrilho.CURVA, orientacaoCurva)

	var resultado: bool = trilhos.tem_conexao(pos, sentidoVizinho)
	assert(
		resultado == esperado,
		"Conexao curva incorreta: sentido vizinho %s, orientacao %s, esperado %s, recebido %s"
		% [sentidoVizinho, orientacaoCurva, esperado, resultado]
	)
	trilhos.remover_trilho(vizinha)

# Verifica a atualização da curva sem vizinhos, com vizinhos e com duas conexões candidatas.
func _testar_atualizar_orientacao_curva(pos: Vector3i) -> void:
	print("Testando rotacao de curvas...")
	var vizinha_direita := _posicao_vizinha(pos, Direcao.Sentido.DIREITA)
	var vizinha_abaixo := _posicao_vizinha(pos, Direcao.Sentido.BAIXO)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)
	trilhos.atualizar_orientacao_curva(pos)
	assert(
		trilhos.get_cell_item(pos) == -1,
		"atualizar_orientacao_curva colocou uma peca em uma celula vazia."
	)

	trilhos.configurar_trilho(pos, Direcao.Eixo.Z, Trilhos.TipoTrilho.RETO, Direcao.Sentido.CIMA)
	var orientacao_reta: int = trilhos.get_cell_item_orientation(pos)
	trilhos.atualizar_orientacao_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == orientacao_reta,
		"atualizar_orientacao_curva alterou a orientacao de um trilho reto."
	)

	trilhos.configurar_trilho(pos, Direcao.Eixo.X, Trilhos.TipoTrilho.CURVA, Direcao.Sentido.CIMA)
	trilhos.configurar_trilho(
		vizinha_direita,
		Direcao.Eixo.X,
		Trilhos.TipoTrilho.CURVA,
		Direcao.Sentido.CIMA
	)
	trilhos.atualizar_orientacao_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == Direcao.orientacao_do_sentido(Direcao.Sentido.DIREITA, trilhos),
		"A curva nao girou em direcao ao trilho da direita."
	)

	trilhos.configurar_trilho(pos, Direcao.Eixo.X, Trilhos.TipoTrilho.CURVA, Direcao.Sentido.CIMA)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.configurar_trilho(
		vizinha_abaixo,
		Direcao.Eixo.X,
		Trilhos.TipoTrilho.CURVA,
		Direcao.Sentido.CIMA
	)
	trilhos.atualizar_orientacao_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == Direcao.orientacao_do_sentido(Direcao.Sentido.ESQUERDA, trilhos),
		"A curva nao girou para o lado oposto ao trilho abaixo."
	)

	trilhos.configurar_trilho(pos, Direcao.Eixo.X, Trilhos.TipoTrilho.CURVA, Direcao.Sentido.CIMA)
	trilhos.remover_trilho(vizinha_abaixo)
	var orientacao_sem_vizinhos: int = trilhos.get_cell_item_orientation(pos)
	trilhos.atualizar_orientacao_curva(pos)
	assert(
		trilhos.get_cell_item_orientation(pos) == orientacao_sem_vizinhos,
		"A curva mudou de orientacao sem trilhos vizinhos."
	)

	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.CIMA, Direcao.Sentido.DIREITA, Direcao.Sentido.DIREITA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.CIMA, Direcao.Sentido.BAIXO, Direcao.Sentido.ESQUERDA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.DIREITA, Direcao.Sentido.BAIXO, Direcao.Sentido.BAIXO
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.DIREITA, Direcao.Sentido.ESQUERDA, Direcao.Sentido.CIMA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.BAIXO, Direcao.Sentido.ESQUERDA, Direcao.Sentido.ESQUERDA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.BAIXO, Direcao.Sentido.CIMA, Direcao.Sentido.DIREITA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.ESQUERDA, Direcao.Sentido.CIMA, Direcao.Sentido.CIMA
	)
	_testar_rotacao_curva_com_vizinho(
		pos, Direcao.Sentido.ESQUERDA, Direcao.Sentido.DIREITA, Direcao.Sentido.BAIXO
	)
	_testar_rotacao_curva_com_dois_vizinhos(pos)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)

# Confere a orientação escolhida para a curva em cada caso com um único vizinho.
func _testar_rotacao_curva_com_vizinho(
	pos: Vector3i,
	orientacaoInicial: Direcao.Sentido,
	ladoVizinho: Direcao.Sentido,
	orientacaoEsperada: Direcao.Sentido
) -> void:
	var celulaVizinha := _posicao_vizinha(pos, ladoVizinho)
	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(celulaVizinha)

	_configurar_curva(pos, orientacaoInicial)
	_configurar_curva(celulaVizinha, _sentido_de_entrada(ladoVizinho))
	trilhos.atualizar_orientacao_curva(pos)

	assert(
		trilhos.get_cell_item_orientation(pos) == Direcao.orientacao_do_sentido(orientacaoEsperada, trilhos),
		"Com orientacao inicial %s e vizinho em %s, esperava orientacao %s."
		% [orientacaoInicial, ladoVizinho, orientacaoEsperada]
	)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(celulaVizinha)

# Confirma que, entre duas conexões candidatas, a curva segue a prioridade definida.
func _testar_rotacao_curva_com_dois_vizinhos(pos: Vector3i) -> void:
	var vizinha_direita := _posicao_vizinha(pos, Direcao.Sentido.DIREITA)
	var vizinha_abaixo := _posicao_vizinha(pos, Direcao.Sentido.BAIXO)
	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)

	_configurar_curva(pos, Direcao.Sentido.CIMA)
	_configurar_curva(vizinha_direita, _sentido_de_entrada(Direcao.Sentido.DIREITA))
	_configurar_curva(vizinha_abaixo, _sentido_de_entrada(Direcao.Sentido.BAIXO))
	trilhos.atualizar_orientacao_curva(pos)

	assert(
		trilhos.get_cell_item_orientation(pos) == Direcao.orientacao_do_sentido(Direcao.Sentido.DIREITA, trilhos),
		"Com duas conexoes candidatas, a curva deveria priorizar a direita."
	)

	trilhos.remover_trilho(pos)
	trilhos.remover_trilho(vizinha_direita)
	trilhos.remover_trilho(vizinha_abaixo)

# Configura uma curva usando o eixo correspondente ao sentido informado.
func _configurar_curva(pos: Vector3i, sentido: Direcao.Sentido) -> void:
	var eixo: Direcao.Eixo = Trilhos.eixo_da_peca(Trilhos.TipoTrilho.CURVA, sentido)
	trilhos.configurar_trilho(pos, eixo, Trilhos.TipoTrilho.CURVA, sentido)

# Retorna o sentido pelo qual o trem entra na célula vizinha.
func _sentido_de_entrada(ladoVizinho: Direcao.Sentido) -> Direcao.Sentido:
	return Direcao.sentido_oposto(ladoVizinho)

# Calcula a posição da célula vizinha no sentido indicado.
func _posicao_vizinha(pos: Vector3i, sentido: Direcao.Sentido) -> Vector3i:
	return pos + Direcao.deslocamento(sentido)
