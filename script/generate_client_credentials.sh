#!/bin/bash
# generate_client_credentials.sh
#
# Genera las credenciales de la cuenta de servicio "apps-user" que
# ticket-hub-api usa para autenticarse contra iam-api (POST /apps-users/login).
# CLIENT_ID es un identificador público fijo (el mismo que luego se carga a
# mano en iam-api como `clienteId` de esa cuenta); CLIENT_SECRET es el secreto
# generado (`clienteSecret`), y CLIENT_SECRET_HASH es su hash bcrypt (10
# rounds, con el mismo `bcrypt` que ya usa iam-api para validarlo) -- iam-api
# nunca guarda el secreto en texto plano, así que hace falta el hash para el
# INSERT en la tabla apps_users. Pensado para ser sourceado desde main.sh:
#   . "$SCRIPT_DIR/generate_client_credentials.sh"
# Deja disponibles en el shell que lo sourcea: CLIENT_ID, CLIENT_SECRET,
# CLIENT_SECRET_HASH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAM_API_DIR="$SCRIPT_DIR/../../iam-api"

# Identificador público, no es un secreto: se hardcodea a propósito para que
# coincida con el `clienteId` esperado en iam-api para esta cuenta de servicio.
CLIENT_ID="ticket-hub-api"

CLIENT_SECRET="$(openssl rand -hex 32)"

if [[ ! -d "$IAM_API_DIR/node_modules/bcrypt" ]]; then
  echo "ERROR: no se encontró $IAM_API_DIR/node_modules/bcrypt." >&2
  echo "Corré 'npm install' en iam-api antes de generar este hash (necesita su propia dependencia bcrypt, la misma que usa para validar el login)." >&2
  exit 1
fi

CLIENT_SECRET_HASH="$(
  cd "$IAM_API_DIR" && node -e "console.log(require('bcrypt').hashSync(process.argv[1], 10))" "$CLIENT_SECRET"
)"

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "CLIENT_ID=$CLIENT_ID"
  echo "CLIENT_SECRET=$CLIENT_SECRET"
  echo "CLIENT_SECRET_HASH=$CLIENT_SECRET_HASH"
fi
