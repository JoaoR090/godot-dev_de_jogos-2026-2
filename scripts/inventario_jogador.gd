
extends Node

signal inventario_alterado

const ITEM_MAO = "Mão"
const ITEM_TRILHO_RETO = "Trilho_Reto"
const ITEM_TRILHO_CURVO = "Trilho_Curvo"
const MAX_ITENS = 3
const MADEIRA_INICIAL = 30

var indice_inventario = 0
var madeira = MADEIRA_INICIAL

var inventario_jogador = {
	0: ITEM_MAO,
	1: ITEM_TRILHO_RETO,
	2: ITEM_TRILHO_CURVO
}

var sentido_trilho = Direcao.Sentido.CIMA
var sentidos_slots = {}


func item_atual() -> String:
	return inventario_jogador.get(indice_inventario, "")

func item_atual_e_trilho() -> bool:
	return item_atual().begins_with("Trilho")

func usando_mao() -> bool:
	return item_atual() == ITEM_MAO


func tem_madeira(quantidade: int = 1) -> bool:
	return madeira >= quantidade

func gastar_madeira(quantidade: int = 1) -> bool:
	if not tem_madeira(quantidade):
		return false

	madeira -= quantidade
	inventario_alterado.emit()
	return true

func adicionar_madeira(quantidade: int = 1) -> void:
	madeira += quantidade
	inventario_alterado.emit()

func definir_indice(indice: int) -> void:
	if indice < 0 or indice >= MAX_ITENS:
		return

	if indice == indice_inventario:
		return

	sentidos_slots[indice_inventario] = sentido_trilho
	indice_inventario = indice

	sentido_trilho = sentidos_slots.get(
		indice,
		Direcao.Sentido.CIMA
	)

	inventario_alterado.emit()


func girar_trilho(passos: int) -> void:
	if not item_atual_e_trilho():
		return

	sentido_trilho = Direcao.avancar_sentido(sentido_trilho, passos)
	inventario_alterado.emit()


func obter_sentido(indice: int) -> Direcao.Sentido:
	if indice == indice_inventario:
		return sentido_trilho

	return sentidos_slots.get(indice, Direcao.Sentido.CIMA)


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
