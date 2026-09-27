#!/bin/bash
# generate_admin_user_credentials.sh
#
# Pide los datos del primer usuario interno ADMIN (el mismo que va a tener
# acceso tanto a "iam" como a "ticket-hub") y calcula el hash bcrypt de su
# contraseña, usando el mismo `bcrypt` que ya está instalado como dependencia
# de iam-api (mismo criterio que ya documenta database.datos-iniciales.md).
# Pensado para ser sourceado desde main.sh:
#   . "$SCRIPT_DIR/generate_admin_user_credentials.sh"
# Deja disponibles en el shell que lo sourcea: ADMIN_NAME, ADMIN_LASTNAME,
# ADMIN_EMAIL, ADMIN_PASSWORD_HASH.
#
# La contraseña en texto plano no se guarda en ninguna variable persistente
# ni se muestra en el resumen final -- una vez calculado el hash, ya no hace
# falta.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAM_API_DIR="$SCRIPT_DIR/../../iam-api"

EMAIL_PATTERN='^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'

ADMIN_NAME=""
while [[ -z "$ADMIN_NAME" ]]; do
  read -rp "Nombre del admin: " ADMIN_NAME
  if [[ -z "$ADMIN_NAME" ]]; then
    echo "ERROR: el nombre no puede estar vacío." >&2
  fi
done

ADMIN_LASTNAME=""
while [[ -z "$ADMIN_LASTNAME" ]]; do
  read -rp "Apellido del admin: " ADMIN_LASTNAME
  if [[ -z "$ADMIN_LASTNAME" ]]; then
    echo "ERROR: el apellido no puede estar vacío." >&2
  fi
done

ADMIN_EMAIL=""
while [[ ! "$ADMIN_EMAIL" =~ $EMAIL_PATTERN ]]; do
  read -rp "Email del admin (usuario para loguearse en iam y ticket-hub): " ADMIN_EMAIL
  if [[ ! "$ADMIN_EMAIL" =~ $EMAIL_PATTERN ]]; then
    echo "ERROR: '$ADMIN_EMAIL' no tiene formato de email válido." >&2
  fi
done

ADMIN_PASSWORD=""
while [[ -z "$ADMIN_PASSWORD" ]]; do
  read -rsp "Password del admin: " ADMIN_PASSWORD
  echo
  if [[ -z "$ADMIN_PASSWORD" ]]; then
    echo "ERROR: la contraseña no puede estar vacía." >&2
  fi
done

if [[ ! -d "$IAM_API_DIR/node_modules/bcrypt" ]]; then
  echo "ERROR: no se encontró $IAM_API_DIR/node_modules/bcrypt." >&2
  echo "Corré 'npm install' en iam-api antes de generar este hash (necesita su propia dependencia bcrypt, la misma que usa para validar el login)." >&2
  exit 1
fi

ADMIN_PASSWORD_HASH="$(
  cd "$IAM_API_DIR" && node -e "console.log(require('bcrypt').hashSync(process.argv[1], 10))" "$ADMIN_PASSWORD"
)"

# La contraseña en texto plano ya cumplió su único propósito (calcular el
# hash) -- se descarta acá, nunca se imprime ni queda en el resumen final.
unset ADMIN_PASSWORD

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ADMIN_NAME=$ADMIN_NAME"
  echo "ADMIN_LASTNAME=$ADMIN_LASTNAME"
  echo "ADMIN_EMAIL=$ADMIN_EMAIL"
  echo "ADMIN_PASSWORD_HASH=$ADMIN_PASSWORD_HASH"
fi
