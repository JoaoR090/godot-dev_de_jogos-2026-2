class_name FonteContador
extends RefCounted

const COR_TEXTO: Color = Color("#ffb347")
const COR_SOMBRA: Color = Color(0.04, 0.03, 0.07, 0.55)

static func fonte() -> SystemFont:
	var nova := SystemFont.new()
	nova.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	nova.font_weight = 700
	nova.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	return nova


static func criar_billboard(rotulo: Label3D) -> void:
	rotulo.font = fonte()
	rotulo.font_size = 19
	rotulo.modulate = COR_TEXTO
	rotulo.outline_size = 2
	rotulo.outline_modulate = COR_SOMBRA
	rotulo.fixed_size = true
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rotulo.no_depth_test = true
