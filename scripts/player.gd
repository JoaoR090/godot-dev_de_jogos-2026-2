
class_name Player
extends Node3D

const SPEED = 20.0
@export var grid_trilhos: Trilhos
var eixo_trilho: Direcao.Eixo = Direcao.Eixo.Z
var sentido_trilho: Direcao.Sentido = Direcao.Sentido.CIMA
var indice_inventario: int = 0
const max_itens: int = 3
var inventario_jogador: Dictionary = {
	0: "Mão",
	1: "Trilho_Reto",
	2: "Trilho_Curvo",
}
var mudou_inventario: bool = true

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	colocar_trilho(grid_trilhos.local_to_map(grid_trilhos.to_local(global_position)))
	trocar_lado_trilho()
	mudar_indice()
	print_inventario()

func print_inventario():
	if mudou_inventario:
		mudou_inventario = false
		print(indice_inventario, " ", eixo_trilho, " ", sentido_trilho)


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

func mudar_indice() -> void:
	if Input.is_action_just_pressed("changeNext"):
		mudou_inventario = true
		indice_inventario = (indice_inventario + 1) % max_itens
		
	if Input.is_action_just_pressed("changePrev"):
		mudou_inventario = true
		indice_inventario = (indice_inventario - 1 + max_itens) % max_itens

func colocar_trilho(posicao: Vector3i)-> void:
	if Input.is_action_just_pressed("place"):
		print("tentando colocar trilho")
		if inventario_jogador[indice_inventario] == "Trilho_Reto":
			print("trilho colocado")
			grid_trilhos.configurar_trilho(posicao, eixo_trilho, Trilhos.TipoTrilho.RETO, sentido_trilho)
		if inventario_jogador[indice_inventario] == "Trilho_Curvo":
			print("trilho colocado")
			grid_trilhos.configurar_trilho(posicao, eixo_trilho, Trilhos.TipoTrilho.CURVA, sentido_trilho)

func trocar_lado_trilho()->void:
	if Input.is_action_just_pressed("next"):
		mudou_inventario = true
		sentido_trilho = Direcao.proximo_sentido(sentido_trilho)
		eixo_trilho = Direcao.proximo_eixo(eixo_trilho)
	if Input.is_action_just_pressed("prev"):
		mudou_inventario = true
		sentido_trilho = Direcao.avancar_sentido(sentido_trilho, 3)
		eixo_trilho = Direcao.proximo_eixo(eixo_trilho)
