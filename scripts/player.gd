class_name Player
extends Node3D

# Emitido quando o item selecionado ou a orientação do trilho mudam (útil para HUD).
signal selecao_mudou(item: int, sentido: Direcao.Sentido)

# A ordem define o índice no inventário.
enum Item {
	MAO,
	TRILHO_RETO,
	TRILHO_CURVO,
}

const VELOCIDADE: float = 20.0

@export var grid_trilhos: Trilhos

var indice_inventario: int = Item.MAO
# O eixo do trilho reto é derivado do sentido (Direcao.eixo_do_sentido).
var sentido_trilho: Direcao.Sentido = Direcao.Sentido.CIMA

func _ready() -> void:
	if not is_instance_valid(grid_trilhos):
		print("O jogador precisa de um nó Trilhos atribuído em grid_trilhos.")
		set_process_unhandled_input(false)
		return
	_notificar_selecao()

func _physics_process(delta: float) -> void:
	_mover(delta)

# Ações discretas tratadas por evento, em vez de consultadas a cada frame.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("place"):
		_colocar_trilho()
	if event.is_action_pressed("changeNext"):
		_mudar_indice(1)
	if event.is_action_pressed("changePrev"):
		_mudar_indice(-1)
	if event.is_action_pressed("next"):
		_girar_trilho(1)
	if event.is_action_pressed("prev"):
		_girar_trilho(-1)

func _mover(delta: float) -> void:
	var entrada: Vector2 = Input.get_vector("left", "right", "up", "down")
	global_position += Vector3(entrada.x, 0.0, entrada.y) * VELOCIDADE * delta

func remover_trilho(posicao: Vector3i) -> void:
	grid_trilhos.remover_trilho(posicao)

func _mudar_indice(passo: int) -> void:
	indice_inventario = posmod(indice_inventario + passo, Item.size())
	_notificar_selecao()

func _girar_trilho(passos: int) -> void:
	sentido_trilho = Direcao.avancar_sentido(sentido_trilho, passos)
	_notificar_selecao()

func _colocar_trilho() -> void:
	var posicao: Vector3i = grid_trilhos.local_to_map(grid_trilhos.to_local(global_position))
	match indice_inventario:
		Item.TRILHO_RETO:
			grid_trilhos.colocar_reto(posicao, Direcao.eixo_do_sentido(sentido_trilho))
		Item.TRILHO_CURVO:
			grid_trilhos.colocar_curva(posicao, sentido_trilho)

func _notificar_selecao() -> void:
	selecao_mudou.emit(indice_inventario, sentido_trilho)
	print(Item.find_key(indice_inventario), " ", Direcao.nome(sentido_trilho))
