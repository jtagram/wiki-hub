#!/bin/bash
# generate_jwt_keys.sh
#
# Genera un par de claves RSA (2048 bits) para firmar/validar JWT, sin
# escribir ningún archivo temporal en disco: todo va directo a variables
# de shell usando la capacidad de openssl de leer/escribir por stdin/stdout.
# Pensado para ser sourceado desde main.sh y llamado una vez por entorno:
#   . "$SCRIPT_DIR/generate_jwt_keys.sh"
#   generate_jwt_keys
# Deja disponibles en el shell que lo sourcea: JWT_PRIVATE_KEY, JWT_PUBLIC_KEY.
set -euo pipefail

generate_jwt_keys() {
  JWT_PRIVATE_KEY="$(openssl genrsa 2048 2>/dev/null)"
  JWT_PUBLIC_KEY="$(openssl rsa -pubout <<< "$JWT_PRIVATE_KEY" 2>/dev/null)"
}

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  generate_jwt_keys
  printf '%s\n' "JWT_PRIVATE_KEY=$JWT_PRIVATE_KEY"
  printf '%s\n' "JWT_PUBLIC_KEY=$JWT_PUBLIC_KEY"
fi
