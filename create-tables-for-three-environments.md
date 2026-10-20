# Crear las tablas en los 3 ambientes

Crea las tablas de cada base de los backends (`iam_api`, `infra_hub_api` y `ticket_hub_api`) en el PostgreSQL de cada VM. Son necesarias porque los backends no crean las tablas solos.

Necesitas:

- Las 3 bases creadas en las 3 VMs — [create-databases-for-three-environments.md](create-databases-for-three-environments.md).
- El `POSTGRES_USER` de cada ambiente: `jtagram_local`, `jtagram_dev` y `jtagram_prod`.

## Archivos usados

Están en la carpeta [create-tables/](create-tables/):

| Archivo | Qué hace |
|---|---|
| [iam-api.sql](create-tables/iam-api.sql) | Crea las tablas de `iam_api`. |
| [infra-hub-api.sql](create-tables/infra-hub-api.sql) | Crea la extensión `uuid-ossp` y las tablas de `infra_hub_api`. |
| [ticket-hub-api.sql](create-tables/ticket-hub-api.sql) | Crea las tablas de `ticket_hub_api`. |

Los SQL son idempotentes: se pueden volver a ejecutar sin romper nada. No crean la base ni cambian de base: cada uno se ejecuta con `psql -d <base>`.

## local

Desde tu PC cliente, dentro de la carpeta `create-tables/`, copia los archivos a la VM:

```bash
scp -i ~/.ssh/pcbox_local iam-api.sql infra-hub-api.sql ticket-hub-api.sql ubuntu@pcbox-local:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, crea las tablas de cada base:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d iam_api -v ON_ERROR_STOP=1 < iam-api.sql

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d infra_hub_api -v ON_ERROR_STOP=1 < infra-hub-api.sql

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d ticket_hub_api -v ON_ERROR_STOP=1 < ticket-hub-api.sql
```

Verifica. Cada comando debe listar las tablas de su base, con `Schema` `public` y `Type` `table`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d iam_api -c '\dt'

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d infra_hub_api -c '\dt'

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d ticket_hub_api -c '\dt'
exit
```

## dev

Desde tu PC cliente, dentro de la carpeta `create-tables/`, copia los archivos a la VM:

```bash
scp -i ~/.ssh/pcbox_dev iam-api.sql infra-hub-api.sql ticket-hub-api.sql ubuntu@pcbox-dev:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, crea las tablas de cada base:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d iam_api -v ON_ERROR_STOP=1 < iam-api.sql

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d infra_hub_api -v ON_ERROR_STOP=1 < infra-hub-api.sql

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d ticket_hub_api -v ON_ERROR_STOP=1 < ticket-hub-api.sql
```

Verifica. Cada comando debe listar las tablas de su base, con `Schema` `public` y `Type` `table`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d iam_api -c '\dt'

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d infra_hub_api -c '\dt'

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d ticket_hub_api -c '\dt'
exit
```

## prod

Desde tu PC cliente, dentro de la carpeta `create-tables/`, copia los archivos a la VM:

```bash
scp -i ~/.ssh/pcbox_prod iam-api.sql infra-hub-api.sql ticket-hub-api.sql ubuntu@pcbox-prod:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, crea las tablas de cada base:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d iam_api -v ON_ERROR_STOP=1 < iam-api.sql

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d infra_hub_api -v ON_ERROR_STOP=1 < infra-hub-api.sql

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d ticket_hub_api -v ON_ERROR_STOP=1 < ticket-hub-api.sql
```

Verifica. Cada comando debe listar las tablas de su base, con `Schema` `public` y `Type` `table`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d iam_api -c '\dt'

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d infra_hub_api -c '\dt'

microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d ticket_hub_api -c '\dt'
exit
```

<p align="right"><a href="set-up-the-ecosystem-jtagram.md">← Back</a></p>
