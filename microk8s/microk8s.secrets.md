# Crear secretos en MicroK8s

Configuración inicial de los secretos utilizados por los servicios del cluster MicroK8s. Por el momento solo se creará el secreto con las credenciales de PostgreSQL; los demás secretos se agregarán más adelante cuando sean necesarios.

## 1. Conectarse al servidor

Desde la PC cliente, conéctate al servidor `pcbox` mediante SSH usando la clave privada configurada en `pcbox.bootstrap.md`:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Todos los comandos siguientes se ejecutan dentro de la sesión SSH del servidor `pcbox`.

Antes de crear el secreto, asegúrate de que el namespace `databases` ya exista. Si todavía no lo creaste, sigue el instructivo de `pcbox.namespace.md`.

## 2. Crear el secreto de PostgreSQL

Ejecuta el siguiente comando para crear el secreto `postgres-credentials` en el namespace `databases`:

```bash
microk8s kubectl create secret generic postgres-credentials \
	-n databases \
	--from-literal=POSTGRES_USER=usuario_db \
	--from-literal=POSTGRES_PASSWORD=clave_segura
```

Reemplaza `usuario_db` y `clave_segura` por las credenciales reales antes de ejecutar el comando. No incluyas esas credenciales en el repositorio ni las compartas en texto plano.

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

```bash
microk8s kubectl create secret generic jwt-keys \
  -n iam-api \
  --from-file=JWT_PRIVATE_KEY='<ruta-a-jwt_private.pem>' \
  --from-file=JWT_PUBLIC_KEY='<ruta-a-jwt_public.pem>'
```

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

```bash
microk8s kubectl create secret generic server-ssh-key \
  -n infra-hub-api \
  --from-literal=SERVER_SSH_HOST='<host-o-ip-de-pcbox>' \
  --from-literal=SERVER_SSH_USER='<usuario-ssh>' \
  --from-file=SERVER_SSH_PRIVATE_KEY='<ruta-a-la-clave-privada>'
```

### 4.3. `ticket-hub-api` (namespace `ticket-hub-api`)

Ver [`ticket-hub-api/README.md`](../../ticket-hub-api/README.md) para la lista completa de variables y cómo obtener cada valor.

**`postgres-credentials`** (`POSTGRES_USER`, `POSTGRES_PASSWORD`):

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n ticket-hub-api \
  --from-literal=POSTGRES_USER='<usuario-real>' \
  --from-literal=POSTGRES_PASSWORD='<password-real>'
```

**`jwt-public-key`** (`JWT_PUBLIC_KEY`):

```bash
microk8s kubectl create secret generic jwt-public-key \
  -n ticket-hub-api \
  --from-file=JWT_PUBLIC_KEY='<ruta-a-jwt_public.pem>'
```

### 4.4. `iam` (namespace `iam`)

Ver [`iam/README.md`](../../iam/README.md) para la lista completa de variables y cómo obtener cada valor.

```bash
microk8s kubectl create secret generic app-config \
  -n iam \
  --from-literal=IAM_API_URL='<url-real>' \
  --from-literal=IAM_APPLICATION_NAME='<nombre-real>'
```

### 4.5. `ticket-hub` (namespace `ticket-hub`)

Ver [`ticket-hub/README.md`](../../ticket-hub/README.md) para la lista completa de variables y cómo obtener cada valor.

```bash
microk8s kubectl create secret generic app-config \
  -n ticket-hub \
  --from-literal=IAM_API_URL='<url-real>' \
  --from-literal=TICKET_HUB_APPLICATION_NAME='<nombre-real>' \
  --from-literal=TICKET_HUB_API_URL='<url-real>'
```

## 5. Verificar

Comprobar que los Secrets quedaron creados en el namespace correcto de cada app:

```bash
microk8s kubectl get secrets -n iam
microk8s kubectl get secrets -n iam-api
microk8s kubectl get secrets -n infra-hub-api
microk8s kubectl get secrets -n ticket-hub
microk8s kubectl get secrets -n ticket-hub-api
```

`get secrets` no expone los valores, solo confirma qué Secrets existen en
cada namespace.
