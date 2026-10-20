# Crear un usuario por ambiente para ver todo y editar secretos

Crea un usuario de Kubernetes en cada VM (`local`, `dev` y `prod`), con su propio kubeconfig para usarlo desde la PC cliente por Tailscale. El usuario es un `ServiceAccount` llamado `viewer-secrets-editor` en el namespace `microk8s-access`.

Los permisos del usuario se definen en dos pasos más: los roles ([create-roles-for-three-environments.md](create-roles-for-three-environments.md)) y su asignación ([create-rolebindings-for-three-environments.md](create-rolebindings-for-three-environments.md)). Con ellos, cada usuario podrá:

- **Ver todo el cluster de su VM** (`get`, `list`, `watch`), incluidos los valores de los Secrets.
- **Crear, editar y borrar Secrets solo en los namespaces de su ambiente.**
- **Nada más.** No podrá crear, borrar ni modificar ningún otro recurso.

Los cambios en el cluster (deploys, escalado, borrado) pasan por la ticketera. Los tres instructivos aplican el control técnico (RBAC) que lo hace cumplir.

Necesitas:

- Namespaces creados en las 3 VMs, incluido `microk8s-access` — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).
- Tu PC cliente con `kubectl` y conectada a la tailnet.

Mientras no existan los roles y sus asignaciones, el usuario recibe `Forbidden` en cualquier operación. Es lo esperado: no lo uses hasta completar [create-rolebindings-for-three-environments.md](create-rolebindings-for-three-environments.md).

Los pasos de cada ambiente se ejecutan desde tu PC cliente, dentro de la VM.

---

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Usuario

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
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

```bash
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

### Usuario

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
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

```bash
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

### Usuario

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
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

## Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `viewer-secrets-editor` | `ServiceAccount` en `microk8s-access` | Identidad del usuario de cada ambiente |
| `viewer-secrets-editor-token` | Secret con el token de cada usuario | Fuente del token. Para revocar el acceso, bórralo |
| `pcbox-kubeconfig-viewer-<ambiente>.yaml` | Kubeconfig del usuario | Lo que usa la PC cliente para conectarse |

<p align="right"><a href="set-up-the-ecosystem-jtagram.md">← Back</a></p>
