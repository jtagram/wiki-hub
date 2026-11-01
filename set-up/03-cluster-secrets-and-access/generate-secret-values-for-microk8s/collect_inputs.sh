#!/bin/bash
# collect_inputs.sh
#
# Define los datos de UN entorno (prod, dev o local). No pide nada: todo se
# deriva del nombre del entorno:
#   POSTGRES_USER    jtagram_<entorno>
#   SERVER_SSH_HOST  pcbox-<entorno>
#   SERVER_SSH_USER  ubuntu
#   ADMIN_NAME       Admin
#   ADMIN_LASTNAME   <Entorno>
#   ADMIN_EMAIL      admin.<entorno>@jtagram.local
# Pensado para ser sourceado desde main.sh y llamado una vez por entorno:
#   . "$SCRIPT_DIR/collect_inputs.sh"
#   collect_inputs prod
# Deja disponibles en el shell que lo sourcea: POSTGRES_USER, SERVER_SSH_HOST,
# SERVER_SSH_USER, ADMIN_NAME, ADMIN_LASTNAME, ADMIN_EMAIL.
#
# Los valores nunca se reutilizan entre entornos: se definen siempre, sin
# importar lo que haya en el entorno del shell.
set -euo pipefail

collect_inputs() {
  local env_name=$1
  echo
  echo "=== Datos del entorno ${env_name^^} ==="
  POSTGRES_USER="jtagram_${env_name}"
  SERVER_SSH_HOST="pcbox-${env_name}"
  SERVER_SSH_USER="ubuntu"
  ADMIN_NAME="Admin"
  ADMIN_LASTNAME="${env_name^}"
  ADMIN_EMAIL="admin.${env_name}@jtagram.local"
}
