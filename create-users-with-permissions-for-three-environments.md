# Crear un usuario por ambiente para ver todo y editar secretos

Crea un usuario de Kubernetes en cada VM (`local`, `dev` y `prod`), con su propio kubeconfig para usarlo desde la PC cliente por Tailscale. Cada usuario puede:

- **Ver todo el cluster de su VM** (`get`, `list`, `watch`), incluidos los valores de los Secrets.
- **Crear, editar y borrar Secrets solo en los namespaces de su ambiente.**
- **Nada más.** No puede crear, borrar ni modificar ningún otro recurso.

Los cambios en el cluster (deploys, escalado, borrado) pasan por la ticketera. Este instructivo aplica el control técnico (RBAC) que lo hace cumplir.

Necesitas:

- El addon `rbac` habilitado en las 3 VMs — [install-microk8s-for-three-environments.md](install-microk8s-for-three-environments.md). Compruébalo con `microk8s status | grep rbac` dentro de cada VM: debe aparecer bajo `enabled`. Sin RBAC los permisos de este instructivo no se aplican.
- Namespaces creados en las 3 VMs, incluido `microk8s-access` — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).
- Tu PC cliente con `kubectl` y conectada a la tailnet.

Namespaces de cada ambiente donde el usuario edita Secrets: `iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`, `databases` y `tailscale`, con el prefijo del ambiente.

Los pasos de cada ambiente se ejecutan desde tu PC cliente, dentro de la VM.

---

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Certificado del API server

El API server solo acepta conexiones a las IPs de su certificado. Hay que agregar la IP de Tailscale de la VM.

Obtén la IP y edita la plantilla del certificado:

```bash
tailscale ip -4
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]`, **sin reemplazar ninguna línea existente**, agrega una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

Regenera el certificado y espera a que el cluster esté listo:

```bash
sudo microk8s refresh-certs -e server.crt
microk8s status --wait-ready
```

### Permisos

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-editor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access

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

### Token y kubeconfig

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Este token no expira.

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: viewer-secrets-editor-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: viewer-secrets-editor
type: kubernetes.io/service-account-token
EOF
```

Espera unos segundos a que Kubernetes rellene el campo `token` y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-viewer-local.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-local
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-viewer-local
    context:
      cluster: pcbox-local
      user: viewer-local
current-context: microk8s-viewer-local
users:
  - name: viewer-local
    user:
      token: $TOKEN
EOF
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

### Certificado del API server

El API server solo acepta conexiones a las IPs de su certificado. Hay que agregar la IP de Tailscale de la VM.

Obtén la IP y edita la plantilla del certificado:

```bash
tailscale ip -4
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]`, **sin reemplazar ninguna línea existente**, agrega una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

Regenera el certificado y espera a que el cluster esté listo:

```bash
sudo microk8s refresh-certs -e server.crt
microk8s status --wait-ready
```

### Permisos

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-editor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access

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

### Token y kubeconfig

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Este token no expira.

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: viewer-secrets-editor-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: viewer-secrets-editor
type: kubernetes.io/service-account-token
EOF
```

Espera unos segundos a que Kubernetes rellene el campo `token` y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-viewer-dev.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-dev
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-viewer-dev
    context:
      cluster: pcbox-dev
      user: viewer-dev
current-context: microk8s-viewer-dev
users:
  - name: viewer-dev
    user:
      token: $TOKEN
EOF
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

### Certificado del API server

El API server solo acepta conexiones a las IPs de su certificado. Hay que agregar la IP de Tailscale de la VM.

Obtén la IP y edita la plantilla del certificado:

```bash
tailscale ip -4
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]`, **sin reemplazar ninguna línea existente**, agrega una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

Regenera el certificado y espera a que el cluster esté listo:

```bash
sudo microk8s refresh-certs -e server.crt
microk8s status --wait-ready
```

### Permisos

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-editor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access

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

### Token y kubeconfig

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Este token no expira.

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: viewer-secrets-editor-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: viewer-secrets-editor
type: kubernetes.io/service-account-token
EOF
```

Espera unos segundos a que Kubernetes rellene el campo `token` y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-viewer-prod.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-prod
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-viewer-prod
    context:
      cluster: pcbox-prod
      user: viewer-prod
current-context: microk8s-viewer-prod
users:
  - name: viewer-prod
    user:
      token: $TOKEN
EOF
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

## Bajar los kubeconfig a la PC cliente

Desde la PC cliente. Los archivos contienen tokens: no se commitean.

```bash
scp -i ~/.ssh/pcbox_local ubuntu@pcbox-local:~/pcbox-kubeconfig-viewer-local.yaml .
scp -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev:~/pcbox-kubeconfig-viewer-dev.yaml .
scp -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod:~/pcbox-kubeconfig-viewer-prod.yaml .
```

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

Si un comando que debía fallar se ejecuta, revisa los `ClusterRole` del paso de permisos: no debe haber verbos de escritura fuera de los Secrets.

## Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `viewer-secrets-editor` | `ServiceAccount` en `microk8s-access` | Identidad del usuario de cada ambiente |
| `cluster-viewer` | `ClusterRole` de solo lectura | Permite ver todo el cluster de la VM |
| `secrets-editor` | `ClusterRole` que escribe Secrets | Se asigna con un `RoleBinding` en cada namespace del ambiente, así que solo vale ahí |
| `viewer-secrets-editor-token` | Secret con el token de cada usuario | Fuente del token. Para revocar el acceso, bórralo |
| `pcbox-kubeconfig-viewer-<ambiente>.yaml` | Kubeconfig del usuario | Lo que usa la PC cliente para conectarse |
