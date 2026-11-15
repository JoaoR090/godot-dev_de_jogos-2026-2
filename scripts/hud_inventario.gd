class_name HudInventario
extends CanvasLayer

const CAMINHO_ICONES: String = "res://assets/hud/trilhos/"
const CAMINHO_MUSICA: String = "res://assets/music/planice-sem-trem.wav"
const FUNDO_SLOT_NORMAL: Texture2D = preload("res://assets/hud/fundo_slot_desequipado.png")
const FUNDO_SLOT_EQUIPADO: Texture2D = preload("res://assets/hud/fundo_slot_equipado.png")
const VOLUME_SFX_PADRAO: float = 0.5
const VOLUME_MUSICA_PADRAO: float = 0.1

const MODULATE_SLOT_HOVER: Color = Color(1.2, 1.15, 1.25)

const MARGEM_TELA: Vector2 = Vector2(12.0, 12.0)
const LARGURA_SLOT: float = 52.0
const ALTURA_SLOT: float = 50.0
const SEPARACAO_SLOTS: float = 4.0
const CENTRO_SLOTS_TRILHO: float = LARGURA_SLOT * 2.0 + SEPARACAO_SLOTS * 1.5
const LARGURA_ROTULO_MADEIRA: float = 48.0
const ALTURA_ROTULO_MADEIRA: float = 16.0
const TAMANHO_ICONE: float = 40.0
const QUANTIDADE_SLOTS_PADRAO: int = 3
const INTERVALO_BUSCA_JOGADOR: float = 0.5

@export var jogador: Player

var _painel: VBoxContainer
var _lista_slots: HBoxContainer
var _rotulo_madeira: Label
var _musica: AudioStreamPlayer
var _slider_volume: HSlider
var _slider_musica: HSlider
var _slots: Array[PanelContainer] = []
var _icones_slots: Array[TextureRect] = []
var _fundos_slots: Array[TextureRect] = []
var _texturas: Dictionary = {}
var _indice_sob_mouse: int = -1
var _tempo_busca: float = 0.0


func _ready() -> void:
	layer = 10
	_configurar_audio()
	_localizar_jogador()
	_construir_interface()
	_criar_controles_audio()
	_iniciar_musica()

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


func _exit_tree() -> void:
	if not is_instance_valid(_musica):
		return

	_musica.stop()
	_musica.stream = null


func _vincular_jogador() -> void:
	if not jogador.inventario.inventario_alterado.is_connected(_atualizar_inventario):
		jogador.inventario.inventario_alterado.connect(_atualizar_inventario)

	_atualizar_inventario()


func _localizar_jogador() -> void:
	if is_instance_valid(jogador):
		return

	var raiz: Node = get_tree().current_scene
	if not is_instance_valid(raiz):
		return

	jogador = raiz.find_child("Player", true, false) as Player


func _construir_interface() -> void:
	_painel = VBoxContainer.new()
	_painel.name = "Inventario"
	_painel.position = MARGEM_TELA
	_painel.theme = _criar_tema_retro()
	_painel.add_theme_constant_override("separation", 4)
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painel)

	_lista_slots = HBoxContainer.new()
	_lista_slots.name = "Slots"
	_lista_slots.alignment = BoxContainer.ALIGNMENT_BEGIN
	_lista_slots.add_theme_constant_override("separation", int(SEPARACAO_SLOTS))
	_lista_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(_lista_slots)

	_criar_slots(_quantidade_de_slots())
	_painel.reset_size()
	_criar_rotulo_madeira()


func _criar_rotulo_madeira() -> void:
	_rotulo_madeira = Label.new()
	_rotulo_madeira.name = "Madeira"
	_rotulo_madeira.text = "0x"
	_rotulo_madeira.size = Vector2(LARGURA_ROTULO_MADEIRA, ALTURA_ROTULO_MADEIRA)
	_rotulo_madeira.position = Vector2(
		MARGEM_TELA.x + CENTRO_SLOTS_TRILHO - LARGURA_ROTULO_MADEIRA * 0.5,
		MARGEM_TELA.y + ALTURA_SLOT + 2.0
	)
	_rotulo_madeira.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_madeira.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rotulo_madeira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo_madeira.theme = _painel.theme
	_rotulo_madeira.add_theme_font_size_override("font_size", 12)
	_rotulo_madeira.add_theme_color_override("font_color", FonteContador.COR_TEXTO)
	_rotulo_madeira.add_theme_color_override(
		"font_shadow_color",
		FonteContador.COR_SOMBRA
	)
	_rotulo_madeira.add_theme_constant_override("shadow_offset_x", 1)
	_rotulo_madeira.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_rotulo_madeira)


func _criar_fundo_slot(textura: Texture2D) -> TextureRect:
	var fundo := TextureRect.new()
	fundo.name = "Fundo"
	fundo.texture = textura
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fundo


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
		slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_lista_slots.add_child(slot)

		var fundo := _criar_fundo_slot(FUNDO_SLOT_NORMAL)
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
	_atualizar_madeira()


func _atualizar_madeira() -> void:
	if not is_instance_valid(_rotulo_madeira):
		return

	var quantidade: int = 0
	if is_instance_valid(jogador):
		quantidade = jogador.inventario.madeira

	_rotulo_madeira.text = "%dx" % quantidade


func _atualizar_aparencia_slots() -> void:
	var indice_ativo: int = -1
	if is_instance_valid(jogador):
		indice_ativo = jogador.inventario.indice_inventario

	for indice in range(_slots.size()):
		var ativo: bool = indice == indice_ativo
		var hover: bool = indice == _indice_sob_mouse and not ativo

		_fundos_slots[indice].texture = (
			FUNDO_SLOT_EQUIPADO if ativo else FUNDO_SLOT_NORMAL
		)
		_fundos_slots[indice].modulate = (
			MODULATE_SLOT_HOVER if hover else Color.WHITE
		)
		_icones_slots[indice].modulate = Color.WHITE if ativo else Color(1, 1, 1, 0.8)


func _mostrar_sem_jogador() -> void:
	if not is_instance_valid(_lista_slots):
		return

	for indice in range(_icones_slots.size()):
		_icones_slots[indice].texture = null

	_atualizar_aparencia_slots()
	_atualizar_madeira()


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


func _rotacao_icone(item: String, eixo: Direcao.Eixo, sentido: Direcao.Sentido) -> float:
	match item:
		"Trilho_Reto":
			if eixo == Direcao.Eixo.X:
				return 90.0
			return 0.0
		"Trilho_Curvo":
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


func _centralizar_pivo(controle: Control) -> void:
	controle.pivot_offset = controle.size * 0.5


func _nome_item(item: String) -> String:
	return item.replace("_", " ")


func _criar_tema_retro() -> Theme:
	var tema := Theme.new()
	tema.default_font = FonteContador.fonte()
	tema.default_font_size = 11
	return tema


func _configurar_audio() -> void:
	AudioServer.set_bus_mute(
		AudioSfx.garantir_bus(AudioSfx.BUS_SFX),
		false
	)
	AudioServer.set_bus_mute(
		AudioSfx.garantir_bus(AudioSfx.BUS_MUSICA),
		false
	)


func _iniciar_musica() -> void:
	var stream: AudioStream = load(CAMINHO_MUSICA)
	if stream == null:
		push_error("Não foi possível carregar %s" % CAMINHO_MUSICA)
		return

	_musica = AudioStreamPlayer.new()
	_musica.name = "Musica"
	_musica.stream = stream
	_musica.bus = AudioSfx.BUS_MUSICA
	_musica.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_musica)
	_musica.finished.connect(_ao_musica_terminar)
	_musica.play()


func _criar_controles_audio() -> void:
	var margem := MarginContainer.new()
	margem.name = "ControlesAudio"
	margem.anchor_left = 1.0
	margem.anchor_top = 1.0
	margem.anchor_right = 1.0
	margem.anchor_bottom = 1.0
	margem.offset_left = -180.0
	margem.offset_top = -56.0
	margem.offset_right = -12.0
	margem.offset_bottom = -12.0
	margem.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	margem.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margem.add_child(vbox)

	_slider_volume = _criar_slider_linha(
		vbox,
		"Volume",
		AudioSfx.BUS_SFX,
		VOLUME_SFX_PADRAO
	)
	_slider_musica = _criar_slider_linha(
		vbox,
		"Música",
		AudioSfx.BUS_MUSICA,
		VOLUME_MUSICA_PADRAO
	)


func _criar_slider_linha(
	pai: VBoxContainer,
	rotulo: String,
	bus: String,
	valor_inicial: float = 1.0
) -> HSlider:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 4)
	pai.add_child(linha)

	var texto := Label.new()
	texto.text = rotulo
	texto.custom_minimum_size.x = 46.0
	texto.theme = _painel.theme
	texto.add_theme_font_size_override("font_size", 10)
	texto.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	linha.add_child(texto)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = valor_inicial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(100.0, 12.0)
	slider.value_changed.connect(_ao_alterar_volume.bind(bus))
	linha.add_child(slider)

	_ao_alterar_volume(valor_inicial, bus)
	return slider


func _ao_alterar_volume(valor: float, bus: String) -> void:
	var indice := AudioSfx.garantir_bus(bus)

	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(valor, 0.0001)))
	AudioServer.set_bus_mute(indice, valor <= 0.001)


func _ao_musica_terminar() -> void:
	if is_instance_valid(_musica):
		_musica.play()
