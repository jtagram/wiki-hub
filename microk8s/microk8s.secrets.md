# Crear secretos en MicroK8s

Configuración inicial de los secretos utilizados por los servicios del cluster MicroK8s.

Antes de empezar, tené a mano los valores generados por `wiki-hub/script/main.sh` (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY`, `SERVER_SSH_HOST`, `SERVER_SSH_USER`, `SERVER_SSH_PRIVATE_KEY`, `CLIENT_ID`, `CLIENT_SECRET`) — son los que vas a usar para reemplazar los placeholders en los comandos `kubectl create secret` de este documento. Si todavía no lo corriste, ejecutalo ahora (`cd wiki-hub/script && ./main.sh`) y guardá su salida antes de seguir.

## 1. Conectarse al servidor

Desde la PC cliente, conéctate al servidor `pcbox` mediante SSH usando la clave privada configurada en `pcbox.bootstrap.md`:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Todos los comandos siguientes se ejecutan dentro de la sesión SSH del servidor `pcbox`.

Antes de crear el secreto, asegúrate de que los namespaces ya existan. Si todavía no los creaste, sigue el instructivo de `microk8s.namespace.md`.

## 2. Crear el secreto de PostgreSQL

Ejecuta el siguiente comando para crear el secreto `postgres-credentials` en el namespace `databases`, reemplazando los placeholders por el `POSTGRES_USER`/`POSTGRES_PASSWORD` reales que te imprimió `main.sh`:

```bash
microk8s kubectl create secret generic postgres-credentials \
	-n databases \
	--from-literal=POSTGRES_USER='<usuario-real>' \
	--from-literal=POSTGRES_PASSWORD='<password-real>'
```

## 3. Verificar

Comprobar que el secreto fue creado en el namespace correcto:

```bash
microk8s kubectl get secret postgres-credentials -n databases
```

La salida debe mostrar el secreto `postgres-credentials` dentro del namespace `databases`. Este comando no muestra los valores de las credenciales.

## 4. Secretos por aplicación

### 4.1. `iam-api` (namespace `iam-api`)

Ver [`iam-api/README.md`](../../iam-api/README.md) para la lista completa de variables y cómo obtener cada valor.

**`postgres-credentials`** (`POSTGRES_USER`, `POSTGRES_PASSWORD`):

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n iam-api \
  --from-literal=POSTGRES_USER='<usuario-real>' \
  --from-literal=POSTGRES_PASSWORD='<password-real>'
```

**`jwt-keys`** (`JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY`):

A diferencia de `POSTGRES_USER`/`POSTGRES_PASSWORD`, `main.sh` no guarda estas dos en ningún archivo — las imprime como texto (el bloque PEM completo, con `-----BEGIN...-----` y `-----END...-----`). `--from-file` necesita una ruta a un archivo, no el contenido pegado directamente en el comando, así que primero hay que guardar cada bloque en su propio archivo:

```bash
nano jwt_private.pem
```

Pegar ahí el bloque completo de `JWT_PRIVATE_KEY` (desde `-----BEGIN PRIVATE KEY-----` hasta `-----END PRIVATE KEY-----`), guardar y salir. Repetir con el público:

```bash
nano jwt_public.pem
```

Pegar el bloque de `JWT_PUBLIC_KEY` (desde `-----BEGIN PUBLIC KEY-----` hasta `-----END PUBLIC KEY-----`). Recién ahí usar esas rutas en `--from-file`:

```bash
microk8s kubectl create secret generic jwt-keys \
  -n iam-api \
  --from-file=JWT_PRIVATE_KEY=jwt_private.pem \
  --from-file=JWT_PUBLIC_KEY=jwt_public.pem
```

Los dos `.pem` ya cumplieron su función una vez cargados al Secret — no se commitean al repo, se pueden borrar del servidor después (`rm jwt_private.pem jwt_public.pem`).

Las variables no sensibles (`DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `JWT_EXPIRES_IN`, `PORT`, `LOG_LEVEL`, `IAM_APPLICATION_NAME`) van como env var literal directamente en `deployment.yaml`, no como Secret.

### 4.2. `infra-hub-api` (namespace `infra-hub-api`)

Ver [`infra-hub-api/README.md`](../../infra-hub-api/README.md) para la lista completa de variables y cómo obtener cada valor.

**`postgres-credentials`** (`POSTGRES_USER`, `POSTGRES_PASSWORD`):

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n infra-hub-api \
  --from-literal=POSTGRES_USER='<usuario-real>' \
  --from-literal=POSTGRES_PASSWORD='<password-real>'
```

**`server-ssh-key`** (`SERVER_SSH_HOST`, `SERVER_SSH_USER`, `SERVER_SSH_PRIVATE_KEY`):

`SERVER_SSH_PRIVATE_KEY` también sale como texto en la salida de `main.sh` (no como archivo en el servidor — el archivo que genera `generate_server_ssh_key.sh` queda en la PC donde corriste `main.sh`, no en `pcbox`). Mismo caso que `jwt-keys`: guardala en un archivo antes de usar `--from-file`:

```bash
nano server_ssh_key
```

Pegar ahí el bloque completo de `SERVER_SSH_PRIVATE_KEY` (`-----BEGIN OPENSSH PRIVATE KEY-----` ... `-----END OPENSSH PRIVATE KEY-----`), guardar y salir. Después:

```bash
microk8s kubectl create secret generic server-ssh-key \
  -n infra-hub-api \
  --from-literal=SERVER_SSH_HOST='<host-o-ip-de-pcbox>' \
  --from-literal=SERVER_SSH_USER='<usuario-ssh>' \
  --from-file=SERVER_SSH_PRIVATE_KEY=server_ssh_key
```

Y borrar el archivo temporal, ya cumplió su función:

```bash
rm server_ssh_key
```

Las variables no sensibles (`DB_HOST`, `DB_PORT`, `DB_NAME`, `PORT`, `LOG_LEVEL`, `IAM_API_URL`, `INFRA_HUB_API_APPLICATION_NAME`) van como env var literal directamente en `deployment.yaml`, no como Secret.

### 4.3. `ticket-hub-api` (namespace `ticket-hub-api`)

Ver [`ticket-hub-api/README.md`](../../ticket-hub-api/README.md) para la lista completa de variables y cómo obtener cada valor.

**`postgres-credentials`** (`POSTGRES_USER`, `POSTGRES_PASSWORD`):

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n ticket-hub-api \
  --from-literal=POSTGRES_USER='<usuario-real>' \
  --from-literal=POSTGRES_PASSWORD='<password-real>'
```

**`ticket-hub-api-service-credentials`** (`CLIENT_ID`, `CLIENT_SECRET`):

```bash
microk8s kubectl create secret generic ticket-hub-api-service-credentials \
  -n ticket-hub-api \
  --from-literal=CLIENT_ID='<clienteId-real>' \
  --from-literal=CLIENT_SECRET='<clienteSecret-real>'
```

Las variables no sensibles (`DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `PORT`, `LOG_LEVEL`, `INFRA_HUB_API_URL`, `IAM_API_URL`, `TICKET_HUB_APPLICATION_NAME`, `INFRA_HUB_API_APPLICATION_NAME`) van como env var literal directamente en `deployment.yaml`, no como Secret.

### 4.4. `iam` (namespace `iam`)

Ver [`iam/README.md`](../../iam/README.md) para la lista completa de variables y cómo obtener cada valor. `IAM_API_URL` e `IAM_APPLICATION_NAME` van como env var literal directamente en `deployment.yaml`, no como Secret — este namespace no necesita un Secret propio.

### 4.5. `ticket-hub` (namespace `ticket-hub`)

Ver [`ticket-hub/README.md`](../../ticket-hub/README.md) para la lista completa de variables y cómo obtener cada valor. `IAM_API_URL`, `TICKET_HUB_APPLICATION_NAME` y `TICKET_HUB_API_URL` van como env var literal directamente en `deployment.yaml`, no como Secret — este namespace no necesita un Secret propio.

## 5. Verificar

Comprobar que los Secrets quedaron creados en el namespace correcto de cada app:

```bash
microk8s kubectl get secrets -n iam-api
microk8s kubectl get secrets -n infra-hub-api
microk8s kubectl get secrets -n ticket-hub-api
```

`iam` y `ticket-hub` no aparecen acá porque no tienen Secret propio.

`get secrets` no expone los valores, solo confirma qué Secrets existen en
cada namespace.
