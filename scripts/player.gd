
class_name Player
extends Node3D

# Emitido quando o item selecionado, a orientação do trilho ou o conteúdo do
# inventário muda. O HUD usa este sinal para se atualizar na hora.
signal inventario_alterado

const SPEED = 20.0
@export var grid_trilhos: Trilhos
var eixo_trilho: Direcao.Eixo = Direcao.Eixo.Z
var sentido_trilho: Direcao.Sentido = Direcao.Sentido.CIMA
var indice_inventario: int = 0
const max_itens: int = 3
var inventario_jogador: Dictionary = {
	0: "Mão",
	1: "Trilho_Reto",
	2: "Trilho_Curvo",
}
var mudou_inventario: bool = true

# Orientação guardada por slot. O slot selecionado usa eixo_trilho/sentido_trilho;
# os demais mantêm sua própria rotação até serem selecionados.
var _orientacoes_slots: Dictionary = {}

# Prévia azul e transparente do trilho selecionado, exibida antes de colocar.
var _preview: MeshInstance3D
var _material_preview: StandardMaterial3D


func _ready() -> void:
	_criar_preview()


# Atalhos numéricos: 1 = mão, 2 = reto, 3 = lado.
func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey):
		return

	var tecla := evento as InputEventKey
	if not tecla.pressed or tecla.echo:
		return

	var codigo: Key = tecla.keycode
	if codigo == KEY_NONE:
		codigo = tecla.physical_keycode

	match codigo:
		KEY_1, KEY_KP_1:
			selecionar_item(0)
		KEY_2, KEY_KP_2:
			selecionar_item(1)
		KEY_3, KEY_KP_3:
			selecionar_item(2)


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	var posicao: Vector3i = grid_trilhos.local_to_map(grid_trilhos.to_local(global_position))
	colocar_trilho(posicao)
	trocar_lado_trilho()
	mudar_indice()
	_atualizar_preview(posicao)
	print_inventario()

func print_inventario():
	if mudou_inventario:
		mudou_inventario = false
		print(indice_inventario, " ", eixo_trilho, " ", sentido_trilho)


func _handle_movement(delta: float) -> void:
	var direction := Vector3.ZERO

	if Input.is_action_pressed("up"):
		direction.z -= 1

	if Input.is_action_pressed("down"):
		direction.z += 1

	if Input.is_action_pressed("left"):
		direction.x -= 1

	if Input.is_action_pressed("right"):
		direction.x += 1

	direction = direction.normalized()
	global_position += direction * SPEED * delta

func remover_trilho(posicao: Vector3i)-> void:
	grid_trilhos.remover_trilho(posicao)

func mudar_indice() -> void:
	if Input.is_action_just_pressed("changeNext"):
		_definir_indice((indice_inventario + 1) % max_itens)
	elif Input.is_action_just_pressed("changePrev"):
		_definir_indice((indice_inventario - 1 + max_itens) % max_itens)


# Troca o slot ativo guardando/restaurando a orientação de cada seleção.
func _definir_indice(novo_indice: int) -> void:
	if novo_indice == indice_inventario:
		return

	_orientacoes_slots[indice_inventario] = {
		"eixo": eixo_trilho,
		"sentido": sentido_trilho,
	}
	indice_inventario = novo_indice

	var orientacao: Dictionary = _orientacoes_slots.get(indice_inventario, {})
	eixo_trilho = orientacao.get("eixo", Direcao.Eixo.Z)
	sentido_trilho = orientacao.get("sentido", Direcao.Sentido.CIMA)

	mudou_inventario = true
	inventario_alterado.emit()


# Orientação de um slot específico, usada pelo HUD para girar só o ícone certo.
func obter_eixo(indice: int) -> Direcao.Eixo:
	if indice == indice_inventario:
		return eixo_trilho
	var orientacao: Dictionary = _orientacoes_slots.get(indice, {})
	return orientacao.get("eixo", Direcao.Eixo.Z)


func obter_sentido(indice: int) -> Direcao.Sentido:
	if indice == indice_inventario:
		return sentido_trilho
	var orientacao: Dictionary = _orientacoes_slots.get(indice, {})
	return orientacao.get("sentido", Direcao.Sentido.CIMA)


# Altera o item de um slot e avisa o HUD.
func definir_item(indice: int, nomeItem: String) -> bool:
	if not inventario_jogador.has(indice):
		push_error("Índice de inventário inválido: %d" % indice)
		return false

	inventario_jogador[indice] = nomeItem
	mudou_inventario = true
	inventario_alterado.emit()
	return true


# Seleciona um slot pelo clique no HUD.
func selecionar_item(indice: int) -> bool:
	if not inventario_jogador.has(indice):
		push_error("Índice de inventário inválido: %d" % indice)
		return false
	if indice == indice_inventario:
		return false

	_definir_indice(indice)
	return true

func colocar_trilho(posicao: Vector3i)-> void:
	if Input.is_action_just_pressed("place"):
		# Cliques sobre o HUD selecionam itens em vez de colocar trilhos.
		if get_viewport().gui_get_hovered_control() != null:
			return

		print("tentando colocar trilho")
		if inventario_jogador[indice_inventario] == "Trilho_Reto":
			print("trilho colocado")
			grid_trilhos.configurar_trilho(posicao, eixo_trilho, Trilhos.TipoTrilho.RETO, sentido_trilho)
		if inventario_jogador[indice_inventario] == "Trilho_Curvo":
			print("trilho colocado")
			grid_trilhos.configurar_trilho(posicao, eixo_trilho, Trilhos.TipoTrilho.CURVA, sentido_trilho)

# Cria a malha-fantasma usada para pré-visualizar o trilho selecionado.
func _criar_preview() -> void:
	_preview = MeshInstance3D.new()
	_preview.name = "PreviewTrilho"
	_preview.visible = false
	_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_material_preview = StandardMaterial3D.new()
	_material_preview.albedo_color = Color(0.35, 0.7, 1.0, 0.45)
	_material_preview.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_preview.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_preview.cull_mode = BaseMaterial3D.CULL_DISABLED
	_preview.material_override = _material_preview

	add_child(_preview)


# Posiciona e orienta a prévia azul na grid onde o trilho seria colocado.
func _atualizar_preview(posicao: Vector3i) -> void:
	if not is_instance_valid(_preview) or not is_instance_valid(grid_trilhos):
		return
	if grid_trilhos.mesh_library == null:
		return

	var item: String = str(inventario_jogador.get(indice_inventario, ""))
	var id_peca: int = -1
	var rotacao: float = 0.0

	match item:
		"Trilho_Reto":
			id_peca = grid_trilhos.ID_RETO
			rotacao = Direcao.angulo_do_eixo(eixo_trilho)
		"Trilho_Curvo":
			id_peca = grid_trilhos.ID_CURVO
			rotacao = Direcao.angulo_do_sentido(sentido_trilho)

	if id_peca < 0 or rotacao < 0.0:
		_preview.visible = false
		return

	var malha: Mesh = grid_trilhos.mesh_library.get_item_mesh(id_peca)
	if malha == null:
		_preview.visible = false
		return

	_preview.mesh = malha
	_preview.global_transform = grid_trilhos.global_transform * Transform3D(
		Basis(Vector3.UP, deg_to_rad(rotacao)),
		grid_trilhos.map_to_local(posicao)
	)
	_preview.visible = true


func trocar_lado_trilho()->void:
	var item: String = str(inventario_jogador.get(indice_inventario, ""))
	if not item.begins_with("Trilho"):
		return

	var alterou: bool = false

	if Input.is_action_just_pressed("next"):
		sentido_trilho = Direcao.proximo_sentido(sentido_trilho)
		eixo_trilho = Direcao.proximo_eixo(eixo_trilho)
		alterou = true
	if Input.is_action_just_pressed("prev"):
		sentido_trilho = Direcao.avancar_sentido(sentido_trilho, 3)
		eixo_trilho = Direcao.proximo_eixo(eixo_trilho)
		alterou = true

	if alterou:
		_orientacoes_slots[indice_inventario] = {
			"eixo": eixo_trilho,
			"sentido": sentido_trilho,
		}
		mudou_inventario = true
		inventario_alterado.emit()
