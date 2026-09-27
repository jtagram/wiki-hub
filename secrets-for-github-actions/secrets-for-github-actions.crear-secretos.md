# Crear los secretos de GitHub Actions

Instructivo para generar todos los valores que usan los workflows de GitHub Actions de este sistema, y dónde cargarlos.

Todos los secretos se cargan igual: en el repositorio correspondiente, **Settings → Secrets and variables → Actions → New repository secret**.

## Dónde va cada secreto

| Secreto | Repositorio(s) donde se carga |
|---|---|
| `DOCKERHUB_USERNAME` | `deploy-hub-api` y los 5 repos de apps (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`) |
| `DOCKERHUB_TOKEN` | Los 5 repos de apps (no hace falta en `deploy-hub-api`) |
| `KUBECONFIG_MICROK8S` | Solo `deploy-hub-api` |
| `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET` | Solo `deploy-hub-api` |
| `IAM_DISPATCH_TOKEN` | `iam` **y** `iam-api` (cada uno con su propio secreto, mismo nombre) |
| `TICKET_HUB_DISPATCH_TOKEN` | `ticket-hub` **y** `ticket-hub-api` (cada uno con su propio secreto, mismo nombre) |
| `INFRA_HUB_DISPATCH_TOKEN` | Solo `infra-hub-api` |

## 1. Crear la cuenta de Docker Hub

1. Entrá a [hub.docker.com](https://hub.docker.com/) y creá una cuenta (o usá una existente).
2. El **username** de esa cuenta es directamente el valor de `DOCKERHUB_USERNAME` — es el que se usa para armar el nombre de cada imagen (`docker.io/$DOCKERHUB_USERNAME/<app>:<tag>`).

## 2. Obtener `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`

- `DOCKERHUB_USERNAME`: el username de la cuenta creada en el paso 1, tal cual.
- `DOCKERHUB_TOKEN`: **no es la contraseña de la cuenta** — es un Personal Access Token, necesario para que `docker/build-push-action` pueda loguearse y pushear imágenes sin exponer la contraseña real:
  1. Logueate en [hub.docker.com](https://hub.docker.com/) → ícono de tu cuenta (arriba a la derecha) → **Account Settings**.
  2. **Security** → **New Access Token**.
  3. Ponele una descripción (ej. `github-actions-jtagram`) y elegí permisos **Read & Write** (necesita escribir para pushear imágenes).
  4. Generá el token y copialo apenas se muestra — Docker Hub no lo vuelve a mostrar después.

Cargá `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN` en cada uno de los 5 repos de apps (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`) — son los que buildean y pushean su propia imagen en el workflow de release. `deploy-hub-api` solo necesita `DOCKERHUB_USERNAME` (arma el nombre de la imagen a desplegar, pero no pushea nada, así que no necesita el token).

## 3. Crear `KUBECONFIG_MICROK8S`

Es el contenido completo del kubeconfig que le permite a `kubectl` (corriendo en el runner de GitHub Actions) administrar el cluster de microk8s en `pcbox` a través de Tailscale. El procedimiento detallado para generarlo (incluida la extensión del certificado del API server) ya está documentado en [`pcbox/pcbox.microk8s-setup.md`](../pcbox/pcbox.microk8s-setup.md), sección 2 — seguilo paso a paso si no lo hiciste todavía. En resumen:

1. Conectate por SSH al servidor `pcbox`.
2. Extendé el certificado del API server para que sea válido también desde la IP de Tailscale (`sudo microk8s refresh-certs -e server.crt`, después de agregar esa IP al `[alt_names]` del template del certificado) — el detalle completo está en el documento linkeado arriba.
3. Generá el kubeconfig: `microk8s config > ~/pcbox-kubeconfig.yaml`.
4. Editá el campo `server:` de ese archivo para que apunte a la IP de Tailscale en vez de a la IP local del servidor.
5. Sacá el archivo del servidor a tu PC cliente (`scp jhon@IP_TAILSCALE:~/pcbox-kubeconfig.yaml .`) — no lo commitees, es un secreto.
6. Copiá el contenido **completo** de ese archivo y pegalo como valor del secreto `KUBECONFIG_MICROK8S` en `deploy-hub-api`.

Este secreto solo se carga en `deploy-hub-api` — es el único repo cuyos workflows corren `kubectl`/`microk8s`.

## 4. Crear `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`

La **cuenta** de Tailscale ya la creaste al configurar el servidor y microk8s (`pcbox.bootstrap.md`, paso 2 — el login que hiciste con `sudo tailscale up`). Esto no crea una cuenta nueva, es generar credenciales de aplicación (OAuth client) dentro de esa misma cuenta, para que el runner de GitHub Actions pueda unirse a la tailnet sin que un humano tenga que autenticarse a mano en cada corrida.

1. Entrá a la [consola de admin de Tailscale](https://login.tailscale.com/admin/settings/oauth) con la misma cuenta.
2. **Settings → OAuth clients → Generate OAuth client**.
3. **Scopes**: elegí **Devices Core** con permiso de escritura (`write`) — necesario para que el runner se pueda registrar como nodo.
4. **Tags**: asigná `tag:continuous-integration` — tiene que ser exactamente el mismo tag que usa el step "Unirse a la red de Tailscale" en los workflows de `deploy-hub-api`.
5. Generá el cliente y copiá el **Client ID** y el **Client Secret** apenas se muestren — el secret solo se ve una vez.
6. Guardalos como `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`, solo en `deploy-hub-api`.

> Si el join a la tailnet falla con un error de tags no permitidos: `tag:continuous-integration` tiene que estar declarado en `tagOwners` dentro de la [ACL policy](https://login.tailscale.com/admin/acls) de la tailnet, y el OAuth client necesita permiso para asignarlo.

## 5. Generar cada `DISPATCH_TOKEN`

Cada repo de app (frontend o backend) tiene un workflow de release que, después de pushear la imagen a Docker Hub, dispara el deploy real disparando un `workflow_dispatch` en el repo `deploy-hub-api` (ver `disparar-deploy-<app>.sh` en cada uno). El token por defecto que GitHub le da a cada workflow (`GITHUB_TOKEN`) solo tiene permisos dentro de su propio repositorio — no alcanza para disparar un workflow en otro repo (`deploy-hub-api`), así que hace falta un Personal Access Token propio.

**Podés usar el mismo Personal Access Token para los 5 casos** (el permiso que necesita es siempre el mismo: poder disparar `workflow_dispatch` sobre `jtagram/deploy-hub-api`, que es un repo público) — simplemente lo vas a cargar varias veces, con nombres de secreto distintos, en cada repo.

### Generar el Personal Access Token

1. Entrá a [github.com/settings/tokens](https://github.com/settings/tokens) (o `github.com/settings/personal-access-tokens` para uno *fine-grained*).
2. **Generate new token (classic)**.
3. Scopes necesarios: `public_repo` (alcanza porque `deploy-hub-api` es público) y `workflow` (necesario para disparar/leer runs de Actions).
4. Ponele una expiración razonable y generalo. Copiá el token apenas se muestra — no se puede volver a ver.

### Cargar el token en cada repo

| Repo | Nombre del secreto |
|---|---|
| `iam` | `IAM_DISPATCH_TOKEN` |
| `iam-api` | `IAM_DISPATCH_TOKEN` |
| `ticket-hub` | `TICKET_HUB_DISPATCH_TOKEN` |
| `ticket-hub-api` | `TICKET_HUB_DISPATCH_TOKEN` |
| `infra-hub-api` | `INFRA_HUB_DISPATCH_TOKEN` |

Notá que `iam`/`iam-api` usan el mismo *nombre* de secreto, y lo mismo `ticket-hub`/`ticket-hub-api` — pero como cada repo tiene su propio almacén de secretos en GitHub, hay que cargarlo por separado en cada uno (5 veces en total), aunque el valor del token sea idéntico en los 5.
