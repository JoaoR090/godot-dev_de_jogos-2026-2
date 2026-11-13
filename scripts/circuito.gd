class_name Circuito
extends RefCounted

# Trilhos retos entre duas curvas (o lado completo tem esse número + 1 curva).
const RETOS_POR_LADO: int = 4

# Desenha um circuito quadrado a partir de `posicao`.
# Atenção: o circuito fecha sobre a própria `posicao`, então a última curva
# substitui a peça que estiver nessa célula (a do trem, no modo demo).
static func criar(trilhos: Trilhos, posicao: Vector3i, sentido: Direcao.Sentido, retos_por_lado: int = RETOS_POR_LADO) -> void:
	var posicao_atual: Vector3i = posicao
	var sentido_atual: Direcao.Sentido = sentido

	for _lado in range(4):
		for _passo in range(retos_por_lado):
			posicao_atual += Direcao.deslocamento(sentido_atual)
			trilhos.colocar_reto(posicao_atual, Direcao.eixo_do_sentido(sentido_atual))

		posicao_atual += Direcao.deslocamento(sentido_atual)
		trilhos.colocar_curva(posicao_atual, Direcao.sentido_oposto(sentido_atual))
		sentido_atual = Direcao.proximo_sentido(sentido_atual)
