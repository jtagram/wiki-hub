# Generar los secretos de los 3 ambientes

## Cómo ejecutarlo

En tu PC cliente, desde la carpeta de este paso:

```bash
cd wiki-hub/set-up/03-cluster-secrets-and-access/generate-secret-values-for-microk8s
./main.sh
```

## Requisitos

El script no pide ningún dato. Usa las llaves `~/.ssh/pcbox_prod`, `~/.ssh/pcbox_dev` y `~/.ssh/pcbox_local` que creaste en [configure-access-key-for-three-environments..md](../../01-server-and-vms/configure-access-key-for-three-environments..md) para entrar a cada VM y autorizar la llave del CI.

## Respuesta del script

Al final imprime un bloque por entorno, en este orden: `PROD`, `DEV`, `LOCAL`.
Cada bloque tiene exactamente esta estructura:

```
========================================
      ENTORNO: PROD
========================================

POSTGRES_USER=
POSTGRES_PASSWORD=

JWT_PRIVATE_KEY=
JWT_PUBLIC_KEY=

SERVER_SSH_HOST=
SERVER_SSH_USER=
SERVER_SSH_PRIVATE_KEY=

CLIENT_ID=
CLIENT_SECRET=
CLIENT_SECRET_HASH=

ADMIN_NAME=
ADMIN_LASTNAME=
ADMIN_EMAIL=
ADMIN_PASSWORD=
ADMIN_PASSWORD_HASH=
```
```
========================================
      ENTORNO: DEV
========================================

POSTGRES_USER=
POSTGRES_PASSWORD=

JWT_PRIVATE_KEY=
JWT_PUBLIC_KEY=

SERVER_SSH_HOST=
SERVER_SSH_USER=
SERVER_SSH_PRIVATE_KEY=

CLIENT_ID=
CLIENT_SECRET=
CLIENT_SECRET_HASH=

ADMIN_NAME=
ADMIN_LASTNAME=
ADMIN_EMAIL=
ADMIN_PASSWORD=
ADMIN_PASSWORD_HASH=
```
```
========================================
      ENTORNO: LOCAL
========================================

POSTGRES_USER=
POSTGRES_PASSWORD=

JWT_PRIVATE_KEY=
JWT_PUBLIC_KEY=

SERVER_SSH_HOST=
SERVER_SSH_USER=
SERVER_SSH_PRIVATE_KEY=

CLIENT_ID=
CLIENT_SECRET=
CLIENT_SECRET_HASH=

ADMIN_NAME=
ADMIN_LASTNAME=
ADMIN_EMAIL=
ADMIN_PASSWORD=
ADMIN_PASSWORD_HASH=
```

<div align="right">

[← Back](../../set-up-the-ecosystem-jtagram.md)

</div>
