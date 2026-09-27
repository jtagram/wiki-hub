#!/bin/bash
# configure_server_ssh_info.sh
#
# Pide (o confirma, si ya vienen seteados) los datos de conexión SSH al
# servidor pcbox: SERVER_SSH_HOST y SERVER_SSH_USER. Pensado para ser
# sourceado desde main.sh:
#   . "$SCRIPT_DIR/configure_server_ssh_info.sh"
# Deja disponibles en el shell que lo sourcea: SERVER_SSH_HOST, SERVER_SSH_USER.
set -euo pipefail

cat_explanation() {
  cat <<'EOF'
========================================
  Datos de conexión SSH al servidor pcbox
========================================

SERVER_SSH_HOST: es la IP de Tailscale del servidor al que se conecta la
aplicación. Se obtiene ejecutando `tailscale status` desde una PC que ya
esté conectada a la misma tailnet, buscando la fila correspondiente al
servidor `pcbox` (dirección con formato 100.x.x.x).

SERVER_SSH_USER: es el usuario Linux con el que se conecta por SSH al
servidor. Es el usuario que se creó durante la instalación de Ubuntu
Server en el servidor.

Ambos datos están documentados en wiki-hub/pcbox/pcbox.bootstrap.md
(paso 0 para SERVER_SSH_USER, paso 2 para SERVER_SSH_HOST). Podés abrir
ese archivo si no los tenés a mano.
EOF
}

cat_explanation

# SERVER_SSH_HOST: si ya viene seteado (fallback, por ejemplo de una
# corrida anterior en la misma sesión de shell), no se vuelve a pedir.
if [[ -n "${SERVER_SSH_HOST:-}" ]]; then
  echo "SERVER_SSH_HOST ya está seteado: $SERVER_SSH_HOST"
else
  SERVER_SSH_HOST=""
  while [[ -z "$SERVER_SSH_HOST" ]]; do
    read -rp "SERVER_SSH_HOST: " SERVER_SSH_HOST
    if [[ -z "$SERVER_SSH_HOST" ]]; then
      echo "ERROR: SERVER_SSH_HOST no puede estar vacío." >&2
    fi
  done
fi

# SERVER_SSH_USER: mismo criterio que SERVER_SSH_HOST.
if [[ -n "${SERVER_SSH_USER:-}" ]]; then
  echo "SERVER_SSH_USER ya está seteado: $SERVER_SSH_USER"
else
  SERVER_SSH_USER=""
  while [[ -z "$SERVER_SSH_USER" ]]; do
    read -rp "SERVER_SSH_USER: " SERVER_SSH_USER
    if [[ -z "$SERVER_SSH_USER" ]]; then
      echo "ERROR: SERVER_SSH_USER no puede estar vacío." >&2
    fi
  done
fi

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "SERVER_SSH_HOST=$SERVER_SSH_HOST"
  echo "SERVER_SSH_USER=$SERVER_SSH_USER"
fi
