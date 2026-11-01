#!/bin/bash
# generate_server_ssh_key.sh
#
# Genera un par de claves ed25519 por entorno en $SCRIPT_DIR/generated/, copia
# la clave pública al servidor y verifica que la autenticación con la clave
# privada funcione. El acceso al servidor para copiarla se hace con la llave
# de administración ~/.ssh/pcbox_<entorno> (la de la guía de llaves de acceso),
# sin contraseña. Pensado para ser sourceado desde main.sh y llamado una vez
# por entorno:
#   . "$SCRIPT_DIR/generate_server_ssh_key.sh"
#   generate_server_ssh_key prod
# Requiere ya seteados: SERVER_SSH_HOST, SERVER_SSH_USER (los define
# collect_inputs.sh).
# Deja disponible en el shell que lo sourcea: SERVER_SSH_PRIVATE_KEY.
#
# La clave privada NUNCA se manda al servidor: solo se copia la pública.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="$SCRIPT_DIR/generated"

# Quotea un string para uso seguro como un único token de shell POSIX
# (comillas simples, escapando comillas simples internas como '\''). Se usa
# para armar el comando remoto como una sola palabra y evitar que ssh vuelva
# a unir varios argumentos con espacios.
shquote() {
  local s=$1
  printf "'%s'" "${s//\'/\'\\\'\'}"
}

generate_server_ssh_key() {
  local env_name=$1
  local key_path="$GENERATED_DIR/${env_name}_deploy_key"
  local admin_key_path="$HOME/.ssh/pcbox_${env_name}"
  local ssh_opts=(-i "$admin_key_path" -o IdentitiesOnly=yes -o PasswordAuthentication=no
    -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)

  if [[ ! -f "$admin_key_path" ]]; then
    echo "ERROR: no existe la llave de administración $admin_key_path." >&2
    echo "Créala siguiendo la guía de llaves de acceso (configure-access-key-for-three-environments)." >&2
    exit 1
  fi

  mkdir -p "$GENERATED_DIR"

  # Si ya existe un par de una corrida anterior, se borra antes de generar
  # uno nuevo para evitar que ssh-keygen pregunte si sobrescribir.
  rm -f "$key_path" "${key_path}.pub"

  ssh-keygen -t ed25519 -f "$key_path" -N "" -C "ticket-hub-api-service-${env_name}" -q
  chmod 600 "$key_path"

  local public_key_content
  public_key_content="$(< "${key_path}.pub")"

  # Chequeo de conectividad previo: si falla, el problema es de red, host o
  # llave de administración.
  local connectivity_error
  if ! connectivity_error="$(ssh "${ssh_opts[@]}" \
      "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" true 2>&1)"; then
    echo "ERROR: no se pudo conectar a ${SERVER_SSH_USER}@${SERVER_SSH_HOST} con $admin_key_path." >&2
    echo "$connectivity_error" >&2
    echo "Revisa que el servidor esté encendido, conectado a Tailscale, y que la llave de administración esté autorizada en la VM." >&2
    exit 1
  fi

  # La clave se agrega al authorized_keys de $SERVER_SSH_USER: no requiere sudo.
  local remote_script='
set -euo pipefail
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
NEW_KEY="$(cat)"
grep -qxF "$NEW_KEY" ~/.ssh/authorized_keys || printf "%s\n" "$NEW_KEY" >> ~/.ssh/authorized_keys
'

  # El comando remoto va como UNA sola palabra quoteada: ssh concatena los
  # argumentos con espacios, lo que rompería un script con saltos de línea.
  local remote_cmd="bash -c $(shquote "$remote_script")"

  if ssh "${ssh_opts[@]}" \
      "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" "$remote_cmd" <<< "$public_key_content"; then
    echo "[$env_name] Clave pública agregada."
  else
    echo "ERROR: no se pudo agregar la clave pública al servidor." >&2
    exit 1
  fi

  # Verificación con la nueva clave: BatchMode=yes hace que falle en vez de
  # colgarse pidiendo password si algo salió mal.
  local verify_output
  if verify_output="$(ssh -i "$key_path" -o IdentitiesOnly=yes \
      -o PasswordAuthentication=no -o StrictHostKeyChecking=accept-new \
      -o BatchMode=yes -o ConnectTimeout=10 \
      "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" true 2>&1)"; then
    echo "[$env_name] SSH configurado correctamente."
  else
    echo "ERROR: la autenticación con la nueva clave privada falló." >&2
    echo "$verify_output" >&2
    exit 1
  fi

  SERVER_SSH_PRIVATE_KEY="$(< "$key_path")"
}
