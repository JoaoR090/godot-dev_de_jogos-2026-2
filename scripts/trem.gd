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

var _tem_estacao: bool = false
var _estacao_meio: Vector3i = Vector3i.ZERO
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
	_registrar_estacao()

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

	if _tem_estacao and proxima_posicao == _estacao_meio:
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


func _registrar_estacao() -> void:
	if not is_instance_valid(trilhos):
		return

	var estacao := get_parent().find_child(
		"Estacao",
		true,
		false
	) as Node3D

	if not is_instance_valid(estacao):
		estacao = get_tree().current_scene.find_child(
			"Estacao",
			true,
			false
		) as Node3D
	if not is_instance_valid(estacao):
		return

	var malha := _encontrar_malha(estacao)
	if malha == null:
		return

	var aabb_local: AABB = malha.mesh.get_aabb()
	var canto_a: Vector3 = malha.to_global(aabb_local.position)
	var canto_b: Vector3 = malha.to_global(aabb_local.position + aabb_local.size)
	var canto_min_mundo: Vector3 = canto_a.min(canto_b)
	var canto_max_mundo: Vector3 = canto_a.max(canto_b)
	var tamanho: Vector3 = canto_max_mundo - canto_min_mundo

	var eixo: Direcao.Eixo = (
		Direcao.Eixo.Z if tamanho.z >= tamanho.x else Direcao.Eixo.X
	)

	var y := posicao_trem.y

	if eixo == Direcao.Eixo.Z:
		var centro_x: float = (canto_min_mundo.x + canto_max_mundo.x) * 0.5
		var coluna: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(centro_x, 0.0, 0.0)
			)
		).x
		var x_min: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(canto_min_mundo.x + 0.001, 0.0, 0.0)
			)
		).x
		var x_max: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(canto_max_mundo.x - 0.001, 0.0, 0.0)
			)
		).x
		var z_min: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(0.0, 0.0, canto_min_mundo.z + 0.001)
			)
		).z
		var z_max: int = trilhos.local_to_map(
			trilhos.to_local(
				Vector3(0.0, 0.0, canto_max_mundo.z - 0.001)
			)
		).z

		for x in range(x_min, x_max + 1):
			for z in range(z_min, z_max + 1):
				trilhos.proteger_celula(Vector3i(x, y, z))

		for z in range(z_min, z_max + 1):
			trilhos.colocar_reto(Vector3i(coluna, y, z), Direcao.Eixo.Z)

		_estacao_meio = Vector3i(coluna, y, (z_min + z_max) / 2)
		_tem_estacao = true
		return

	var centro_z: float = (canto_min_mundo.z + canto_max_mundo.z) * 0.5
	var linha: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(0.0, 0.0, centro_z)
		)
	).z
	var z_min: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(0.0, 0.0, canto_min_mundo.z + 0.001)
		)
	).z
	var z_max: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(0.0, 0.0, canto_max_mundo.z - 0.001)
		)
	).z
	var x_min: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(canto_min_mundo.x + 0.001, 0.0, 0.0)
		)
	).x
	var x_max: int = trilhos.local_to_map(
		trilhos.to_local(
			Vector3(canto_max_mundo.x - 0.001, 0.0, 0.0)
		)
	).x

	for z in range(z_min, z_max + 1):
		for x in range(x_min, x_max + 1):
			trilhos.proteger_celula(Vector3i(x, y, z))

	for x in range(x_min, x_max + 1):
		trilhos.colocar_reto(Vector3i(x, y, linha), Direcao.Eixo.X)

	_estacao_meio = Vector3i((x_min + x_max) / 2, y, linha)
	_tem_estacao = true


func _encontrar_malha(raiz: Node) -> MeshInstance3D:
	for filho in raiz.find_children("*", "MeshInstance3D", true, false):
		if filho is MeshInstance3D:
			return filho as MeshInstance3D
	return null
