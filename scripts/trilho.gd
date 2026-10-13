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
	var trilho
	if tipo == tipos.RETO:
		trilho = preload("res://assets/3d models/Trilho.glb").instantiate()
		if direc_eixo == eixo.EIXO_X:
			trilho.rotation_degrees = Vector3(0, angulo - 90, 0)
		add_child(trilho)
	elif tipo == tipos.CURVA:
		if direc_eixo == eixo.EIXO_Z:
			match sentidos[0]:
				sentido.DIREITA:
					trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					trilho.rotation_degrees = Vector3(0, angulo - 90, 0)
					add_child(trilho)
				sentido.ESQUERDA:
					trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					trilho.rotation_degrees = Vector3(0, angulo + 90, 0)
					add_child(trilho)
		elif direc_eixo == eixo.EIXO_X:
			match sentidos[0]:
				sentido.CIMA:
					trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					trilho.rotation_degrees = Vector3(0, angulo + 0, 0)
					add_child(trilho)
				sentido.BAIXO:
					trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
					trilho.rotation_degrees = Vector3(0, angulo + 180, 0)
					add_child(trilho)
	elif tipo == tipos.VÀRIAS:
		if direc_eixo == eixo.EIXO_Z:
			for pos in sentidos:
				match pos:
					sentido.CIMA or sentido.BAIXO:
						trilho = preload("res://assets/3d models/Trilho.glb").instantiate()
						trilho.rotation_degrees = Vector3(0, angulo + 0, 0)
						add_child(trilho)
					sentido.DIREITA:
						trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						trilho.rotation_degrees = Vector3(0, angulo - 90, 0)
						add_child(trilho)
					sentido.ESQUERDA:
						trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						trilho.rotation_degrees = Vector3(0, angulo + 90, 0)
						add_child(trilho)
					_:
						print('f')
		elif direc_eixo == eixo.EIXO_X:
			for pos in sentidos:
				match pos:
					sentido.CIMA:
						trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						trilho.rotation_degrees = Vector3(0, angulo + 0, 0)
						add_child(trilho)
					sentido.DIREITA or sentido.ESQUERDA:
						trilho = preload("res://assets/3d models/Trilho.glb").instantiate()
						trilho.rotation_degrees = Vector3(0, angulo - 90, 0)
						add_child(trilho)
					sentido.BAIXO:
						trilho = preload("res://assets/3d models/Trilho_curvo.glb").instantiate()
						trilho.rotation_degrees = Vector3(0, angulo + 180, 0)
						add_child(trilho)
					_:
						print('f')
