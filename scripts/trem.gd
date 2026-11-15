class_name Trem
extends Node3D

const SFX_TREM_LOOP: AudioStream = preload("res://assets/sfx/train_rail_loop.mp3")
const SFX_CRASH: AudioStream = preload("res://assets/sfx/crash.wav")
const LOOP_REINICIO_MS: int = 5000
const TEMPO_PAUSA_ESTACAO: float = 3.0
const ALTURA_ROTULO_ESTACAO: float = 2.6

@export var trilhos: Trilhos
@export var direcao_inicial: Direcao.Sentido = Direcao.Sentido.CIMA
@export var velocity: float = 1.0

var _audio_loop: AudioStreamPlayer3D
var _audio_batida: AudioStreamPlayer3D
var _loop_inicio_ms: int = -1

var _estacoes_meio: Array[Vector3i] = []
var _rotulo_estacao: Label3D
var _tempo_estacao: float = 0.0

var posicao_trem: Vector3i
var direcao_trem: Direcao.Sentido
var _movendo: bool = false

func _ready() -> void:
	_audio_loop = AudioSfx.criar_player_3d(self, SFX_TREM_LOOP)
	if _audio_loop.stream is AudioStreamMP3:
		var mp3 := _audio_loop.stream as AudioStreamMP3
		mp3.loop = true
		mp3.loop_offset = 0.0
	_audio_batida = AudioSfx.criar_player_3d(self, SFX_CRASH)

	if not is_instance_valid(trilhos):
		print("O trem precisa ter um nó Trilhos atribuído.")
		return
	if direcao_inicial == Direcao.Sentido.INVALIDO:
		print("O trem precisa de uma direção inicial válida.")
		return

	posicao_trem = trilhos.local_to_map(trilhos.to_local(global_position))
	direcao_trem = direcao_inicial
	rotation.y = deg_to_rad(Direcao.angulo_do_sentido(direcao_trem))
	global_position = trilhos.to_global(trilhos.map_to_local(posicao_trem))
	_registrar_estacoes()

	trilhos.colocar_reto(posicao_trem, Direcao.eixo_do_sentido(direcao_trem))

func movimento(sentido: Direcao.Sentido) -> void:
	if _movendo or not is_instance_valid(trilhos) or velocity <= 0.0:
		return
	if sentido == Direcao.Sentido.INVALIDO or direcao_trem == Direcao.Sentido.INVALIDO:
		return

	if sentido == Direcao.sentido_oposto(direcao_trem):
		return
	var esta_em_curva: bool = trilhos.get_cell_item(posicao_trem) == Trilhos.ID_CURVO
	if sentido != direcao_trem and not esta_em_curva:
		return

	if not trilhos.tem_conexao(posicao_trem, sentido):
		return

	var proxima_posicao: Vector3i = posicao_trem + Direcao.deslocamento(sentido)
	var posicao_atual_mundo: Vector3 = trilhos.to_global(trilhos.map_to_local(posicao_trem))
	var proxima_posicao_mundo: Vector3 = trilhos.to_global(trilhos.map_to_local(proxima_posicao))
	var deslocamento_mundo: Vector3 = proxima_posicao_mundo - posicao_atual_mundo
	var destino: Vector3 = global_position + deslocamento_mundo

	var angulo_anterior: float = Direcao.angulo_do_sentido(direcao_trem)
	var angulo_posterior: float = Direcao.angulo_do_sentido(sentido)
	var diferenca_angular: float = wrapf(deg_to_rad(angulo_posterior - angulo_anterior), -PI, PI)
	var duracao: float = deslocamento_mundo.length() / velocity

	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "global_position", destino, duracao)
	tween.tween_property(self, "rotation:y", rotation.y + diferenca_angular, duracao)

	_movendo = true
	posicao_trem = proxima_posicao
	direcao_trem = sentido
	_garantir_loop_lancando()
	await tween.finished

	if _estacoes_meio.has(proxima_posicao):
		_iniciar_pausa_estacao()
		await get_tree().create_timer(TEMPO_PAUSA_ESTACAO).timeout
		_encerrar_pausa_estacao()

	_movendo = false

func _garantir_loop_lancando() -> void:
	if not is_instance_valid(_audio_loop):
		return
	if _audio_loop.playing:
		return
	var agora_ms := Time.get_ticks_msec()
	if _loop_inicio_ms >= 0 and agora_ms - _loop_inicio_ms < LOOP_REINICIO_MS:
		return
	_loop_inicio_ms = agora_ms
	_audio_loop.play()


func tocar_batida() -> void:
	if is_instance_valid(_audio_loop):
		_audio_loop.stop()
	_loop_inicio_ms = -1
	if is_instance_valid(_audio_batida):
		_audio_batida.play()


func esta_movendo() -> bool:
	return _movendo


func _process(delta: float) -> void:
	if not is_instance_valid(_rotulo_estacao):
		return

	_tempo_estacao = maxf(0.0, _tempo_estacao - delta)
	_rotulo_estacao.text = str(ceili(_tempo_estacao))

	if _tempo_estacao <= 0.0:
		_encerrar_pausa_estacao()


func _iniciar_pausa_estacao() -> void:
	if is_instance_valid(_audio_loop):
		_audio_loop.stop()

	_loop_inicio_ms = -1

	_tempo_estacao = TEMPO_PAUSA_ESTACAO
	_rotulo_estacao = Label3D.new()
	_rotulo_estacao.name = "RotuloEstacao"
	_rotulo_estacao.text = str(ceili(_tempo_estacao))
	_rotulo_estacao.position = Vector3(0.0, ALTURA_ROTULO_ESTACAO, 0.0)
	FonteContador.criar_billboard(_rotulo_estacao)
	add_child(_rotulo_estacao)


func _encerrar_pausa_estacao() -> void:
	if not is_instance_valid(_rotulo_estacao):
		return

	_rotulo_estacao.queue_free()
	_rotulo_estacao = null


func _registrar_estacoes() -> void:
	if not is_instance_valid(trilhos):
		return

	var estacao := get_parent().find_child(
		"Estacao",
		true,
		false
	) as Node3D

	if not is_instance_valid(estacao) and get_tree() != null:
		estacao = get_tree().current_scene.find_child(
			"Estacao",
			true,
			false
		) as Node3D

	if is_instance_valid(estacao):
		var malha := _encontrar_malha(estacao)

		if malha != null:
			var aabb_local: AABB = malha.mesh.get_aabb()
			var canto_a: Vector3 = malha.to_global(aabb_local.position)
			var canto_b: Vector3 = malha.to_global(
				aabb_local.position + aabb_local.size
			)
			_registrar_aabb_estacao(canto_a.min(canto_b), canto_a.max(canto_b))

	var raiz := get_parent()

	if not is_instance_valid(raiz):
		return

	for mapa in raiz.find_children("*", "GridMap", true, false):
		if mapa is GridMap:
			_registrar_estacoes_no_grid(mapa as GridMap)


func _registrar_estacoes_no_grid(mapa: GridMap) -> void:
	var biblioteca := mapa.mesh_library

	if biblioteca == null:
		return

	var ids_estacao := {}
	for item_id in biblioteca.get_item_list():
		if biblioteca.get_item_name(item_id) == "Estacao":
			ids_estacao[item_id] = true

	if ids_estacao.is_empty():
		return

	for celula in mapa.get_used_cells():
		var item: int = mapa.get_cell_item(celula)

		if not ids_estacao.has(item):
			continue

		var base: Basis = mapa.get_basis_with_orthogonal_index(
			mapa.get_cell_item_orientation(celula)
		)
		var item_transform: Transform3D = biblioteca.get_item_mesh_transform(item)
		var aabb_local: AABB = biblioteca.get_item_mesh(item).get_aabb()
		var origem: Transform3D = (
			Transform3D(base, mapa.map_to_local(celula)) * item_transform
		)

		var minimo := Vector3(INF, INF, INF)
		var maximo := Vector3(-INF, -INF, -INF)

		for canto in _cantos_aabb(aabb_local):
			var mundo := mapa.to_global(origem * canto)
			minimo = minimo.min(mundo)
			maximo = maximo.max(mundo)

		_registrar_aabb_estacao(minimo, maximo)


func _cantos_aabb(aabb: AABB) -> Array[Vector3]:
	var minimo := aabb.position
	var maximo := aabb.position + aabb.size
	var cantos: Array[Vector3] = []

	for x in [minimo.x, maximo.x]:
		for y in [minimo.y, maximo.y]:
			for z in [minimo.z, maximo.z]:
				cantos.append(Vector3(x, y, z))

	return cantos


func _registrar_aabb_estacao(minimo: Vector3, maximo: Vector3) -> void:
	var tamanho: Vector3 = maximo - minimo

	var eixo: Direcao.Eixo = (
		Direcao.Eixo.Z if tamanho.z >= tamanho.x else Direcao.Eixo.X
	)

	var y := posicao_trem.y

	if eixo == Direcao.Eixo.Z:
		var centro_x: float = (minimo.x + maximo.x) * 0.5
		var coluna: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(centro_x, 0.0, 0.0)
			)
		).x
		var x_min: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(minimo.x + 0.001, 0.0, 0.0)
			)
		).x
		var x_max: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(maximo.x - 0.001, 0.0, 0.0)
			)
		).x
		var z_min: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(0.0, 0.0, minimo.z + 0.001)
			)
		).z
		var z_max: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(0.0, 0.0, maximo.z - 0.001)
			)
		).z

		for x in range(x_min, x_max + 1):
			for z in range(z_min, z_max + 1):
				trilhos.proteger_celula(Vector3i(x, y, z))

		for z in range(z_min, z_max + 1):
			trilhos.colocar_reto(Vector3i(coluna, y, z), Direcao.Eixo.Z)

		_estacoes_meio.append(Vector3i(coluna, y, (z_min + z_max) / 2))
		return

	var centro_z: float = (minimo.z + maximo.z) * 0.5
	var linha: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(0.0, 0.0, centro_z)
		)
	).z
	var z_min: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(0.0, 0.0, minimo.z + 0.001)
		)
	).z
	var z_max: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(0.0, 0.0, maximo.z - 0.001)
		)
	).z
	var x_min: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(minimo.x + 0.001, 0.0, 0.0)
		)
	).x
	var x_max: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(maximo.x - 0.001, 0.0, 0.0)
		)
	).x

	for z in range(z_min, z_max + 1):
		for x in range(x_min, x_max + 1):
			trilhos.proteger_celula(Vector3i(x, y, z))

	for x in range(x_min, x_max + 1):
		trilhos.colocar_reto(Vector3i(x, y, linha), Direcao.Eixo.X)

	_estacoes_meio.append(Vector3i((x_min + x_max) / 2, y, linha))


func _encontrar_malha(raiz: Node) -> MeshInstance3D:
	for filho in raiz.find_children("*", "MeshInstance3D", true, false):
		if filho is MeshInstance3D:
			return filho as MeshInstance3D
	return null
