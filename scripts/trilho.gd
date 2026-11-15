class_name Trilhos
extends GridMap

enum TipoTrilho {
	CURVA,
	RETO
}

const ID_RETO: int = 0
const ID_CURVO: int = 1

var _celulas_protegidas: Dictionary = {}


func proteger_celula(posicao: Vector3i) -> void:
	_celulas_protegidas[posicao] = true


func celula_protegida(posicao: Vector3i) -> bool:
	return _celulas_protegidas.has(posicao)


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

func colocar_reto(posicao: Vector3i, eixo: Direcao.Eixo) -> void:
	var rotacao: float = Direcao.angulo_do_eixo(eixo)
	if rotacao < 0.0:
		print("Eixo inválido ao colocar trilho reto.")
		return
	_colocar_peca(posicao, ID_RETO, rotacao)

func colocar_curva(posicao: Vector3i, sentido: Direcao.Sentido) -> void:
	var rotacao: float = Direcao.angulo_do_sentido(sentido)
	if rotacao < 0.0:
		print("Sentido inválido ao colocar curva.")
		return
	_colocar_peca(posicao, ID_CURVO, rotacao)

func remover_trilho(posicao: Vector3i) -> void:
	if _celulas_protegidas.has(posicao):
		return

	set_cell_item(posicao, INVALID_CELL_ITEM)

func tem_conexao(posicao: Vector3i, sentido: Direcao.Sentido) -> bool:
	var vizinha: Vector3i = posicao + Direcao.deslocamento(sentido)
	return (
		_lados_abertos_da_celula(posicao).has(sentido)
		and _lados_abertos_da_celula(vizinha).has(Direcao.sentido_oposto(sentido))
	)

func girar_curva_horario(posicao: Vector3i, pontas_minimas: int = 2) -> bool:
	if get_cell_item(posicao) != ID_CURVO:
		return false

	var sentido_atual: Direcao.Sentido = Direcao.sentido_da_orientacao(get_cell_item_orientation(posicao), self)
	if sentido_atual == Direcao.Sentido.INVALIDO:
		return false

	for passo in range(1, 4):
		var candidato: Direcao.Sentido = Direcao.avancar_sentido(sentido_atual, passo)
		if _pontas_encaixadas(posicao, candidato) >= pontas_minimas:
			colocar_curva(posicao, candidato)
			return true

	return false

func _pontas_encaixadas(posicao: Vector3i, sentido: Direcao.Sentido) -> int:
	var pontas: int = 0
	for lado in lados_abertos(TipoTrilho.CURVA, sentido):
		if _vizinho_aceita(posicao, lado):
			pontas += 1
	return pontas

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

func _vizinho_aceita(posicao: Vector3i, lado: Direcao.Sentido) -> bool:
	var vizinha: Vector3i = posicao + Direcao.deslocamento(lado)
	return _lados_abertos_da_celula(vizinha).has(Direcao.sentido_oposto(lado))

func _colocar_peca(posicao: Vector3i, id_peca: int, rotacao_y: float) -> void:
	var orientacao: int = Direcao.orientacao_do_angulo(rotacao_y, self)
	set_cell_item(posicao, id_peca, orientacao)
