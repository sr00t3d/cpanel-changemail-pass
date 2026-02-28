#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   cPanel Reseller Usage v1.0.1                                            ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Author:   Percio Castelo                                                ║
# ║   Contact:  percio@evolya.com.br | contato@perciocastelo.com.br           ║
# ║   Web:      https://perciocastelo.com.br                                  ║
# ║                                                                           ║
# ║   Function: Automate changing email passwords on WHM/cPanel servers.      ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

if [[ -z "$1" ]]; then
    echo "[!] - Usage mode: cp-changemail-pass.sh email@domain.com.br"
    exit 1
fi

EMAIL=$1

function verificaOpenssl(){ 
    # Validates openssl
    if ! command -v openssl >/dev/null 2>&1; then
        echo "[!] - The script requires OpenSSL to function"
        exit 1
    fi
}

# Generates a 16-character password using only letters and numbers to avoid issues in email clients
SENHA=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 16)

function verificaEmail(){
    # Validates the variable
    if [[ -z "${EMAIL}" ]]; then
        echo "[!] - The email cannot be blank"
        exit 1
    fi

    # Validates the email
    if [[ ! ${EMAIL} =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "[!] - The email ${EMAIL} is invalid"
        exit 1
    fi
}

function verificaSenha(){
    if [[ -z "${SENHA}" ]]; then
        echo "[!] - There was a problem generating the password"
        exit 1
    fi
}

# Calls the functions
verificaOpenssl
verificaEmail
verificaSenha

# Gets the domain via $EMAIL after the @
DOMINIO=${EMAIL#*@}

# Checks the $DOMINIO variable
if [[ -z "${DOMINIO}" ]]; then
    echo "[!] - There was a problem obtaining the domain"
    exit 1
fi

# Checks if the domain resolves
if ! getent hosts "${DOMINIO}" >/dev/null; then
    echo "[!] - Domain ${DOMINIO} does not resolve"
fi

# Checks if the domain is registered
if grep -iE "^${DOMINIO}:" /etc/trueuserdomains >/dev/null; then
    echo "Domain ${DOMINIO} is registered on the server"
else
    echo "[!] Domain ${DOMINIO} is NOT registered on the server"
    exit 1
fi

# Gets the domain user
USUARIO=$(/scripts/whoowns "${DOMINIO}")
if [[ -z "${USUARIO}" ]]; then
    echo "[!] - There was a problem obtaining the domain user."
    exit 1
fi

# Checks existence of the email (using list_pops, without fragile parsing)
if ! uapi --user="${USUARIO}" Email list_pops domain="${DOMINIO}" | grep -qF "${EMAIL}"; then
    echo "[!] - The email ${EMAIL} does not exist on the server."
    exit 1
fi

# Isolates only the email prefix (before @) to correctly send to cPanel
PREFIXO=${EMAIL%@*}

# Executes the password change using uapi sending only $PREFIXO in the email parameter
RESPONSE=$(uapi --user="${USUARIO}" Email passwd_pop email="${PREFIXO}" domain="${DOMINIO}" password="${SENHA}" --output=json)
status=$(echo "$RESPONSE" | grep -oP '"status":\s*\K\d+')

if [[ -z "$status" || "$status" -ne 1 ]]; then
    echo "[!] - Error changing password: ${RESPONSE}"
    exit 1
fi

# Message to the client
echo -e "

Password for the email address ${EMAIL} successfully changed, see the details below:

Email: ${EMAIL}
Password: ${SENHA}
"