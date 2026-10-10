# Cargar los secretos en los namespaces de los 3 ambientes

Carga en cada VM los secretos de su ambiente, en el MicroK8s de esa VM.

Necesitas:

- Namespaces creados en las 3 VMs — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).
- Los valores generados por [main.sh](generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md). Cada ambiente usa su propio bloque (`PROD`, `DEV`, `LOCAL`).

Reemplaza cada `<VARIABLE>` por el valor de esa variable en el bloque del ambiente.

## Secretos por ambiente

| Secret | Namespace | Variables |
|---|---|---|
| `postgres-credentials` | `databases` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `postgres-credentials` | `iam-api` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `jwt-keys` | `iam-api` | `JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY` |
| `postgres-credentials` | `infra-hub-api` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `server-ssh-key` | `infra-hub-api` | `SERVER_SSH_HOST`, `SERVER_SSH_USER`, `SERVER_SSH_PRIVATE_KEY` |
| `postgres-credentials` | `ticket-hub-api` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `ticket-hub-api-service-credentials` | `ticket-hub-api` | `CLIENT_ID`, `CLIENT_SECRET` |

`iam` y `ticket-hub` no tienen secretos.

`JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY` y `SERVER_SSH_PRIVATE_KEY` son bloques de varias líneas. En cada VM se guardan primero en archivos temporales, pegando el bloque completo (de `-----BEGIN` a `-----END`), y se cargan con `--from-file`. Al terminar se borran.

Todos los comandos se ejecutan desde tu PC cliente, dentro de cada VM.

---

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, crea los archivos con las claves:

```bash
nano jwt_private.pem
nano jwt_public.pem
nano server_ssh_key
```

### Databases

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n databases \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'
```

### iam-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n iam-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic jwt-keys \
  -n iam-api \
  --from-file=JWT_PRIVATE_KEY=jwt_private.pem \
  --from-file=JWT_PUBLIC_KEY=jwt_public.pem
```

### infra-hub-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n infra-hub-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic server-ssh-key \
  -n infra-hub-api \
  --from-literal=SERVER_SSH_HOST='<SERVER_SSH_HOST>' \
  --from-literal=SERVER_SSH_USER='<SERVER_SSH_USER>' \
  --from-file=SERVER_SSH_PRIVATE_KEY=server_ssh_key
```

### ticket-hub-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n ticket-hub-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic ticket-hub-api-service-credentials \
  -n ticket-hub-api \
  --from-literal=CLIENT_ID='<CLIENT_ID>' \
  --from-literal=CLIENT_SECRET='<CLIENT_SECRET>'
```

### Verificar

```bash
microk8s kubectl get secrets -n databases
```

```
NAME                   TYPE     DATA   AGE
postgres-credentials   Opaque   2      10s
```

```bash
microk8s kubectl get secrets -n iam-api
```

```
NAME                   TYPE     DATA   AGE
jwt-keys               Opaque   2      10s
postgres-credentials   Opaque   2      10s
```

```bash
microk8s kubectl get secrets -n infra-hub-api
```

```
NAME                   TYPE     DATA   AGE
postgres-credentials   Opaque   2      10s
server-ssh-key         Opaque   3      10s
```

```bash
microk8s kubectl get secrets -n ticket-hub-api
```

```
NAME                                 TYPE     DATA   AGE
postgres-credentials                 Opaque   2      10s
ticket-hub-api-service-credentials   Opaque   2      10s
```

### Borrar los archivos temporales

```bash
rm jwt_private.pem jwt_public.pem server_ssh_key
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, crea los archivos con las claves:

```bash
nano jwt_private.pem
nano jwt_public.pem
nano server_ssh_key
```

### Databases

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n databases \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'
```

### iam-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n iam-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic jwt-keys \
  -n iam-api \
  --from-file=JWT_PRIVATE_KEY=jwt_private.pem \
  --from-file=JWT_PUBLIC_KEY=jwt_public.pem
```

### infra-hub-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n infra-hub-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic server-ssh-key \
  -n infra-hub-api \
  --from-literal=SERVER_SSH_HOST='<SERVER_SSH_HOST>' \
  --from-literal=SERVER_SSH_USER='<SERVER_SSH_USER>' \
  --from-file=SERVER_SSH_PRIVATE_KEY=server_ssh_key
```

### ticket-hub-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n ticket-hub-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic ticket-hub-api-service-credentials \
  -n ticket-hub-api \
  --from-literal=CLIENT_ID='<CLIENT_ID>' \
  --from-literal=CLIENT_SECRET='<CLIENT_SECRET>'
```

### Verificar

```bash
microk8s kubectl get secrets -n databases
```

```
NAME                   TYPE     DATA   AGE
postgres-credentials   Opaque   2      10s
```

```bash
microk8s kubectl get secrets -n iam-api
```

```
NAME                   TYPE     DATA   AGE
jwt-keys               Opaque   2      10s
postgres-credentials   Opaque   2      10s
```

```bash
microk8s kubectl get secrets -n infra-hub-api
```

```
NAME                   TYPE     DATA   AGE
postgres-credentials   Opaque   2      10s
server-ssh-key         Opaque   3      10s
```

```bash
microk8s kubectl get secrets -n ticket-hub-api
```

```
NAME                                 TYPE     DATA   AGE
postgres-credentials                 Opaque   2      10s
ticket-hub-api-service-credentials   Opaque   2      10s
```

### Borrar los archivos temporales

```bash
rm jwt_private.pem jwt_public.pem server_ssh_key
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, crea los archivos con las claves:

```bash
nano jwt_private.pem
nano jwt_public.pem
nano server_ssh_key
```

### Databases

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n databases \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'
```

### iam-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n iam-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic jwt-keys \
  -n iam-api \
  --from-file=JWT_PRIVATE_KEY=jwt_private.pem \
  --from-file=JWT_PUBLIC_KEY=jwt_public.pem
```

### infra-hub-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n infra-hub-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic server-ssh-key \
  -n infra-hub-api \
  --from-literal=SERVER_SSH_HOST='<SERVER_SSH_HOST>' \
  --from-literal=SERVER_SSH_USER='<SERVER_SSH_USER>' \
  --from-file=SERVER_SSH_PRIVATE_KEY=server_ssh_key
```

### ticket-hub-api

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n ticket-hub-api \
  --from-literal=POSTGRES_USER='<POSTGRES_USER>' \
  --from-literal=POSTGRES_PASSWORD='<POSTGRES_PASSWORD>'

microk8s kubectl create secret generic ticket-hub-api-service-credentials \
  -n ticket-hub-api \
  --from-literal=CLIENT_ID='<CLIENT_ID>' \
  --from-literal=CLIENT_SECRET='<CLIENT_SECRET>'
```

### Verificar

```bash
microk8s kubectl get secrets -n databases
```

```
NAME                   TYPE     DATA   AGE
postgres-credentials   Opaque   2      10s
```

```bash
microk8s kubectl get secrets -n iam-api
```

```
NAME                   TYPE     DATA   AGE
jwt-keys               Opaque   2      10s
postgres-credentials   Opaque   2      10s
```

```bash
microk8s kubectl get secrets -n infra-hub-api
```

```
NAME                   TYPE     DATA   AGE
postgres-credentials   Opaque   2      10s
server-ssh-key         Opaque   3      10s
```

```bash
microk8s kubectl get secrets -n ticket-hub-api
```

```
NAME                                 TYPE     DATA   AGE
postgres-credentials                 Opaque   2      10s
ticket-hub-api-service-credentials   Opaque   2      10s
```

### Borrar los archivos temporales

```bash
rm jwt_private.pem jwt_public.pem server_ssh_key
exit
```
