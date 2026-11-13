class_name Trilhos
extends GridMap

enum TipoTrilho {
	CURVA,
	RETO
}

# IDs dos modelos correspondentes na biblioteca do GridMap.
const ID_RETO: int = 0
const ID_CURVO: int = 1

# Lados abertos de uma peça, dada a sua orientação.
#  - Reto : abre o sentido e o oposto (ex.: CIMA abre CIMA e BAIXO).
#  - Curva: abre o sentido e o anterior na ordem circular (ex.: CIMA abre CIMA e ESQUERDA).
static func lados_abertos(tipo: TipoTrilho, sentido: Direcao.Sentido) -> Array[Direcao.Sentido]:
	match tipo:
		TipoTrilho.RETO:
			return [sentido, Direcao.sentido_oposto(sentido)]
		TipoTrilho.CURVA:
			return [sentido, Direcao.sentido_anterior(sentido)]
	return []

func tem_trilho(posicao: Vector3i) -> bool:
	var item: int = get_cell_item(posicao)
	return item == ID_RETO or item == ID_CURVO

# Coloca um trilho reto alinhado ao eixo informado.
func colocar_reto(posicao: Vector3i, eixo: Direcao.Eixo) -> void:
	var rotacao: float = Direcao.angulo_do_eixo(eixo)
	if rotacao < 0.0:
		print("Eixo inválido ao colocar trilho reto.")
		return
	_colocar_peca(posicao, ID_RETO, rotacao)

# Coloca uma curva orientada pelo sentido informado.
func colocar_curva(posicao: Vector3i, sentido: Direcao.Sentido) -> void:
	var rotacao: float = Direcao.angulo_do_sentido(sentido)
	if rotacao < 0.0:
		print("Sentido inválido ao colocar curva.")
		return
	_colocar_peca(posicao, ID_CURVO, rotacao)

# Remove a peça da célula indicada.
func remover_trilho(posicao: Vector3i) -> void:
	set_cell_item(posicao, INVALID_CELL_ITEM)

# Duas células estão conectadas quando a primeira tem um lado aberto para
# `sentido` e a vizinha tem o lado oposto aberto para ela.
func tem_conexao(posicao: Vector3i, sentido: Direcao.Sentido) -> bool:
	var vizinha: Vector3i = posicao + Direcao.deslocamento(sentido)
	return (
		_lados_abertos_da_celula(posicao).has(sentido)
		and _lados_abertos_da_celula(vizinha).has(Direcao.sentido_oposto(sentido))
	)

# Gira a curva no sentido horário até a primeira orientação em que suas pontas
# se encaixam nos trilhos vizinhos. Se nenhuma outra orientação encaixar, a curva
# fica como estava. Retorna true se a curva girou.
# `pontas_minimas`: 2 exige as duas pontas ligadas (evita deixar a curva
# "meio conectada"); 1 aceita encaixar só uma ponta.
func girar_curva_horario(posicao: Vector3i, pontas_minimas: int = 2) -> bool:
	if get_cell_item(posicao) != ID_CURVO:
		return false

	var sentido_atual: Direcao.Sentido = Direcao.sentido_da_orientacao(get_cell_item_orientation(posicao), self)
	if sentido_atual == Direcao.Sentido.INVALIDO:
		return false

	# Passos 1 a 3: a orientação atual não é candidata (a alavanca tem que mudar algo).
	for passo in range(1, 4):
		var candidato: Direcao.Sentido = Direcao.avancar_sentido(sentido_atual, passo)
		if _pontas_encaixadas(posicao, candidato) >= pontas_minimas:
			colocar_curva(posicao, candidato)
			return true

	return false

# Quantas das duas pontas da curva (nessa orientação) têm um vizinho aceitando.
func _pontas_encaixadas(posicao: Vector3i, sentido: Direcao.Sentido) -> int:
	var pontas: int = 0
	for lado in lados_abertos(TipoTrilho.CURVA, sentido):
		if _vizinho_aceita(posicao, lado):
			pontas += 1
	return pontas

# Lados abertos da peça que está na célula (lista vazia se não houver trilho).
func _lados_abertos_da_celula(posicao: Vector3i) -> Array[Direcao.Sentido]:
	var item: int = get_cell_item(posicao)
	if item == INVALID_CELL_ITEM:
		return []

	var sentido: Direcao.Sentido = Direcao.sentido_da_orientacao(get_cell_item_orientation(posicao), self)
	if sentido == Direcao.Sentido.INVALIDO:
		return []

	match item:
		ID_RETO:
			return lados_abertos(TipoTrilho.RETO, sentido)
		ID_CURVO:
			return lados_abertos(TipoTrilho.CURVA, sentido)
	return []

# A célula vizinha em `lado` tem uma ponta aberta voltada para `posicao`?
func _vizinho_aceita(posicao: Vector3i, lado: Direcao.Sentido) -> bool:
	var vizinha: Vector3i = posicao + Direcao.deslocamento(lado)
	return _lados_abertos_da_celula(vizinha).has(Direcao.sentido_oposto(lado))

# Aplica uma peça na célula usando o ângulo informado para sua rotação.
func _colocar_peca(posicao: Vector3i, id_peca: int, rotacao_y: float) -> void:
	var orientacao: int = Direcao.orientacao_do_angulo(rotacao_y, self)
	set_cell_item(posicao, id_peca, orientacao)