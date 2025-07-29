# Payara Deploy Script

> Script Shell criado para substituir o plugin "Payara Tools" do IntelliJ IDEA (versão Premium), permitindo o deploy e gerenciamento de aplicações no Payara Server diretamente pelo terminal.
## Índice

- [Descrição](#descrição)
- [Motivação](#motivação)
- [Pré-requisitos](#pré-requisitos)
- [Como usar](#como-usar)

---
## 📖 Descrição

>Este script foi desenvolvido com o objetivo de automatizar tarefas de deploy e gerenciamento de aplicações no **Payara Server**, eliminando a dependência do plugin "Payara Tools" no IntelliJ IDEA, que requer uma versão paga da IDE.
>
>Ideal para desenvolvedores que utilizam a versão gratuita do IntelliJ ou preferem uma abordagem mais leve e automatizada via terminal.

## 💡 Motivação

> Por utilizar a versão **Community** do IntelliJ IDEA, não era possível utilizar o plugin "Payara Tools" para gerenciar projetos diretamente pela IDE. Isso exigia que todo o processo de deploy fosse feito manualmente, acessando o painel de controle do Payara Server via navegador.
>
> Essa abordagem manual era repetitiva, demandava tempo e tornava o fluxo de trabalho menos eficiente. Como alternativa, surgiu a ideia de utilizar os comandos administrativos disponíveis via terminal para automatizar essas tarefas, tornando o processo mais rápido, prático e integrado ao dia a dia de desenvolvimento.

## 🛠️ Pré-requisitos

Liste os requisitos para executar o script, como:

- Linux/macOS (bash compatível)
- Permissões de execução (`chmod 777`)


## 🚀 Como usar

> Para utilizar o script corretamente, siga os passos abaixo:

1. **Configure o ambiente:**

   Execute o script com a opção `--config` ou `-c` para realizar as configurações iniciais:
   `sh payara_run.sh -c`

   Esse comando permitirá que você defina os caminhos necessários para o funcionamento do script. Depois de rodar pela primeira vez, será adicionado no seu caminho bashrc o alias para utilizar o script em qualquer lugar do sistema, podendo abstrair o "sh" de execução e ".sh" da extensão do arquivo.

2. **Ajuste as constantes internas:**

   Dentro do script, localize e edite as seguintes constantes:

    - `CAMINHO_PROJETOS_EXEMPLO`: Caminho completo até o diretório onde está o projeto que será feito o deploy.

    - `CAMINHO_PROJETOS_EXEMPLO_EAR`: Caminho até o arquivo `.ear` (caso o projeto utilize EAR).


    > ⚠️ Esses caminhos devem ser ajustados manualmente de acordo com sua estrutura de projeto.

3. **Atualize o nome da aplicação no Payara:**

   Nas opções `deploy`, `undeploy` e `reset-build`, altere o valor da variável referente ao **nome da aplicação no Payara Server**. Esse nome será utilizado para referenciar a aplicação durante as operações.