#!/bin/bash
# generate_server_ssh_key.sh
#
# Genera un par de claves ed25519 por entorno en $SCRIPT_DIR/generated/, copia
# la clave pública al servidor (primero sin sudo, con fallback a sudo) y
# verifica que la autenticación con la clave privada funcione. Pensado para
# ser sourceado desde main.sh y llamado una vez por entorno:
#   . "$SCRIPT_DIR/generate_server_ssh_key.sh"
#   check_sshpass_available
#   generate_server_ssh_key prod
# Requiere ya seteados: SERVER_SSH_HOST, SERVER_SSH_USER, SSH_PASSWORD,
# SUDO_PASSWORD (los pide collect_inputs.sh).
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

# Falla temprano (antes de pedir nada al usuario) si falta sshpass.
check_sshpass_available() {
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "ERROR: falta el comando 'sshpass', necesario para automatizar el login SSH con contraseña." >&2
    echo "Instálalo con:" >&2
    echo "  Debian/Ubuntu: sudo apt install sshpass" >&2
    echo "  Fedora:        sudo dnf install sshpass" >&2
    exit 1
  fi
}

generate_server_ssh_key() {
  local env_name=$1
  local key_path="$GENERATED_DIR/${env_name}_deploy_key"
  local ssh_opts=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)

  mkdir -p "$GENERATED_DIR"

  # Si ya existe un par de una corrida anterior, se borra antes de generar
  # uno nuevo para evitar que ssh-keygen pregunte si sobrescribir.
  rm -f "$key_path" "${key_path}.pub"

  ssh-keygen -t ed25519 -f "$key_path" -N "" -C "ticket-hub-api-service-${env_name}" -q
  chmod 600 "$key_path"

  local public_key_content
  public_key_content="$(< "${key_path}.pub")"

  # Chequeo de conectividad previo: si falla, el problema es de red/host/
  # credenciales, no de permisos, y reintentar con sudo no ayuda.
  local connectivity_error
  if ! connectivity_error="$(sshpass -p "$SSH_PASSWORD" ssh "${ssh_opts[@]}" \
      "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" true 2>&1)"; then
    echo "ERROR: no se pudo conectar a ${SERVER_SSH_USER}@${SERVER_SSH_HOST}." >&2
    echo "$connectivity_error" >&2
    echo "Revisa que el servidor esté encendido, conectado a Tailscale, y que SSH_PASSWORD sea correcta (no es un problema de permisos)." >&2
    exit 1
  fi

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
  local remote_cmd_no_sudo="bash -c $(shquote "$remote_script")"

  if sshpass -p "$SSH_PASSWORD" ssh "${ssh_opts[@]}" \
      "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" "$remote_cmd_no_sudo" <<< "$public_key_content"; then
    echo "[$env_name] Clave pública agregada sin necesitar sudo."
  else
    echo "[$env_name] El intento sin sudo falló. Reintentando con sudo..." >&2

    # sudo -S consume solo la primera línea de stdin (la contraseña); el
    # resto (la clave pública) queda disponible para el "cat" remoto.
    local remote_cmd_sudo="sudo -S bash -c $(shquote "$remote_script")"

    if printf '%s\n%s' "$SUDO_PASSWORD" "$public_key_content" | \
        sshpass -p "$SSH_PASSWORD" ssh "${ssh_opts[@]}" \
        "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" "$remote_cmd_sudo"; then
      echo "[$env_name] Clave pública agregada usando sudo."
    else
      echo "ERROR: no se pudo agregar la clave pública al servidor (falló tanto sin sudo como con sudo)." >&2
      exit 1
    fi
  fi

  # Verificación: no hace falta sshpass; BatchMode=yes hace que falle en vez
  # de colgarse pidiendo password si algo salió mal.
  local verify_output
  if verify_output="$(ssh -i "$key_path" \
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
