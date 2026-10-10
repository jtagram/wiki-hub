#!/bin/bash
# generate_admin_credentials.sh
#
# Genera la contraseña del primer usuario ADMIN (el que accede a "iam" y a
# "ticket-hub") y calcula su hash bcrypt (10 rounds, con el mismo `bcrypt`
# que usa iam-api para validar el login). ADMIN_NAME, ADMIN_LASTNAME y
# ADMIN_EMAIL los pide collect_inputs.sh. Pensado para ser sourceado desde
# main.sh y llamado una vez por entorno, después de check_bcrypt_available
# (definida en generate_client_credentials.sh):
#   . "$SCRIPT_DIR/generate_admin_credentials.sh"
#   generate_admin_credentials
# Deja disponibles en el shell que lo sourcea: ADMIN_PASSWORD (texto plano,
# para entregárselo al admin) y ADMIN_PASSWORD_HASH (el que va en la base).
set -euo pipefail

ADMIN_IAM_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../iam-api"

generate_admin_credentials() {
  ADMIN_PASSWORD="$(openssl rand -hex 16)"
  ADMIN_PASSWORD_HASH="$(
    cd "$ADMIN_IAM_API_DIR" && node -e "console.log(require('bcrypt').hashSync(process.argv[1], 10))" "$ADMIN_PASSWORD"
  )"
}
