# script/

Scripts Bash para generar/configurar todos los secretos que necesita el
sistema. `main.sh` es el punto de entrada único.

## Cómo correrlo

Desde esta carpeta:

```bash
./main.sh
# o
bash main.sh
```

Es interactivo: va a pedir `POSTGRES_USER`, `SERVER_SSH_HOST`,
`SERVER_SSH_USER` (si no están seteados ya como variables de entorno),
`SSH_PASSWORD`, si hace falta `SUDO_PASSWORD`, y los datos del primer
usuario ADMIN (nombre, apellido, email y contraseña). Al final imprime un
resumen con todos los secretos generados (contraseñas, claves RSA/ed25519,
credenciales de cliente, hash de la contraseña del admin).

Cada script individual (`generate_postgres_secrets.sh`,
`generate_jwt_keys.sh`, `configure_server_ssh_info.sh`,
`generate_server_ssh_key.sh`, `generate_client_credentials.sh`,
`generate_admin_user_credentials.sh`) también se puede ejecutar suelto para
probarlo (`./generate_jwt_keys.sh`), aunque están pensados para ser
sourceados por `main.sh`.

## Dependencias del sistema

- `openssl` — genera `POSTGRES_PASSWORD`, `JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY`
  y `CLIENT_SECRET`. Debian/Ubuntu: `sudo apt install openssl`.
- `ssh` y `ssh-keygen` (paquete `openssh-client`) — generan y prueban la
  clave del servidor. Debian/Ubuntu: `sudo apt install openssh-client`.
- `sshpass` — automatiza el login SSH con contraseña para copiar la clave
  pública al servidor. Debian/Ubuntu: `sudo apt install sshpass`. Fedora:
  `sudo dnf install sshpass`.
- `node` + el `bcrypt` de `iam-api` ya instalado (`npm install` corrido ahí)
  — `generate_admin_user_credentials.sh` lo usa para calcular el hash de la
  contraseña del admin con la misma librería que `iam-api` usa para
  validarla al loguearse.

## `generated/`

`generate_server_ssh_key.sh` escribe ahí el par de claves ed25519
(`pcbox_deploy_key` / `pcbox_deploy_key.pub`) que se usa para conectarse al
servidor `pcbox`. Esa carpeta está en `.gitignore` (`generated/`) y **nunca**
se commitea: contiene una clave privada real.
