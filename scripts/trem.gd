class_name Trem
extends Node3D

const SFX_TREM_LOOP: AudioStream = preload("res://assets/sfx/train_rail_loop.mp3")
const SFX_CRASH: AudioStream = preload("res://assets/sfx/crash.wav")
const LOOP_REINICIO_MS: int = 5000

@export var trilhos: Trilhos
@export var direcao_inicial: Direcao.Sentido = Direcao.Sentido.CIMA
# Velocidade em unidades de mundo por segundo.
@export var velocity: float = 1.0

var _audio_loop: AudioStreamPlayer3D
var _audio_batida: AudioStreamPlayer3D
var _loop_inicio_ms: int = -1

var posicao_trem: Vector3i
var direcao_trem: Direcao.Sentido
var _movendo: bool = false

# Inicializa a posição e a orientação do trem na grade de trilhos.
func _ready() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var bus_sfx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_sfx, "SFX")
		AudioServer.set_bus_send(bus_sfx, "Master")
	_audio_loop = AudioStreamPlayer3D.new()
	var stream_loop: AudioStream = SFX_TREM_LOOP
	if stream_loop is AudioStreamMP3:
		var mp3 := stream_loop as AudioStreamMP3
		mp3.loop = true
		mp3.loop_offset = 0.0
	_audio_loop.stream = stream_loop
	_audio_loop.bus = "SFX"
	_audio_loop.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_audio_loop.unit_size = 6.0
	_audio_loop.max_distance = 64.0
	add_child(_audio_loop)

	_audio_batida = AudioStreamPlayer3D.new()
	_audio_batida.stream = SFX_CRASH
	_audio_batida.bus = "SFX"
	_audio_batida.volume_db = 0.0
	_audio_batida.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_audio_batida.unit_size = 6.0
	_audio_batida.max_distance = 64.0
	add_child(_audio_batida)

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

	# Garante um trilho reto sob o trem (substitui qualquer peça que já esteja ali).
	trilhos.colocar_reto(posicao_trem, Direcao.eixo_do_sentido(direcao_trem))

# Move o trem uma célula na direção informada se os trilhos estiverem conectados.
func movimento(sentido: Direcao.Sentido) -> void:
	if _movendo or not is_instance_valid(trilhos) or velocity <= 0.0:
		return
	if sentido == Direcao.Sentido.INVALIDO or direcao_trem == Direcao.Sentido.INVALIDO:
		return

	# O trem não dá ré e só muda de direção sobre uma curva.
	if sentido == Direcao.sentido_oposto(direcao_trem):
		return
	var esta_em_curva: bool = trilhos.get_cell_item(posicao_trem) == Trilhos.ID_CURVO
	if sentido != direcao_trem and not esta_em_curva:
		return

	# tem_conexao já confere as duas pontas (célula atual e vizinha).
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
	_movendo = false

# Inicia o loop de trilhos se ainda não estiver tocando e se já se passaram
# pelo menos LOOP_REINICIO_MS desde o último início (evita reiniciar a cada célula).
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


# Toca o som de batida no local do trem (one-shot) e encerra o loop de trilhos.
func tocar_batida() -> void:
	if is_instance_valid(_audio_loop):
		_audio_loop.stop()
	_loop_inicio_ms = -1
	if is_instance_valid(_audio_batida):
		_audio_batida.play()


# Informa ao controlador se uma animação de movimento ainda está em andamento.
func esta_movendo() -> bool:
	return _movendo
