# Primer deploy de las 5 apps

Instructivo para dejar `iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api` corriendo por primera vez en el cluster microk8s del servidor `pcbox`. El build de la imagen y el deploy los maneja GitHub Actions: el repo de cada app compila y publica su imagen y dispara el deploy; `deploy-hub-api` tiene los manifiestos k8s (`namespace.yaml`, `deployment.yaml`, `service.yaml`) y los workflows que los aplican contra el cluster.

## Prerequisitos

Si llegaste hasta acá siguiendo el wiki en orden, ya hiciste todo esto — se listan solo como referencia, por si falta algo:

- Namespace propio de cada app — `microk8s/microk8s.namespace.md`.
- Secrets propios de cada namespace (varían por app) — `microk8s/microk8s.secrets.md` sección 4.
- ServiceAccount de cada app — `first-deploy/first-deploy.service-account.md`.
- Secrets de GitHub Actions (Docker Hub + `DISPATCH_TOKEN`), en el repo de cada app y en `deploy-hub-api` — `secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md`.
- Primer tag en git y Docker Hub — `first-deploy/first-deploy.primer-tag.md`.
- Environment `production` configurado — `first-deploy/first-deploy.environment-produccion.md`.

## Disparar el release

Desde GitHub, en el repo de la app, correr manualmente `release-<app>.yml` (pestaña Actions → Run workflow) con estos inputs:

| App | `previous_stable_tag` | `new_tag` |
|---|---|---|
| `iam` | `v0.1.0` | `v0.1.1` |
| `iam-api` | `v0.1.0` | `v0.1.1` |
| `infra-hub-api` | `v0.1.0` | `v0.1.1` |
| `ticket-hub` | `v0.1.0` | `v0.1.1` |
| `ticket-hub-api` | `v0.1.0` | `v0.1.1` |

(`v0.1.0` es el tag inicial que ya creaste en `first-deploy.primer-tag.md`; `v0.1.1` es la primera versión real que vas a publicar — usá el siguiente número si ya la usaste antes.)

El workflow compila y publica la imagen, crea el tag de git, pide la aprobación manual del Environment `production`, y una vez aprobado dispara `deploy-<app>.yml` en `deploy-hub-api`, que aplica los manifiestos y espera el rollout.

Si el dispatch automático fallara, la alternativa manual es aplicar los manifiestos directo desde `pcbox` (reemplazando antes a mano los placeholders `DOCKERHUB_USER`/`IMAGE_TAG` en el `deployment.yaml` correspondiente):

```bash
microk8s kubectl apply -f deploy-hub-api/.github/workflows/<app>/manifests/
```

## Verificar

Seguí el rollout de `deploy-<app>.yml` en la pestaña Actions de `deploy-hub-api`. Cuando termine, en el servidor:

```bash
microk8s kubectl get pods -n <namespace> -w
microk8s kubectl logs -n <namespace> deploy/<app>      # si algo falla
microk8s kubectl get svc -n <namespace>
```

Namespace, Deployment/Service y DNS interno son iguales al nombre de la app en las 5 (puerto `3000`, todas `ClusterIP`, sin Ingress todavía):

| App | Namespace | DNS interno |
|---|---|---|
| `iam` | `iam` | `iam.iam.svc.cluster.local:3000` |
| `iam-api` | `iam-api` | `iam-api.iam-api.svc.cluster.local:3000` |
| `infra-hub-api` | `infra-hub-api` | `infra-hub-api.infra-hub-api.svc.cluster.local:3000` |
| `ticket-hub` | `ticket-hub` | `ticket-hub.ticket-hub.svc.cluster.local:3000` |
| `ticket-hub-api` | `ticket-hub-api` | `ticket-hub-api.ticket-hub-api.svc.cluster.local:3000` |

Orden sugerido por dependencias entre apps: `iam-api` primero (todas la necesitan para validar tokens), después `infra-hub-api`, después `ticket-hub-api`, y por último `iam` y `ticket-hub`.
