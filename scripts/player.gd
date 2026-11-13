
class_name Player
extends Node3D

signal inventario_alterado

@export var grid_trilhos: Trilhos
@export_range(0, 10, 1) var raio_colocacao: int = 1

@onready var movimento = $MovimentoJogador
@onready var inventario = $InventarioJogador
@onready var construcao = $ConstrucaoTrilhos
@onready var preview = $PreviewTrilhos


func _ready() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var bus_sfx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_sfx, "SFX")
		AudioServer.set_bus_send(bus_sfx, "Master")
	_audio_walk = AudioStreamPlayer.new()
	_audio_walk.stream = SFX_WALK
	_audio_walk.bus = "SFX"
	_audio_walk.volume_db = -6.0
	add_child(_audio_walk)
	_audio_place = AudioStreamPlayer.new()
	_audio_place.stream = SFX_PLACE
	_audio_place.bus = "SFX"
	add_child(_audio_place)

	if not is_instance_valid(grid_trilhos):
		push_error("Atribua o GridMap de trilhos no Player.")
		return

	movimento.jogador = self
	movimento.grid_trilhos = grid_trilhos

	construcao.jogador = self
	construcao.grid_trilhos = grid_trilhos
	construcao.inventario = inventario
	construcao.raio_colocacao = raio_colocacao

	preview.jogador = self
	preview.grid_trilhos = grid_trilhos
	preview.construcao = construcao
	preview.inventario = inventario

	inventario.inventario_alterado.connect(_notificar_mudanca)
	_notificar_mudanca()


func _physics_process(delta: float) -> void:
	movimento.mover_em_grade(delta)
	construcao.colocar_trilho()
	construcao.remover_trilho()
	preview.atualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("changeNext"):
		inventario.definir_indice(
			posmod(inventario.indice_inventario + 1, 3)
		)

	if evento.is_action_pressed("changePrev"):
		inventario.definir_indice(
			posmod(inventario.indice_inventario - 1, 3)
		)

	if evento.is_action_pressed("next"):
		inventario.girar_trilho(1)

	if evento.is_action_pressed("prev"):
		inventario.girar_trilho(-1)

	if evento.is_action_pressed("1"):
		selecionar_item(0)

	if evento.is_action_pressed("2"):
		selecionar_item(1)

	if evento.is_action_pressed("3"):
		selecionar_item(2)


func selecionar_item(indice: int) -> bool:
	return inventario.selecionar_item(indice)


func definir_item(indice: int, nome_item: String) -> bool:
	return inventario.definir_item(indice, nome_item)


func obter_sentido(indice: int) -> Direcao.Sentido:
	return inventario.obter_sentido(indice)


func obter_eixo(indice: int) -> Direcao.Eixo:
	return inventario.obter_eixo(indice)


func _notificar_mudanca() -> void:
	inventario_alterado.emit()
	print(
		inventario.item_atual(),
		" ",
		Direcao.nome(inventario.sentido_trilho)
	)
