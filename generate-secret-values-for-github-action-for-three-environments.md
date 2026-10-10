# Obtener los secretos de GitHub Actions de los 3 ambientes

Instructivo para obtener los valores que usan los workflows de GitHub Actions en `prod`, `dev` y `local`. Solo explica **cómo conseguir cada valor**. Cómo cargarlos en GitHub está en [load-secrets-for-github-action-for-three-environments.md](load-secrets-for-github-action-for-three-environments.md).

Los secretos **no llevan prefijo de ambiente**: tienen el mismo nombre en los tres y un valor distinto en cada uno. Anota los valores de cada ambiente en un lugar seguro: el siguiente paso los necesita.

Necesitas:

- Repositorios clonados — [clone-organization-repositories.md](clone-organization-repositories.md).
- Las 3 VMs con MicroK8s y el certificado del API server extendido con su IP de Tailscale — sección "Certificado del API server" de [create-users-with-permissions-for-three-environments.md](create-users-with-permissions-for-three-environments.md). Sin eso, el kubeconfig de abajo no puede conectarse.

El kubeconfig de cada ambiente es el de **administración** de esa VM, distinto de los kubeconfig de solo lectura del usuario `viewer`. Lo usa `deploy-hub-api` para desplegar.

Secretos de cada ambiente: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET` y el token de dispatch (un mismo valor que se carga con 5 nombres distintos).

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

Contenido completo del kubeconfig de administración del cluster de la VM `prod`.

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, obtén la IP de Tailscale y genera el archivo:

```bash
tailscale ip -4
microk8s config > ~/pcbox-kubeconfig-prod.yaml
nano ~/pcbox-kubeconfig-prod.yaml
```

En `nano`, cambia únicamente la línea `server:` para que apunte a la IP de Tailscale en vez de a la IP local:

```yaml
server: https://100.x.x.x:16443
```

Sal de la VM y cópialo a tu PC cliente:

```bash
exit
scp -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod:~/pcbox-kubeconfig-prod.yaml .
```

Deja el archivo en la carpeta desde la que vas a cargar los secretos. No lo commitees: contiene una clave privada.

### TS_OAUTH_CLIENT_ID y TS_OAUTH_SECRET

1. Abrir la [consola de Tailscale](https://login.tailscale.com/admin).
2. **Settings → Trust credentials → + Credential**, elegir el tipo **OAuth** y en **Description** poner `github-actions-prod` (es solo una referencia interna), luego **Continue**.
3. Scope: **Auth Keys** con `write` (es el que usa `tailscale/github-action` para crear la clave efímera del runner).
4. Tag: `tag:continuous-integration`.
5. Copiar **Client ID** y **Client Secret**; el secret se muestra una sola vez.

### Dispatch tokens

Un Personal Access Token **fine-grained**, acotado solo a `deploy-hub-api`:

1. **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
   - Token name: `dispatch-deploy-hub-api-prod`.
   - Description: `Dispara el workflow de deploy en deploy-hub-api desde los repos de apps (prod)`.
   - Expiration: definir una fecha (ej. 90 días) y anotarla; al vencer, el deploy falla.
2. Resource owner: la **organización** a la que pertenece `deploy-hub-api` (no tu usuario personal). Si la organización exige aprobación de tokens, aprobarlo en **Organization settings → Personal access tokens → Pending requests**.
3. Repository access: solo `deploy-hub-api`.
4. Permissions: `Actions` Read and write, `Contents` Read-only (el workflow solo dispara y sigue el deploy con `gh workflow run` y `gh run watch`; no hace push, así que no necesita escritura en `Contents`).
5. Copiar el token al generarlo.

Este mismo valor se carga en los 5 repos de apps.

---

## DEV

### DOCKERHUB_USERNAME y DOCKERHUB_TOKEN

- `DOCKERHUB_USERNAME`: username de la cuenta en [hub.docker.com](https://hub.docker.com/).
- `DOCKERHUB_TOKEN`: Personal Access Token (no la contraseña):
  1. **Account settings → Personal access tokens → Generate new token** (menú lateral izquierdo de [app.docker.com/settings](https://app.docker.com/settings)).
  2. Descripción (ej. `github-actions-dev`) y permisos **Read, Write & Delete** (Delete es necesario porque el job `cleanup-tags` elimina los tags anteriores en Docker Hub).
  3. Copiar el token al generarlo; no se vuelve a mostrar.

### KUBECONFIG_MICROK8S

Contenido completo del kubeconfig de administración del cluster de la VM `dev`.

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, obtén la IP de Tailscale y genera el archivo:

```bash
tailscale ip -4
microk8s config > ~/pcbox-kubeconfig-dev.yaml
nano ~/pcbox-kubeconfig-dev.yaml
```

En `nano`, cambia únicamente la línea `server:` para que apunte a la IP de Tailscale en vez de a la IP local:

```yaml
server: https://100.x.x.x:16443
```

Sal de la VM y cópialo a tu PC cliente:

```bash
exit
scp -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev:~/pcbox-kubeconfig-dev.yaml .
```

Deja el archivo en la carpeta desde la que vas a cargar los secretos. No lo commitees: contiene una clave privada.

### TS_OAUTH_CLIENT_ID y TS_OAUTH_SECRET

1. Abrir la [consola de Tailscale](https://login.tailscale.com/admin).
2. **Settings → Trust credentials → + Credential**, elegir el tipo **OAuth** y en **Description** poner `github-actions-dev` (es solo una referencia interna), luego **Continue**.
3. Scope: **Auth Keys** con `write` (es el que usa `tailscale/github-action` para crear la clave efímera del runner).
4. Tag: `tag:continuous-integration`.
5. Copiar **Client ID** y **Client Secret**; el secret se muestra una sola vez.

### Dispatch tokens

Un Personal Access Token **fine-grained**, acotado solo a `deploy-hub-api`:

1. **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
   - Token name: `dispatch-deploy-hub-api-dev`.
   - Description: `Dispara el workflow de deploy en deploy-hub-api desde los repos de apps (dev)`.
   - Expiration: definir una fecha (ej. 90 días) y anotarla; al vencer, el deploy falla.
2. Resource owner: la **organización** a la que pertenece `deploy-hub-api` (no tu usuario personal). Si la organización exige aprobación de tokens, aprobarlo en **Organization settings → Personal access tokens → Pending requests**.
3. Repository access: solo `deploy-hub-api`.
4. Permissions: `Actions` Read and write, `Contents` Read-only (el workflow solo dispara y sigue el deploy con `gh workflow run` y `gh run watch`; no hace push, así que no necesita escritura en `Contents`).
5. Copiar el token al generarlo.

Este mismo valor se carga en los 5 repos de apps.

---

## LOCAL

### DOCKERHUB_USERNAME y DOCKERHUB_TOKEN

- `DOCKERHUB_USERNAME`: username de la cuenta en [hub.docker.com](https://hub.docker.com/).
- `DOCKERHUB_TOKEN`: Personal Access Token (no la contraseña):
  1. **Account settings → Personal access tokens → Generate new token** (menú lateral izquierdo de [app.docker.com/settings](https://app.docker.com/settings)).
  2. Descripción (ej. `github-actions-local`) y permisos **Read, Write & Delete** (Delete es necesario porque el job `cleanup-tags` elimina los tags anteriores en Docker Hub).
  3. Copiar el token al generarlo; no se vuelve a mostrar.

### KUBECONFIG_MICROK8S

Contenido completo del kubeconfig de administración del cluster de la VM `local`.

Entra a la VM:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, obtén la IP de Tailscale y genera el archivo:

```bash
tailscale ip -4
microk8s config > ~/pcbox-kubeconfig-local.yaml
nano ~/pcbox-kubeconfig-local.yaml
```

En `nano`, cambia únicamente la línea `server:` para que apunte a la IP de Tailscale en vez de a la IP local:

```yaml
server: https://100.x.x.x:16443
```

Sal de la VM y cópialo a tu PC cliente:

```bash
exit
scp -i ~/.ssh/pcbox_local ubuntu@pcbox-local:~/pcbox-kubeconfig-local.yaml .
```

Deja el archivo en la carpeta desde la que vas a cargar los secretos. No lo commitees: contiene una clave privada.

### TS_OAUTH_CLIENT_ID y TS_OAUTH_SECRET

1. Abrir la [consola de Tailscale](https://login.tailscale.com/admin).
2. **Settings → Trust credentials → + Credential**, elegir el tipo **OAuth** y en **Description** poner `github-actions-local` (es solo una referencia interna), luego **Continue**.
3. Scope: **Auth Keys** con `write` (es el que usa `tailscale/github-action` para crear la clave efímera del runner).
4. Tag: `tag:continuous-integration`.
5. Copiar **Client ID** y **Client Secret**; el secret se muestra una sola vez.

### Dispatch tokens

Un Personal Access Token **fine-grained**, acotado solo a `deploy-hub-api`:

1. **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
   - Token name: `dispatch-deploy-hub-api-local`.
   - Description: `Dispara el workflow de deploy en deploy-hub-api desde los repos de apps (local)`.
   - Expiration: definir una fecha (ej. 90 días) y anotarla; al vencer, el deploy falla.
2. Resource owner: la **organización** a la que pertenece `deploy-hub-api` (no tu usuario personal). Si la organización exige aprobación de tokens, aprobarlo en **Organization settings → Personal access tokens → Pending requests**.
3. Repository access: solo `deploy-hub-api`.
4. Permissions: `Actions` Read and write, `Contents` **Read and write**. En local el workflow no dispara un `workflow_dispatch`: hace un commit y un push a la rama `local` de `deploy-hub-api`, y con `Contents` en Read-only falla con `403 Permission denied`.
5. Copiar el token al generarlo.

Este mismo valor se carga en los 5 repos de apps.

---
