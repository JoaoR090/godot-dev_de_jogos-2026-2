class_name Trem
extends Node3D

var velocity: float = 1.0
var trilhos: Trilhos
var posicao_trem: Vector3i

# Ponto de entrada reservado para implementar o movimento do trem.
func movimento():
	pass

# Lista os sentidos das células vizinhas que contêm trilhos.
func _proximo_trilho(posicao: Vector3i) -> Array[Direcao.Sentido]:
	var trilhos_disponiveis: Array[Direcao.Sentido] = []
	var sentido: Direcao.Sentido = Direcao.Sentido.CIMA
	for i in range(4):
		if _tem_trilho(sentido, posicao):
			trilhos_disponiveis.append(sentido)
		sentido = Direcao.proximo_sentido(sentido)
	return trilhos_disponiveis

# Verifica se há um trilho na célula vizinha no sentido indicado.
func _tem_trilho(sentido: Direcao.Sentido, posicao: Vector3i) -> bool:
	var posicao_vizinha: Vector3i = posicao + Direcao.deslocamento(sentido)
	return trilhos.tem_trilho(posicao_vizinha)
