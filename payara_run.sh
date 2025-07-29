#!/bin/bash
#
# payara_run.sh
#
# Autor:
# Matheus Dias de Queiroz
#
# Versão 1.2: 25/08/24 - Matheus:
#	- Criando menu de ajuda das opções disponíveis
#	- Adicionando melhoria na configuração dos caminhos utilizados
#	- Adicionando opções -h, -v, -c, -u, -r
#
# Versão 1.3: 27/08/24 - Matheus:
# 	- Adicionando validações de payara já online
#	- Adicionando opção -o, -l
#
# Versão 1.3.1: 30/08/24 - Matheus:
#	- Melhorando como é printado mensagens coloridas
#	- Retirando print da saida dos greps (-q)
#	- Melhorando o processo de encerrar o processo do payara,
#	onde acontecia de matar a execução do arquivo e travar a opção de reset
#
# Versão 1.3.2: 04/09/24 - Matheus:
# 	- Adicionando saidas melhores para diferenciar qual processo está sendo
#	feito deploy/undeploy
#
# Versão 1.4: 12/09/24 - Matheus
# 	- Adicionando mapeamento para criação de função de build
#	- Criando função de build do projeto
# 	- Criando opção -rb
#
# Versão 1.5: 04/10/24 - Matheus
# 	- Corrigindo alias para o script funcionar em qualquer lugar do sistema
#	- Melhorando opção -rb para fazer undeploy, build e deploy de todos os projetos na sequencia correta
#
# Versão 1.5.2: 19/12/24 - Matheus
#	- Removendo relatório de build do maven, agora só mostrará log quando houver erros
#
# Versão 1.5.5: 27/03/25 - Matheus
#	- Corrigindo como é pego o processo do payara para verificar se está ativo

#Constates utilizadas
# Definindo cores
NA='\033[0m'
VERMELHO='\033[0;31m'
VERMELHO(){
	echo -e "$VERMELHO$1$NA";
}
AMARELO='\033[1;33m'
AMARELO(){
	echo -e "$AMARELO$1$NA";
}
VERDE='\033[0;32m'
VERDE(){
	echo -e "$VERDE$1$NA";
}
AZUL='\033[0;34m'
AZUL(){
	echo -e "$AZUL$1$NA";
}
MAGENTA='\033[0;35m'
MAGENTA(){
	echo -e "$MAGENTA$1$NA";
}
CIANO='\033[0;36m'
CIANO(){
	echo -e "$CIANO$1$NA";
}

MENSAGEM_HELP="
 -h, --help 		Mostra tela de ajuda
 -v, --version 		Mostra versão atual do programa
 -c, --config		Reseta configuração dos arquivos, sendo necessário reinformar os caminhos do projeto
 -d, --deploy		Faz deploy em todos os projetos base, passando argumentos poderá escolher qual projeto será feito deploy
 -u, --undeploy		Faz undeploy em todos os projetos ativos, passando argumentos poderá escolher qual projeto será feito undeploy
 -r, --reset 		Reseta apenas o payara, mantém os projetos que estão ativos
 -rb, --reset-build Faz undeploy, build e deploy do projeto especificado ou de uma lista de projetos, na sequencia informada
 -o, --out 		Utiliza o comando less no log do payara
 -l, --list 		Lista todos os projetos ativos no payara
";

HELP_UNDEPLOY="Utilizando o -u app será feito o undeploy apenas da aplicação solicitada, podendo ser extendida por mais de um argumento
$MAGENTA Exemplo: $NA
	-u birt - Será feito o undeploy apenas da aplicação birt
	-u birt exemplo - Será feito o undeploy das aplicações birt, logo após exemplo
";

HELP_DEPLOY="Utilizando o -d app será feito o deploy apenas da aplicação solicitada, podendo ser extendida por mais de um argumento
$MAGENTA Exemplo: $NA
	-d birt - Será feito o deploy apenas da aplicação birt
	-d birt exemplo - Será feito o deploy das aplicações birt, logo após exemplo

$VERMELHO Atenção: Será feito na sequência passada por parâmetro, logo, se houver dependências de sequência, a mesma deve ser respeitada. $NA
";

# Quantidade de threads disponiveis para o build
THREAD_COUNT="3C"

### DIRETORIOS ###
HOME="/home/matheus";
SCRIPT_DIR=$(realpath "$0");

# Diretorio onde o Payara está instalado
PAYARA="/home/matheus/payara5";
CAMINHO_PAYARA_ADMIN="$PAYARA/bin/asadmin";
CAMINHO_LOG_PAYARA="$PAYARA/glassfish/domains/domain1/logs/server.log";

# Diretorio onde estão os projetos
# Configurado pelo usuário
CAMINHO_PROJETOS="/home/matheus/Projetos";

CAMINHO_PROJETOS_EXEMPLO="/home/matheus/Projetos/ProjetoExemplo"
CAMINHO_PROJETOS_EXEMPLO_EAR="/home/matheus/Projetos/ProjetoExemplo/target"

## Sequencia de build dos projetos, para alterar basta alterar a sequencia dos projetos
SEQUENCIA_BUILD_PROJETOS=(
	CAMINHO_PROJETOS_EXEMPLO
);

## Sequencia deploy projetos, para alterar basta alterar a sequencia dos projetos
SEQUENCIA_DEPLOY_PROJETOS=(
	CAMINHO_PROJETOS_EXEMPLO
)

# Caminho bashrc
BASHRC="$HOME/.bashrc"


validaExistenciaCaminhos(){
	# Validando
	if [ -z "$CAMINHO_PROJETOS" ]; then
		echo -e "O caminho do projeto está vazia."
		read -p "Por favor, insira um novo valor para o caminho dos projetos: Exemplo: /home/usuario/Projeto: " VALOR;
		VALOR_TRATADO=$(echo "$VALOR" | sed 's/\//\\\//g');
		sed -i "s/^CAMINHO_PROJETOS=.*/CAMINHO_PROJETOS=\"$VALOR_TRATADO\"/" "$0";
	fi

	if [ -z "$PAYARA" ]; then
		read -p "A variável de caminho do payara está vazia. Por favor, insira onde está instalado: " VALOR
		VALOR_TRATADO=$(echo "$VALOR" | sed 's/\//\\\//g');
		sed -i "s/^PAYARA=.*/PAYARA=\"$VALOR_TRATADO\"/" "$0";
	fi

	if [ -z "$HOME" ]; then
		read -p "A variável de caminho da home está vazia. Por favor, insira o caminho da home: " VALOR
		VALOR_TRATADO=$(echo "$VALOR" | sed 's/\//\\\//g');
		sed -i "s/^HOME=.*/HOME=\"$VALOR_TRATADO\"/" "$0";
	fi

	if [ -z "$THREAD_COUNT" ]; then
		read -p "A variável do thread count está vazia. Por favor, insira a quantidade de threads a serem utilizadas no build: " VALOR
		VALOR_TRATADO=$(echo "$VALOR" | sed 's/\//\\\//g');
		VALOR_TRATADO="$VALOR_TRATADO""C";
		sed -i "s/^THREAD_COUNT=.*/THREAD_COUNT=\"$VALOR_TRATADO\"/" "$0";
	fi

	grep -q "^alias payara_run=" "$BASHRC" || {
		echo "alias payara_run=\"$SCRIPT_DIR\"" >> "$BASHRC";
		echo "A constante payara_run foi adicionada ao .bashrc.";
	}
}

validaPayaraOn(){
	if ps aux | grep -v grep | grep -v "$0" | grep -q "domain1"; then
		echo -e $(VERDE "Payara está online");
	else
		echo -e $(VERMELHO "Payara está offline");
		echo -e $(VERDE "Dando start no Payara");
		$CAMINHO_PAYARA_ADMIN start-domain --debug;
	fi
}

getProjetoDoDiretorio(){
	string_inversa=$(echo "$project_dir" | rev);
	substring=$(echo "$string_inversa" | cut -d'/' -f1);
	projeto=$(echo "$substring" | rev);
	echo -e $(MAGENTA "$projeto");
}

buildaProjeto(){
	local project_dir="$1"
    if [ -f "$project_dir/pom.xml" ]; then
        echo -e $(MAGENTA "Executando o clean install em")
		getProjetoDoDiretorio;
        (cd "$project_dir" && mvn clean install -U -q -T "$THREAD_COUNT")
        if [ $? -ne 0 ]; then
            echo "Erro ao executar mvn clean install em $project_dir"
            exit 1
        fi
    else
        echo "pom.xml não encontrado em $project_dir"
    fi
}

undeployProjetosAtivos(){
	# Recupera as aplicações ativas e faz undeploy em todas
	for app in $($CAMINHO_PAYARA_ADMIN list-applications | awk '{print $1}' | head -n -1)
	do
	  echo -e $(MAGENTA "$app");
		$CAMINHO_PAYARA_ADMIN undeploy $app
	done
}

deploySequenciaProjetos(){
	for app in "${SEQUENCIA_DEPLOY_PROJETOS[@]}"
	do
		$CAMINHO_PAYARA_ADMIN deploy $app;
	done
}

validaExistenciaCaminhos;
## Menu de parâmetros
case "$1" in
	-h | --help)
		if [ -z "$2" ]; then
			echo "$MENSAGEM_HELP";
		else
			case "$2" in
				-u | --undeploy)
					echo -e "$HELP_UNDEPLOY";
				;;

				-d | --deploy)
					echo -e "$HELP_DEPLOY";
				;;

				*)
					echo -e $(VERMELHO "Opção inválida para help $2");
				;;
			esac
		fi
		exit 0;
	;;

	-v | --version)
		echo -n $(basename "$0");
		grep '^# Versão ' "$0" | tail -1 | cut -d : -f 1 | tr -d \#;
		exit 0;
	;;

	-c | --config)
		sed -i "s/^CAMINHO_PROJETOS=.*/CAMINHO_PROJETOS=\"\"/" "$0";
		sed -i "s/^PAYARA=.*/PAYARA=\"\"/" "$0";
		sed -i "s/^THREAD_COUNT=.*/THREAD_COUNT=\"\"/" "$0";
		validaExistenciaCaminhos;
	;;

	-d | --deploy)
		validaPayaraOn;
		echo -e $(CIANO "Fazendo deploy do payara");
		if [ -z "$2" ]; then
			deploySequenciaProjetos;
		else
			#pega todos os argumentos que vierem a partir do $2
			shift
			LISTA=("$@");

			for app in "${LISTA[@]}"
			do
				case $app in
					exemplo)
						echo -e $(MAGENTA "Detran:");
						$CAMINHO_PAYARA_ADMIN deploy $CAMINHO_PROJETOS_EXEMPLO;
					;;
					*)
						echo -e $(VERMELHO "Projeto inválido");
						exit 1;
					;;
				esac
			done
		fi
	;;

	-u | --undeploy)
		validaPayaraOn;
		echo -e $(CIANO "Fazendo undeploy do payara");

		if [ -z "$2" ] && ps aux | grep -v grep | grep -v "$0" | grep -q "domain1"; then
			undeployProjetosAtivos;
		else
			## fazer parte que tem lista de exceção de undeploy
			#pega todos os argumentos que vierem a partir do $2
			shift
			LISTA=("$@");

			# Faz undeploy das aplicações que foram passadas por parâmetro
			for app in "${LISTA[@]}"
			do
				case $app in
					exemplo)
						echo -e $(MAGENTA "Exemplo:");
						$CAMINHO_PAYARA_ADMIN undeploy exemplo;
					;;
					*)
						echo -e $(VERMELHO "Projeto inválido");
						exit 1;
					;;
				esac
			done
		fi
	;;

	-r | --reset)

		if [ -z $(ps aux | grep 'domain1' | grep -v 'grep' | grep -v "$0" | awk '{print $2}') ]; then
			echo -e $(VERDE "Não existe processo do payara ativo");
		else
			echo -e $(VERMELHO "Finalizando o processo do payara");
			kill -9 $(ps aux | grep 'domain1' | grep -v 'grep' | grep -v "$0" | awk '{print $2}')
		fi

		validaPayaraOn
	;;

	-rb | --reset-build)
		validaPayaraOn
		if [ -z "$2" ] ; then
			undeployProjetosAtivos;
			for project in "${SEQUENCIA_BUILD_PROJETOS[@]}"; do
			    buildaProjeto $project;
			done
			deploySequenciaProjetos;
		else
			shift
			LISTA=("$@");

			# Faz undeploy das aplicações que foram passadas por parâmetro
			for app in "${LISTA[@]}"
			do
				case $app in
					exemplo)
						echo -e $(MAGENTA "Exemplo:");
						$CAMINHO_PAYARA_ADMIN undeploy exemplo;
						buildaProjeto "$CAMINHO_CAMINHO_PROJETOS_EXEMPLO";
						$CAMINHO_PAYARA_ADMIN deploy $CAMINHO_CAMINHO_PROJETOS_EXEMPLO_EAR;
					;;
					*)
						echo -e $(VERMELHO "Projeto inválido");
						exit 1;
					;;
					esac
				done
		fi
	;;

	-o| --out)
		less $CAMINHO_LOG_PAYARA;
	;;

	-l | --list)
		$CAMINHO_PAYARA_ADMIN list-applications;
	;;

	*)
		if [ -n "$1" ]; then
			echo -e $(VERMELHO "Opção inválida $1");
			echo -e $(VERDE "Utilize o comando -h ou --help para ajuda");
			exit 1;
		fi
	;;
esac