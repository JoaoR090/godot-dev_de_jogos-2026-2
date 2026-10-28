class_name Direcao
extends RefCounted

enum Eixo {
	Z,
	X
}

enum Sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA
}

static func deslocamento(sentido: Sentido) -> Vector3i:
	match sentido:
		Sentido.CIMA:
			return Vector3i(0, 0, -1)
		Sentido.DIREITA:
			return Vector3i(1, 0, 0)
		Sentido.BAIXO:
			return Vector3i(0, 0, 1)
		Sentido.ESQUERDA:
			return Vector3i(-1, 0, 0)
	return Vector3i.ZERO


static func proximo_sentido(sentido: Sentido) -> Sentido:
	match sentido:
		Sentido.CIMA:
			return Sentido.DIREITA
		Sentido.DIREITA:
			return Sentido.BAIXO
		Sentido.BAIXO:
			return Sentido.ESQUERDA
		Sentido.ESQUERDA:
			return Sentido.CIMA
	return sentido


static func avancar_sentido(sentido: Sentido, passos: int) -> Sentido:
	for _i in range(posmod(passos, 4)):
		sentido = proximo_sentido(sentido)
	return sentido


static func sentido_oposto(sentido: Sentido) -> Sentido:
	return avancar_sentido(sentido, 2)


static func angulo_do_eixo(eixo: Eixo) -> float:
	match eixo:
		Eixo.Z:
			return 0.0
		Eixo.X:
			return 90.0
	return -1.0


static func angulo_do_sentido(sentido: Sentido) -> float:
	match sentido:
		Sentido.CIMA:
			return 0.0
		Sentido.DIREITA:
			return 90.0
		Sentido.BAIXO:
			return 180.0
		Sentido.ESQUERDA:
			return 270.0
	return -1.0


static func sentido_da_orientacao(orientacao: int, mapa: GridMap) -> Sentido:
	var base: Basis = mapa.get_basis_with_orthogonal_index(orientacao)
	var angulo: float = fposmod(rad_to_deg(base.get_euler().y), 360.0)

	match roundi(angulo):
		0:
			return Sentido.CIMA
		90:
			return Sentido.DIREITA
		180:
			return Sentido.BAIXO
		270:
			return Sentido.ESQUERDA
	return -1


static func orientacao_do_sentido(sentido: Sentido, mapa: GridMap) -> int:
	var angulo: float = angulo_do_sentido(sentido)
	if angulo < 0.0:
		return -1
	return mapa.get_orthogonal_index_from_basis(Basis(Vector3.UP, deg_to_rad(angulo)))


static func orientacao_do_angulo(angulo: float, mapa: GridMap) -> int:
	var base := Basis(Vector3.UP, deg_to_rad(angulo))
	return mapa.get_orthogonal_index_from_basis(base)
