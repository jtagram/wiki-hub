#!/bin/bash
# generate_postgres_secrets.sh
#
# Pide el nombre de usuario de PostgreSQL y genera una contraseña aleatoria
# fuerte para ese usuario. Pensado para ser sourceado desde main.sh:
#   . "$SCRIPT_DIR/generate_postgres_secrets.sh"
# Deja disponibles en el shell que lo sourcea: POSTGRES_USER, POSTGRES_PASSWORD.
set -euo pipefail

# Pide POSTGRES_USER hasta recibir un valor no vacío.
POSTGRES_USER=""
while [[ -z "$POSTGRES_USER" ]]; do
  read -rp "POSTGRES_USER: " POSTGRES_USER
  if [[ -z "$POSTGRES_USER" ]]; then
    echo "ERROR: POSTGRES_USER no puede estar vacío." >&2
  fi
done

# Contraseña aleatoria en hexadecimal (evita '/', '+', '=' de base64, que
# pueden complicar el uso posterior en YAML/URLs de conexión).
POSTGRES_PASSWORD="$(openssl rand -hex 32)"

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "POSTGRES_USER=$POSTGRES_USER"
  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
fi
