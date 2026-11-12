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
# Cria um circuito temporário para demonstrar o movimento do trem.
@export var criar_circuito_demo: bool = false

var estado: Estado = Estado.AGUARDANDO

# Aguarda o tempo inicial configurado e inicia o movimento automático.
func _ready() -> void:
	if not is_instance_valid(trem) or not is_instance_valid(trem.trilhos):
		push_error("O controlador precisa de um trem conectado aos trilhos.")
		encerrar_jogo()
		return

	if tempo_inicial > 0.0:
		await get_tree().create_timer(tempo_inicial).timeout

	if criar_circuito_demo:
		Circuito.criar(trem.trilhos, trem.posicao_trem, trem.direcao_inicial)

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
	var proximos_sentidos: Array[Direcao.Sentido] = _proximo_trilho(trem.posicao_trem, trem.direcao_trem)

	if proximos_sentidos.size() <= 1:
		print("Game Over")
		return
	for sentido in proximos_sentidos:
		print(print_sentido(sentido))
	print(" ")
	
	if proximos_sentidos[0] == sentido_retorno:
		trem.movimento(proximos_sentidos[1])
	else:
		trem.movimento(proximos_sentidos[0])

func print_sentido(sentido: Direcao.Sentido)-> String:
	match sentido:
		Direcao.Sentido.CIMA:
			return "cima"
		Direcao.Sentido.DIREITA:
			return "direita"
		Direcao.Sentido.BAIXO:
			return "baixo"
		Direcao.Sentido.ESQUERDA:
			return "esquerda"
	return "erro"


# Retorna uma saída conectada, priorizando a continuidade do movimento atual.
func _proximo_trilho(posicao: Vector3i, sentido_desejado: Direcao.Sentido) -> Array[Direcao.Sentido]:
	var sentidos: Array[Direcao.Sentido] = []
	var sentido: Direcao.Sentido = sentido_desejado

	for _i in range(4):
		if (_tem_trilho(sentido, posicao) and trem.trilhos.tem_conexao(posicao, sentido)):
			sentidos.append(sentido)
		sentido = Direcao.proximo_sentido(sentido)

	return sentidos

# Verifica se há um trilho vizinho na direção informada.
func _tem_trilho(sentido: Direcao.Sentido, posicao: Vector3i) -> bool:
	var posicao_vizinha: Vector3i = posicao + Direcao.deslocamento(sentido)
	return trem.trilhos.tem_trilho(posicao_vizinha)
