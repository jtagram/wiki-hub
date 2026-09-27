# Primer deploy de las 5 apps

Instructivo para dejar `iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api` corriendo por primera vez en el cluster microk8s del servidor `pcbox`. A diferencia de las bases de datos, ninguna de las 5 se despliega con manifiestos que vivan en este repo: el build de la imagen y el deploy los maneja GitHub Actions, repartido en dos repos:

- El repo de cada app (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`): compila y publica su imagen en Docker Hub, y dispara el deploy.
- `deploy-hub-api`: tiene los manifiestos k8s (`namespace.yaml`, `deployment.yaml`, `service.yaml`) de las 5 y los workflows que los aplican contra el cluster (`deploy-iam.yml`, `deploy-iam-api.yml`, `deploy-infra-hub-api.yml`, `deploy-ticket-hub.yml`, `deploy-ticket-hub-api.yml`, en la raíz de `.github/workflows/` — los manifiestos y la documentación de secretos de cada app siguen viviendo en su propia subcarpeta, `.github/workflows/<app>/manifests/` y `.github/workflows/<app>/como-obtener-los-secretos.md`).

Requisito, para las 5: namespace propio ya creado (`microk8s/microk8s.namespace.md`), los repos de la app y `deploy-hub-api` ya clonados (`repositories/repositories.clonar-organizacion.md`), y el primer tag de git + el Environment `production` ya configurados en el repo de esa app (`first-deploy/first-deploy.preparacion.md`). Para `iam-api`, `infra-hub-api` y `ticket-hub-api` además hace falta la base de datos correspondiente con sus tablas y, para `iam-api`, el usuario admin ya cargado (`database/database.crear-bases.md` y `database/database.datos-iniciales.md`).

El procedimiento es el mismo patrón para las 5 apps — lo que cambia entre ellas son los Secrets que necesita cada namespace (según lo que valide cada app al arrancar) y poco más. Las secciones siguientes marcan explícitamente esas diferencias.

## 1. Secrets del namespace de cada app en microk8s

No todas las apps necesitan los mismos Secrets: las dos frontends (`iam`, `ticket-hub`) no necesitan ninguno propio (su configuración es toda no sensible y va como env var literal en `deployment.yaml`); las tres APIs sí, y cada una con un set distinto. Ver `microk8s/microk8s.secrets.md` sección 4 para el detalle completo de cómo crear cada uno.

| App | Namespace | Secrets propios | Sección de `microk8s.secrets.md` |
|---|---|---|---|
| `iam` | `iam` | Ninguno | 4.4 |
| `iam-api` | `iam-api` | `postgres-credentials` (`POSTGRES_USER`/`POSTGRES_PASSWORD`), `jwt-keys` (`JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY`) | 4.1 |
| `infra-hub-api` | `infra-hub-api` | `postgres-credentials` (`POSTGRES_USER`/`POSTGRES_PASSWORD`), `server-ssh-key` (`SERVER_SSH_HOST`/`SERVER_SSH_USER`/`SERVER_SSH_PRIVATE_KEY`) | 4.2 |
| `ticket-hub` | `ticket-hub` | Ninguno | 4.5 |
| `ticket-hub-api` | `ticket-hub-api` | `postgres-credentials` (`POSTGRES_USER`/`POSTGRES_PASSWORD`), `ticket-hub-api-service-credentials` (`CLIENT_ID`/`CLIENT_SECRET`) | 4.3 |

`iam-api` y `ticket-hub-api` usan `postgres-credentials` con el mismo nombre pero valores propios por namespace — no es el mismo Secret que el de `databases`, hay que crearlo de nuevo en cada namespace de app. `infra-hub-api` no valida JWT ni tiene Secret de Postgres extra más allá del propio; en cambio necesita `server-ssh-key` porque ejecuta playbooks de Ansible contra el servidor real `pcbox` por SSH. Ninguna de las tres APIs necesita `JWT_PRIVATE_KEY` salvo `iam-api` (es la única que emite tokens; las demás solo lo validan pidiéndole a `iam-api` su clave pública por HTTP en tiempo de ejecución, `GET /auth/public-key`, no como Secret local).

Verificá que ya existan los que le correspondan a cada app:

```bash
microk8s kubectl get secrets -n iam-api
microk8s kubectl get secrets -n infra-hub-api
microk8s kubectl get secrets -n ticket-hub-api
```

(`iam` y `ticket-hub` no tienen Secret propio, así que no hay nada que verificar ahí.)

Si falta alguno de los que le corresponden a esa app, volvé a `microk8s.secrets.md` y creálo antes de seguir — sin esto el Pod arranca y muere, porque cada API valida sus env vars al iniciar y no levanta si falta una.

## 2. ServiceAccount de cada app

El `Deployment` de las 5 apps (`deploy-hub-api/.github/workflows/<app>/manifests/deployment.yaml`) referencia `serviceAccountName: <app>`, pero ese ServiceAccount no está versionado en ningún manifiesto del repo — pasa igual en las 5, no solo en `iam-api`. Hay que crearlo a mano, una sola vez por app, antes de su primer deploy:

```bash
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
```

Si no existe el de una app, el Pod de esa app en particular queda sin crearse.

## 3. Secrets de GitHub Actions

Confirmá que estén cargados los secrets de `secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md`:

En el repo de **cada** app:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (con permiso de borrado — el workflow también limpia tags viejos)
- Su `DISPATCH_TOKEN` propio:

| Repo | Nombre del secreto |
|---|---|
| `iam` | `IAM_DISPATCH_TOKEN` |
| `iam-api` | `IAM_API_DISPATCH_TOKEN` |
| `infra-hub-api` | `INFRA_HUB_API_DISPATCH_TOKEN` |
| `ticket-hub` | `TICKET_HUB_DISPATCH_TOKEN` |
| `ticket-hub-api` | `TICKET_HUB_API_DISPATCH_TOKEN` |

En el repo `deploy-hub-api` (una sola vez, no por app):
- `DOCKERHUB_USERNAME`
- `KUBECONFIG_MICROK8S`
- `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET`

## 4. Disparar el release

Desde GitHub, en el repo de la app que corresponda, correr manualmente el workflow `release-<app>.yml` (pestaña Actions → Run workflow), completando los inputs `previous_stable_tag` y `new_tag`.

Este workflow (mismo patrón en las 5):

1. Compila y publica la imagen `docker.io/<DOCKERHUB_USERNAME>/<app>:<new_tag>`.
2. Crea el tag de git.
3. Pide aprobación manual del environment `production` (queda pendiente en la pestaña Actions del repo de la app — aprobala ahí).
4. Una vez aprobado, dispara `deploy-<app>.yml` en `deploy-hub-api` (vía el `<APP>_DISPATCH_TOKEN` correspondiente), que aplica `namespace.yaml` + `deployment.yaml` + `service.yaml` contra el cluster y espera el rollout.

Si el dispatch automático fallara, la alternativa manual es aplicar los manifiestos directo desde `pcbox`, reemplazando antes a mano los placeholders `DOCKERHUB_USER`/`IMAGE_TAG` en `deploy-hub-api/.github/workflows/<app>/manifests/deployment.yaml`:

```bash
microk8s kubectl apply -f deploy-hub-api/.github/workflows/iam/manifests/
microk8s kubectl apply -f deploy-hub-api/.github/workflows/iam-api/manifests/
microk8s kubectl apply -f deploy-hub-api/.github/workflows/infra-hub-api/manifests/
microk8s kubectl apply -f deploy-hub-api/.github/workflows/ticket-hub/manifests/
microk8s kubectl apply -f deploy-hub-api/.github/workflows/ticket-hub-api/manifests/
```

## 5. Verificar

Seguí el rollout de `deploy-<app>.yml` en la pestaña Actions de `deploy-hub-api`. Cuando termine, en el servidor, por cada app desplegada:

```bash
microk8s kubectl get pods -n <namespace> -w
```

Tiene que quedar un Pod `Running`. Si algo falla, ver logs:

```bash
microk8s kubectl logs -n <namespace> deploy/<app>
```

Y confirmar el Service:

```bash
microk8s kubectl get svc -n <namespace>
```

Namespace, nombre del Deployment/Service y DNS interno son iguales al nombre de la app en las 5 (todas escuchan en el puerto `3000`, todas son `ClusterIP`, ninguna tiene Ingress todavía):

| App | Namespace | DNS interno |
|---|---|---|
| `iam` | `iam` | `iam.iam.svc.cluster.local:3000` |
| `iam-api` | `iam-api` | `iam-api.iam-api.svc.cluster.local:3000` |
| `infra-hub-api` | `infra-hub-api` | `infra-hub-api.infra-hub-api.svc.cluster.local:3000` |
| `ticket-hub` | `ticket-hub` | `ticket-hub.ticket-hub.svc.cluster.local:3000` |
| `ticket-hub-api` | `ticket-hub-api` | `ticket-hub-api.ticket-hub-api.svc.cluster.local:3000` |

No hay Ingress todavía, así que no hay acceso HTTP externo directo a ninguna — queda para un instructivo aparte si hace falta.

Orden sugerido para el primer deploy de las 5, por dependencias entre ellas (según `IAM_API_URL`/`INFRA_HUB_API_URL`/`TICKET_HUB_API_URL` de cada README): `iam-api` primero (todas las demás la necesitan para validar tokens), después `infra-hub-api` (la necesita `ticket-hub-api`), después `ticket-hub-api`, y por último las dos frontends `iam` y `ticket-hub` (esta última necesita a `ticket-hub-api` ya arriba).
