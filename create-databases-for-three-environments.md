# Crear las bases de datos en los 3 ambientes

Crea las 3 bases de los backends en el PostgreSQL de cada VM: `iam_api`, `infra_hub_api` y `ticket_hub_api`. Las tablas se crean después, en [create-tables-for-three-environments.md](create-tables-for-three-environments.md).

Necesitas:

- PostgreSQL desplegado y en `Running` en las 3 VMs — [deploy-postgres-for-three-environments.md](deploy-postgres-for-three-environments.md).
- El `POSTGRES_USER` de cada ambiente, del bloque generado por [main.sh](generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md): `jtagram_local`, `jtagram_dev` y `jtagram_prod`.

## Archivos usados

Están en la carpeta [create-databases/](create-databases/):

| Archivo | Qué hace |
|---|---|
| [create-databases.sql](create-databases/create-databases.sql) | Crea las bases `iam_api`, `infra_hub_api` y `ticket_hub_api`. |

El SQL es idempotente: se puede volver a ejecutar sin romper nada. Una base que ya existe se omite.

## local

Desde tu PC cliente, dentro de la carpeta `create-databases/`, copia el archivo a la VM:

```bash
scp -i ~/.ssh/pcbox_local create-databases.sql ubuntu@pcbox-local:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, crea las bases:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -v ON_ERROR_STOP=1 < create-databases.sql
```

Verifica. La lista debe incluir `iam_api`, `infra_hub_api` y `ticket_hub_api`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -c '\l'
exit
```

## dev

Desde tu PC cliente, dentro de la carpeta `create-databases/`, copia el archivo a la VM:

```bash
scp -i ~/.ssh/pcbox_dev create-databases.sql ubuntu@pcbox-dev:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, crea las bases:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -v ON_ERROR_STOP=1 < create-databases.sql
```

Verifica. La lista debe incluir `iam_api`, `infra_hub_api` y `ticket_hub_api`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -c '\l'
exit
```

## prod

Desde tu PC cliente, dentro de la carpeta `create-databases/`, copia el archivo a la VM:

```bash
scp -i ~/.ssh/pcbox_prod create-databases.sql ubuntu@pcbox-prod:~/
```

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, crea las bases:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -v ON_ERROR_STOP=1 < create-databases.sql
```

Verifica. La lista debe incluir `iam_api`, `infra_hub_api` y `ticket_hub_api`:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -c '\l'
exit
```

<p align="right"><a href="set-up-the-ecosystem-jtagram.md">← Back</a></p>
