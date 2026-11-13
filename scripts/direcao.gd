class_name Direcao
extends RefCounted

enum Eixo {
	Z,
	X,
	INVALIDO = -1,
}

enum Sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA,
	INVALIDO = -1,
}

# Ordem circular dos sentidos: cima, direita, baixo e esquerda.
# Os valores do enum acima foram mantidos (cenas salvas guardam esses números);
# esta lista é quem define o "próximo", o "anterior" e o "oposto".
const ORDEM_CIRCULAR := [
	Sentido.CIMA,
	Sentido.DIREITA,
	Sentido.BAIXO,
	Sentido.ESQUERDA,
]

# Retorna o deslocamento de uma célula correspondente ao sentido informado.
static func deslocamento(sentido: Sentido) -> Vector3i:
	match sentido:
		Sentido.CIMA:
			return Vector3i(0, 0, 1)
		Sentido.DIREITA:
			return Vector3i(-1, 0, 0)
		Sentido.BAIXO:
			return Vector3i(0, 0, -1)
		Sentido.ESQUERDA:
			return Vector3i(1, 0, 0)
	return Vector3i.ZERO

# Avança (ou recua, se negativo) vários passos na ordem circular.
static func avancar_sentido(sentido: Sentido, passos: int) -> Sentido:
	var indice: int = ORDEM_CIRCULAR.find(sentido)
	if indice == -1:
		return Sentido.INVALIDO
	return ORDEM_CIRCULAR[posmod(indice + passos, ORDEM_CIRCULAR.size())]

static func proximo_sentido(sentido: Sentido) -> Sentido:
	return avancar_sentido(sentido, 1)

static func sentido_anterior(sentido: Sentido) -> Sentido:
	return avancar_sentido(sentido, -1)

static func sentido_oposto(sentido: Sentido) -> Sentido:
	return avancar_sentido(sentido, 2)

static func proximo_eixo(eixo: Eixo) -> Eixo:
	match eixo:
		Eixo.Z:
			return Eixo.X
		Eixo.X:
			return Eixo.Z
	return Eixo.INVALIDO

# Nome legível do sentido (útil para depuração).
static func nome(sentido: Sentido) -> String:
	return str(Sentido.find_key(sentido))

# Converte um eixo de trilho reto no ângulo de rotação correspondente.
# Retorna -1.0 se o eixo for inválido.
static func angulo_do_eixo(eixo: Eixo) -> float:
	match eixo:
		Eixo.Z:
			return 0.0
		Eixo.X:
			return 90.0
	return -1.0

# Converte um sentido em seu ângulo de rotação positiva no eixo Y.
# Retorna -1.0 se o sentido for inválido.
static func angulo_do_sentido(sentido: Sentido) -> float:
	match sentido:
		Sentido.CIMA:
			return 0.0
		Sentido.ESQUERDA:
			return 90.0
		Sentido.BAIXO:
			return 180.0
		Sentido.DIREITA:
			return 270.0
	return -1.0	

# Converte a orientação ortogonal do GridMap no sentido equivalente.
static func sentido_da_orientacao(orientacao: int, mapa: GridMap) -> Sentido:
	if orientacao < 0:
		return Sentido.INVALIDO
	var base: Basis = mapa.get_basis_with_orthogonal_index(orientacao)
	var angulo: float = fposmod(rad_to_deg(base.get_euler().y), 360.0)
	return sentido_do_angulo(angulo)

# Converte o ângulo no sentido equivalente (aceita 360, -90, etc.).
static func sentido_do_angulo(angulo: float) -> Sentido:
	match posmod(roundi(angulo), 360):
		0:
			return Sentido.CIMA
		90:
			return Sentido.ESQUERDA
		180:
			return Sentido.BAIXO
		270:
			return Sentido.DIREITA
	return Sentido.INVALIDO

# Converte um sentido na orientação ortogonal correspondente do GridMap.
static func orientacao_do_sentido(sentido: Sentido, mapa: GridMap) -> int:
	var angulo: float = angulo_do_sentido(sentido)
	if angulo < 0.0:
		return -1
	return orientacao_do_angulo(angulo, mapa)

# Converte um ângulo de rotação na orientação ortogonal correspondente do GridMap.
static func orientacao_do_angulo(angulo: float, mapa: GridMap) -> int:
	var base := Basis(Vector3.UP, deg_to_rad(angulo))
	return mapa.get_orthogonal_index_from_basis(base)

# Converte um sentido em um eixo.
static func eixo_do_sentido(sentido: Sentido) -> Eixo:
	match sentido:
		Sentido.CIMA, Sentido.BAIXO:
			return Eixo.Z
		Sentido.DIREITA, Sentido.ESQUERDA:
			return Eixo.X
	return Eixo.INVALIDO
