class_name Trem
extends Node3D

# Direcoes utilizadas pelo trem para navegar pela grade de trilhos.
enum Sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA
}

# Ponto de extensao: a verificacao de trilho ainda nao foi implementada.
func _esta_no_trilho(posicao: Vector3i):
	pass
