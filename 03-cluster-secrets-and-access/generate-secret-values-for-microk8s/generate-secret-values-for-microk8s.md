# Generar los secretos de los 3 ambientes

## Cómo ejecutarlo

En tu PC cliente, desde la carpeta de este paso:

```bash
cd wiki-hub/03-cluster-secrets-and-access/generate-secret-values-for-microk8s
./main.sh
```

## Datos que va a pedir el script `main.sh`

Solo contraseñas, una por entorno, en este orden: `PROD`, `DEV`, `LOCAL`.

| Dato | `PROD` | `DEV` | `LOCAL` |
|---|---|---|---|
| `SSH_PASSWORD` | contraseña de `ubuntu` en `prod` | contraseña de `ubuntu` en `dev` | contraseña de `ubuntu` en `local` |

Es la contraseña que definiste en el paso 5 de la guía de llaves.

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
