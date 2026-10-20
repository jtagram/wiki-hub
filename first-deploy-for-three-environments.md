# Primer deploy de las apps en los 3 ambientes

Deja `iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api` corriendo por primera vez en MicroK8s, en cada ambiente (local, dev y prod). Todo el flujo corre en `deploy-hub-api`: GitHub Actions compila y publica la imagen y aplica los manifiestos en el cluster de la VM de ese ambiente, usando el secreto `KUBECONFIG_MICROK8S` del Environment correspondiente.

## 1. Prerequisitos

Antes de empezar debe estar hecho, en este orden:

1. Repositorios clonados — [clone-organization-repositories.md](clone-organization-repositories.md).
2. Namespaces — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).
3. Secrets en MicroK8s — [create-secrets-for-three-environments.md](create-secrets-for-three-environments.md).
4. ServiceAccounts — [create-serviceaccounts-for-three-environments.md](create-serviceaccounts-for-three-environments.md).
5. Secrets de GitHub Actions — [generate-secret-values-for-github-action-for-three-environments.md](generate-secret-values-for-github-action-for-three-environments.md).
6. Primer tag en git y Docker Hub — [create-tag-for-dockerhub-and-github.md](create-tag-for-dockerhub-and-github.md).
7. Environments de GitHub — [create-environment-in-github.md](create-environment-in-github.md).
8. PostgreSQL desplegado — [deploy-postgres-for-three-environments.md](deploy-postgres-for-three-environments.md).
9. Bases de datos creadas — [create-databases-for-three-environments.md](create-databases-for-three-environments.md).
10. Tablas creadas — [create-tables-for-three-environments.md](create-tables-for-three-environments.md).

## 2. Orden de las apps

Despliega en este orden, porque unas dependen de otras:

1. `iam-api`: todas la necesitan para validar tokens.
2. `infra-hub-api`
3. `ticket-hub-api`
4. `iam`
5. `ticket-hub`

Termina un ambiente completo antes de pasar al siguiente: primero local, después dev, al final prod.

## 3. Datos por ambiente

| Ambiente | VM | Rama | Prefijo del namespace | `previous_stable_tag` | `new_tag` | Aprobación manual |
|---|---|---|---|---|---|---|
| Local | `pcbox-local` | `local` | `local-` | no aplica | no aplica | No |
| Desarrollo | `pcbox-dev` | `dev` | `dev-` | `dev-v0.1.0` | `dev-v0.1.1` | Sí |
| Producción | `pcbox-prod` | rama principal | `prod-` | `prod-v0.1.0` | `prod-v0.1.1` | Sí |

En local el flujo arranca con un push a la rama `local` de la app, que solo dispara el deploy en `deploy-hub-api`, y publica siempre la imagen con el tag `local`, así que no usa tags de versión. En dev y prod el flujo arranca siempre con los dos tags: `previous_stable_tag` (dev y prod) es el tag inicial que creaste en [create-tag-for-dockerhub-and-github.md](create-tag-for-dockerhub-and-github.md). `new_tag` es la primera versión real y no debe existir todavía. Si ya la usaste, elige el siguiente número.

## 4. Disparar el deploy

Requiere la CLI de GitHub (`gh`) con sesión iniciada (`gh auth login`). Reemplaza `<tu-organizacion>` y pega:

```bash
ORG=<tu-organizacion>
```

Ejecuta las apps en el orden de la sección 2 y espera a que termine cada una antes de lanzar la siguiente: `gh run watch` sigue la ejecución hasta el final. Todas las ejecuciones corren en `deploy-hub-api`, así que ahí se sigue el progreso. Si falla, muestra el error y puedes seguir en la pestaña **Actions** de `deploy-hub-api`.

Termina un ambiente completo antes de pasar al siguiente.

### 4.1. Local

El flujo arranca con un push a `local` de la app: el workflow de la app solo dispara `deploy-<app>-local.yml` en `deploy-hub-api`, y ahí se compila, publica y despliega. Cada comando crea un commit vacío (no cambia código) para dispararlo y después sigue la ejecución de `deploy-hub-api`. Los clones deben tener la rama `local` al día (`git pull origin local`).

#### iam-api

```bash
git -C iam-api checkout local
git -C iam-api commit --allow-empty -m "chore: trigger local deploy"
git -C iam-api push origin local
sleep 15
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-iam-api-local.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### infra-hub-api

```bash
git -C infra-hub-api checkout local
git -C infra-hub-api commit --allow-empty -m "chore: trigger local deploy"
git -C infra-hub-api push origin local
sleep 15
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-infra-hub-api-local.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### ticket-hub-api

```bash
git -C ticket-hub-api checkout local
git -C ticket-hub-api commit --allow-empty -m "chore: trigger local deploy"
git -C ticket-hub-api push origin local
sleep 15
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-ticket-hub-api-local.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### iam

```bash
git -C iam checkout local
git -C iam commit --allow-empty -m "chore: trigger local deploy"
git -C iam push origin local
sleep 15
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-iam-local.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### ticket-hub

```bash
git -C ticket-hub checkout local
git -C ticket-hub commit --allow-empty -m "chore: trigger local deploy"
git -C ticket-hub push origin local
sleep 15
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-ticket-hub-local.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

### 4.2. Desarrollo

Lanza el workflow desde la rama `dev` de `deploy-hub-api` (`--ref dev`): el job `validate-branch` rechaza cualquier otra. Antes del deploy, el job `gate` pide la aprobación manual del Environment `development-approver` de `deploy-hub-api`: abre la ejecución en GitHub y pulsa **Review deployments** → **Approve and deploy**. `gh run watch` queda esperando hasta que la apruebes.

#### iam-api

```bash
gh workflow run deploy-iam-api-dev.yml --repo "$ORG/deploy-hub-api" --ref dev -f previous_stable_tag=dev-v0.1.0 -f new_tag=dev-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-iam-api-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### infra-hub-api

```bash
gh workflow run deploy-infra-hub-api-dev.yml --repo "$ORG/deploy-hub-api" --ref dev -f previous_stable_tag=dev-v0.1.0 -f new_tag=dev-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-infra-hub-api-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### ticket-hub-api

```bash
gh workflow run deploy-ticket-hub-api-dev.yml --repo "$ORG/deploy-hub-api" --ref dev -f previous_stable_tag=dev-v0.1.0 -f new_tag=dev-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-ticket-hub-api-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### iam

```bash
gh workflow run deploy-iam-dev.yml --repo "$ORG/deploy-hub-api" --ref dev -f previous_stable_tag=dev-v0.1.0 -f new_tag=dev-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-iam-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### ticket-hub

```bash
gh workflow run deploy-ticket-hub-dev.yml --repo "$ORG/deploy-hub-api" --ref dev -f previous_stable_tag=dev-v0.1.0 -f new_tag=dev-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-ticket-hub-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

### 4.3. Producción

Lanza el workflow desde la rama `master` de `deploy-hub-api` (`--ref master`). Igual que en dev, el job `gate` pide la aprobación del Environment `production-approver` de `deploy-hub-api`: **Review deployments** → **Approve and deploy**.

#### iam-api

```bash
gh workflow run deploy-iam-api-prod.yml --repo "$ORG/deploy-hub-api" --ref master -f previous_stable_tag=prod-v0.1.0 -f new_tag=prod-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-iam-api-prod.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### infra-hub-api

```bash
gh workflow run deploy-infra-hub-api-prod.yml --repo "$ORG/deploy-hub-api" --ref master -f previous_stable_tag=prod-v0.1.0 -f new_tag=prod-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-infra-hub-api-prod.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### ticket-hub-api

```bash
gh workflow run deploy-ticket-hub-api-prod.yml --repo "$ORG/deploy-hub-api" --ref master -f previous_stable_tag=prod-v0.1.0 -f new_tag=prod-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-ticket-hub-api-prod.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### iam

```bash
gh workflow run deploy-iam-prod.yml --repo "$ORG/deploy-hub-api" --ref master -f previous_stable_tag=prod-v0.1.0 -f new_tag=prod-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-iam-prod.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

#### ticket-hub

```bash
gh workflow run deploy-ticket-hub-prod.yml --repo "$ORG/deploy-hub-api" --ref master -f previous_stable_tag=prod-v0.1.0 -f new_tag=prod-v0.1.1
sleep 5
gh run watch --repo "$ORG/deploy-hub-api" $(gh run list --repo "$ORG/deploy-hub-api" --workflow deploy-ticket-hub-prod.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

El workflow valida los tags (`previous_stable_tag` debe existir y `new_tag` no), prueba el código, compila y publica la imagen, crea el tag `new_tag` en el repo de la app y, tras la aprobación, despliega y deja en Docker Hub solo esos dos tags. Sigue todo en la pestaña **Actions** de `deploy-hub-api`.

### Si el deploy automático falla

Si el workflow falla en el deploy (por ejemplo, el cluster no responde) y necesitas salir del paso, aplica los manifiestos directo en la VM del ambiente. Reemplaza a mano los placeholders `DOCKERHUB_USER` e `IMAGE_TAG` en el `deployment.yaml` de la app y copia la carpeta de manifiestos a la VM. Ejemplo con `dev`; repite con `local` y `prod` usando su llave y su VM:

```bash
scp -i ~/.ssh/pcbox_dev -r deploy-hub-api/.github/workflows/<app>/manifests ubuntu@pcbox-dev:~/
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev 'microk8s kubectl apply -f ~/manifests/'
```

## 5. Verificar

Se hace en la VM de cada ambiente.

### local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM:

```bash
microk8s kubectl get pods -A | grep "^local-"
microk8s kubectl get svc -A | grep "^local-"
microk8s kubectl get deploy -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image | grep "^local-"
microk8s kubectl logs -n iam-api deploy/iam-api
exit
```

### dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM:

```bash
microk8s kubectl get pods -A | grep "^dev-"
microk8s kubectl get svc -A | grep "^dev-"
microk8s kubectl get deploy -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image | grep "^dev-"
microk8s kubectl logs -n iam-api deploy/iam-api
exit
```

### prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM:

```bash
microk8s kubectl get pods -A | grep "^prod-"
microk8s kubectl get svc -A | grep "^prod-"
microk8s kubectl get deploy -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image | grep "^prod-"
microk8s kubectl logs -n iam-api deploy/iam-api
exit
```

### Qué debe mostrar

Pods: las 5 apps en `1/1 Running` con `RESTARTS 0`, uno por app. Ejemplo con `dev`:

```
iam              iam-...              1/1   Running   0   1m
iam-api          iam-api-...          1/1   Running   0   5m
infra-hub-api    infra-hub-api-...    1/1   Running   0   4m
ticket-hub       ticket-hub-...       1/1   Running   0   30s
ticket-hub-api   ticket-hub-api-...   1/1   Running   0   3m
```

Además aparecen los Pods de `databases` y `tailscale`, que no son de las apps.

Si un Pod queda en `FailedCreate`, falta el ServiceAccount. Si queda en `ImagePullBackOff`, el tag o la imagen no existen en Docker Hub.

Services: cada app es `ClusterIP` en el puerto `3000`, sin IP externa.

```
iam-api   iam-api   ClusterIP   10.152.183.25   <none>   3000/TCP   1m
```

Imágenes: cada deployment debe usar la del tag que publicaste, por ejemplo `<DOCKERHUB_USERNAME>/iam-api:dev-v0.1.1` en `dev`.

### DNS interno

Cada app responde dentro del cluster de su VM en `<app>.<namespace>.svc.cluster.local:3000`:

| App | Dirección |
|---|---|
| `iam` | `iam.iam` |
| `iam-api` | `iam-api.iam-api` |
| `infra-hub-api` | `infra-hub-api.infra-hub-api` |
| `ticket-hub` | `ticket-hub.ticket-hub` |
| `ticket-hub-api` | `ticket-hub-api.ticket-hub-api` |

Agrega `.svc.cluster.local:3000` a cada valor.

<p align="right"><a href="set-up-the-ecosystem-jtagram.md">← Back</a></p>
