class_name AudioSfx
extends RefCounted

const BUS_SFX := "SFX"
const BUS_MUSICA := "Music"
const UNIT_SIZE_PADRAO := 6.0
const DISTANCIA_MAXIMA_PADRAO := 64.0


static func garantir_bus(nome: String) -> int:
	var indice := AudioServer.get_bus_index(nome)

	if indice == -1:
		indice = AudioServer.bus_count
		AudioServer.bus_count = indice + 1
		AudioServer.set_bus_name(indice, nome)
		AudioServer.set_bus_send(indice, "Master")

	return indice


static func criar_player(
	pai: Node,
	stream: AudioStream,
	volume_db: float = 0.0
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = volume_db

	garantir_bus(BUS_SFX)
	pai.add_child(player)

	return player


static func criar_player_3d(
	pai: Node,
	stream: AudioStream,
	volume_db: float = 0.0
) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = volume_db
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.unit_size = UNIT_SIZE_PADRAO
	player.max_distance = DISTANCIA_MAXIMA_PADRAO

	garantir_bus(BUS_SFX)
	pai.add_child(player)

	return player
