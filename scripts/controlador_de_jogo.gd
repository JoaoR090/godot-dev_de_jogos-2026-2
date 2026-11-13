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
# Imprime no console as saídas escolhidas a cada passo.
@export var depurar: bool = false

var estado: Estado = Estado.AGUARDANDO

# Aguarda o tempo inicial configurado e inicia o movimento automático.
func _ready() -> void:
	if not is_instance_valid(trem) or not is_instance_valid(trem.trilhos):
		push_error("O controlador precisa de um trem conectado aos trilhos.")
		encerrar_jogo()
		return

	if tempo_inicial > 0.0:
		await get_tree().create_timer(tempo_inicial).timeout

	# Durante a espera o jogo pode ter sido encerrado ou o trem removido.
	if estado == Estado.ENCERRADO or not is_instance_valid(trem):
		return

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

	var saidas: Array[Direcao.Sentido] = _saidas_disponiveis(trem.posicao_trem, trem.direcao_trem)
	# O trem não dá ré: se só sobrou o caminho de volta, não há para onde ir.
	saidas.erase(Direcao.sentido_oposto(trem.direcao_trem))

	if saidas.is_empty():
		print("Game Over")
		encerrar_jogo()
		return

	if depurar:
		print("Saída escolhida: ", Direcao.nome(saidas[0]))
	trem.movimento(saidas[0])

# Lista os sentidos conectados a partir da posição, começando pelo sentido atual
# (assim a continuidade do movimento tem prioridade).
func _saidas_disponiveis(posicao: Vector3i, sentido_inicial: Direcao.Sentido) -> Array[Direcao.Sentido]:
	var saidas: Array[Direcao.Sentido] = []
	for passo in range(4):
		var sentido: Direcao.Sentido = Direcao.avancar_sentido(sentido_inicial, passo)
		if trem.trilhos.tem_conexao(posicao, sentido):
			saidas.append(sentido)
	return saidas
