Preciso de um planejamento técnico para criação de um container Docker chamado **ansible-cisco**, com foco em automação de dispositivos de networking Cisco usando Ansible.

O objetivo é construir uma imagem Docker simples, reutilizável e preparada para laboratórios e automações de rede, contendo o Ansible instalado via:

```bash
pip3 install ansible
```

A imagem deve incluir todas as bibliotecas necessárias para conexão com dispositivos de networking, incluindo:

* Cisco IOS
* Cisco IOS XE
* Cisco NX-OS
* Equipamentos Cisco legados
* Equipamentos que utilizam SSH moderno
* Equipamentos que ainda dependem de SSH/ciphers antigos

O container deve suportar conexões SSH com algoritmos modernos e antigos, incluindo ajustes para aceitar ciphers, key exchange algorithms e host key algorithms legados quando necessário.

O projeto deve contemplar a instalação e configuração das collections do Ansible necessárias para automação de rede, como:

```bash
ansible-galaxy collection install cisco.ios
ansible-galaxy collection install cisco.nxos
ansible-galaxy collection install ansible.netcommon
ansible-galaxy collection install ansible.utils
```

Também deve incluir bibliotecas Python normalmente utilizadas para conexões de rede, como:

```bash
paramiko
ansible-pylibssh
netmiko
ncclient
textfsm
ntc-templates
jmespath
```

O container deve possuir uma configuração padrão do Ansible, usando um arquivo `ansible.cfg`, com boas práticas para ambiente de laboratório e automação inicial, incluindo:

```ini
[defaults]
host_key_checking = False
retry_files_enabled = False
inventory = ./inventory
timeout = 30
interpreter_python = auto_silent

[persistent_connection]
connect_timeout = 60
command_timeout = 60
connect_retry_timeout = 30
```

Também deve ser avaliada a configuração de variáveis de ambiente, como:

```bash
ANSIBLE_HOST_KEY_CHECKING=False
ANSIBLE_NETWORK_CLI_SSH_TYPE=paramiko
ANSIBLE_PERSISTENT_COMMAND_TIMEOUT=60
ANSIBLE_PERSISTENT_CONNECT_TIMEOUT=60
```

O projeto deve prever que, nos primeiros testes de conexão com switches e roteadores, não seja necessário aceitar manualmente chaves SSH ou responder prompts interativos. A solução deve negar o `host_key_checking` e implementar configurações conhecidas para evitar falhas comuns em ambientes Cisco.

O planejamento deve entregar:

1. Estrutura sugerida do projeto
2. Dockerfile completo
3. requirements.txt
4. ansible.cfg
5. Exemplo de inventory para Cisco IOS, IOS XE e NX-OS
6. Exemplo de playbook simples para teste de conexão
7. Comandos para build da imagem Docker
8. Comandos para executar o container
9. Comandos para testar conexão com os dispositivos
10. Boas práticas de segurança e manutenção
11. Possíveis problemas conhecidos com SSH legado e como corrigir

A solução deve seguir boas práticas de Docker, incluindo:

* Uso de imagem base estável
* Instalação mínima de pacotes necessários
* Criação de usuário não-root, se aplicável
* Uso de `.dockerignore`
* Separação clara entre dependências do sistema, dependências Python e collections Ansible
* Evitar secrets hardcoded
* Documentar variáveis de ambiente e volumes
* Permitir reutilização em diferentes projetos de automação de rede

O resultado esperado é um projeto Docker funcional para automação Cisco com Ansible, preparado para conexões SSH modernas e legadas, com foco em simplicidade, compatibilidade e facilidade de uso.
