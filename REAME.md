# Como baixar e importar o projeto no Godot

Este guia explica como baixar o projeto disponibilizado no GitHub e importá-lo no Godot Engine para abrir, executar e editar o jogo.

## 1. Pré-requisitos

Antes de começar, você precisará dos seguintes programas:

- **Godot Engine:** instalado no computador. Utilize a versão compatível com o projeto.
- **Git:** necessário para clonar o repositório, criar branches, registrar alterações e atualizar o repositório.

Você pode baixar o Godot no site oficial:

[Download do Godot Engine](https://godotengine.org/download/)

Você pode baixar o Git no site oficial:

[Download do Git](https://git-scm.com/install/)

## 2. Baixando o projeto do GitHub

### Opção 1: Baixar o projeto em formato ZIP (recomendado para quem deseja apenas acessar os arquivos)

1. Acesse o repositório do projeto no GitHub.
2. Clique no botão verde **Code**.
3. Selecione a opção **Download ZIP**.
4. Aguarde o download do arquivo.
5. Extraia o conteúdo do arquivo ZIP para uma pasta de sua preferência.

Após a extração, você deverá ter uma pasta contendo os arquivos do projeto Godot.

> **Observação:** Se você pretende desenvolver o projeto, criar branches, realizar commits e enviar alterações para o GitHub, utilize a opção 2. O download em ZIP não configura um repositório Git.

### Opção 2: Clonar o repositório usando Git

Se você possui o Git instalado, também pode baixar o projeto pelo terminal.

Execute o seguinte comando:

```bash
git clone https://github.com/JoaoR090/godot-dev_de-jogos-2026-2.git
```

Após a conclusão, entre na pasta do projeto:

```bash
cd godot-dev_de-jogos-2026-2
```

Agora você terá uma cópia local do repositório, permitindo trabalhar no projeto, criar branches, realizar commits e enviar alterações para o GitHub.

## 3. Importando o projeto no Godot

Depois de baixar e extrair (ou clonar) o projeto, siga estas etapas:

1. Abra o **Godot Engine**.
2. Na tela inicial, localize a opção **Importar (Import)**.
3. Clique em **Importar**.
4. Navegue até a pasta onde o projeto foi baixado.
5. Selecione o arquivo `project.godot`.
6. Confirme a importação do projeto.
7. Aguarde o Godot carregar os arquivos e importar os recursos necessários.

Após a importação, o projeto deverá aparecer na lista de projetos do Godot.

## 4. Criando uma nova branch

Branches permitem desenvolver funcionalidades, corrigir erros ou realizar experimentos sem modificar diretamente a branch principal do projeto.

Antes de começar a trabalhar, certifique-se de estar na pasta do repositório:

```bash
cd godot-dev_de-jogos-2026-2
```

### 4.1. Atualizando a branch principal

Antes de criar uma nova branch, atualize as informações do repositório remoto e baixe as alterações mais recentes da branch principal:

```bash
git switch main
git pull origin main
```

> **Observação:** Caso a branch principal tenha outro nome, substitua `main` pelo nome correto.

### 4.2. Criando e acessando uma nova branch

Para criar uma branch e mudar para ela imediatamente, utilize:

```bash
git switch -c nome-da-branch
```

Por exemplo, para criar uma branch destinada ao desenvolvimento de um sistema de movimentação:

```bash
git switch -c feature/movimentacao
```

A partir desse momento, suas alterações serão realizadas nessa branch.

**Sugestões para nomear branches:**

- `feature/nome-da-funcionalidade` — para novas funcionalidades.
- `fix/nome-do-problema` — para correções de erros.
- `docs/nome-da-documentacao` — para alterações na documentação.

Para verificar em qual branch você está, utilize:

```bash
git branch
```

A branch atual será identificada com um `*`.

## 5. Realizando commits

Commits permitem registrar as alterações realizadas no projeto ao longo do desenvolvimento.

### 5.1. Verificando as alterações

Após modificar arquivos no Godot, abra o terminal na pasta do repositório e execute:

```bash
git status
```

Esse comando mostra os arquivos modificados, adicionados ou removidos.

### 5.2. Adicionando arquivos para o commit

Para adicionar todas as alterações ao próximo commit, utilize:

```bash
git add .
```

Se preferir, adicione apenas um arquivo específico:

```bash
git add caminho/do/arquivo
```

### 5.3. Criando o commit

Após adicionar os arquivos, registre as alterações com:

```bash
git commit -m "Descrição das alterações realizadas"
```

Por exemplo:

```bash
git commit -m "Adiciona sistema de movimentação do personagem"
```

> **Dica:** Escreva mensagens de commit curtas e claras, descrevendo o que foi alterado.

## 6. Enviando a branch para o GitHub

Depois de criar um ou mais commits, você pode enviar sua branch para o repositório remoto.

No primeiro envio da branch, utilize:

```bash
git push -u origin nome-da-branch
```

Por exemplo:

```bash
git push -u origin feature/movimentacao
```

O parâmetro `-u` configura a branch remota como referência padrão. Assim, nos próximos envios dessa mesma branch, você poderá utilizar apenas:

```bash
git push
```

Após o envio, a branch estará disponível no GitHub.

## 7. Atualizando sua branch com as alterações mais recentes

Caso outras pessoas tenham enviado alterações para a branch principal, você pode atualizar sua branch de trabalho com essas mudanças.

Primeiro, atualize a branch principal:

```bash
git switch main
git pull origin main
```

Depois, retorne à sua branch de desenvolvimento:

```bash
git switch nome-da-branch
```

Por fim, incorpore as alterações mais recentes da branch principal:

```bash
git merge main
```

Se houver conflitos, será necessário resolvê-los antes de concluir a integração.

Após resolver os conflitos e concluir o merge, envie as alterações atualizadas:

```bash
git push
```

## 8. Integrando suas alterações à branch principal

Quando terminar o desenvolvimento e quiser incorporar suas alterações à branch principal, é recomendado abrir um **Pull Request (PR)** no GitHub.

Siga estas etapas:

1. Envie sua branch para o GitHub utilizando `git push`.
2. Acesse o repositório no GitHub.
3. Localize a opção para criar um **Pull Request**.
4. Selecione sua branch como origem e `main` como destino.
5. Adicione um título e uma descrição explicando as alterações.
6. Crie o Pull Request para que as alterações possam ser revisadas e integradas à branch principal.

Após a aprovação e a integração do Pull Request, suas alterações farão parte da branch principal.

---

**Pronto!** Após seguir essas etapas, o projeto estará importado no Godot e você poderá desenvolver novas funcionalidades, criar branches, registrar commits e compartilhar suas alterações no GitHub.
