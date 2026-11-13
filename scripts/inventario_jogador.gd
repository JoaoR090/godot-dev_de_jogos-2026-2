
extends Node

signal inventario_alterado

const ITEM_MAO: String = "Mão"
const ITEM_TRILHO_RETO: String = "Trilho_Reto"
const ITEM_TRILHO_CURVO: String = "Trilho_Curvo"
const MAX_ITENS: int = 3

var indice_inventario: int = 0

var inventario_jogador: Dictionary = {
	0: ITEM_MAO,
	1: ITEM_TRILHO_RETO,
	2: ITEM_TRILHO_CURVO
}

var sentido_trilho: Direcao.Sentido = Direcao.Sentido.CIMA

var _sentidos_slots: Dictionary = {}


func item_atual() -> String:
	return str(inventario_jogador.get(indice_inventario, ""))


func definir_indice(novo_indice: int) -> void:
	if novo_indice < 0 or novo_indice >= MAX_ITENS:
		return

	if novo_indice == indice_inventario:
		return

	_sentidos_slots[indice_inventario] = sentido_trilho

	indice_inventario = novo_indice

	sentido_trilho = _sentidos_slots.get(
		indice_inventario,
		Direcao.Sentido.CIMA
	)

	inventario_alterado.emit()


func girar_trilho(passos: int) -> void:
	if not item_atual().begins_with("Trilho"):
		return

	sentido_trilho = Direcao.avancar_sentido(
		sentido_trilho,
		passos
	)

	inventario_alterado.emit()


func obter_sentido(indice: int) -> Direcao.Sentido:
	if indice == indice_inventario:
		return sentido_trilho

	return _sentidos_slots.get(
		indice,
		Direcao.Sentido.CIMA
	)


func obter_eixo(indice: int) -> Direcao.Eixo:
	return Direcao.eixo_do_sentido(obter_sentido(indice))


func definir_item(indice: int, nome_item: String) -> bool:
	if not inventario_jogador.has(indice):
		push_error("Índice de inventário inválido: %d" % indice)
		return false

	inventario_jogador[indice] = nome_item
	inventario_alterado.emit()

	return true


func selecionar_item(indice: int) -> bool:
	if not inventario_jogador.has(indice):
		push_error("Índice de inventário inválido: %d" % indice)
		return false

	if indice == indice_inventario:
		return false

	definir_indice(indice)

	return true
