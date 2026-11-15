class_name ColetaMadeira
extends Node3D


const ID_ARVORE: int = 2
const MADEIRA_POR_ARVORE: int = 1
const TEMPO_QUEBRA: float = 0.5
const FRACAO_STUN: float = 0.4
const SFX_QUEBRA: AudioStream = preload("res://assets/sfx/break.wav")

var jogador: Node3D
var grid_arvores: GridMap
var construcao: Node
var inventario: Node

var _preview: MeshInstance3D
var _audio_quebra: AudioStreamPlayer3D

var _celula_alvo: Vector3i = Vector3i.ZERO
var _tem_alvo: bool = false

var _arvore_oculta: bool = false
var _celula_oculta: Vector3i = Vector3i.ZERO
var _orientacao_oculta: int = 0

var _tempo_stun: float = 0.0
var _quebras: Array[Dictionary] = []


func _ready() -> void:
	_preview = _criar_preview()
	_audio_quebra = AudioSfx.criar_player_3d(self, SFX_QUEBRA, -6.0)


func atualizar(delta: float) -> void:
	_atualizar_quebras(delta)

	if _tempo_stun > 0.0:
		_tempo_stun = maxf(0.0, _tempo_stun - delta)
		return

	var novo_alvo: bool = false

	if _pode_interagir():
		var celula: Vector3i = _celula_alvo_interacao()
		if _tem_arvore(celula):
			_celula_alvo = celula
			novo_alvo = true

	if not novo_alvo:
		_restaurar_arvore_oculta()
		_tem_alvo = false
		_atualizar_preview()
		return

	if not _arvore_oculta or _celula_oculta != _celula_alvo:
		_restaurar_arvore_oculta()
		_ocultar_arvore(_celula_alvo)

	_tem_alvo = true
	_atualizar_preview()


func quebrar_arvore() -> void:
	if esta_atordoado():
		return

	if not _tem_alvo or not _pode_interagir():
		return

	if not Input.is_action_pressed("place"):
		return

	var quebra: Dictionary = {
		"celula": _celula_alvo,
		"orientacao": _orientacao_oculta,
		"tempo": TEMPO_QUEBRA,
		"preview": _preview,
	}

	_quebras.append(quebra)
	_arvore_oculta = false
	_tem_alvo = false
	_tempo_stun = TEMPO_QUEBRA * FRACAO_STUN
	_preview = _criar_preview()


func esta_atordoado() -> bool:
	return _tempo_stun > 0.0


func _atualizar_quebras(delta: float) -> void:
	for i in range(_quebras.size() - 1, -1, -1):
		var quebra: Dictionary = _quebras[i]
		quebra["tempo"] = quebra["tempo"] - delta

		if quebra["tempo"] <= 0.0:
			_concluir_quebra(quebra)
			_quebras.remove_at(i)
			continue

		_quebras[i] = quebra
		_aplicar_transformacao_preview(quebra)


func _concluir_quebra(quebra: Dictionary) -> void:
	var preview_quebra: MeshInstance3D = quebra["preview"]

	if is_instance_valid(preview_quebra):
		preview_quebra.queue_free()

	var posicao_mundo: Vector3 = grid_arvores.to_global(
		grid_arvores.map_to_local(quebra["celula"])
	)

	inventario.adicionar_madeira(MADEIRA_POR_ARVORE)
	_tocar_quebra(posicao_mundo)


func _aplicar_transformacao_preview(quebra: Dictionary) -> void:
	var preview_quebra: MeshInstance3D = quebra["preview"]

	if not is_instance_valid(preview_quebra):
		return

	var malha: Mesh = grid_arvores.mesh_library.get_item_mesh(ID_ARVORE)

	if malha == null:
		return

	preview_quebra.mesh = malha

	var progresso: float = clampf(quebra["tempo"] / TEMPO_QUEBRA, 0.0, 1.0)
	var escala: float = progresso * progresso * (3.0 - 2.0 * progresso)

	preview_quebra.global_transform = _transformacao_preview(
		quebra["orientacao"],
		quebra["celula"],
		escala
	)
	preview_quebra.visible = true


func _celula_alvo_interacao() -> Vector3i:
	var alvo: Dictionary = construcao.celula_alvo_interacao()

	if not alvo.get("valida", false):
		return Vector3i.ZERO

	var celula_trilho: Vector3i = alvo.get("celula", Vector3i.ZERO)
	var celula_jogador: Vector3i = grid_arvores.local_to_map(
		grid_arvores.to_local(jogador.global_position)
	)

	return Vector3i(celula_trilho.x, celula_jogador.y, celula_trilho.z)


func _pode_interagir() -> bool:
	return (
		is_instance_valid(jogador)
		and is_instance_valid(grid_arvores)
		and is_instance_valid(construcao)
		and is_instance_valid(inventario)
		and grid_arvores.mesh_library != null
		and inventario.usando_mao()
		and jogador.get_viewport().gui_get_hovered_control() == null
	)


func _tem_arvore(celula: Vector3i) -> bool:
	if _arvore_oculta and celula == _celula_oculta:
		return true

	return grid_arvores.get_cell_item(celula) == ID_ARVORE


func _ocultar_arvore(celula: Vector3i) -> void:
	_celula_oculta = celula
	_orientacao_oculta = grid_arvores.get_cell_item_orientation(celula)
	_arvore_oculta = true
	grid_arvores.set_cell_item(celula, GridMap.INVALID_CELL_ITEM)


func _restaurar_arvore_oculta() -> void:
	if not _arvore_oculta:
		return

	if is_instance_valid(grid_arvores):
		grid_arvores.set_cell_item(
			_celula_oculta,
			ID_ARVORE,
			_orientacao_oculta
		)

	_arvore_oculta = false


func _criar_preview() -> MeshInstance3D:
	var preview_novo: MeshInstance3D = MeshInstance3D.new()
	preview_novo.name = "PreviewArvore"
	preview_novo.visible = false
	preview_novo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview_novo.material_override = _criar_material_preview()

	add_child(preview_novo)
	return preview_novo


func _criar_material_preview() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.15, 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _transformacao_preview(
	orientacao: int,
	celula: Vector3i,
	escala: float
) -> Transform3D:
	var base: Basis = grid_arvores.get_basis_with_orthogonal_index(
		orientacao
	).scaled(Vector3.ONE * escala)
	var transform_item: Transform3D = (
		grid_arvores.mesh_library.get_item_mesh_transform(ID_ARVORE)
	)

	return (
		grid_arvores.global_transform
		* Transform3D(base, grid_arvores.map_to_local(celula))
		* transform_item
	)


func _atualizar_preview() -> void:
	if not is_instance_valid(_preview):
		return

	if not _tem_alvo:
		_preview.visible = false
		return

	var malha: Mesh = grid_arvores.mesh_library.get_item_mesh(ID_ARVORE)

	if malha == null:
		_preview.visible = false
		return

	_preview.mesh = malha
	_preview.global_transform = _transformacao_preview(
		_orientacao_oculta,
		_celula_alvo,
		1.0
	)
	_preview.visible = true


func _tocar_quebra(posicao_mundo: Vector3) -> void:
	if not is_instance_valid(_audio_quebra):
		return

	_audio_quebra.global_position = posicao_mundo
	_audio_quebra.play()
