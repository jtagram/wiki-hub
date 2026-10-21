# Asignar los roles al usuario en los 3 ambientes

Asigna los roles al `ServiceAccount` `viewer-secrets-editor` en cada VM (`local`, `dev` y `prod`):

- Un `ClusterRoleBinding` le da `cluster-viewer`: ve todo el cluster.
- Un `RoleBinding` por namespace le da `secrets-editor`: edita Secrets solo en los namespaces de su ambiente.

Al terminar, el usuario puede:

- **Ver todo el cluster de su VM** (`get`, `list`, `watch`), incluidos los valores de los Secrets.
- **Crear, editar y borrar Secrets solo en los namespaces de su ambiente.**
- **Nada más.**

Necesitas:

- El usuario y su token — [create-users-for-three-environments.md](create-users-for-three-environments.md).
- El kubeconfig del usuario — [create-kubeconfig-for-three-environments.md](create-kubeconfig-for-three-environments.md).
- Los roles `cluster-viewer` y `secrets-editor` — [create-roles-for-three-environments.md](create-roles-for-three-environments.md).
- Los namespaces de cada ambiente — [create-namespaces-for-three-environments.md](../02-microk8s-base/create-namespaces-for-three-environments.md).
- Tu PC cliente con `kubectl` y conectada a la tailnet.

Namespaces de cada ambiente donde el usuario edita Secrets: `iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`, `databases` y `tailscale`, con el prefijo del ambiente.

Los pasos de cada ambiente se ejecutan desde tu PC cliente, dentro de la VM.

---

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Asignaciones

```bash
microk8s kubectl create clusterrolebinding local-viewer-secrets-editor-view \
  --clusterrole=cluster-viewer \
  --serviceaccount=microk8s-access:viewer-secrets-editor
```

```bash
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n iam --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n iam-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n infra-hub-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n ticket-hub --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n ticket-hub-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n databases --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n tailscale --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
```

### Verificar permisos en la VM

Con `auth can-i` se comprueba cada permiso sin tocar nada:

```bash
SA=system:serviceaccount:microk8s-access:viewer-secrets-editor

microk8s kubectl auth can-i get pods -A --as=$SA
microk8s kubectl auth can-i get secrets -A --as=$SA
microk8s kubectl auth can-i create secrets -n iam-api --as=$SA
microk8s kubectl auth can-i delete secrets -n iam-api --as=$SA
```

Los cuatro deben responder `yes`. Ahora lo que debe fallar:

```bash
microk8s kubectl auth can-i create secrets -n default --as=$SA
microk8s kubectl auth can-i create secrets -n microk8s-access --as=$SA
microk8s kubectl auth can-i delete pods -n iam-api --as=$SA
microk8s kubectl auth can-i update deployments -n iam-api --as=$SA
```

Los cuatro deben responder `no`.

```bash
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

### Asignaciones

```bash
microk8s kubectl create clusterrolebinding dev-viewer-secrets-editor-view \
  --clusterrole=cluster-viewer \
  --serviceaccount=microk8s-access:viewer-secrets-editor
```

```bash
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n iam --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n iam-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n infra-hub-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n ticket-hub --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n ticket-hub-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n databases --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n tailscale --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
```

### Verificar permisos en la VM

Con `auth can-i` se comprueba cada permiso sin tocar nada:

```bash
SA=system:serviceaccount:microk8s-access:viewer-secrets-editor

microk8s kubectl auth can-i get pods -A --as=$SA
microk8s kubectl auth can-i get secrets -A --as=$SA
microk8s kubectl auth can-i create secrets -n iam-api --as=$SA
microk8s kubectl auth can-i delete secrets -n iam-api --as=$SA
```

Los cuatro deben responder `yes`. Ahora lo que debe fallar:

```bash
microk8s kubectl auth can-i create secrets -n default --as=$SA
microk8s kubectl auth can-i create secrets -n microk8s-access --as=$SA
microk8s kubectl auth can-i delete pods -n iam-api --as=$SA
microk8s kubectl auth can-i update deployments -n iam-api --as=$SA
```

Los cuatro deben responder `no`.

```bash
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

### Asignaciones

```bash
microk8s kubectl create clusterrolebinding prod-viewer-secrets-editor-view \
  --clusterrole=cluster-viewer \
  --serviceaccount=microk8s-access:viewer-secrets-editor
```

```bash
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n iam --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n iam-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n infra-hub-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n ticket-hub --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n ticket-hub-api --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n databases --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
microk8s kubectl create rolebinding viewer-secrets-editor-binding -n tailscale --clusterrole=secrets-editor --serviceaccount=microk8s-access:viewer-secrets-editor
```

### Verificar permisos en la VM

Con `auth can-i` se comprueba cada permiso sin tocar nada:

```bash
SA=system:serviceaccount:microk8s-access:viewer-secrets-editor

microk8s kubectl auth can-i get pods -A --as=$SA
microk8s kubectl auth can-i get secrets -A --as=$SA
microk8s kubectl auth can-i create secrets -n iam-api --as=$SA
microk8s kubectl auth can-i delete secrets -n iam-api --as=$SA
```

Los cuatro deben responder `yes`. Ahora lo que debe fallar:

```bash
microk8s kubectl auth can-i create secrets -n default --as=$SA
microk8s kubectl auth can-i create secrets -n microk8s-access --as=$SA
microk8s kubectl auth can-i delete pods -n iam-api --as=$SA
microk8s kubectl auth can-i update deployments -n iam-api --as=$SA
```

Los cuatro deben responder `no`.

```bash
exit
```

---

## Verificar desde la PC cliente

Ejemplo con `dev`. Repite con `local` y `prod` cambiando el archivo y el namespace.

```bash
KC=pcbox-kubeconfig-viewer-dev.yaml

kubectl --kubeconfig=$KC get pods -A
kubectl --kubeconfig=$KC create secret generic test-secret -n iam-api --from-literal=x=1
kubectl --kubeconfig=$KC delete secret test-secret -n iam-api
```

El `get` lista los Pods del cluster. El `create` responde `secret/test-secret created` y el `delete` responde `secret "test-secret" deleted`.

Ahora lo que debe fallar:

```bash
kubectl --kubeconfig=$KC create secret generic test-secret -n default --from-literal=x=1
kubectl --kubeconfig=$KC delete pod <nombre-de-un-pod> -n iam-api
```

Ambos deben devolver `Forbidden`:

```
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:microk8s-access:viewer-secrets-editor" cannot create resource "secrets" in API group "" in the namespace "default"
```

Si un comando que debía fallar se ejecuta, revisa los `ClusterRole` de [create-roles-for-three-environments.md](create-roles-for-three-environments.md): no debe haber verbos de escritura fuera de los Secrets.

## Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `<ambiente>-viewer-secrets-editor-view` | `ClusterRoleBinding` | Le da `cluster-viewer` al usuario: ve todo el cluster de la VM |
| `viewer-secrets-editor-binding` | `RoleBinding` en cada namespace del ambiente | Le da `secrets-editor` al usuario solo en ese namespace |

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
