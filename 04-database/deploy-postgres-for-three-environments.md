# Desplegar PostgreSQL en los 3 ambientes

## Archivos usados

Están en la carpeta [deploy-postgres/](deploy-postgres):

| Archivo | Qué hace |
|---|---|
| [postgres.yaml](deploy-postgres/postgres.yaml) | PVC, Deployment y Service de Postgres (sin namespace; se indica con `-n`). |

## local

Desde tu PC cliente, dentro de la carpeta `deploy-postgres/`, copia el archivo a la VM:

```bash
scp -i ~/.ssh/pcbox_local postgres.yaml ubuntu@pcbox-local:~/
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

```bash
exit
```

## dev

Desde tu PC cliente, dentro de la carpeta `deploy-postgres/`, copia el archivo a la VM:

```bash
scp -i ~/.ssh/pcbox_dev postgres.yaml ubuntu@pcbox-dev:~/
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

```bash
exit
```

## prod

Desde tu PC cliente, dentro de la carpeta `deploy-postgres/`, copia el archivo a la VM:

```bash
scp -i ~/.ssh/pcbox_prod postgres.yaml ubuntu@pcbox-prod:~/
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

```bash
exit
```

## Host para las aplicaciones

Dentro del cluster de cada VM, Postgres responde en:

```
postgres.databases.svc.cluster.local:5432
```

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
