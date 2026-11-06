class_name ControladorDeJogo
extends Node

enum Estado {
	AGUARDANDO,
	ATIVO,
	PAUSADO,
	ENCERRADO
}

# Trem que o controlador coordena.
@export var trem: Trem
# Espera antes do início automático, em segundos.
@export var tempo_inicial: float = 10.0

var estado: Estado = Estado.AGUARDANDO

# Aguarda o tempo inicial configurado e inicia o movimento automático.
func _ready() -> void:
	if not is_instance_valid(trem) or not is_instance_valid(trem.trilhos):
		push_error("O controlador precisa de um trem conectado aos trilhos.")
		encerrar_jogo()
		return

	if tempo_inicial > 0.0:
		await get_tree().create_timer(tempo_inicial).timeout

	iniciar_jogo()

# Inicia ou retoma a simulação do trem.
func iniciar_jogo() -> void:
	if estado != Estado.ENCERRADO:
		estado = Estado.ATIVO

# Pausa o avanço automático do trem.
func pausar_jogo() -> void:
	if estado == Estado.ATIVO:
		estado = Estado.PAUSADO

# Encerra a simulação.
func encerrar_jogo() -> void:
	estado = Estado.ENCERRADO

# Escolhe o próximo trilho e coordena o movimento automático.
func _process(_delta: float) -> void:
	if estado != Estado.ATIVO or not is_instance_valid(trem) or trem.esta_movendo():
		return

	var sentido_retorno: Direcao.Sentido = Direcao.sentido_oposto(trem.direcao_trem)
	var proximo_sentido: Direcao.Sentido = _proximo_trilho(
		trem.posicao_trem,
		trem.direcao_trem
	)

	if proximo_sentido == sentido_retorno:
		return

	trem.movimento(proximo_sentido)

# Retorna uma saída conectada, priorizando a continuidade do movimento atual.
func _proximo_trilho(
	posicao: Vector3i,
	sentido_desejado: Direcao.Sentido
) -> Direcao.Sentido:
	var sentido: Direcao.Sentido = Direcao.avancar_sentido(sentido_desejado, 3)
	var sentido_retorno: Direcao.Sentido = Direcao.sentido_oposto(sentido_desejado)

	for i in range(4):
		if (
			_tem_trilho(sentido, posicao)
			and trem.trilhos.tem_conexao(posicao, sentido)
			and sentido != sentido_retorno
		):
			return sentido
		sentido = Direcao.proximo_sentido(sentido)

	return sentido_retorno

# Verifica se há um trilho vizinho na direção informada.
func _tem_trilho(sentido: Direcao.Sentido, posicao: Vector3i) -> bool:
	var posicao_vizinha: Vector3i = posicao + Direcao.deslocamento(sentido)
	return trem.trilhos.tem_trilho(posicao_vizinha)
