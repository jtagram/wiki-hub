#!/bin/bash
# generate_client_credentials.sh
#
# Genera las credenciales de la cuenta de servicio "apps-user" que
# ticket-hub-api usa para autenticarse contra iam-api (POST /apps-users/login).
# CLIENT_ID es un identificador público fijo (el mismo que luego se carga a
# mano en iam-api como `clienteId` de esa cuenta); CLIENT_SECRET es el secreto
# generado (`clienteSecret`). Pensado para ser sourceado desde main.sh:
#   . "$SCRIPT_DIR/generate_client_credentials.sh"
# Deja disponibles en el shell que lo sourcea: CLIENT_ID, CLIENT_SECRET.
set -euo pipefail

# Identificador público, no es un secreto: se hardcodea a propósito para que
# coincida con el `clienteId` esperado en iam-api para esta cuenta de servicio.
CLIENT_ID="ticket-hub-api"

CLIENT_SECRET="$(openssl rand -hex 32)"

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "CLIENT_ID=$CLIENT_ID"
  echo "CLIENT_SECRET=$CLIENT_SECRET"
fi
