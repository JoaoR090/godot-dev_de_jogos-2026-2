# Padrão de implementação do projeto

Este guia define uma estrutura comum para novos scripts e alterações de código
GDScript neste projeto. Usa `scripts/trilho.gd` como exemplo de organização,
tipagem e separação de responsabilidades.

## Estrutura dos arquivos

- `scripts/`: scripts GDScript.
- `scenes/`: cenas do Godot (`.tscn`).
- `assets/`: modelos, imagens e bibliotecas de recursos.
- `docs/`: documentação do projeto.

Ao criar uma cena ou mover um recurso, atualize também os caminhos `res://` que
apontam para ele e confirme que a cena pode ser aberta no Godot.

## Organização de um script

Organize o arquivo nesta ordem, omitindo as seções que não se aplicam:

1. `class_name` e classe base (`extends`).
2. Sinais, enums e constantes.
3. Propriedades exportadas e estado interno.
4. Métodos públicos usados por outras partes do jogo.
5. Métodos auxiliares privados, com prefixo `_`.

Exemplo baseado na estrutura de `Trilhos`:

```gdscript
class_name Trilhos
extends GridMap

enum Eixo {
	EIXO_Z,
	EIXO_X
}

enum Tipo {
	CURVA,
	RETO
}

enum Sentido {
	CIMA,
	BAIXO,
	DIREITA,
	ESQUERDA
}

@export var ID_RETO: int = 0
@export var ID_CURVO: int = 1

func configurar(posicao: Vector3i, eixoTrilho: Eixo, tipoTrilho: Tipo, sentido: Sentido) -> void:
	# Validar os argumentos e delegar a colocacao da peca.
	pass

func remover_trilho(posicao: Vector3i)->void:
	set_cell_item(posicao, -1)

func _colocar_peca(posicao: Vector3i, idPeca: int, rotacaoY: float) -> void:
	var baseRotacao := Basis(Vector3.UP, deg_to_rad(rotacaoY))
	var orientacao := get_orthogonal_index_from_basis(baseRotacao)
	set_cell_item(posicao, idPeca, orientacao)
```

O trecho é apenas um modelo de organização. Remova o `pass` e o comentário de
orientação antes de usar a função em código real.

## Nomes e idioma

- Use `PascalCase` para classes e tipos: `Trilhos`, `Vector3i`.
- Use `snake_case` para funções: `configurar`, `_colocar_peca`.
- Siga o padrão atual de `trilho.gd` para variáveis e parâmetros em `camelCase`,
  como `eixoTrilho`, `sentidoVizinho` e `baseRotacao`.
- Mantenha os IDs exportados de peças em maiúsculas com sublinhados, como
  `ID_RETO` e `ID_CURVO`, para corresponder ao padrão usado pelo projeto.
- Prefixe funções auxiliares privadas com `_`, como `_colocar_peca`.
- Use nomes claros em português para código de domínio do jogo, seguindo o
  vocabulário já usado em `trilho.gd`.
- Mantenha os nomes e as unidades explícitos. Por exemplo, `rotacaoY` deixa
  claro qual eixo o ângulo representa.
- Não renomeie símbolos já usados por cenas ou outros scripts sem atualizar
  todas as referências.

## Tipos e interfaces

- Declare o tipo de retorno de cada função, inclusive `-> void`.
- Tipifique parâmetros, variáveis locais, coleções e valores retornados sempre
  que o tipo for conhecido.
- Use tipos específicos do Godot, como `Vector3i`, `Basis` e enums do próprio
  script, em vez de valores sem tipo.
- Use `@export` apenas para valores que precisam ser configuráveis no Inspector.
  Explique o propósito de cada propriedade exportada.
- Prefira enums a números mágicos quando um argumento representa um conjunto
  limitado de opções, como eixos, tipos de peça e sentidos.

## Métodos e validação

- Dê a cada método uma responsabilidade clara. Em `trilho.gd`, `configurar`,
  `tem_conexao` e `mudar_curva` expressam operações distintas; conversões e
  colocação ficam em auxiliares.
- Valide entradas antes de alterar a cena ou o estado do objeto. Se uma
  combinação for inválida, não deixe o objeto em um estado parcialmente
  atualizado.
- Use retornos antecipados para casos inválidos ou operações que não se aplicam.
- Ao rejeitar uma entrada, forneça uma mensagem útil pelo mecanismo de erro ou
  log adotado pelo contexto. Não apresente uma falha como se a operação tivesse
  sido concluída com sucesso.
- Evite duplicar conversões de direção e orientação; reutilize um auxiliar
  existente quando a regra for a mesma.

## Comentários

- Escreva comentários em português para explicar intenção, regras não óbvias,
  limitações ou relações com o Inspector.
- Prefira comentários curtos junto à declaração ou ao trecho explicado.
- Não repita em comentário o que o nome da função já comunica.
- Atualize comentários quando a implementação mudar.

## Cenas e recursos

- Vincule scripts às cenas correspondentes e confira o tipo do nó base. Por
  exemplo, `Trilhos` estende `GridMap` e precisa de uma biblioteca de malha
  configurada para mostrar as peças.
- Confirme que IDs exportados, como os IDs de trilho reto e curvo, correspondem
  aos itens da `MeshLibrary` usada pela cena.
- Use caminhos `res://` existentes e confira que continuam válidos depois de
  renomear ou mover cenas e recursos.

## Testes

- Coloque testes temporários ou de desenvolvimento numa cena de teste separada,
  como `scenes/teste.tscn`, sem depender da cena principal.
- Teste resultados observáveis: item colocado, orientação, retorno de conexão e
  estado após uma entrada inválida.
- Inclua casos válidos, inválidos e de limite. Para conexões de trilho, teste
  cada direção e a orientação compatível e incompatível das peças vizinhas.
- Use `assert(condicao, mensagem)` para indicar claramente qual cenário falhou.
- Limpe as células ou os nós usados pelo teste para que um caso não afete o
  seguinte.
- Execute a cena pelo Godot e confirme que todos os `assert`s passam; mensagens
  esperadas de entradas inválidas devem ser distinguíveis de falhas.

## Observacoes sobre `trilho.gd`

`trilho.gd` é a referência de estilo atual do projeto. A configuração de curvas
recebe um único valor `Sentido`; a validação da combinação entre eixo e sentido
determina se a curva pode ser colocada.

Valores inválidos de eixo para trilho reto são rejeitados, e `tem_conexao`
interrompe a verificação quando a orientação do vizinho não corresponde a um
sentido conhecido.
