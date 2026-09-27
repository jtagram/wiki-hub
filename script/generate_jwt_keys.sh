#!/bin/bash
# generate_jwt_keys.sh
#
# Genera un par de claves RSA (2048 bits) para firmar/validar JWT, sin
# escribir ningún archivo temporal en disco: todo va directo a variables
# de shell usando la capacidad de openssl de leer/escribir por stdin/stdout.
# Pensado para ser sourceado desde main.sh:
#   . "$SCRIPT_DIR/generate_jwt_keys.sh"
# Deja disponibles en el shell que lo sourcea: JWT_PRIVATE_KEY, JWT_PUBLIC_KEY.
set -euo pipefail

# Clave privada RSA 2048 (mínimo suficiente, coincide con lo usado por
# iam-api en producción). Se genera directo a una variable, nunca a un archivo.
JWT_PRIVATE_KEY="$(openssl genrsa 2048 2>/dev/null)"

# Clave pública derivada de la privada, leyendo la privada por stdin
# (here-string) y capturando la salida por stdout, sin archivos intermedios.
JWT_PUBLIC_KEY="$(openssl rsa -pubout <<< "$JWT_PRIVATE_KEY" 2>/dev/null)"

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf '%s\n' "JWT_PRIVATE_KEY=$JWT_PRIVATE_KEY"
  printf '%s\n' "JWT_PUBLIC_KEY=$JWT_PUBLIC_KEY"
fi
