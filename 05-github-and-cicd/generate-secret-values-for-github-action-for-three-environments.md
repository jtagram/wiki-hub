# Obtener los secretos de GitHub Actions de los 3 ambientes

Instructivo para obtener los valores que usan los workflows de GitHub Actions en `prod`, `dev` y `local`. Solo explica **cómo conseguir cada valor**. Cómo cargarlos en GitHub está en [load-secrets-for-github-action-for-three-environments.md](load-secrets-for-github-action-for-three-environments.md).

Los secretos **no llevan prefijo de ambiente**: tienen el mismo nombre en los tres y un valor distinto en cada uno. Anota los valores de cada ambiente en un lugar seguro: el siguiente paso los necesita.

Necesitas:

- Repositorios clonados — [clone-organization-repositories.md](clone-organization-repositories.md).
- Las 3 VMs con MicroK8s y el certificado del API server extendido con su IP de Tailscale — sección "Certificado del API server" de [create-users-for-three-environments.md](../03-cluster-secrets-and-access/create-users-for-three-environments.md). Sin eso, el kubeconfig de abajo no puede conectarse.

El kubeconfig de cada ambiente es el del ServiceAccount `deployer` de esa VM, con permisos limitados a desplegar las apps. No es el de administración ni el de solo lectura del usuario `viewer`. Lo usa `deploy-hub-api` para desplegar.

Secretos de cada ambiente, todos en `deploy-hub-api`: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`. En `prod` y `dev` se suma `APP_REPO_TOKEN` (para subir los tags de git a las apps). En `local` se suma `DISPATCH_DEPLOY_HUB_API_LOCAL`, un token que se carga en cada app para que dispare el deploy de local.

---

## PROD

Environment de GitHub: `prod`.

### DOCKERHUB_USERNAME y DOCKERHUB_TOKEN

- `DOCKERHUB_USERNAME`: username de la cuenta en [hub.docker.com](https://hub.docker.com/).
- `DOCKERHUB_TOKEN`: Personal Access Token (no la contraseña):
  1. **Account settings → Personal access tokens → Generate new token** (menú lateral izquierdo de [app.docker.com/settings](https://app.docker.com/settings)).
  2. Descripción (ej. `github-actions-prod`) y permisos **Read, Write & Delete** (Delete es necesario porque el job `cleanup-tags` elimina los tags anteriores en Docker Hub).
  3. Copiar el token al generarlo; no se vuelve a mostrar.

### KUBECONFIG_MICROK8S

Kubeconfig del ServiceAccount `deployer` del cluster de la VM `prod`. Solo puede desplegar las apps; no es el de administración.

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, crea los permisos mínimos:

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: app-deployer
rules:
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["replicasets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployer-cluster
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["namespaces"]
    resourceNames: ["iam", "iam-api", "infra-hub-api", "ticket-hub", "ticket-hub-api"]
    verbs: ["get", "patch"]
EOF
```

Crea el ServiceAccount y asígnale los permisos en cada namespace de las apps:

```bash
microk8s kubectl create serviceaccount deployer -n microk8s-access
microk8s kubectl create clusterrolebinding deployer-cluster --clusterrole=deployer-cluster --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n iam --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n iam-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n infra-hub-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n ticket-hub --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n ticket-hub-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
```

Pide el token (no expira) y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
EOF
```

Espera unos segundos a que Kubernetes rellene el campo `token` y genera el archivo:

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret deployer-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-deployer-prod.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-prod
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-deployer-prod
    context:
      cluster: pcbox-prod
      user: deployer-prod
current-context: microk8s-deployer-prod
users:
  - name: deployer-prod
    user:
      token: $TOKEN
EOF
```

Verifica los permisos antes de salir. Los dos primeros deben responder `yes` y los dos últimos `no`:

```bash
microk8s kubectl auth can-i patch deployments -n infra-hub-api --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i list nodes --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i get secrets -n databases --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i create clusterrolebindings --as=system:serviceaccount:microk8s-access:deployer
```

Sal de la VM y cópialo a tu PC cliente:

```bash
exit
scp -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod:~/pcbox-kubeconfig-deployer-prod.yaml .
```

Deja el archivo en la carpeta desde la que vas a cargar los secretos. No lo commitees: contiene un token.

### TS_OAUTH_CLIENT_ID y TS_OAUTH_SECRET

1. Abrir la [consola de Tailscale](https://login.tailscale.com/admin).
2. **Settings → Trust credentials → + Credential**, elegir el tipo **OAuth** y en **Description** poner `github-actions-prod` (es solo una referencia interna), luego **Continue**.
3. Scope: **Auth Keys** con `write` (es el que usa `tailscale/github-action` para crear la clave efímera del runner).
4. Tag: `tag:continuous-integration`.
5. Copiar **Client ID** y **Client Secret**; el secret se muestra una sola vez.

### APP_REPO_TOKEN

Lo usa `deploy.yml` para clonar la app y crear y subir el tag de git `new_tag` en el repo de la app (job `build-and-push`). Se carga en `deploy-hub-api`, no en las apps. Es un Personal Access Token **fine-grained**:

1. **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
   - Token name: `app-repo-token-prod`.
   - Description: `Sube los tags de git de las apps desde deploy-hub-api (prod)`.
   - Expiration: definir una fecha (ej. 90 días) y anotarla; al vencer, el deploy falla al crear el tag.
2. Resource owner: la **organización** a la que pertenecen las apps (no tu usuario personal). Si la organización exige aprobación de tokens, aprobarlo en **Organization settings → Personal access tokens → Pending requests**.
3. Repository access: **Only select repositories** y elegir los 5 repos de apps: `iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api`. No hace falta `deploy-hub-api`.
4. Permissions: `Contents` Read and write (necesario para subir el tag). Nada más.
5. Copiar el token al generarlo.

Con escritura en `Contents`, el token también podría pushear código a esos repos. Para limitar el daño si se filtra, protege las ramas `dev` y `master` de las apps (PR obligatorio).

---

## DEV

### DOCKERHUB_USERNAME y DOCKERHUB_TOKEN

- `DOCKERHUB_USERNAME`: username de la cuenta en [hub.docker.com](https://hub.docker.com/).
- `DOCKERHUB_TOKEN`: Personal Access Token (no la contraseña):
  1. **Account settings → Personal access tokens → Generate new token** (menú lateral izquierdo de [app.docker.com/settings](https://app.docker.com/settings)).
  2. Descripción (ej. `github-actions-dev`) y permisos **Read, Write & Delete** (Delete es necesario porque el job `cleanup-tags` elimina los tags anteriores en Docker Hub).
  3. Copiar el token al generarlo; no se vuelve a mostrar.

### KUBECONFIG_MICROK8S

Kubeconfig del ServiceAccount `deployer` del cluster de la VM `dev`. Solo puede desplegar las apps; no es el de administración.

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, crea los permisos mínimos:

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: app-deployer
rules:
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["replicasets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployer-cluster
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["namespaces"]
    resourceNames: ["iam", "iam-api", "infra-hub-api", "ticket-hub", "ticket-hub-api"]
    verbs: ["get", "patch"]
EOF
```

Crea el ServiceAccount y asígnale los permisos en cada namespace de las apps:

```bash
microk8s kubectl create serviceaccount deployer -n microk8s-access
microk8s kubectl create clusterrolebinding deployer-cluster --clusterrole=deployer-cluster --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n iam --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n iam-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n infra-hub-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n ticket-hub --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n ticket-hub-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
```

Pide el token (no expira) y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
EOF
```

Espera unos segundos a que Kubernetes rellene el campo `token` y genera el archivo:

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret deployer-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-deployer-dev.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-dev
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-deployer-dev
    context:
      cluster: pcbox-dev
      user: deployer-dev
current-context: microk8s-deployer-dev
users:
  - name: deployer-dev
    user:
      token: $TOKEN
EOF
```

Verifica los permisos antes de salir. Los dos primeros deben responder `yes` y los dos últimos `no`:

```bash
microk8s kubectl auth can-i patch deployments -n infra-hub-api --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i list nodes --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i get secrets -n databases --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i create clusterrolebindings --as=system:serviceaccount:microk8s-access:deployer
```

Sal de la VM y cópialo a tu PC cliente:

```bash
exit
scp -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev:~/pcbox-kubeconfig-deployer-dev.yaml .
```

Deja el archivo en la carpeta desde la que vas a cargar los secretos. No lo commitees: contiene un token.

### TS_OAUTH_CLIENT_ID y TS_OAUTH_SECRET

1. Abrir la [consola de Tailscale](https://login.tailscale.com/admin).
2. **Settings → Trust credentials → + Credential**, elegir el tipo **OAuth** y en **Description** poner `github-actions-dev` (es solo una referencia interna), luego **Continue**.
3. Scope: **Auth Keys** con `write` (es el que usa `tailscale/github-action` para crear la clave efímera del runner).
4. Tag: `tag:continuous-integration`.
5. Copiar **Client ID** y **Client Secret**; el secret se muestra una sola vez.

### APP_REPO_TOKEN

Lo usa `deploy.yml` para clonar la app y crear y subir el tag de git `new_tag` en el repo de la app (job `build-and-push`). Se carga en `deploy-hub-api`, no en las apps. Es un Personal Access Token **fine-grained**:

1. **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
   - Token name: `app-repo-token-dev`.
   - Description: `Sube los tags de git de las apps desde deploy-hub-api (dev)`.
   - Expiration: definir una fecha (ej. 90 días) y anotarla; al vencer, el deploy falla al crear el tag.
2. Resource owner: la **organización** a la que pertenecen las apps (no tu usuario personal). Si la organización exige aprobación de tokens, aprobarlo en **Organization settings → Personal access tokens → Pending requests**.
3. Repository access: **Only select repositories** y elegir los 5 repos de apps: `iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api`. No hace falta `deploy-hub-api`.
4. Permissions: `Contents` Read and write (necesario para subir el tag). Nada más.
5. Copiar el token al generarlo.

Con escritura en `Contents`, el token también podría pushear código a esos repos. Para limitar el daño si se filtra, protege las ramas `dev` y `master` de las apps (PR obligatorio).

---

## LOCAL

### DOCKERHUB_USERNAME y DOCKERHUB_TOKEN

- `DOCKERHUB_USERNAME`: username de la cuenta en [hub.docker.com](https://hub.docker.com/).
- `DOCKERHUB_TOKEN`: Personal Access Token (no la contraseña):
  1. **Account settings → Personal access tokens → Generate new token** (menú lateral izquierdo de [app.docker.com/settings](https://app.docker.com/settings)).
  2. Descripción (ej. `github-actions-local`) y permisos **Read & Write** (en local no hace falta Delete: el flujo de local no borra tags de Docker Hub).
  3. Copiar el token al generarlo; no se vuelve a mostrar.

### KUBECONFIG_MICROK8S

Kubeconfig del ServiceAccount `deployer` del cluster de la VM `local`. Solo puede desplegar las apps; no es el de administración.

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, crea los permisos mínimos:

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: app-deployer
rules:
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["replicasets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployer-cluster
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["namespaces"]
    resourceNames: ["iam", "iam-api", "infra-hub-api", "ticket-hub", "ticket-hub-api"]
    verbs: ["get", "patch"]
EOF
```

Crea el ServiceAccount y asígnale los permisos en cada namespace de las apps:

```bash
microk8s kubectl create serviceaccount deployer -n microk8s-access
microk8s kubectl create clusterrolebinding deployer-cluster --clusterrole=deployer-cluster --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n iam --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n iam-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n infra-hub-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n ticket-hub --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
microk8s kubectl create rolebinding deployer-binding -n ticket-hub-api --clusterrole=app-deployer --serviceaccount=microk8s-access:deployer
```

Pide el token (no expira) y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
EOF
```

Espera unos segundos a que Kubernetes rellene el campo `token` y genera el archivo:

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret deployer-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-deployer-local.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-local
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-deployer-local
    context:
      cluster: pcbox-local
      user: deployer-local
current-context: microk8s-deployer-local
users:
  - name: deployer-local
    user:
      token: $TOKEN
EOF
```

Verifica los permisos antes de salir. Los dos primeros deben responder `yes` y los dos últimos `no`:

```bash
microk8s kubectl auth can-i patch deployments -n infra-hub-api --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i list nodes --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i get secrets -n databases --as=system:serviceaccount:microk8s-access:deployer
microk8s kubectl auth can-i create clusterrolebindings --as=system:serviceaccount:microk8s-access:deployer
```

Sal de la VM y cópialo a tu PC cliente:

```bash
exit
scp -i ~/.ssh/pcbox_local ubuntu@pcbox-local:~/pcbox-kubeconfig-deployer-local.yaml .
```

Deja el archivo en la carpeta desde la que vas a cargar los secretos. No lo commitees: contiene un token.

### TS_OAUTH_CLIENT_ID y TS_OAUTH_SECRET

1. Abrir la [consola de Tailscale](https://login.tailscale.com/admin).
2. **Settings → Trust credentials → + Credential**, elegir el tipo **OAuth** y en **Description** poner `github-actions-local` (es solo una referencia interna), luego **Continue**.
3. Scope: **Auth Keys** con `write` (es el que usa `tailscale/github-action` para crear la clave efímera del runner).
4. Tag: `tag:continuous-integration`.
5. Copiar **Client ID** y **Client Secret**; el secret se muestra una sola vez.

### DISPATCH_DEPLOY_HUB_API_LOCAL

Lo usa el workflow de cada app (`release-<app>-local.yml`) para disparar el deploy de local en `deploy-hub-api` con `gh workflow run`. Se carga en cada app, en su Environment `local`. Es un Personal Access Token **fine-grained**, acotado solo a `deploy-hub-api`:

1. **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
   - Token name: `dispatch-deploy-hub-api-local`.
   - Description: `Dispara el workflow de deploy en deploy-hub-api desde los repos de apps (local)`.
   - Expiration: definir una fecha (ej. 90 días) y anotarla; al vencer, el deploy de local deja de dispararse.
2. Resource owner: la **organización** a la que pertenece `deploy-hub-api` (no tu usuario personal). Si la organización exige aprobación de tokens, aprobarlo en **Organization settings → Personal access tokens → Pending requests**.
3. Repository access: solo `deploy-hub-api`.
4. Permissions: `Actions` Read and write, `Contents` Read-only (el workflow solo dispara el deploy con `gh workflow run`; no hace push, así que no necesita escritura en `Contents`).
5. Copiar el token al generarlo.

Este mismo valor se carga en los 5 repos de apps, con el nombre `DISPATCH_DEPLOY_HUB_API_LOCAL`.

---

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
