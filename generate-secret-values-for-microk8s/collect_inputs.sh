#!/bin/bash
# collect_inputs.sh
#
# Define los datos de UN entorno (prod, dev o local). Lo único que se pide es
# SSH_PASSWORD; el resto se deriva del nombre del entorno:
#   POSTGRES_USER    jtagram_<entorno>
#   SERVER_SSH_HOST  pcbox-<entorno>
#   SERVER_SSH_USER  ubuntu
#   SUDO_PASSWORD    igual a SSH_PASSWORD (sudo no la pide en las VMs)
#   ADMIN_NAME       Admin
#   ADMIN_LASTNAME   <Entorno>
#   ADMIN_EMAIL      admin.<entorno>@jtagram.local
# Pensado para ser sourceado desde main.sh y llamado una vez por entorno:
#   . "$SCRIPT_DIR/collect_inputs.sh"
#   collect_inputs prod
# Deja disponibles en el shell que lo sourcea: POSTGRES_USER, SERVER_SSH_HOST,
# SERVER_SSH_USER, SSH_PASSWORD, SUDO_PASSWORD, ADMIN_NAME, ADMIN_LASTNAME,
# ADMIN_EMAIL.
#
# Los valores nunca se reutilizan entre entornos: se definen o se piden
# siempre, sin importar lo que haya en el entorno del shell. La contraseña se
# pide sin eco y nunca se guarda en archivo ni se imprime.
set -euo pipefail

# Pide una contraseña sin eco hasta recibir un valor no vacío.
# Uso: prompt_secret NOMBRE_VARIABLE ENTORNO
prompt_secret() {
  local name=$1 env_name=$2 value=""
  while [[ -z "$value" ]]; do
    read -rsp "[${env_name^^}] $name: " value
    echo
    if [[ -z "$value" ]]; then
      echo "ERROR: $name no puede estar vacío." >&2
    fi
  done
  printf -v "$name" '%s' "$value"
}

collect_inputs() {
  local env_name=$1
  echo
  echo "=== Datos del entorno ${env_name^^} ==="
  POSTGRES_USER="jtagram_${env_name}"
  SERVER_SSH_HOST="pcbox-${env_name}"
  SERVER_SSH_USER="ubuntu"
  prompt_secret SSH_PASSWORD "$env_name"
  SUDO_PASSWORD="$SSH_PASSWORD"
  ADMIN_NAME="Admin"
  ADMIN_LASTNAME="${env_name^}"
  ADMIN_EMAIL="admin.${env_name}@jtagram.local"
}
