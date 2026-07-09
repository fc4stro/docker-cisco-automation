# ansible-cisco

Container Docker para automação de dispositivos de rede **Cisco** (IOS, IOS XE,
NX-OS) com **Ansible**. Vem pronto com as collections Cisco, bibliotecas Python
de rede e suporte a SSH **moderno e legado** — sem prompts interativos de aceite
de chave nos primeiros testes.

## Índice

- [Estrutura do projeto](#estrutura-do-projeto)
- [O que vem na imagem](#o-que-vem-na-imagem)
- [Pré-requisitos](#pré-requisitos)
- [Build](#build)
- [Configuração (credenciais e inventário)](#configuração-credenciais-e-inventário)
- [Executar o container](#executar-o-container)
- [Testar conexão com os dispositivos](#testar-conexão-com-os-dispositivos)
- [SSH legado (ciphers/kex antigos)](#ssh-legado-cipherskex-antigos)
- [Variáveis de ambiente](#variáveis-de-ambiente)
- [Volumes](#volumes)
- [Boas práticas de segurança e manutenção](#boas-práticas-de-segurança-e-manutenção)
- [Problemas conhecidos de SSH legado](#problemas-conhecidos-de-ssh-legado)

## Estrutura do projeto

```text
.
├── Dockerfile              # imagem Ubuntu 22.04 + Ansible + libs + collections
├── docker-compose.yml      # execução com volumes (Compose v2)
├── .dockerignore           # protege secrets e reduz o contexto de build
├── .gitignore
├── .env.example            # modelo de credenciais (copie para .env)
├── requirements.txt        # dependências Python (pinadas)
├── requirements.yml        # collections Ansible (galaxy)
├── ansible.cfg             # configuração padrão do Ansible
├── Makefile                # atalhos: build/run/ping/test/...
├── inventory/
│   └── hosts.ini           # grupos ios / iosxe / nxos / legacy
├── group_vars/
│   ├── all.yml             # credenciais via env, conexão network_cli
│   ├── ios.yml             # ansible_network_os = cisco.ios.ios
│   ├── iosxe.yml           # IOS XE usa a collection cisco.ios
│   ├── nxos.yml            # ansible_network_os = cisco.nxos.nxos
│   └── legacy.yml          # SSH legado escopado por grupo
├── playbooks/
│   └── test_connection.yml # coleta facts e imprime hostname/versão
└── ssh/
    └── config              # StrictHostKeyChecking no + legado por host
```

## O que vem na imagem

- **Base:** `ubuntu:22.04` (pinada), usuário não-root `ansible`, `WORKDIR /ansible`.
- **Ansible** (via pip) + collections `cisco.ios`, `cisco.nxos`,
  `ansible.netcommon`, `ansible.utils`.
- **Libs Python:** paramiko, ansible-pylibssh, netmiko, ncclient, textfsm,
  ntc-templates, jmespath.
- **Ferramentas de rede:** ping, telnet, netcat, dig/nslookup, ssh, sshpass.

As dependências são separadas em três camadas: **sistema** (apt no Dockerfile),
**Python** (`requirements.txt`) e **collections** (`requirements.yml`).

## Pré-requisitos

- Docker Engine com o plugin **Compose v2** (`docker compose ...`).

## Build

```bash
# via Docker
docker build -t ansible-cisco .

# ou via Compose
docker compose build

# ou via Makefile
make build
```

## Configuração (credenciais e inventário)

1. **Credenciais** — nunca vão no código. Copie o modelo e preencha:

   ```bash
   cp .env.example .env
   # edite .env: ANSIBLE_NET_USERNAME / ANSIBLE_NET_PASSWORD
   ```

2. **Inventário** — edite `inventory/hosts.ini` com os IPs/hosts reais do seu lab
   (grupos `ios`, `iosxe`, `nxos`, `legacy`).

3. **Variáveis por grupo** — ajuste `group_vars/*.yml` se necessário (enable,
   tipo de SSH, etc.).

## Executar o container

```bash
# shell interativo no container (com volumes montados)
docker compose run --rm ansible-cisco
# ou: make run

# rodar um comando único
docker compose run --rm ansible-cisco ansible --version

# sem compose (montando volumes manualmente)
docker run -it --rm \
  --env-file .env \
  -v "$(pwd)/playbooks:/ansible/playbooks" \
  -v "$(pwd)/inventory:/ansible/inventory" \
  -v "$(pwd)/group_vars:/ansible/group_vars" \
  -v "$(pwd)/ansible.cfg:/ansible/ansible.cfg:ro" \
  -v "$(pwd)/ssh/config:/home/ansible/.ssh/config:ro" \
  ansible-cisco
```

## Testar conexão com os dispositivos

```bash
# 1) Sanity da imagem (não precisa de dispositivos)
make versions        # ansible --version
make collections     # lista cisco.ios, cisco.nxos, ansible.netcommon, ansible.utils
make libs            # importa netmiko/paramiko/ncclient/textfsm/jmespath
make syntax          # --syntax-check do playbook

# 2) Contra os dispositivos do inventário
make ping                       # ansible cisco -m ping
make test                       # roda playbooks/test_connection.yml
make test LIMIT=nxos            # apenas o grupo nxos

# equivalentes diretos
docker compose run --rm ansible-cisco ansible cisco -m ping
docker compose run --rm ansible-cisco ansible-playbook playbooks/test_connection.yml --limit ios

# 3) Teste SSH cru (valida algoritmos, útil para host legado)
docker compose run --rm ansible-cisco ssh -F /home/ansible/.ssh/config rtr-legacy-01
```

## SSH legado (ciphers/kex antigos)

Equipamentos antigos podem exigir algoritmos que o OpenSSH moderno desativa por
padrão. Este projeto trata isso de **duas formas**, priorizando a mais segura:

1. **Por host (padrão, recomendado)** — em `group_vars/legacy.yml`
   (`ansible_ssh_common_args`) e em `ssh/config` (bloco `Host rtr-legacy-01`).
   Só os hosts legados usam SSH enfraquecido; o resto permanece seguro.

2. **Global (opcional, desencorajado)** — há um bloco `Host *` **comentado** no
   fim de `ssh/config`. Descomente **apenas** se a maioria dos equipamentos for
   legada e você aceitar o risco de enfraquecer o SSH para todos.

> ⚠️ Algoritmos como `diffie-hellman-group1-sha1`, `ssh-rsa` e `3des-cbc` são
> fracos/obsoletos. Use somente em labs ou redes controladas.

## Variáveis de ambiente

Já definidas na imagem (podem ser sobrescritas via `.env`):

| Variável | Valor padrão | Função |
|---|---|---|
| `ANSIBLE_HOST_KEY_CHECKING` | `False` | não pede aceite de chave SSH |
| `ANSIBLE_NETWORK_CLI_SSH_TYPE` | `paramiko` | transporte SSH tolerante a legado |
| `ANSIBLE_PERSISTENT_COMMAND_TIMEOUT` | `60` | timeout de comando |
| `ANSIBLE_PERSISTENT_CONNECT_TIMEOUT` | `60` | timeout de conexão |
| `ANSIBLE_CONFIG` | `/ansible/ansible.cfg` | caminho do ansible.cfg |
| `ANSIBLE_COLLECTIONS_PATH` | `/opt/ansible/collections` | onde as collections estão |

Credenciais (via `.env`): `ANSIBLE_NET_USERNAME`, `ANSIBLE_NET_PASSWORD`,
`ANSIBLE_NET_AUTH_PASS` (enable, opcional).

## Volumes

| Host | Container | Modo |
|---|---|---|
| `./playbooks` | `/ansible/playbooks` | rw |
| `./inventory` | `/ansible/inventory` | rw |
| `./group_vars` | `/ansible/group_vars` | rw |
| `./ansible.cfg` | `/ansible/ansible.cfg` | ro |
| `./ssh/config` | `/home/ansible/.ssh/config` | ro |
| `~/.ssh/id_rsa` (opcional) | `/home/ansible/.ssh/id_rsa` | ro |

## Boas práticas de segurança e manutenção

- **Sem secrets hardcoded**: credenciais via `.env`/variáveis de ambiente ou
  `ansible-vault`. `.env`, chaves e `*.pem` estão no `.dockerignore`/`.gitignore`.
- **Usuário não-root** dentro do container.
- **Versões pinadas** (base, pip, collections) para builds reprodutíveis.
- **SSH legado escopado por host**; global apenas por decisão consciente.
- Reconstrua a imagem periodicamente para atualizações de segurança do apt.

## Problemas conhecidos de SSH legado

| Erro | Causa | Correção |
|---|---|---|
| `Unable to negotiate ... no matching key exchange method found` | kex antigo desativado | adicionar `KexAlgorithms +diffie-hellman-group14-sha1` (ou `group1`) no host |
| `no matching host key type found. Their offer: ssh-rsa` | host key RSA-SHA1 | `HostKeyAlgorithms +ssh-rsa` e `PubkeyAcceptedAlgorithms +ssh-rsa` |
| `no matching cipher found` | cipher CBC/3DES antigo | `Ciphers +aes128-cbc,3des-cbc` |
| Prompt "Are you sure you want to continue connecting" | known_hosts vazio | já resolvido por `StrictHostKeyChecking no` + `UserKnownHostsFile /dev/null` |
| Conexão trava/nega com libssh | dispositivo muito antigo | usar `ansible_network_cli_ssh_type=paramiko` (padrão) |

Todos os ajustes de algoritmo acima já têm exemplo pronto em
`ssh/config` (por host) e `group_vars/legacy.yml`.
