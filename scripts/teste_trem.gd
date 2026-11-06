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
		(trem.global_basis * Vector3.FORWARD).normalized().is_equal_approx(
			Vector3.RIGHT
		),
		"O trem nao terminou orientado para o sentido do movimento."
	)
	assert(
		trem.global_position.is_equal_approx(
			trilhos.to_global(trilhos.map_to_local(posicao_seguinte))
		),
		"O trem não terminou alinhado com a célula de destino."
	)

	trilhos.configurar_trilho(
		posicao_seguinte,
		Direcao.Eixo.X,
		Trilhos.TipoTrilho.CURVA,
		Direcao.Sentido.CIMA
	)
	var posicao_saida_curva: Vector3i = posicao_seguinte + Direcao.deslocamento(
		Direcao.Sentido.CIMA
	)
	trilhos.configurar_trilho(
		posicao_saida_curva,
		Direcao.Eixo.Z,
		Trilhos.TipoTrilho.RETO,
		Direcao.Sentido.CIMA
	)
	await trem.movimento(Direcao.Sentido.CIMA)

	assert(trem.posicao_trem == posicao_saida_curva)
	assert(trem.direcao_trem == Direcao.Sentido.CIMA)
	assert(
		(trem.global_basis * Vector3.FORWARD).normalized().is_equal_approx(
			Vector3.FORWARD
		),
		"O trem nao virou para cima ao sair da curva CIMA."
	)

	var posicao_bifurcacao: Vector3i = posicao_saida_curva + Vector3i(10, 0, 0)
	trilhos.configurar_trilho(
		posicao_bifurcacao + Direcao.deslocamento(Direcao.Sentido.DIREITA),
		Direcao.Eixo.X,
		Trilhos.TipoTrilho.RETO,
		Direcao.Sentido.DIREITA
	)
	trilhos.configurar_trilho(
		posicao_bifurcacao + Direcao.deslocamento(Direcao.Sentido.CIMA),
		Direcao.Eixo.Z,
		Trilhos.TipoTrilho.RETO,
		Direcao.Sentido.CIMA
	)
	assert(
		controlador._proximo_trilho(
			posicao_bifurcacao,
			Direcao.Sentido.DIREITA
		) == Direcao.Sentido.DIREITA,
		"O trem deveria preferir continuar em frente quando ha trilho conectado."
	)

	print("Testes de trem passaram.")
