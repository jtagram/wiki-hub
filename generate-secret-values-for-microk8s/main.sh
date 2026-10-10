#!/bin/bash
# main.sh
#
# Punto de entrada único para generar los secretos de los tres entornos:
# prod, dev y local. Los nombres de variable son idénticos en los tres; solo
# cambian los valores (cada entorno recibe secretos propios).
#
# Sourcea (no ejecuta como subproceso) cada script auxiliar, de forma que las
# variables que generan queden disponibles acá y los prompts interactivos
# (read) funcionen contra la terminal real.
#
# Bajo set -euo pipefail: si algo falla dentro de un script sourceado, todo
# el proceso se detiene (es el comportamiento buscado ante un fallo crítico).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENVIRONMENTS=(prod dev local)

. "$SCRIPT_DIR/collect_inputs.sh"
. "$SCRIPT_DIR/generate_postgres_secrets.sh"
. "$SCRIPT_DIR/generate_jwt_keys.sh"
. "$SCRIPT_DIR/generate_server_ssh_key.sh"
. "$SCRIPT_DIR/generate_client_credentials.sh"
. "$SCRIPT_DIR/generate_admin_credentials.sh"

# Dependencias verificadas antes de pedir datos, para no hacer escribir
# contraseñas y fallar después.
check_sshpass_available
check_bcrypt_available

declare -A SUMMARY

# Arma el bloque de salida de un entorno con las variables recién generadas.
# Aislado en su propia función a propósito: el día que esto se reemplace por
# `kubectl create secret ...` (o similar), alcanza con tocar esta función.
build_env_block() {
  local env_name=$1
  SUMMARY[$env_name]="$(
    echo "========================================"
    echo "      ENTORNO: ${env_name^^}"
    echo "========================================"
    echo
    echo "POSTGRES_USER=$POSTGRES_USER"
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
    echo
    printf '%s\n' "JWT_PRIVATE_KEY=$JWT_PRIVATE_KEY"
    printf '%s\n' "JWT_PUBLIC_KEY=$JWT_PUBLIC_KEY"
    echo
    echo "SERVER_SSH_HOST=$SERVER_SSH_HOST"
    echo "SERVER_SSH_USER=$SERVER_SSH_USER"
    printf '%s\n' "SERVER_SSH_PRIVATE_KEY=$SERVER_SSH_PRIVATE_KEY"
    echo
    echo "CLIENT_ID=$CLIENT_ID"
    echo "CLIENT_SECRET=$CLIENT_SECRET"
    echo "CLIENT_SECRET_HASH=$CLIENT_SECRET_HASH"
    echo
    echo "ADMIN_NAME=$ADMIN_NAME"
    echo "ADMIN_LASTNAME=$ADMIN_LASTNAME"
    echo "ADMIN_EMAIL=$ADMIN_EMAIL"
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD"
    echo "ADMIN_PASSWORD_HASH=$ADMIN_PASSWORD_HASH"
  )"
}

for env_name in "${ENVIRONMENTS[@]}"; do
  echo
  collect_inputs "$env_name"
  echo "=== Generando secretos para ${env_name^^} ==="
  generate_postgres_secrets
  generate_jwt_keys
  generate_server_ssh_key "$env_name"
  generate_client_credentials
  generate_admin_credentials
  build_env_block "$env_name"
  # Las contraseñas ya cumplieron su propósito: se descartan al terminar
  # cada entorno, antes de pedir las del siguiente.
  unset SSH_PASSWORD SUDO_PASSWORD
done

echo
echo "########################################"
echo "      SECRETOS GENERADOS"
echo "########################################"
for env_name in "${ENVIRONMENTS[@]}"; do
  echo
  printf '%s\n' "${SUMMARY[$env_name]}"
done
echo
echo "########################################"
