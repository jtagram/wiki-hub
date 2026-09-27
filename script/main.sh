#!/bin/bash
# main.sh
#
# Punto de entrada único para generar/configurar todos los secretos que
# necesita el sistema. Sourcea (no ejecuta como subproceso) cada uno de los
# scripts de generación, de forma que las variables que generan queden
# directamente disponibles acá para el resumen final, y los prompts
# interactivos (read) funcionen naturalmente contra la terminal real.
#
# Bajo set -euo pipefail: si algo falla dentro de un script sourceado, todo
# el proceso se detiene acá también (es el comportamiento buscado: frenar
# ante un fallo en una operación crítica).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Generando POSTGRES_USER / POSTGRES_PASSWORD ==="
. "$SCRIPT_DIR/generate_postgres_secrets.sh"

echo
echo "=== Generando JWT_PRIVATE_KEY / JWT_PUBLIC_KEY ==="
. "$SCRIPT_DIR/generate_jwt_keys.sh"

echo
echo "=== Configurando SERVER_SSH_HOST / SERVER_SSH_USER ==="
. "$SCRIPT_DIR/configure_server_ssh_info.sh"

echo
echo "=== Generando y configurando la clave SSH del servidor ==="
. "$SCRIPT_DIR/generate_server_ssh_key.sh"

echo
echo "=== Generando CLIENT_ID / CLIENT_SECRET ==="
. "$SCRIPT_DIR/generate_client_credentials.sh"

# Bloque de impresión final aislado en su propia función a propósito: el día
# que esto se reemplace por `kubectl create secret ...` (o similar), alcanza
# con tocar esta función, sin afectar la generación de secretos de arriba.
print_summary() {
  echo
  echo "========================================"
  echo "      SECRETOS GENERADOS"
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
  echo
  echo "========================================"
}

print_summary
