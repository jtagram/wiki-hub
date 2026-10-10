# Crear serviceaccounts en los 3 ambientes

Cada app corre con su propio `ServiceAccount`, que lleva el mismo nombre de la app. El `Deployment` lo referencia con `serviceAccountName: <app>`. Si no existe, el Pod no se crea (`FailedCreate`).

Se crea una sola vez por app y por ambiente, antes del primer deploy. Cada VM solo necesita los de su ambiente.

Necesitas los namespaces creados en las 3 VMs — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).

Todos los comandos se ejecutan desde tu PC cliente, dentro de cada VM.

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM:

```bash
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
microk8s kubectl get serviceaccounts -A | grep -E "^(iam|iam-api|infra-hub-api|ticket-hub|ticket-hub-api) "
exit
```

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM:

```bash
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
microk8s kubectl get serviceaccounts -A | grep -E "^(iam|iam-api|infra-hub-api|ticket-hub|ticket-hub-api) "
exit
```

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM:

```bash
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
microk8s kubectl get serviceaccounts -A | grep -E "^(iam|iam-api|infra-hub-api|ticket-hub|ticket-hub-api) "
exit
```

## Verificar

En cada VM, el `get serviceaccounts` debe mostrar los 5 serviceaccounts de su ambiente. El valor de `AGE` varía. Ejemplo en `dev`:

```
iam                iam              0   1m
iam-api            iam-api          0   1m
infra-hub-api      infra-hub-api    0   1m
ticket-hub         ticket-hub       0   1m
ticket-hub-api     ticket-hub-api   0   1m
```

`0` en la columna `SECRETS` es lo esperado: desde Kubernetes 1.24 no se crea un Secret con token para cada serviceaccount.

Si algún comando devuelve `Error from server (NotFound): namespaces "..." not found`, falta crear ese namespace en esa VM.
