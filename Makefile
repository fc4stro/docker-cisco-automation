# Atalhos para build/execução/teste do container ansible-cisco.
IMAGE ?= ansible-cisco:latest
LIMIT ?=

.PHONY: help build run ping test syntax lint versions collections libs clean

help: ## Lista os alvos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Constrói a imagem Docker
	docker build -t $(IMAGE) .

run: ## Abre um shell interativo no container
	docker compose run --rm ansible-cisco

ping: ## ansible -m ping (sanity do inventário/execução)
	docker compose run --rm ansible-cisco ansible cisco -m ping $(if $(LIMIT),--limit $(LIMIT),)

test: ## Executa o playbook de teste de conexão
	docker compose run --rm ansible-cisco \
		ansible-playbook playbooks/test_connection.yml $(if $(LIMIT),--limit $(LIMIT),)

syntax: ## Checagem de sintaxe do playbook (sem dispositivos)
	docker compose run --rm ansible-cisco \
		ansible-playbook playbooks/test_connection.yml --syntax-check

versions: ## Mostra versão do Ansible/Python
	docker run --rm $(IMAGE) ansible --version

collections: ## Lista as collections instaladas
	docker run --rm $(IMAGE) ansible-galaxy collection list

libs: ## Valida import das libs Python de rede
	docker run --rm $(IMAGE) python3 -c "import netmiko, paramiko, ncclient, textfsm, jmespath; print('libs OK')"

clean: ## Remove a imagem local
	-docker rmi $(IMAGE)
