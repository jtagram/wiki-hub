# Preparación para el primer deploy

Dos cosas que hay que dejar listas una sola vez **en cada uno de los 5 repos de apps** (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`), antes de correr su `release-<app>.yml` por primera vez. Sin esto, la primera corrida del workflow falla o no pide aprobación.

El procedimiento es **idéntico en las 5** — el mismo `release-<app>.yml` (mismos jobs, mismos scripts de validación de tags, mismo `environment: production`), solo cambia el nombre de la app. Los pasos siguientes usan `<app>` como placeholder: reemplazalo por cada uno de los 5 nombres (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api` — el nombre del repo es siempre igual al nombre de la imagen en Docker Hub).

## 1. Crear el primer tag, en git y en Docker Hub

`release-<app>.yml` pide dos inputs: `previous_stable_tag` (tiene que **existir ya**) y `new_tag` (tiene que **no existir todavía**). El job `validate` chequea `previous_stable_tag` en dos lugares — como tag de git (`verificar-tag-existe.sh`) y como tag publicado en Docker Hub (`verificar-tag-docker-hub-existe.sh`) — así que para el primer release de cada app hay que crearlo a mano en los dos.

Tag de git, sobre el commit actual:

```bash
cd <app>
git tag v0.1.0
git push origin v0.1.0
```

Imagen en Docker Hub, con el mismo tag:

```bash
docker build -t <DOCKERHUB_USERNAME>/<app>:v0.1.0 .
docker login
docker push <DOCKERHUB_USERNAME>/<app>:v0.1.0
```

Si te falta cualquiera de los dos, `validate` falla con un mensaje que lo explica (`el tag '<tag>' no existe como tag de git` o `no existe en el repositorio '<usuario>/<app>' de Docker Hub`).

Al disparar el workflow por primera vez, usá:

- `previous_stable_tag`: `v0.1.0` (el que acabás de crear).
- `new_tag`: la próxima versión real que vas a publicar, por ejemplo `v0.1.1` — tiene que ser distinto de `v0.1.0`, porque el paso siguiente (`verificar-tag-no-existe.sh`) falla si `new_tag` ya existe.

Repetí este paso una vez por cada uno de los 5 repos:

| App | Repo / imagen Docker Hub |
|---|---|
| `iam` | `<DOCKERHUB_USERNAME>/iam` |
| `iam-api` | `<DOCKERHUB_USERNAME>/iam-api` |
| `infra-hub-api` | `<DOCKERHUB_USERNAME>/infra-hub-api` |
| `ticket-hub` | `<DOCKERHUB_USERNAME>/ticket-hub` |
| `ticket-hub-api` | `<DOCKERHUB_USERNAME>/ticket-hub-api` |

## 2. Configurar el Environment `production`

El job `approve-and-deploy` de `release-<app>.yml` usa `environment: production` para frenar y pedir aprobación manual antes de disparar el deploy. Si ese Environment no existe todavía en el repo, GitHub Actions lo crea solo la primera vez que se usa, pero **sin ninguna regla de protección** — el job pasa derecho, sin mostrar ningún botón. Hay que crear la regla a mano, **en el repo de cada app** (no en `deploy-hub-api`, que no tiene este Environment):

1. `<app>` → **Settings** → **Environments**.
2. Si no está, **New environment** → nombre exacto `production` (tiene que coincidir con el `environment.name` del workflow).
3. **Deployment protection rules** → **Required reviewers** → agregate a vos (o al equipo que corresponda) → **Save protection rules**.

**"Required reviewers" no aparece en repos privados si la organización está en plan Free** (solo está disponible en Free para repos públicos, o en cualquier repo si la organización es Team/Enterprise). Si no te aparece la sección, o hacés `<app>` público (**Settings** → **Danger Zone** → **Change visibility**), o subís la organización a un plan que soporte protection rules en repos privados.

Con la regla creada, `approve-and-deploy` va a quedar pausado con el botón "Review deployments" hasta que lo aprueben.

Cada uno de los 5 repos tiene su **propia** configuración de Environments en GitHub — no se comparte entre repos, así que hay que repetir este paso 2 en los 5:

| App | Repo donde configurar el Environment |
|---|---|
| `iam` | `iam` |
| `iam-api` | `iam-api` |
| `infra-hub-api` | `infra-hub-api` |
| `ticket-hub` | `ticket-hub` |
| `ticket-hub-api` | `ticket-hub-api` |
