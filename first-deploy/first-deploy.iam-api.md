# Primer deploy de iam-api

Instructivo para dejar `iam-api` corriendo por primera vez en el cluster microk8s del servidor `pcbox`. A diferencia de las bases de datos, `iam-api` no se despliega con manifiestos que vivan en este repo: el build de la imagen y el deploy los maneja GitHub Actions, repartido en dos repos:

- `iam-api`: compila y publica la imagen en Docker Hub, y dispara el deploy.
- `deploy-hub-api`: tiene los manifiestos k8s (`namespace.yaml`, `deployment.yaml`, `service.yaml`) y el workflow que los aplica contra el cluster.

Requisito: namespace `iam-api` ya creado (`microk8s/microk8s.namespace.md`), la base `iam_api` con sus tablas y el usuario admin ya cargados (`database/database.crear-bases.md` y `database/database.datos-iniciales.md`), y los repos `iam-api` y `deploy-hub-api` ya clonados (`repositories/repositories.clonar-organizacion.md`).

## 1. Secrets del namespace `iam-api` en microk8s

`iam-api` necesita, en su propio namespace (no en el de `databases`), dos secrets — ver `microk8s/microk8s.secrets.md`, sección 4.1:

- `postgres-credentials`: los mismos `POSTGRES_USER`/`POSTGRES_PASSWORD` generados por `wiki-hub/script/main.sh`, pero cargados en el namespace `iam-api`.
- `jwt-keys`: `JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY`, cargados como archivo (`--from-file`).

Verificá que ya existan:

```bash
microk8s kubectl get secrets -n iam-api
```

Si falta alguno, volvé a `microk8s.secrets.md` §4.1 y creálo antes de seguir — sin esto el Pod arranca y muere, porque `iam-api` valida esas env vars al iniciar y no levanta si falta una.

## 2. ServiceAccount `iam-api`

El `Deployment` de `iam-api` (`deploy-hub-api/.github/workflows/iam-api/manifests/deployment.yaml`) referencia `serviceAccountName: iam-api`, pero ese ServiceAccount no está versionado en ningún manifiesto del repo. Hay que crearlo a mano, una sola vez, antes del primer deploy:

```bash
microk8s kubectl create serviceaccount iam-api -n iam-api
```

Si no existe, el Pod queda sin crearse.

## 3. Secrets de GitHub Actions

Confirmá que estén cargados los secrets de `secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md`:

En el repo `iam-api`:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (con permiso de borrado — el workflow también limpia tags viejos)
- `IAM_API_DISPATCH_TOKEN`

En el repo `deploy-hub-api`:
- `DOCKERHUB_USERNAME`
- `KUBECONFIG_MICROK8S`
- `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET`

## 4. Disparar el release

Desde GitHub, en el repo `iam-api`, correr manualmente el workflow `release-iam-api.yml` (pestaña Actions → Run workflow), completando los inputs `previous_stable_tag` y `new_tag`.

Este workflow:

1. Compila y publica la imagen `docker.io/<DOCKERHUB_USERNAME>/iam-api:<new_tag>`.
2. Crea el tag de git.
3. Pide aprobación manual del environment `production` (queda pendiente en la pestaña Actions del repo `iam-api` — aprobala ahí).
4. Una vez aprobado, dispara `deploy-iam-api.yml` en `deploy-hub-api` (vía `IAM_API_DISPATCH_TOKEN`), que aplica `namespace.yaml` + `deployment.yaml` + `service.yaml` contra el cluster y espera el rollout.

Si el dispatch automático fallara, la alternativa manual es aplicar los manifiestos directo desde `pcbox`, reemplazando antes a mano los placeholders `DOCKERHUB_USER`/`IMAGE_TAG` en `deploy-hub-api/.github/workflows/iam-api/manifests/deployment.yaml`:

```bash
microk8s kubectl apply -f deploy-hub-api/.github/workflows/iam-api/manifests/
```

## 5. Verificar

Seguí el rollout de `deploy-iam-api.yml` en la pestaña Actions de `deploy-hub-api`. Cuando termine, en el servidor:

```bash
microk8s kubectl get pods -n iam-api -w
```

Tiene que quedar un Pod `Running`. Si algo falla, ver logs:

```bash
microk8s kubectl logs -n iam-api deploy/iam-api
```

Y confirmar el Service:

```bash
microk8s kubectl get svc -n iam-api
```

`iam-api` queda accesible dentro del cluster en `iam-api.iam-api.svc.cluster.local:3000`. No hay Ingress todavía, así que no hay acceso HTTP externo directo — queda para un instructivo aparte si hace falta.
