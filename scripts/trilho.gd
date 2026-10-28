class_name Trilhos
extends GridMap

enum TipoTrilho {
	CURVA,
	RETO
}

# IDs dos modelos correspondentes na biblioteca do GridMap.
var ID_RETO: int = 0
var ID_CURVO: int = 1

static func eixo_da_peca(tipo: TipoTrilho, sentido: Direcao.Sentido) -> Direcao.Eixo:
	var sentido_vertical: bool = (sentido == Direcao.Sentido.CIMA or sentido == Direcao.Sentido.BAIXO)
	var sentido_horizontal: bool = (sentido == Direcao.Sentido.DIREITA or sentido == Direcao.Sentido.ESQUERDA)

	match tipo:
		TipoTrilho.RETO:
			if sentido_vertical:
				return Direcao.Eixo.Z
			if sentido_horizontal:
				return Direcao.Eixo.X
		TipoTrilho.CURVA:
			if sentido_vertical:
				return Direcao.Eixo.X
			if sentido_horizontal:
				return Direcao.Eixo.Z
	return -1


func tem_trilho(posicao: Vector3i) -> bool:
	var item: int = get_cell_item(posicao)
	return item == ID_RETO or item == ID_CURVO

# Coloca um trilho reto pelo eixo ou orienta uma curva pelo sentido informado.
func configurar_trilho(posicao: Vector3i, eixoTrilho: Direcao.Eixo, tipoTrilho: TipoTrilho, sentido: Direcao.Sentido) -> void:
	match tipoTrilho:
		TipoTrilho.RETO:
			var rotacao: float = Direcao.angulo_do_eixo(eixoTrilho)
			if rotacao < 0.0:
				print("Eixo inválido.")
				return
			_colocar_peca(posicao, ID_RETO, rotacao)

		TipoTrilho.CURVA:
			if eixoTrilho != Trilhos.eixo_da_peca(tipoTrilho, sentido):
				print("Combinação de eixo e sentido inválida.")
				return
			var orientacao: int = Direcao.orientacao_do_sentido(sentido, self)
			set_cell_item(posicao, ID_CURVO, orientacao)

# Remove a peca da celula indicada.
func remover_trilho(posicao: Vector3i)->void:
	set_cell_item(posicao, -1)

# Gira a curva para uma orientacao compativel com os trilhos vizinhos.
func atualizar_orientacao_curva(posicao: Vector3i) -> void:
	var item: int = get_cell_item(posicao)

	if item != ID_CURVO:
		return

	var orientacao: int = get_cell_item_orientation(posicao)
	var sentidoAtual: Direcao.Sentido = Direcao.sentido_da_orientacao(orientacao, self)

	if sentidoAtual == -1:
		return

	var novoSentido: Direcao.Sentido = _calcular_sentido_curva(posicao, sentidoAtual)

	if novoSentido == -1:
		return

	var novaOrientacao: int = Direcao.orientacao_do_sentido(novoSentido, self)

	set_cell_item(posicao, item, novaOrientacao)

# Verifica se a celula vizinha na direcao indicada forma uma conexao valida.
func tem_conexao(posicao: Vector3i, sentido: Direcao.Sentido) -> bool:
	var posicaoVizinha: Vector3i = posicao + Direcao.deslocamento(sentido)

	var itemVizinho = get_cell_item(posicaoVizinha)

	if itemVizinho == -1:
		return false

	var sentidoVizinho: Direcao.Sentido = Direcao.sentido_da_orientacao(
		get_cell_item_orientation(posicaoVizinha),
		self
	)

	if sentidoVizinho == -1:
		return false

	var ehConectavel: bool = false

	if itemVizinho == ID_RETO:
		var eixoVizinho: Direcao.Eixo = Trilhos.eixo_da_peca(TipoTrilho.RETO, sentidoVizinho)
		if ((sentido == Direcao.Sentido.CIMA or sentido == Direcao.Sentido.BAIXO) and eixoVizinho == Direcao.Eixo.Z):
			ehConectavel = true
		elif ((sentido == Direcao.Sentido.DIREITA or sentido == Direcao.Sentido.ESQUERDA) and eixoVizinho == Direcao.Eixo.X):
			ehConectavel = true

	elif itemVizinho == ID_CURVO:
		match sentido:
			Direcao.Sentido.CIMA:
				if sentidoVizinho == Direcao.Sentido.BAIXO or sentidoVizinho == Direcao.Sentido.ESQUERDA:
					ehConectavel = true
			Direcao.Sentido.DIREITA:
				if sentidoVizinho == Direcao.Sentido.ESQUERDA or sentidoVizinho == Direcao.Sentido.CIMA:
					ehConectavel = true
			Direcao.Sentido.BAIXO:
				if sentidoVizinho == Direcao.Sentido.CIMA or sentidoVizinho == Direcao.Sentido.DIREITA:
					ehConectavel = true
			Direcao.Sentido.ESQUERDA:
				if sentidoVizinho == Direcao.Sentido.DIREITA or sentidoVizinho == Direcao.Sentido.BAIXO:
					ehConectavel = true

	return ehConectavel

# Usa as conexoes vizinhas para determinar a nova orientacao da curva.
func _calcular_sentido_curva(posicao: Vector3i, sentidoAtual: Direcao.Sentido) -> Direcao.Sentido:
	var trilhosAdjacentes: Array[Direcao.Sentido] = []
	var sentido: Direcao.Sentido = sentidoAtual

	for i in range(2):
		sentido = Direcao.proximo_sentido(sentido)

		if tem_conexao(posicao, sentido):
			trilhosAdjacentes.push_back(sentido)

	if trilhosAdjacentes.is_empty():
		print("Sem trilhos adjacentes")
		return -1

	if trilhosAdjacentes[0] == Direcao.proximo_sentido(sentidoAtual):
		return trilhosAdjacentes[0]

	if trilhosAdjacentes[0] == Direcao.avancar_sentido(sentidoAtual, 2):
		return Direcao.avancar_sentido(sentidoAtual, 3)

	return -1

# Aplica uma peca na celula usando o angulo informado para sua rotacao.
func _colocar_peca(posicao: Vector3i, idPeca: int, rotacaoY: float) -> void:
	var orientacao: int = Direcao.orientacao_do_angulo(rotacaoY, self)
	set_cell_item(posicao, idPeca, orientacao)
