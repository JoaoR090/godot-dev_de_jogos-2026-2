
class_name Player
extends Node3D

# Emitido quando o item selecionado, a orientação do trilho ou o conteúdo do
# inventário muda. O HUD usa este sinal para se atualizar na hora.
signal inventario_alterado

const SPEED = 20.0

# Movimento em grade: desloca uma célula por vez.
var _movendo_grade: bool = false
var _alvo_grade: Vector3 = Vector3.ZERO

# Alcance de colocação em células a partir do jogador (1 = área 3x3).
@export var raio_colocacao: int = 1
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
	colocar_trilho()
	trocar_lado_trilho()
	mudar_indice()
	_atualizar_preview()
	print_inventario()

func print_inventario():
	if mudou_inventario:
		mudou_inventario = false
		print(indice_inventario, " ", eixo_trilho, " ", sentido_trilho)


func _handle_movement(delta: float) -> void:
	if not is_instance_valid(grid_trilhos):
		return

	if _movendo_grade:
		global_position = global_position.move_toward(_alvo_grade, SPEED * delta)
		if global_position.distance_to(_alvo_grade) <= 0.001:
			global_position = _alvo_grade
			_movendo_grade = false
		return

	var direcao_grade := Vector3i.ZERO
	if Input.is_action_pressed("up"):
		direcao_grade.z -= 1
	if Input.is_action_pressed("down"):
		direcao_grade.z += 1
	if Input.is_action_pressed("left"):
		direcao_grade.x -= 1
	if Input.is_action_pressed("right"):
		direcao_grade.x += 1

	if direcao_grade == Vector3i.ZERO:
		return

	var celula_atual: Vector3i = _celula_jogador()
	var celula_alvo: Vector3i = celula_atual + direcao_grade
	_alvo_grade = grid_trilhos.to_global(grid_trilhos.map_to_local(celula_alvo))
	_alvo_grade.y = global_position.y
	_movendo_grade = true


func _celula_jogador() -> Vector3i:
	return grid_trilhos.local_to_map(grid_trilhos.to_local(global_position))


# Célula do grid sob o cursor, se estiver dentro do alcance ao redor do jogador.
func _celula_alvo_colocacao() -> Dictionary:
	if not is_instance_valid(grid_trilhos):
		return {"valida": false, "celula": Vector3i.ZERO}

	var centro: Vector3i = _celula_jogador()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {"valida": false, "celula": centro}

	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origem: Vector3 = camera.project_ray_origin(mouse)
	var direcao: Vector3 = camera.project_ray_normal(mouse)

	# Plano na altura da célula do jogador para projetar o cursor no grid.
	var centro_mundo: Vector3 = grid_trilhos.to_global(grid_trilhos.map_to_local(centro))
	var plano := Plane(Vector3.UP, centro_mundo.y)
	var ponto = plano.intersects_ray(origem, direcao)
	if ponto == null:
		return {"valida": true, "celula": centro}

	var alvo: Vector3i = grid_trilhos.local_to_map(grid_trilhos.to_local(ponto))
	# Mantém o alvo dentro do alcance, na célula mais próxima do cursor.
	var dx: int = clampi(alvo.x - centro.x, -raio_colocacao, raio_colocacao)
	var dz: int = clampi(alvo.z - centro.z, -raio_colocacao, raio_colocacao)
	alvo = centro + Vector3i(dx, 0, dz)
	return {"valida": true, "celula": alvo}

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

func colocar_trilho() -> void:
	if not Input.is_action_pressed("place"):
		return
	# Cliques sobre o HUD selecionam itens em vez de colocar trilhos.
	if get_viewport().gui_get_hovered_control() != null:
		return
	if not is_instance_valid(grid_trilhos):
		return

	var alvo: Dictionary = _celula_alvo_colocacao()
	if not alvo.get("valida", false):
		return
	var posicao: Vector3i = alvo.get("celula", _celula_jogador())

	var primeiro_clique: bool = Input.is_action_just_pressed("place")
	# Primeiro clique: repõe mesmo se já houver trilho na célula.
	# Para exigir célula vazia também no primeiro clique, descomente a checagem abaixo.
	# if grid_trilhos.tem_trilho(posicao):
	# 	return
	# Ao segurar, só coloca em células vazias.
	if not primeiro_clique and grid_trilhos.tem_trilho(posicao):
		return

	if inventario_jogador[indice_inventario] == "Trilho_Reto":
		grid_trilhos.configurar_trilho(posicao, eixo_trilho, Trilhos.TipoTrilho.RETO, sentido_trilho)
	elif inventario_jogador[indice_inventario] == "Trilho_Curvo":
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


# Posiciona e orienta a prévia azul na célula onde o trilho seria colocado.
func _atualizar_preview() -> void:
	if not is_instance_valid(_preview) or not is_instance_valid(grid_trilhos):
		_atualizar_preview_visibilidade(false)
		return
	if grid_trilhos.mesh_library == null:
		_atualizar_preview_visibilidade(false)
		return
	# Evita mostrar prévia quando o cursor está sobre o HUD.
	if get_viewport().gui_get_hovered_control() != null:
		_atualizar_preview_visibilidade(false)
		return

	var alvo: Dictionary = _celula_alvo_colocacao()
	if not alvo.get("valida", false):
		_atualizar_preview_visibilidade(false)
		return
	var posicao: Vector3i = alvo.get("celula", _celula_jogador())

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
		_atualizar_preview_visibilidade(false)
		return

	var malha: Mesh = grid_trilhos.mesh_library.get_item_mesh(id_peca)
	if malha == null:
		_atualizar_preview_visibilidade(false)
		return

	_preview.mesh = malha
	_preview.global_transform = grid_trilhos.global_transform * Transform3D(
		Basis(Vector3.UP, deg_to_rad(rotacao)),
		grid_trilhos.map_to_local(posicao)
	)
	_preview.visible = true


func _atualizar_preview_visibilidade(visivel: bool) -> void:
	if is_instance_valid(_preview):
		_preview.visible = visivel


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
