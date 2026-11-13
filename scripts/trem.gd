class_name Trem
extends Node3D

@export var trilhos: Trilhos
@export var direcao_inicial: Direcao.Sentido = Direcao.Sentido.CIMA
# Velocidade em unidades de mundo por segundo.
@export var velocity: float = 1.0

var posicao_trem: Vector3i
var direcao_trem: Direcao.Sentido
var _movendo: bool = false

# Inicializa a posição e a orientação do trem na grade de trilhos.
func _ready() -> void:
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
	await tween.finished
	_movendo = false

# Informa ao controlador se uma animação de movimento ainda está em andamento.
func esta_movendo() -> bool:
	return _movendo
