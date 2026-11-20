# cPanel Email Password Auto-Changer (`cp-changemail-pass.sh`)

![Capa do cPanel Email Password Auto-Changer](./cp-changemail-pass-cover.webp)

[![Versão](https://img.shields.io/badge/version-2.0.0-blue.svg)](./cp-changemail-pass.sh)
[![Licença](https://img.shields.io/badge/license-Apache--2.0-green.svg)](./LICENSE)
[![Plataforma](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel%20%2F%20WHM%20%7C%20UAPI-orange.svg)](#requisitos)

> 🇺🇸 **[Read in English (README.md)](./README.md)**

O **cPanel Email Password Auto-Changer** (`cp-changemail-pass.sh` v2.0.0) é uma ferramenta CLI em Bash para automatizar a troca individual ou em lote de senhas de contas de e-mail em servidores cPanel/WHM via UAPI `Email passwd_pop`. Possui geração segura de senhas via CSPRNG (OpenSSL), processamento por arquivo de lote, rotação de domínio completo, simulação dry-run, mascaramento de senhas e relatórios em `table`, `json` ou `csv`.

---

## Funcionalidades

- **Troca Individual ou em Lote:** Altere um único e-mail (`-e`), processe uma lista em arquivo (`-f`) ou rotacione todas as contas de um domínio (`-d`).
- **Geração Segura via CSPRNG:** Gera senhas alfanuméricas de 16 caracteres (customizável via `-l`) utilizando OpenSSL ou `/dev/urandom`, evitando caracteres que quebram clientes de e-mail. Permite também definir senha fixa com `-p`.
- **Modo Simulação Dry-Run (`-n, --dry-run`):** Valida formato de e-mail, dono da conta e existência sem alterar credenciais em produção.
- **Segurança e Privacidade:** Permite mascarar senhas na tela (`--mask-passwords`) para gravações/demonstrações e exportar para arquivo CSV seguro (`-s, --save-csv`) com permissão restrita `chmod 600`.
- **Saídas Estruturadas para Automação:** Relatórios em `table` (padrão), `json` ou `csv`. Retorna exit code `0` em sucesso e `2` se alguma alteração falhar.

---

## Requisitos

- Linux com Bash 4.0+ e Python 3.6+
- Servidor cPanel & WHM com `/usr/bin/uapi` e `/scripts/whoowns`
- Acesso root ou privilégios de usuário da conta cPanel

---

## Instalação

```bash
git clone https://github.com/sr00t3d/cpanel-changemail-pass.git
cd cpanel-changemail-pass
chmod +x cp-changemail-pass.sh
```

---

## Como usar

```bash
# Alterar senha de um único e-mail gerando senha segura:
sudo ./cp-changemail-pass.sh -e admin@example.com

# Simular em dry-run uma rotação em lote a partir de arquivo:
sudo ./cp-changemail-pass.sh -f emails.txt --dry-run

# Rotacionar todos os e-mails de um domínio e salvar credenciais em CSV seguro:
sudo ./cp-changemail-pass.sh -d example.com -s /root/senhas.csv

# Mascarar senhas na tela do terminal:
sudo ./cp-changemail-pass.sh -e admin@example.com --mask-passwords

# Exportar relatório em JSON:
sudo ./cp-changemail-pass.sh -f emails.txt -o json
```

### Opções da CLI

| Opção | Descrição |
| :--- | :--- |
| `-e, --email <endereço>` | E-mail de destino único |
| `-f, --file <caminho>` | Arquivo com lista de e-mails (um por linha) |
| `-d, --domain <domínio>` | Rotaciona todas as contas sob o domínio |
| `-u, --user <usuário>` | Usuário cPanel explícito (pula detecção automática) |
| `-p, --password <senha>` | Senha fixa para todas as contas processadas |
| `-l, --length <int>` | Tamanho da senha gerada (padrão: 16, mín: 12) |
| `-n, --dry-run` | Modo de simulação (nenhuma alteração é feita) |
| `--mask-passwords` | Mascara as senhas no terminal (`********`) |
| `-s, --save-csv <path>` | Salva mapeamento em arquivo seguro (`chmod 600`) |
| `-o, --output <fmt>` | Formato de saída: `table` (padrão), `json`, `csv` |
| `-q, --quiet` | Suprime mensagens de progresso |
| `--no-color` | Desativa cores ANSI |
| `-V, --version` | Exibe a versão e encerra |
| `-h, --help` | Exibe a ajuda e encerra |

---

## Exemplo de Saída Real

Capturado em container AlmaLinux 8.10 / cPanel executando lote em modo dry-run sobre 4 contas de teste (2 válidas simuladas, 1 com sintaxe inválida, 1 com domínio não registrado):

```text
================================================================================================================
 CPANEL EMAIL PASSWORD CHANGER v2.0.0 | Mode: DRY-RUN | Targets: 4
================================================================================================================
EMAIL                            | USER         | PASSWORD                 | STATUS     | NOTE
----------------------------------------------------------------------------------------------------------------
admin@example.com                | cpaneluser   | GPCeCALKgzn6mGFP         | SIMULATED  | Dry-run (no changes made)
support@example.com              | cpaneluser   | CUgcSf16aBEoYgeV         | SIMULATED  | Dry-run (no changes made)
invalid-email-format             | none         | 9gLnu9VfvR6IJCsg         | FAILED     | Invalid email format
billing@unregistered-domain-999. | none         | 8YhVEdfUdWnSbOFJ         | FAILED     | Domain not registered on server
================================================================================================================
 Summary: 4 processed | Success/Simulated: 2 | Failed: 2
================================================================================================================
```

---

## Licença

Distribuído sob a [Licença Apache-2.0](./LICENSE).
