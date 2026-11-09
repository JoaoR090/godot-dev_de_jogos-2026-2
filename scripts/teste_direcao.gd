extends Node

# Executa os testes unitários das conversões e operações de direção.
func _ready() -> void:
	assert(Direcao.deslocamento(Direcao.Sentido.CIMA) == Vector3i(0, 0, -1))
	assert(Direcao.deslocamento(Direcao.Sentido.DIREITA) == Vector3i(1, 0, 0))
	assert(Direcao.deslocamento(Direcao.Sentido.BAIXO) == Vector3i(0, 0, 1))
	assert(Direcao.deslocamento(Direcao.Sentido.ESQUERDA) == Vector3i(-1, 0, 0))

	assert(
		Direcao.proximo_sentido(Direcao.Sentido.CIMA)
		== Direcao.Sentido.DIREITA
	)
	assert(
		Direcao.proximo_sentido(Direcao.Sentido.DIREITA)
		== Direcao.Sentido.BAIXO
	)
	assert(
		Direcao.proximo_sentido(Direcao.Sentido.BAIXO)
		== Direcao.Sentido.ESQUERDA
	)
	assert(
		Direcao.proximo_sentido(Direcao.Sentido.ESQUERDA)
		== Direcao.Sentido.CIMA
	)

	assert(
		Direcao.avancar_sentido(Direcao.Sentido.CIMA, 5)
		== Direcao.Sentido.DIREITA
	)
	assert(
		Direcao.avancar_sentido(Direcao.Sentido.CIMA, -1)
		== Direcao.Sentido.ESQUERDA
	)
	assert(
		Direcao.sentido_oposto(Direcao.Sentido.CIMA)
		== Direcao.Sentido.BAIXO
	)
	assert(Direcao.angulo_do_eixo(Direcao.Eixo.Z) == 0.0)
	assert(Direcao.angulo_do_eixo(Direcao.Eixo.X) == 90.0)
	assert(Direcao.angulo_do_sentido(Direcao.Sentido.CIMA) == 0.0)
	assert(Direcao.angulo_do_sentido(Direcao.Sentido.DIREITA) == 270.0)
	assert(Direcao.angulo_do_sentido(Direcao.Sentido.BAIXO) == 180.0)
	assert(Direcao.angulo_do_sentido(Direcao.Sentido.ESQUERDA) == 90.0)
	assert(Direcao.sentido_do_angulo(0.0) == Direcao.Sentido.CIMA)
	assert(Direcao.sentido_do_angulo(90.0) == Direcao.Sentido.ESQUERDA)
	assert(Direcao.sentido_do_angulo(180.0) == Direcao.Sentido.BAIXO)
	assert(Direcao.sentido_do_angulo(270.0) == Direcao.Sentido.DIREITA)
	assert(Direcao.eixo_do_sentido(Direcao.Sentido.CIMA) == Direcao.Eixo.Z)
	assert(Direcao.eixo_do_sentido(Direcao.Sentido.BAIXO) == Direcao.Eixo.Z)
	assert(Direcao.eixo_do_sentido(Direcao.Sentido.DIREITA) == Direcao.Eixo.X)
	assert(Direcao.eixo_do_sentido(Direcao.Sentido.ESQUERDA) == Direcao.Eixo.X)

	print("Testes de direcao passaram.")
