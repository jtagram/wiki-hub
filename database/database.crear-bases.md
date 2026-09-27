# Crear las bases de datos

Instructivo para levantar el servidor de PostgreSQL en el cluster y crear las 3 bases de datos que necesitan los backends (`iam-api`, `infra-hub-api`, `ticket-hub-api`), con sus tablas. El nombre de cada base de datos es igual al nombre de la app: `iam_api`, `infra_hub_api`, `ticket_hub_api` (con `_` en vez de `-`, porque Postgres no acepta `-` en un identificador sin comillas).

Todo esto se hace conectado por SSH al servidor `pcbox` sobre su IP de Tailscale (ver `pcbox/pcbox.bootstrap.md`):

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Antes de empezar, tené a mano las credenciales generadas por `wiki-hub/script/main.sh` (`POSTGRES_USER`, `POSTGRES_PASSWORD`) — si todavía no lo corriste, hacelo ahora. También asegurate de que el namespace `databases` ya exista (`microk8s/microk8s.namespace.md`).

## 1. Habilitar almacenamiento persistente en microk8s

Postgres necesita un `PersistentVolumeClaim` para no perder los datos si el Pod se reinicia. El addon de storage de microk8s todavía no está habilitado en este cluster (no se usó en ningún paso anterior):

```bash
sudo microk8s enable hostpath-storage
```

## 2. El Secret con las credenciales del servidor de Postgres

Este es el mismo Secret `postgres-credentials` del namespace `databases` que ya creaste en `microk8s/microk8s.secrets.md`, sección "2. Crear el secreto de PostgreSQL" — el contenedor de Postgres se inicializa con esos mismos valores, así que si ya seguiste ese instructivo no hay nada más que hacer acá.

## 3. Traer los archivos de este directorio al servidor

Todo lo que sigue (el manifiesto de Postgres y los 3 SQL) son archivos de este mismo directorio (`wiki-hub/database/`) — traé este repo al servidor si todavía no lo tenés ahí:

```bash
git clone https://github.com/jtagram/wiki-hub.git
cd wiki-hub/database
```

## 4. Desplegar el servidor de Postgres

El manifiesto (PVC + Deployment + Service) está en [`postgres.yaml`](postgres.yaml), en este mismo directorio:

```bash
microk8s kubectl apply -f postgres.yaml
```

Verificar que el Pod quede `Running` (puede tardar un poco la primera vez, mientras se crea el volumen y corre `initdb`):

```bash
microk8s kubectl get pods -n databases -w
```

Esto es lo que hace que `postgres.databases.svc.cluster.local:5432` (el host que ya usan `iam-api`, `infra-hub-api` y `ticket-hub-api`) responda.

## 5. Los 3 archivos SQL

También en este directorio hay 3 archivos SQL, uno por backend, generados a partir de las entidades TypeORM reales de cada uno (los 3 proyectos tienen `synchronize: false`, así que las tablas no se crean solas al arrancar la app — este paso es obligatorio):

- [`iam-api.sql`](iam-api.sql)
- [`infra-hub-api.sql`](infra-hub-api.sql)
- [`ticket-hub-api.sql`](ticket-hub-api.sql)

Cada archivo es autosuficiente: arranca con un `CREATE DATABASE` idempotente (simulado con `\gexec`, porque Postgres no tiene `CREATE DATABASE IF NOT EXISTS` nativo — solo ejecuta el `CREATE DATABASE` si esa base todavía no existe en `pg_database`), sigue con un `\c` a esa base recién creada, y termina con sus `CREATE TABLE IF NOT EXISTS`. Los 3 archivos se pueden volver a correr las veces que hagan falta sin romper nada — probado localmente contra un Postgres real, en limpio y también corriéndolos dos veces seguidas.

## 6. Crear las 3 bases y sus tablas

Como cada archivo es autosuficiente, se pueden concatenar y mandar los 3 en un solo comando contra el mismo Pod de Postgres:

```bash
cat iam-api.sql infra-hub-api.sql ticket-hub-api.sql | microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -v ON_ERROR_STOP=1
```

`<POSTGRES_USER-real>` es el mismo `POSTGRES_USER` generado por `wiki-hub/script/main.sh` (paso 2 de este mismo instructivo) — el que se cargó en el Secret `postgres-credentials` con el que arrancó el propio contenedor de Postgres.

## 7. Verificar

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -c '\l'
```

Tiene que aparecer `iam_api`, `infra_hub_api` y `ticket_hub_api` en la lista. Para confirmar las tablas de una en particular:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -d iam_api -c '\dt'
```
