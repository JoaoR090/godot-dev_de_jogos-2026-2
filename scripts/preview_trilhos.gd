
extends Node3D

@export var jogador: Node3D

var grid_trilhos: Trilhos
var construcao: Node
var inventario: Node

var _preview: MeshInstance3D
var _material_preview: StandardMaterial3D


func _ready() -> void:
	_criar_preview()


func atualizar() -> void:
	var alvo: Dictionary = construcao.celula_alvo_interacao()

	var id_peca := -1
	var rotacao := 0.0

	match inventario.item_atual():
		"Trilho_Reto":
			id_peca = Trilhos.ID_RETO
			rotacao = Direcao.angulo_do_eixo(inventario.obter_eixo(inventario.indice_inventario))

		"Trilho_Curvo":
			id_peca = Trilhos.ID_CURVO
			rotacao = Direcao.angulo_do_sentido(inventario.sentido_trilho)

	if not alvo.get("valida", false) or id_peca < 0 or rotacao < 0.0:
		_preview.visible = false
		return

	if jogador.get_viewport().gui_get_hovered_control() != null or not inventario.tem_madeira():
		_preview.visible = false
		return

	if grid_trilhos.mesh_library == null:
		_preview.visible = false
		return

	var posicao: Vector3i = alvo.get("celula", Vector3i.ZERO)
	if grid_trilhos.celula_protegida(posicao):
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

	jogador.add_child.call_deferred(_preview)