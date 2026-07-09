# check=skip=SecretsUsedInArgOrEnv
# ^ Diretiva de parser (PRECISA ser a 1a linha): silencia o falso positivo do
#   linter. ANSIBLE_HOST_KEY_CHECKING nao e um segredo (o nome apenas contem
#   "KEY"), e uma flag de comportamento do Ansible.

# ansible-cisco — ambiente de automação de rede Cisco com Ansible
# Base estável e pinada. Ubuntu 22.04 (Jammy).


FROM ubuntu:22.04

# ---------------------------------------------------------------------------
# Metadados
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="ansible-cisco" \
      org.opencontainers.image.description="Ansible + collections Cisco (IOS/IOS XE/NX-OS) com suporte a SSH moderno e legado" \
      org.opencontainers.image.source="https://example.local/ansible-cisco"

# ---------------------------------------------------------------------------
# Variáveis de ambiente
#  - Evita prompts interativos do apt.
#  - Ajustes de Ansible para rede (host key checking desligado, timeouts).
#  - paramiko como tipo de SSH padrão: mais tolerante a dispositivos legados.
# ---------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_NETWORK_CLI_SSH_TYPE=paramiko \
    ANSIBLE_PERSISTENT_COMMAND_TIMEOUT=60 \
    ANSIBLE_PERSISTENT_CONNECT_TIMEOUT=60 \
    ANSIBLE_COLLECTIONS_PATH=/opt/ansible/collections \
    ANSIBLE_CONFIG=/ansible/ansible.cfg

# ---------------------------------------------------------------------------
# 1) Dependências de SISTEMA (apt) — apenas o necessário, numa única camada.
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        openssh-client \
        sshpass \
        ca-certificates \
        libssl-dev \
        libffi-dev \
        libssh-dev \
        build-essential \
        gcc \
        iputils-ping \
        telnet \
        netcat-openbsd \
        dnsutils \
        less \
        vim && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Usuário não-root e diretórios de trabalho.
# As collections ficam em /opt/ansible/collections (legível por todos).
# ---------------------------------------------------------------------------
RUN groupadd --gid 1000 ansible && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash ansible && \
    mkdir -p /ansible /opt/ansible/collections && \
    chown -R ansible:ansible /ansible /opt/ansible

WORKDIR /ansible

# ---------------------------------------------------------------------------
# 2) Dependências PYTHON (pip) — instala Ansible e libs de rede pinadas.
# ---------------------------------------------------------------------------
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

# ---------------------------------------------------------------------------
# 3) Collections ANSIBLE (galaxy) — instaladas em caminho compartilhado.
# ---------------------------------------------------------------------------
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml \
        -p /opt/ansible/collections && \
    rm -f /tmp/requirements.yml && \
    chown -R ansible:ansible /opt/ansible

# ---------------------------------------------------------------------------
# Configuração padrão do Ansible e SSH.
# São copiados para dentro da imagem para funcionar mesmo sem volumes;
# em uso normal, o docker-compose sobrepõe estes arquivos via bind mount.
# ---------------------------------------------------------------------------
COPY --chown=ansible:ansible ansible.cfg /ansible/ansible.cfg
COPY --chown=ansible:ansible ssh/config  /home/ansible/.ssh/config
RUN chmod 700 /home/ansible/.ssh && chmod 600 /home/ansible/.ssh/config && \
    chown -R ansible:ansible /home/ansible/.ssh

USER ansible

# Shell interativo por padrão — este é um container de trabalho.
CMD ["/bin/bash"]
