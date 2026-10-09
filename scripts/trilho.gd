class_name Trilho
extends Node3D

enum eixo {
	EIXO_Z,
	EIXO_X
}

enum tipos {
	CURVA,
	RETO,
	VÀRIAS
}

enum sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA
}

var angulo: int = 0
var pos: Vector3
var direção : eixo

func _init(direc_eixo: eixo, tipo: tipos, sentidos: Array[sentido]):
	direção = direc_eixo
	if tipo == tipos.RETO:
		if direc_eixo == eixo.EIXO_Z:
			var reto = preload("res://assets/3d models/Trilho.glb").instantiate()
			add_child(reto)
		elif direc_eixo == eixo.EIXO_X:
			var reto = preload("res://assets/3d models/Trilho.glb").instantiate()
			add_child(reto)
	elif tipo == tipos.CURVA:
		if direc_eixo == eixo.EIXO_Z:
			match sentidos[0]:
				sentido.DIREITA:
					var direita = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					direita.rotation_degrees = Vector3(0, angulo - 90, 0)
					add_child(direita)
				sentido.ESQUERDA:
					var esquerda = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					esquerda.rotation_degrees = Vector3(0, angulo + 90, 0)
					add_child(esquerda)
		elif direc_eixo == eixo.EIXO_X:
			match sentidos[0]:
				sentido.CIMA:
					var cima = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					cima.rotation_degrees = Vector3(0, angulo + 0, 0)
					add_child(cima)
				sentido.BAIXO:
					var baixo = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					baixo.rotation_degrees = Vector3(0, angulo + 180, 0)
					add_child(baixo)
	elif tipo == tipos.VÀRIAS:
		if direc_eixo == eixo.EIXO_Z:
			for pos in sentidos:
				match pos:
					sentido.CIMA or sentido.BAIXO:
						var cima_baixo = preload("res://assets/3d models/Trilho.glb").instantiate()
						add_child(cima_baixo)
					sentido.DIREITA:
						var direita = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						add_child(direita)
					sentido.ESQUERDA:
						var esquerda = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						add_child(esquerda)
					_:
						print('f')
		elif direc_eixo == eixo.EIXO_X:
			for pos in sentidos:
				match pos:
					sentido.CIMA:
						var cima = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						add_child(cima)
					sentido.DIREITA or sentido.ESQUERDA:
						var direita_esquerda = preload("res://assets/3d models/Trilho.glb").instantiate()
						add_child(direita_esquerda)
					sentido.BAIXO:
						var baixo = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						add_child(baixo)
					_:
						print('f')
