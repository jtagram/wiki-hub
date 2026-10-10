# Crear las bases de datos en los 3 ambientes

Levanta un PostgreSQL en cada VM y crea las 3 bases de los backends: `iam_api`, `infra_hub_api` y `ticket_hub_api`. Cada VM tiene su propio servidor en su namespace `databases`.

Necesitas:

- Namespaces creados en las 3 VMs — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).
- Secret `postgres-credentials` en `databases` — [create-secrets-for-three-environments.md](create-secrets-for-three-environments.md).
- El `POSTGRES_USER` de cada ambiente, del bloque generado por [main.sh](generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md): `jtagram_local`, `jtagram_dev` y `jtagram_prod`.

## Archivos usados

Están en la carpeta [create-databases/](create-databases/):

| Archivo | Qué hace |
|---|---|
| [postgres.yaml](create-databases/postgres.yaml) | PVC, Deployment y Service de Postgres (sin namespace; se indica con `-n`). |
| [iam-api.sql](create-databases/iam-api.sql) | Crea la base `iam_api` y sus tablas. |
| [infra-hub-api.sql](create-databases/infra-hub-api.sql) | Crea la base `infra_hub_api` y sus tablas. |
| [ticket-hub-api.sql](create-databases/ticket-hub-api.sql) | Crea la base `ticket_hub_api` y sus tablas. |

Los SQL son idempotentes: se pueden volver a ejecutar sin romper nada. Son necesarios porque los backends no crean las tablas solos.

## local

Desde tu PC cliente, dentro de la carpeta `create-databases/`, copia los archivos a la VM:

```bash
scp -i ~/.ssh/pcbox_local postgres.yaml iam-api.sql infra-hub-api.sql ticket-hub-api.sql ubuntu@pcbox-local:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, habilita el almacenamiento persistente y despliega Postgres:

```bash
sudo microk8s enable hostpath-storage
microk8s kubectl apply -n databases -f postgres.yaml
microk8s kubectl get pods -n databases -w
```

Espera a que el pod esté `Running` y `READY 1/1`, y sal del `-w` con `Ctrl+C`. Salida esperada:

```
NAME                        READY   STATUS    RESTARTS   AGE
postgres-7d9c8b6f5d-x2k4m   1/1     Running   0          45s
```

Crea las bases y tablas:

```bash
cat iam-api.sql infra-hub-api.sql ticket-hub-api.sql | \
  microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -v ON_ERROR_STOP=1
```

Verifica. La lista debe incluir `iam_api`, `infra_hub_api` y `ticket_hub_api`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -c '\l'
```

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d iam_api -c '\dt'
exit
```

El segundo comando debe listar las tablas de `iam_api`, con `Schema` `public` y `Type` `table`.

## dev

Desde tu PC cliente, dentro de la carpeta `create-databases/`, copia los archivos a la VM:

```bash
scp -i ~/.ssh/pcbox_dev postgres.yaml iam-api.sql infra-hub-api.sql ticket-hub-api.sql ubuntu@pcbox-dev:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, habilita el almacenamiento persistente y despliega Postgres:

```bash
sudo microk8s enable hostpath-storage
microk8s kubectl apply -n databases -f postgres.yaml
microk8s kubectl get pods -n databases -w
```

Espera a que el pod esté `Running` y `READY 1/1`, y sal del `-w` con `Ctrl+C`. Salida esperada:

```
NAME                        READY   STATUS    RESTARTS   AGE
postgres-7d9c8b6f5d-x2k4m   1/1     Running   0          45s
```

Crea las bases y tablas:

```bash
cat iam-api.sql infra-hub-api.sql ticket-hub-api.sql | \
  microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -v ON_ERROR_STOP=1
```

Verifica. La lista debe incluir `iam_api`, `infra_hub_api` y `ticket_hub_api`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -c '\l'
```

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d iam_api -c '\dt'
exit
```

El segundo comando debe listar las tablas de `iam_api`, con `Schema` `public` y `Type` `table`.

## prod

Desde tu PC cliente, dentro de la carpeta `create-databases/`, copia los archivos a la VM:

```bash
scp -i ~/.ssh/pcbox_prod postgres.yaml iam-api.sql infra-hub-api.sql ticket-hub-api.sql ubuntu@pcbox-prod:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, habilita el almacenamiento persistente y despliega Postgres:

```bash
sudo microk8s enable hostpath-storage
microk8s kubectl apply -n databases -f postgres.yaml
microk8s kubectl get pods -n databases -w
```

Espera a que el pod esté `Running` y `READY 1/1`, y sal del `-w` con `Ctrl+C`. Salida esperada:

```
NAME                        READY   STATUS    RESTARTS   AGE
postgres-7d9c8b6f5d-x2k4m   1/1     Running   0          45s
```

Crea las bases y tablas:

```bash
cat iam-api.sql infra-hub-api.sql ticket-hub-api.sql | \
  microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -v ON_ERROR_STOP=1
```

Verifica. La lista debe incluir `iam_api`, `infra_hub_api` y `ticket_hub_api`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -c '\l'
```

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d iam_api -c '\dt'
exit
```

El segundo comando debe listar las tablas de `iam_api`, con `Schema` `public` y `Type` `table`.

## Host para las aplicaciones

Dentro del cluster de cada VM, Postgres responde en:

```
postgres.databases.svc.cluster.local:5432
```
