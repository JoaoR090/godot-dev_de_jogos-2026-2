class_name ControladorDeJogo
extends Node

enum Estado {
	AGUARDANDO,
	ATIVO,
	PAUSADO,
	ENCERRADO
}

const ALTURA_ROTULO_CONTAGEM: float = 2.6

# Trem que o controlador coordena.
@export var trem: Trem
# Espera antes do início automático, em segundos.
@export var tempo_inicial: float = 10.0
# Cria um circuito temporário para demonstrar o movimento do trem.
@export var criar_circuito_demo: bool = false
# Imprime no console as saídas escolhidas a cada passo.
@export var depurar: bool = false

var estado: Estado = Estado.AGUARDANDO
var _som_batida_tocado: bool = false
var _rotulo_contagem: Label3D
var _tempo_contagem: float = 0.0

# Aguarda o tempo inicial configurado e inicia o movimento automático.
func _ready() -> void:
	if not is_instance_valid(trem) or not is_instance_valid(trem.trilhos):
		push_error("O controlador precisa de um trem conectado aos trilhos.")
		encerrar_jogo()
		return

	_criar_rotulo_contagem()

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

	if is_instance_valid(_rotulo_contagem):
		_rotulo_contagem.queue_free()
		_rotulo_contagem = null


# Cria, acima do trem, um rótulo 3D com a contagem regressiva para o início.
func _criar_rotulo_contagem() -> void:
	if tempo_inicial <= 0.0:
		return

	_tempo_contagem = tempo_inicial
	_rotulo_contagem = Label3D.new()
	_rotulo_contagem.name = "RotuloContagem"
	_rotulo_contagem.text = str(ceili(_tempo_contagem))
	_rotulo_contagem.position = Vector3(0.0, ALTURA_ROTULO_CONTAGEM, 0.0)
	FonteContador.criar_billboard(_rotulo_contagem)
	trem.add_child(_rotulo_contagem)


# Decrementa a contagem enquanto o jogo está aguardando.
func _atualizar_contagem(delta: float) -> void:
	if not is_instance_valid(_rotulo_contagem):
		return

	_tempo_contagem = maxf(0.0, _tempo_contagem - delta)
	_rotulo_contagem.text = str(ceili(_tempo_contagem))

	if _tempo_contagem <= 0.0:
		_rotulo_contagem.queue_free()
		_rotulo_contagem = null

# Pausa o avanço automático do trem.
func pausar_jogo() -> void:
	if estado == Estado.ATIVO:
		estado = Estado.PAUSADO

# Encerra a simulação.
func encerrar_jogo() -> void:
	estado = Estado.ENCERRADO

# Escolhe o próximo trilho e coordena o movimento automático.
func _process(delta: float) -> void:
	if estado != Estado.ATIVO:
		_atualizar_contagem(delta)
		return

	if not is_instance_valid(trem) or trem.esta_movendo():
		return

	var saidas: Array[Direcao.Sentido] = _saidas_disponiveis(trem.posicao_trem, trem.direcao_trem)
	# O trem não dá ré: se só sobrou o caminho de volta, não há para onde ir.
	saidas.erase(Direcao.sentido_oposto(trem.direcao_trem))

	if saidas.is_empty():
		print("Game Over")
		if not _som_batida_tocado:
			_som_batida_tocado = true
			trem.tocar_batida()
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
