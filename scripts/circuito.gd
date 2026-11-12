class_name Circuito
extends RefCounted

static func criar(trilhos: Trilhos, posicao: Vector3i, sentido: Direcao.Sentido) -> void:
	var posicao_trilho: Vector3i = posicao
	var proximo_sentido: Direcao.Sentido = sentido

	for lado in range(4):
		for passo in range(4):
			posicao_trilho += Direcao.deslocamento(proximo_sentido)
			if (proximo_sentido == Direcao.Sentido.ESQUERDA or proximo_sentido == Direcao.Sentido.DIREITA):
				_trilho_reto_eixo_x(trilhos, posicao_trilho)
			else:
				_trilho_reto_eixo_z(trilhos, posicao_trilho)

		posicao_trilho += Direcao.deslocamento(proximo_sentido)
		_trilho_reto_curvo(trilhos, posicao_trilho, Direcao.sentido_oposto(proximo_sentido))
		proximo_sentido = Direcao.proximo_sentido(proximo_sentido)

static func _trilho_reto_eixo_x(trilhos: Trilhos, posicao: Vector3i) -> void:
	trilhos.configurar_trilho(posicao, Direcao.Eixo.X, Trilhos.TipoTrilho.RETO, Direcao.Sentido.DIREITA)

static func _trilho_reto_eixo_z(trilhos: Trilhos, posicao: Vector3i) -> void:
	trilhos.configurar_trilho(posicao, Direcao.Eixo.Z, Trilhos.TipoTrilho.RETO, Direcao.Sentido.DIREITA)

static func _trilho_reto_curvo(trilhos: Trilhos, posicao: Vector3i, direcao: Direcao.Sentido) -> void:
	trilhos.configurar_trilho(posicao, Direcao.Eixo.Z, Trilhos.TipoTrilho.CURVA, direcao)
