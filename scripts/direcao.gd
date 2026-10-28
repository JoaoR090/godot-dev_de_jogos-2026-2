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

# Retorna o deslocamento de uma célula correspondente ao sentido informado.
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


# Avança um sentido na ordem circular: cima, direita, baixo e esquerda.
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


# Avança vários passos na sequência circular de sentidos.
static func avancar_sentido(sentido: Sentido, passos: int) -> Sentido:
	for _i in range(posmod(passos, 4)):
		sentido = proximo_sentido(sentido)
	return sentido


# Retorna o sentido oposto, avançando duas posições na sequência.
static func sentido_oposto(sentido: Sentido) -> Sentido:
	return avancar_sentido(sentido, 2)


# Converte um eixo de trilho reto no ângulo de rotação correspondente.
static func angulo_do_eixo(eixo: Eixo) -> float:
	match eixo:
		Eixo.Z:
			return 0.0
		Eixo.X:
			return 90.0
	return -1.0


# Converte um sentido em seu ângulo de rotação no eixo Y.
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


# Converte a orientação ortogonal do GridMap no sentido equivalente.
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


# Converte um sentido na orientação ortogonal correspondente do GridMap.
static func orientacao_do_sentido(sentido: Sentido, mapa: GridMap) -> int:
	var angulo: float = angulo_do_sentido(sentido)
	if angulo < 0.0:
		return -1
	return mapa.get_orthogonal_index_from_basis(Basis(Vector3.UP, deg_to_rad(angulo)))


# Converte um ângulo de rotação na orientação ortogonal correspondente do GridMap.
static func orientacao_do_angulo(angulo: float, mapa: GridMap) -> int:
	var base := Basis(Vector3.UP, deg_to_rad(angulo))
	return mapa.get_orthogonal_index_from_basis(base)
