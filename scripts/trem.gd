class_name Trem
extends Node3D

var velocity: float = 1.0
@export var trilhos: Trilhos
@export var direcao_inicial: Direcao.Sentido = Direcao.Sentido.CIMA
@export var intial_timeout: float
var posicao_trem: Vector3i
var direcao_trem: Direcao.Sentido
var _movimento_automatico_ativo: bool = false
var _movendo: bool = false

func _ready() -> void:
	if not is_instance_valid(trilhos):
		push_error("O trem precisa ter um nó Trilhos atribuído.")
		return

	posicao_trem = trilhos.local_to_map(trilhos.to_local(global_position))
	direcao_trem = direcao_inicial

	global_position = trilhos.to_global(trilhos.map_to_local(posicao_trem))

	var eixo_trilho_inicial: Direcao.Eixo = Direcao.eixo_do_sentido(direcao_trem)

	trilhos.configurar_trilho(posicao_trem, eixo_trilho_inicial, trilhos.TipoTrilho.RETO, Direcao.sentido_do_angulo(Direcao.angulo_do_eixo(eixo_trilho_inicial)))

	await get_tree().create_timer(intial_timeout).timeout
	_movimento_automatico_ativo = true

# Move o trem uma célula na direção informada se os trilhos estiverem conectados.
func movimento(sentido: Direcao.Sentido) -> void:
	if _movendo or not is_instance_valid(trilhos) or velocity <= 0.0:
		return

	var angulo_posterior: float = Direcao.angulo_do_sentido(sentido)
	var angulo_anterior: float = Direcao.angulo_do_sentido(direcao_trem)

	if angulo_posterior < 0.0 or angulo_anterior < 0.0:
		return

	var proxima_posicao: Vector3i = posicao_trem + Direcao.deslocamento(sentido)

	if not trilhos.tem_trilho(posicao_trem) or not trilhos.tem_trilho(proxima_posicao):
		return

	if not trilhos.tem_conexao(posicao_trem, sentido):
		return

	var sentido_oposto: Direcao.Sentido = Direcao.sentido_oposto(sentido)
	if not trilhos.tem_conexao(proxima_posicao, sentido_oposto):
		return

	var posicao_atual_mundo: Vector3 = trilhos.to_global(trilhos.map_to_local(posicao_trem))
	var proxima_posicao_mundo: Vector3 = trilhos.to_global(trilhos.map_to_local(proxima_posicao))

	var deslocamento_mundo: Vector3 = proxima_posicao_mundo - posicao_atual_mundo

	var destino: Vector3 = global_position + deslocamento_mundo

	var diferenca_angular: float = wrapf(deg_to_rad(angulo_posterior - angulo_anterior), -deg_to_rad(180.0), deg_to_rad(180.0))
	var duracao: float = deslocamento_mundo.length() / velocity

	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "global_position", destino, duracao)
	tween.tween_property(self, "rotation:y",rotation.y + diferenca_angular, duracao)

	_movendo = true
	posicao_trem = proxima_posicao
	direcao_trem = sentido
	await tween.finished
	_movendo = false

# Lista as saídas conectadas à célula atual.
func _proximo_trilho(posicao: Vector3i, sentido_desejado: Direcao.Sentido) -> Direcao.Sentido:
	var sentido: Direcao.Sentido = Direcao.avancar_sentido(sentido_desejado, 3)
	var sentido_oposto: Direcao.Sentido = Direcao.sentido_oposto(sentido_desejado)
	for i in range(4):
		if (_tem_trilho(sentido, posicao) and trilhos.tem_conexao(posicao, sentido) and sentido != sentido_oposto):
			return sentido
		sentido = Direcao.proximo_sentido(sentido)
	return sentido_oposto

# Verifica se há um trilho na célula vizinha no sentido indicado.
func _tem_trilho(sentido: Direcao.Sentido, posicao: Vector3i) -> bool:
	var posicao_vizinha: Vector3i = posicao + Direcao.deslocamento(sentido)
	return trilhos.tem_trilho(posicao_vizinha)

func _process(_delta: float) -> void:
	if not _movimento_automatico_ativo or _movendo:
		return

	var sentido_retorno: Direcao.Sentido = Direcao.sentido_oposto(direcao_trem)
	var sentido_proximo_trilho: Direcao.Sentido = _proximo_trilho(posicao_trem, direcao_trem)
	if sentido_proximo_trilho == sentido_retorno:
		return # Game Over // Necessário implementar

	movimento(sentido_proximo_trilho)
