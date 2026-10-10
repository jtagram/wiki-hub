#!/bin/bash
# generate_postgres_secrets.sh
#
# Genera una contraseña aleatoria fuerte para POSTGRES_USER. Pensado para ser
# sourceado desde main.sh y llamado una vez por entorno:
#   . "$SCRIPT_DIR/generate_postgres_secrets.sh"
#   generate_postgres_secrets
# Deja disponible en el shell que lo sourcea: POSTGRES_PASSWORD
# (POSTGRES_USER lo pide collect_inputs.sh).
set -euo pipefail

generate_postgres_secrets() {
  # Hexadecimal (evita '/', '+', '=' de base64, que pueden complicar el uso
  # posterior en YAML/URLs de conexión).
  POSTGRES_PASSWORD="$(openssl rand -hex 32)"
}

# Si el script se ejecuta directo (no sourceado), pide el usuario y muestra el resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  read -rp "POSTGRES_USER: " POSTGRES_USER
  generate_postgres_secrets
  echo "POSTGRES_USER=$POSTGRES_USER"
  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
fi
