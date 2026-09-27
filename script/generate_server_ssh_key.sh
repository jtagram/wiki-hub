#!/bin/bash
# generate_server_ssh_key.sh
#
# Genera un par de claves ed25519 en $SCRIPT_DIR/generated/ para conectarse
# por SSH sin contraseña al servidor pcbox, copia la clave pública al
# servidor (primero sin sudo, con fallback a sudo si hace falta) y verifica
# que la autenticación con la clave privada funcione. Pensado para ser
# sourceado desde main.sh:
#   . "$SCRIPT_DIR/generate_server_ssh_key.sh"
# Deja disponible en el shell que lo sourcea: SERVER_SSH_PRIVATE_KEY
# (además de SERVER_SSH_HOST/SERVER_SSH_USER, si no venían seteados ya).
#
# La clave privada NUNCA se manda al servidor: solo se copia la pública.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="$SCRIPT_DIR/generated"
KEY_PATH="$GENERATED_DIR/pcbox_deploy_key"

# Quotea un string para uso seguro como un único token de shell POSIX
# (comillas simples, escapando comillas simples internas como '\''). Se usa
# para armar el comando remoto como una sola palabra y evitar que ssh vuelva
# a unir varios argumentos con espacios (lo que rompería el script remoto
# si este contiene saltos de línea o comillas).
shquote() {
  local s=$1
  printf "'%s'" "${s//\'/\'\\\'\'}"
}

# --- 4.1. Datos de entrada -------------------------------------------------

# Si SERVER_SSH_HOST/SERVER_SSH_USER no están seteados (ejecución standalone),
# se sourcea configure_server_ssh_info.sh para no duplicar la lógica de
# explicación/validación.
if [[ -z "${SERVER_SSH_HOST:-}" || -z "${SERVER_SSH_USER:-}" ]]; then
  . "$SCRIPT_DIR/configure_server_ssh_info.sh"
fi

read -rsp "SSH_PASSWORD (contraseña actual del usuario SSH): " SSH_PASSWORD
echo

# --- 4.2. Generación de la clave (local, nunca se manda la privada) --------

mkdir -p "$GENERATED_DIR"

# Si ya existe un par de claves de una corrida anterior, se borra antes de
# generar uno nuevo para evitar que ssh-keygen pregunte interactivamente si
# sobrescribir (lo que colgaría el script bajo set -euo pipefail).
if [[ -f "$KEY_PATH" || -f "${KEY_PATH}.pub" ]]; then
  rm -f "$KEY_PATH" "${KEY_PATH}.pub"
fi

ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "ticket-hub-api-service" -q

# Explícito por si el umask del sistema no lo deja así por defecto.
chmod 600 "$KEY_PATH"

# --- 4.3. Copiar la clave pública al servidor -------------------------------

if ! command -v sshpass >/dev/null 2>&1; then
  echo "ERROR: falta el comando 'sshpass', necesario para automatizar el login SSH con contraseña." >&2
  echo "Instalalo con:" >&2
  echo "  Debian/Ubuntu: sudo apt install sshpass" >&2
  echo "  Fedora:        sudo dnf install sshpass" >&2
  exit 1
fi

PUBLIC_KEY_CONTENT="$(cat "${KEY_PATH}.pub")"

REMOTE_SCRIPT='
set -euo pipefail
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
NEW_KEY="$(cat)"
grep -qxF "$NEW_KEY" ~/.ssh/authorized_keys || printf "%s\n" "$NEW_KEY" >> ~/.ssh/authorized_keys
'

# El comando remoto se arma como UNA sola palabra ya quoteada (con
# shquote), en vez de pasar "bash" "-c" "$REMOTE_SCRIPT" como argumentos
# separados a ssh: ssh concatena los argumentos del comando remoto con un
# simple espacio antes de mandarlos al shell remoto, lo que rompería este
# script (tiene saltos de línea y comillas) si se pasara en varias palabras.
REMOTE_CMD_NO_SUDO="bash -c $(shquote "$REMOTE_SCRIPT")"

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)

if sshpass -p "$SSH_PASSWORD" ssh "${SSH_OPTS[@]}" \
    "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" "$REMOTE_CMD_NO_SUDO" <<< "$PUBLIC_KEY_CONTENT"; then
  echo "Clave pública agregada sin necesitar sudo."
else
  echo "El intento sin sudo falló. Reintentando con sudo..." >&2
  read -rsp "SUDO_PASSWORD (contraseña de sudo para ${SERVER_SSH_USER} en el servidor): " SUDO_PASSWORD
  echo

  # sudo -S consume solo la primera línea de stdin (la contraseña); el
  # resto de stdin (la clave pública) sigue disponible para el "cat" que
  # corre dentro de REMOTE_SCRIPT, ya ejecutándose como el usuario root.
  REMOTE_CMD_SUDO="sudo -S bash -c $(shquote "$REMOTE_SCRIPT")"

  if printf '%s\n%s' "$SUDO_PASSWORD" "$PUBLIC_KEY_CONTENT" | \
      sshpass -p "$SSH_PASSWORD" ssh "${SSH_OPTS[@]}" \
      "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" "$REMOTE_CMD_SUDO"; then
    echo "Clave pública agregada usando sudo."
  else
    echo "ERROR: no se pudo agregar la clave pública al servidor (falló tanto sin sudo como con sudo)." >&2
    unset SSH_PASSWORD SUDO_PASSWORD 2>/dev/null || true
    exit 1
  fi
fi

# --- 4.4. Verificación -------------------------------------------------------

# No hace falta sshpass acá: si la clave quedó bien instalada, la conexión
# no debería pedir contraseña. BatchMode=yes hace que falle en vez de
# colgarse pidiendo password si algo salió mal.
if ssh_verify_output="$(ssh -i "$KEY_PATH" \
    -o PasswordAuthentication=no -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes -o ConnectTimeout=10 \
    "${SERVER_SSH_USER}@${SERVER_SSH_HOST}" true 2>&1)"; then
  echo "SSH configurado correctamente."
else
  echo "ERROR: la autenticación con la nueva clave privada falló." >&2
  echo "$ssh_verify_output" >&2
  unset SSH_PASSWORD SUDO_PASSWORD 2>/dev/null || true
  exit 1
fi

# Nunca se guardan en archivo ni se imprimen; se limpian del entorno apenas
# dejan de hacer falta.
unset SSH_PASSWORD SUDO_PASSWORD 2>/dev/null || true

# --- 4.5. Resultado final ----------------------------------------------------

SERVER_SSH_PRIVATE_KEY="$(cat "$KEY_PATH")"

# Si el script se ejecuta directo (no sourceado), imprime su propio resultado.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "SERVER_SSH_HOST=$SERVER_SSH_HOST"
  echo "SERVER_SSH_USER=$SERVER_SSH_USER"
  printf '%s\n' "SERVER_SSH_PRIVATE_KEY=$SERVER_SSH_PRIVATE_KEY"
fi
