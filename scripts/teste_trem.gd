extends Node3D

@onready var trilhos: Trilhos = $Trilhos
@onready var trem: Trem = $Trem
@onready var controlador: ControladorDeJogo = $ControladorDeJogo

# Testa os estados do controlador e o movimento do trem entre células conectadas.
func _ready() -> void:
	assert(controlador.estado == ControladorDeJogo.Estado.AGUARDANDO)

	controlador.iniciar_jogo()
	assert(controlador.estado == ControladorDeJogo.Estado.ATIVO)
	controlador.pausar_jogo()
	assert(controlador.estado == ControladorDeJogo.Estado.PAUSADO)
	controlador.iniciar_jogo()
	assert(controlador.estado == ControladorDeJogo.Estado.ATIVO)
	controlador.encerrar_jogo()
	assert(controlador.estado == ControladorDeJogo.Estado.ENCERRADO)
	controlador.iniciar_jogo()
	assert(controlador.estado == ControladorDeJogo.Estado.ENCERRADO)

	var posicao_inicial: Vector3i = trem.posicao_trem
	var posicao_seguinte: Vector3i = posicao_inicial + Direcao.deslocamento(
		Direcao.Sentido.DIREITA
	)
	trilhos.configurar_trilho(
		posicao_inicial,
		Direcao.Eixo.X,
		Trilhos.TipoTrilho.RETO,
		Direcao.Sentido.DIREITA
	)
	trem.velocity = 1000.0
	trem.movimento(Direcao.Sentido.DIREITA)
	assert(
		trem.posicao_trem == posicao_inicial,
		"O trem avançou sem encontrar um trilho conectado."
	)

	trilhos.configurar_trilho(
		posicao_seguinte,
		Direcao.Eixo.X,
		Trilhos.TipoTrilho.RETO,
		Direcao.Sentido.DIREITA
	)
	await trem.movimento(Direcao.Sentido.DIREITA)

	assert(trem.posicao_trem == posicao_seguinte)
	assert(trem.direcao_trem == Direcao.Sentido.DIREITA)
	assert(
		trem.global_position.is_equal_approx(
			trilhos.to_global(trilhos.map_to_local(posicao_seguinte))
		),
		"O trem não terminou alinhado com a célula de destino."
	)

	print("Testes de trem passaram.")
