# Workflows de GitHub Actions

## Qué es

El pipeline que lleva el código de una app hasta el cluster de cada ambiente (local, dev, prod). Todo corre en `deploy-hub-api`: los repos de las apps no tienen lógica de release ni de deploy.

- **dev y prod:** un solo workflow reutilizable (`deploy.yml`) valida, prueba, construye la imagen, la publica en Docker Hub, crea el tag de git, pide aprobación y despliega.
- **local:** un workflow reutilizable más simple (`deploy-local.yml`) construye la imagen y la despliega, sin validaciones ni aprobación. El repo de la app solo lo dispara.

La app nunca toca el cluster. Solo `deploy-hub-api` tiene el kubeconfig.

### Flujo: dev y prod

Se lanza a mano (`workflow_dispatch`) desde **`deploy-hub-api`** y siempre arranca con dos inputs: `previous_stable_tag` y `new_tag`, con el prefijo del ambiente:

| Ambiente | Formato | Ejemplo |
|---|---|---|
| dev | `dev-vNUMERO.NUMERO.NUMERO` | `dev-v0.1.5` |
| prod | `prod-vNUMERO.NUMERO.NUMERO` | `prod-v0.1.5` |

- `previous_stable_tag`: la última versión estable. Debe **existir ya**, en git (en el repo de la app) y en Docker Hub.
- `new_tag`: la versión que se va a publicar y desplegar. Debe **no existir todavía**.

Cada app tiene un workflow propio por cada ambiente (`local`, `dev` y `prod`) en `deploy-hub-api`, con el nombre `deploy-<app>-<ambiente>.yml`. Ese archivo es solo una puerta de entrada: define los parámetros de esa app y ese ambiente y los pasa a un workflow reutilizable, donde está la lógica real:

- **dev y prod:** `deploy-<app>-dev.yml` y `deploy-<app>-prod.yml` llaman a `deploy.yml`.
- **local:** `deploy-<app>-local.yml` llama a `deploy-local.yml`, más simple y sin aprobación.

| Ambiente | Se lanza desde la rama de `deploy-hub-api` | Compila la rama de la app | Aprobación |
|---|---|---|---|
| dev | `dev` | `dev` | `development-approver` |
| prod | `master` | `master` | `production-approver` |

```text
 DEPLOY-HUB-API  (deploy-<app>-<ambiente>.yml  →  deploy.yml)
┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
│ 1.validate │─▶│ 2.validate │─▶│ 3.validate │─▶│ 4.validate │─▶│ 5.validate │─▶│ 6.validate │
│  branch    │  │  caller    │  │  input     │  │  secrets   │  │  manifests │  │  tags      │
│ rama de    │  │  inputs    │  │  tag       │  │            │  │  YAML      │  │ git y      │
│ lanzamiento│  │ no blancos │  │ prefijo y  │  │            │  │            │  │ Docker Hub │
│            │  │            │  │ formato    │  │            │  │            │  │            │
└────────────┘  └────────────┘  └────────────┘  └────────────┘  └────────────┘  └─────┬──────┘
                                                                                      │
┌────────────┐  ┌────────────────┐  ┌────────────┐  ┌──────────────────────┐  ┌──────▼─────┐
│ 12.cleanup │◀─│ 11.deploy      │◀─│ 10.gate    │◀─│ 9.build-and-push     │◀─│ 7.quality  │
│ -tags      │  │ Tailscale →    │  │ aprobación │  │ imagen a Docker Hub  │  │ lint,      │
│ borra tags │  │ kubeconfig →   │  │ manual     │  │ + tag de git en la   │  │ prettier,  │
│ viejos     │  │ kubectl apply →│  │            │  │ app                  │  │ tests, e2e │
│            │  │ rollout        │  │            │  │                      │  │ (backends) │
└────────────┘  └────────────────┘  └────────────┘  └──────────────────────┘  └────────────┘
```

| Paso | Qué hace |
|---|---|
| 1 | Verifica que el workflow se haya lanzado desde la rama permitida de `deploy-hub-api` (`dev` o `master`) |
| 2 | Verifica que los parámetros del workflow de la app (`app_name`, `namespace`, `app_ref`, etc.) no lleguen vacíos |
| 3 | Valida `previous_stable_tag` y `new_tag`: que no estén vacíos y que sigan el formato del ambiente, el prefijo (`dev-` o `prod-`) seguido de `vNUMERO.NUMERO.NUMERO`, por ejemplo `dev-v0.1.5` |
| 4-5 | Verifica que estén todos los secrets y que los manifiestos de k8s sean YAML válido |
| 6 | Clona la rama de la app y fija su commit; comprueba que `previous_stable_tag` exista y que `new_tag` no exista, en git y en Docker Hub |
| 7 | `npm run lint`, `format:check`, tests unitarios y, solo en los backends, e2e (los frontends no los ejecutan) |
| 9 | Construye y sube `<usuario>/<app>:<new_tag>`; crea el tag `new_tag` en el repo de la app, en el mismo commit que pasó los tests |
| 10 | Espera la aprobación del environment `development-approver` (dev) o `production-approver` (prod) |
| 11 | Aplica los manifiestos y reinicia el deployment; si falla, muestra `describe` y eventos |
| 12 | Deja en Docker Hub solo `previous_stable_tag` y `new_tag` (el anterior sirve para rollback) |

El `quality` y el `build-and-push` usan el mismo commit de la app, el que se fijó en el paso 6, aunque alguien haga push mientras se espera la aprobación.

La concurrencia está por workflow: en dev, una ejecución nueva cancela la que esté en curso; en prod no se cancela ninguna.

### Flujo: local

Sin validaciones, tags ni aprobación. Un `push` a la rama `local` de la app solo **dispara** el workflow de local de esa app en `deploy-hub-api`, que construye la imagen con el tag fijo `local` (se sobrescribe en cada push) y la despliega. No usa versiones: `local-v0.1.0` solo existe como tag semilla creado a mano.

```text
 REPO DE LA APP                          DEPLOY-HUB-API  (rama `local`)
┌──────────────────────┐   dispara   ┌──────────────────────────────────────────────┐
│ push a la rama local │────────────▶│ deploy-<app>-local.yml → deploy-local.yml    │
│ release-<app>-local  │  (token)    │  1.build-and-push (imagen :local)            │
└──────────────────────┘             │  2.deploy → microk8s local                   │
                                     └──────────────────────────────────────────────┘
```

| Paso | Qué hace |
|---|---|
| `push` a `local` | Dispara `release-<app>-local.yml` en el repo de la app, que solo ejecuta `gh workflow run` con el secret `DISPATCH_DEPLOY_HUB_API_LOCAL` |
| `build-and-push` | En `deploy-hub-api`: clona la rama `local` de la app y sube `<usuario>/<app>:local` a Docker Hub |
| `deploy` | En `deploy-hub-api`: aplica los manifiestos en el microk8s local y reinicia el deployment |

<p align="right"><a href="operation.md">← Back</a></p>
