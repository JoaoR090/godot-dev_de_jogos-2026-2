
class_name Player
extends Node3D

const SPEED = 20.0
@export var grid_trilhos: Trilhos
var trilho: Trilhos.TipoTrilho = Trilhos.TipoTrilho.RETO
var eixo_trilho: Direcao.Eixo = Direcao.Eixo.Z
var sentido_trilho: Direcao.Sentido = Direcao.Sentido.CIMA

var _start_position: Vector3

func _ready() -> void:
	_start_position = global_position

func _physics_process(delta: float) -> void:
	_handle_movement(delta)


func _handle_movement(delta: float) -> void:
	var direction := Vector3.ZERO

	if Input.is_action_pressed("up"):
		direction.z -= 1

	if Input.is_action_pressed("down"):
		direction.z += 1

	if Input.is_action_pressed("left"):
		direction.x -= 1

	if Input.is_action_pressed("right"):
		direction.x += 1

	direction = direction.normalized()
	global_position += direction * SPEED * delta

func remover_trilho(posicao: Vector3i)-> void:
	grid_trilhos.remover_trilho(posicao)

func colocar_trilho(posicao: Vector3i)-> void:
	grid_trilhos.configurar_trilho(posicao, eixo_trilho, trilho, sentido_trilho)

func trocar_lado_trilho()->void:
	if Input.is_action_pressed("next"):
		if trilho == Trilhos.TipoTrilho.CURVA:
			sentido_trilho = Direcao.proximo_sentido(sentido_trilho)
		elif trilho == Trilhos.TipoTrilho.RETO:
			eixo_trilho = Direcao.proximo_eixo(eixo_trilho)
	if Input.is_action_pressed("prev"):
		if trilho == Trilhos.TipoTrilho.CURVA:
			sentido_trilho = Direcao.avancar_sentido(sentido_trilho, 3)
		elif trilho == Trilhos.TipoTrilho.RETO:
			eixo_trilho = Direcao.proximo_eixo(eixo_trilho)
