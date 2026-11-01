# Crear los ServiceAccounts en los 3 ambientes

Desde tu PC cliente. Cada comando se ejecuta en la VM por SSH, sin abrir sesión.

Necesitas los namespaces de cada ambiente — [create-namespaces-for-three-environments.md](../02-microk8s-base/create-namespaces-for-three-environments.md).

Se crean todos los `ServiceAccount` de cada ambiente:

- `viewer-secrets-editor` (namespace `microk8s-access`): el usuario de acceso al cluster.
- `deployer` (namespace `microk8s-access`): el que usa `deploy-hub-api` para desplegar.
- Uno por app (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api`), cada uno en su namespace.

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local '
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
microk8s kubectl create serviceaccount deployer -n microk8s-access
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
'
```

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev '
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
microk8s kubectl create serviceaccount deployer -n microk8s-access
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
'
```

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod '
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
microk8s kubectl create serviceaccount deployer -n microk8s-access
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
'
```

## Verificar

En cada VM, el `get serviceaccounts` debe mostrar los 7 serviceaccounts de su ambiente:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local 'microk8s kubectl get serviceaccounts -A | grep -E "^(iam +iam|iam-api +iam-api|infra-hub-api +infra-hub-api|ticket-hub +ticket-hub|ticket-hub-api +ticket-hub-api|microk8s-access +(viewer-secrets-editor|deployer)) "'
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev 'microk8s kubectl get serviceaccounts -A | grep -E "^(iam +iam|iam-api +iam-api|infra-hub-api +infra-hub-api|ticket-hub +ticket-hub|ticket-hub-api +ticket-hub-api|microk8s-access +(viewer-secrets-editor|deployer)) "'
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod 'microk8s kubectl get serviceaccounts -A | grep -E "^(iam +iam|iam-api +iam-api|infra-hub-api +infra-hub-api|ticket-hub +ticket-hub|ticket-hub-api +ticket-hub-api|microk8s-access +(viewer-secrets-editor|deployer)) "'
```

El valor de `AGE` varía. Ejemplo en `dev`:

```
iam                iam                     0   1m
iam-api            iam-api                 0   1m
infra-hub-api      infra-hub-api           0   1m
microk8s-access    deployer                0   1m
microk8s-access    viewer-secrets-editor   0   1m
ticket-hub         ticket-hub              0   1m
ticket-hub-api     ticket-hub-api          0   1m
```

`0` en la columna `SECRETS` es lo esperado: desde Kubernetes 1.24 no se crea un Secret con token para cada serviceaccount. Los tokens de `viewer-secrets-editor` y `deployer` se piden en el siguiente paso: [create-tokens-for-three-environments.md](create-tokens-for-three-environments.md).

Si algún comando devuelve `Error from server (NotFound): namespaces "..." not found`, falta crear ese namespace en esa VM.

<div align="right">

[← Back](../set-up-the-ecosystem-jtagram.md)

</div>
