class_name HudInventario
extends CanvasLayer

## HUD retrô do inventário no canto superior esquerdo.
## Cada slot mostra o ícone do formato atual do trilho e pode ser clicado
## para selecionar o item.

const CAMINHO_ICONES: String = "res://assets/hud/trilhos/"

const COR_BORDA_SLOT: Color = Color("#514467")
const COR_BORDA_SLOT_ATIVO: Color = Color("#ffe0a3")
const COR_TEXTO_ATIVO: Color = Color("#1a1320")
const COR_DESTAQUE: Color = Color("#ffb347")

const COR_FUNDO_SLOT_TOPO: Color = Color(0.16, 0.13, 0.2, 0.35)
const COR_FUNDO_SLOT_BASE: Color = Color(0.04, 0.03, 0.07, 0.55)
const COR_FUNDO_SLOT_HOVER_TOPO: Color = Color(0.3, 0.24, 0.38, 0.5)
const COR_FUNDO_SLOT_HOVER_BASE: Color = Color(0.1, 0.08, 0.15, 0.7)
const COR_FUNDO_SLOT_ATIVO_TOPO: Color = Color(1.0, 0.82, 0.5, 0.92)
const COR_FUNDO_SLOT_ATIVO_BASE: Color = Color(0.92, 0.58, 0.17, 0.92)

const MARGEM_TELA: Vector2 = Vector2(12.0, 12.0)
const LARGURA_SLOT: float = 52.0
const ALTURA_SLOT: float = 50.0
const TAMANHO_ICONE: float = 40.0
const QUANTIDADE_SLOTS_PADRAO: int = 3
const INTERVALO_BUSCA_JOGADOR: float = 0.5

# Jogador cujo inventário será exibido. Se ficar vazio, o HUD procura o nó
# "Player" na cena atual automaticamente.
@export var jogador: Player

var _painel: VBoxContainer
var _lista_slots: HBoxContainer
var _slots: Array[PanelContainer] = []
var _icones_slots: Array[TextureRect] = []
var _fundos_slots: Array[TextureRect] = []
var _texturas: Dictionary = {}
var _indice_sob_mouse: int = -1
var _tempo_busca: float = 0.0

var _fundo_slot_normal: GradientTexture2D
var _fundo_slot_hover: GradientTexture2D
var _fundo_slot_ativo: GradientTexture2D


func _ready() -> void:
	layer = 10
	_localizar_jogador()
	_construir_interface()

	if is_instance_valid(jogador):
		_vincular_jogador()
	else:
		_mostrar_sem_jogador()


func _process(delta: float) -> void:
	if is_instance_valid(jogador):
		return

	_tempo_busca += delta
	if _tempo_busca < INTERVALO_BUSCA_JOGADOR:
		return

	_tempo_busca = 0.0
	_localizar_jogador()

	if is_instance_valid(jogador):
		_vincular_jogador()
	else:
		_mostrar_sem_jogador()


# Conecta o HUD ao sinal do jogador e faz a primeira leitura do inventário.
func _vincular_jogador() -> void:
	if not jogador.inventario.inventario_alterado.is_connected(_atualizar_inventario):
		jogador.inventario.inventario_alterado.connect(_atualizar_inventario)

	_atualizar_inventario()


# Procura o jogador na cena atual quando nenhum foi atribuído no Inspector.
func _localizar_jogador() -> void:
	if is_instance_valid(jogador):
		return

	var raiz: Node = get_tree().current_scene
	if not is_instance_valid(raiz):
		return

	jogador = raiz.find_child("Player", true, false) as Player


# Monta os slots soltos no canto superior esquerdo, sem fundo atrás do HUD.
func _construir_interface() -> void:
	_painel = VBoxContainer.new()
	_painel.name = "Inventario"
	_painel.position = MARGEM_TELA
	_painel.theme = _criar_tema_retro()
	_painel.add_theme_constant_override("separation", 4)
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painel)

	_fundo_slot_normal = _criar_textura_degrade(COR_FUNDO_SLOT_TOPO, COR_FUNDO_SLOT_BASE)
	_fundo_slot_hover = _criar_textura_degrade(COR_FUNDO_SLOT_HOVER_TOPO, COR_FUNDO_SLOT_HOVER_BASE)
	_fundo_slot_ativo = _criar_textura_degrade(COR_FUNDO_SLOT_ATIVO_TOPO, COR_FUNDO_SLOT_ATIVO_BASE)

	_lista_slots = HBoxContainer.new()
	_lista_slots.name = "Slots"
	_lista_slots.alignment = BoxContainer.ALIGNMENT_BEGIN
	_lista_slots.add_theme_constant_override("separation", 4)
	_lista_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(_lista_slots)

	_criar_slots(_quantidade_de_slots())
	_painel.reset_size()


# Degradê translúcido exibido atrás do PNG de cada slot.
func _criar_textura_degrade(cor_topo: Color, cor_base: Color) -> GradientTexture2D:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 1.0])
	gradiente.colors = PackedColorArray([cor_topo, cor_base])

	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2(0.0, 0.0)
	textura.fill_to = Vector2(0.0, 1.0)
	textura.width = 16
	textura.height = 64
	return textura


func _criar_fundo_slot(textura: GradientTexture2D) -> TextureRect:
	var fundo := TextureRect.new()
	fundo.name = "Fundo"
	fundo.texture = textura
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fundo


# Recria os quadros clicáveis do inventário.
func _criar_slots(quantidade: int) -> void:
	for filho in _lista_slots.get_children():
		_lista_slots.remove_child(filho)
		filho.queue_free()

	_slots.clear()
	_icones_slots.clear()
	_fundos_slots.clear()
	_indice_sob_mouse = -1

	for indice in range(quantidade):
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % indice
		slot.custom_minimum_size = Vector2(LARGURA_SLOT, ALTURA_SLOT)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.gui_input.connect(_ao_clicar_slot.bind(indice))
		slot.mouse_entered.connect(_ao_entrar_slot.bind(indice))
		slot.mouse_exited.connect(_ao_sair_slot.bind(indice))
		_lista_slots.add_child(slot)

		# Fica atrás do PNG, dentro da moldura do slot.
		var fundo := _criar_fundo_slot(_fundo_slot_normal)
		slot.add_child(fundo)

		var centro := CenterContainer.new()
		centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(centro)

		var icone := TextureRect.new()
		icone.custom_minimum_size = Vector2(TAMANHO_ICONE, TAMANHO_ICONE)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icone.pivot_offset = Vector2(TAMANHO_ICONE, TAMANHO_ICONE) * 0.5
		icone.resized.connect(_centralizar_pivo.bind(icone))
		centro.add_child(icone)

		_slots.append(slot)
		_icones_slots.append(icone)
		_fundos_slots.append(fundo)


# Lê o estado atual do jogador e atualiza ícones e destaques.
func _atualizar_inventario() -> void:
	if not is_instance_valid(jogador):
		_mostrar_sem_jogador()
		return

	var quantidade: int = jogador.inventario.inventario_jogador.size()
	if quantidade != _slots.size():
		_criar_slots(quantidade)

	for indice in range(quantidade):
		var item: String = str(jogador.inventario.inventario_jogador.get(indice, ""))
		_slots[indice].tooltip_text = "Selecionar %s" % _nome_item(item)
		_icones_slots[indice].texture = _textura_do_item(item)
		_icones_slots[indice].rotation_degrees = _rotacao_icone(
			item, jogador.obter_eixo(indice), jogador.obter_sentido(indice)
		)

	_atualizar_aparencia_slots()


# Aplica o visual retrô de cada slot conforme seleção e hover.
func _atualizar_aparencia_slots() -> void:
	var indice_ativo: int = -1
	if is_instance_valid(jogador):
		indice_ativo = jogador.inventario.indice_inventario

	for indice in range(_slots.size()):
		var ativo: bool = indice == indice_ativo
		var hover: bool = indice == _indice_sob_mouse and not ativo

		var textura_fundo: GradientTexture2D = _fundo_slot_normal
		if ativo:
			textura_fundo = _fundo_slot_ativo
		elif hover:
			textura_fundo = _fundo_slot_hover

		var cor_borda: Color = COR_BORDA_SLOT_ATIVO if ativo else (
			COR_DESTAQUE if hover else COR_BORDA_SLOT
		)

		# O fundo do slot é só o degradê translúcido; a moldura desenha a borda.
		_fundos_slots[indice].texture = textura_fundo
		_slots[indice].add_theme_stylebox_override(
			"panel", _criar_estilo(Color(0, 0, 0, 0), cor_borda, 2 if ativo else 1, 3.0)
		)
		_icones_slots[indice].modulate = Color.WHITE if ativo else Color(1, 1, 1, 0.8)


func _mostrar_sem_jogador() -> void:
	if not is_instance_valid(_lista_slots):
		return

	for indice in range(_icones_slots.size()):
		_icones_slots[indice].texture = null

	_atualizar_aparencia_slots()


func _ao_clicar_slot(evento: InputEvent, indice: int) -> void:
	if not (evento is InputEventMouseButton):
		return

	var clique := evento as InputEventMouseButton
	if not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return

	if is_instance_valid(jogador):
		jogador.selecionar_item(indice)
	get_viewport().set_input_as_handled()


func _ao_entrar_slot(indice: int) -> void:
	_indice_sob_mouse = indice
	_atualizar_aparencia_slots()


func _ao_sair_slot(indice: int) -> void:
	if _indice_sob_mouse == indice:
		_indice_sob_mouse = -1
	_atualizar_aparencia_slots()


func _quantidade_de_slots() -> int:
	if is_instance_valid(jogador) and not jogador.inventario.inventario_jogador.is_empty():
		return jogador.inventario.inventario_jogador.size()
	return QUANTIDADE_SLOTS_PADRAO


# Seleciona o único PNG de cada formato. A rotação é aplicada em tempo real.
func _textura_do_item(item: String) -> Texture2D:
	var caminho: String = _caminho_icone(item)
	if caminho.is_empty():
		return null

	if not _texturas.has(caminho):
		_texturas[caminho] = load(caminho) as Texture2D

	return _texturas[caminho]


func _caminho_icone(item: String) -> String:
	match item:
		"Mão":
			return CAMINHO_ICONES + "Mao.png"
		"Trilho_Reto":
			return CAMINHO_ICONES + "Trilho_reto.png"
		"Trilho_Curvo":
			return CAMINHO_ICONES + "Trilho_curvo.png"
	return ""


# Gira o ícone único conforme o eixo (reto) ou o sentido (curvo).
func _rotacao_icone(item: String, eixo: Direcao.Eixo, sentido: Direcao.Sentido) -> float:
	match item:
		"Trilho_Reto":
			if eixo == Direcao.Eixo.X:
				return 90.0
			return 0.0
		"Trilho_Curvo":
			# Ajuste visual apenas no HUD: inverte DIREITA/ESQUERDA sem afetar
			# a orientação/lógica do trilho no mapa ou na prévia.
			match sentido:
				Direcao.Sentido.CIMA:
					return 0.0
				Direcao.Sentido.DIREITA:
					return 90.0
				Direcao.Sentido.BAIXO:
					return 180.0
				Direcao.Sentido.ESQUERDA:
					return 270.0
	return 0.0


# Mantém o ícone girando em torno do próprio centro.
func _centralizar_pivo(controle: Control) -> void:
	controle.pivot_offset = controle.size * 0.5


func _nome_item(item: String) -> String:
	return item.replace("_", " ")


func _criar_tema_retro() -> Theme:
	var fonte := SystemFont.new()
	fonte.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	fonte.font_weight = 700
	fonte.antialiasing = TextServer.FONT_ANTIALIASING_NONE

	var tema := Theme.new()
	tema.default_font = fonte
	tema.default_font_size = 11
	return tema


# Estilo plano, com cantos retos, borda grossa e sombra deslocada.
func _criar_estilo(
	cor_fundo: Color,
	cor_borda: Color,
	largura_borda: int,
	margem: float = 4.0
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.anti_aliasing = false
	estilo.bg_color = cor_fundo
	estilo.border_color = cor_borda
	estilo.set_border_width_all(largura_borda)
	estilo.set_corner_radius_all(0)
	estilo.content_margin_left = margem
	estilo.content_margin_right = margem
	estilo.content_margin_top = margem
	estilo.content_margin_bottom = margem

	return estilo
