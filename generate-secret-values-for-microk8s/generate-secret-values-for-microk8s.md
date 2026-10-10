# Generar los secretos de los 3 ambientes

Genera los secretos de los entornos `prod`, `dev` y `local`. Los nombres de
variable son los mismos en los tres; solo cambian los valores.

## Antes de empezar

- Las 3 VMs con acceso por SSH con llave y contraseña — [configure-access-key-for-three-environments..md](../configure-access-key-for-three-environments..md).
- Tu PC cliente conectada a la tailnet.
- `sshpass`, `openssl` y `ssh-keygen` instalados en tu PC cliente.
- `npm install` ejecutado en `iam-api` (el script usa su `bcrypt` para los hashes).

## Cómo ejecutarlo

Desde esta carpeta, en tu PC cliente:

```bash
./main.sh
# o
bash main.sh
```

## Datos que va a pedir

Solo contraseñas, una por entorno, en este orden: `PROD`, `DEV`, `LOCAL`.

| Dato | `PROD` | `DEV` | `LOCAL` |
|---|---|---|---|
| `SSH_PASSWORD` | contraseña de `ubuntu` en `prod` | contraseña de `ubuntu` en `dev` | contraseña de `ubuntu` en `local` |

Es la contraseña que definiste en el paso 5 de la guía de llaves.

## Datos que se definen solos

Se derivan del nombre del entorno:

| Dato | `PROD` | `DEV` | `LOCAL` |
|---|---|---|---|
| `POSTGRES_USER` | `jtagram_prod` | `jtagram_dev` | `jtagram_local` |
| `SERVER_SSH_HOST` | `pcbox-prod` | `pcbox-dev` | `pcbox-local` |
| `SERVER_SSH_USER` | `ubuntu` | `ubuntu` | `ubuntu` |
| `SUDO_PASSWORD` | igual a `SSH_PASSWORD` | igual a `SSH_PASSWORD` | igual a `SSH_PASSWORD` |
| `ADMIN_NAME` | `Admin` | `Admin` | `Admin` |
| `ADMIN_LASTNAME` | `Prod` | `Dev` | `Local` |
| `ADMIN_EMAIL` | `admin.prod@jtagram.local` | `admin.dev@jtagram.local` | `admin.local@jtagram.local` |

`SUDO_PASSWORD` no se usa de verdad, porque `sudo` no la pide en las VMs.

## Datos que se generan al azar

Distintos en cada entorno: `POSTGRES_PASSWORD`, `JWT_PRIVATE_KEY`,
`JWT_PUBLIC_KEY`, `SERVER_SSH_PRIVATE_KEY`, `CLIENT_SECRET` y
`ADMIN_PASSWORD`, junto con los hashes de los dos últimos.

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
