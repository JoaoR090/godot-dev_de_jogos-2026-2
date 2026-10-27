class_name Trem
extends Node3D

# Direcoes utilizadas pelo trem para navegar pela grade de trilhos.
enum Sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA
}

var trilhos: Trilhos

func _nao_esta_no_trilho(posicao: Vector3i) -> bool:
	return not trilhos.tem_trilho(posicao)
