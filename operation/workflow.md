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

El prefijo evita que los tags de dev y prod choquen, porque un tag de git y una imagen de Docker Hub son únicos por repositorio. Más detalle en [create-tag-for-dockerhub-and-github.md](../create-tag-for-dockerhub-and-github.md).

Cada app y ambiente tiene su workflow en `deploy-hub-api` (`deploy-<app>-<ambiente>.yml`), que solo pasa sus parámetros al workflow reutilizable `deploy.yml`.

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
| 3 | Verifica que `previous_stable_tag` y `new_tag` no estén vacíos, que empiecen con el prefijo del ambiente y que tengan el formato `vNUMERO.NUMERO.NUMERO` |
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

### Rollback

No hay un workflow que despliegue solo un tag ya publicado: cada ejecución de dev y prod compila y publica un `new_tag` nuevo. Por eso el `cleanup-tags` conserva `previous_stable_tag` en Docker Hub: queda la imagen anterior disponible. Para volver atrás, en la VM del ambiente:

```bash
microk8s kubectl rollout undo deployment/<app> -n <app>
```

### Dónde ver las ejecuciones

| Qué | URL |
|---|---|
| Release y deploy de dev y prod, y deploy de local | `https://github.com/jtagram/deploy-hub-api/actions` |
| Disparo de local de una app (solo el `gh workflow run`) | `https://github.com/jtagram/<app>/actions` |

Cada ejecución de dev y prod deja en el *Summary* de `deploy-hub-api` los tags conservados y eliminados de Docker Hub.

## Dónde está implementado

5 apps × 3 ambientes = 15 workflows en `deploy-hub-api`, más un disparo por app para local.

| Qué | Ruta |
|---|---|
| Workflow reutilizable de dev y prod | `deploy-hub-api/.github/workflows/deploy.yml` |
| Workflow reutilizable de local | `deploy-hub-api/.github/workflows/deploy-local.yml` |
| Workflow de cada app y ambiente | `deploy-hub-api/.github/workflows/deploy-<app>-<ambiente>.yml` |
| Disparo de local en la app | `<app>/.github/workflows/release-<app>-local.yml` |
| Manifiestos de k8s | `deploy-hub-api/.github/workflows/<app>/manifests/` (`namespace`, `deployment`, `service`) |
| Scripts | `deploy-hub-api/scripts/` |

Apps: `iam`, `iam-api`, `ticket-hub`, `ticket-hub-api`, `infra-hub-api`.

Los secrets se cargan por environment de GitHub (`local`, `dev`, `prod`): [load-secrets-for-github-action-for-three-environments.md](../load-secrets-for-github-action-for-three-environments.md).

## Por qué todo en deploy-hub-api

**Criterio principal: que un cambio accidental o hecho con IA en una app no pueda desplegar directo.**

El código de una app se modifica seguido (a mano o con IA) y una aprobación puede darse sin revisar todo. Por eso lo que compila, publica y toca el cluster vive aparte, en `deploy-hub-api`, que se cambia con más cuidado.

- **Las apps no tienen credenciales del cluster ni de Docker Hub:** el kubeconfig, los secrets de Tailscale y de Docker Hub viven solo en `deploy-hub-api`. Un workflow de app solo puede pedir que se despliegue su rama `local`; no puede cambiar manifiestos, pasos de rollout ni secrets.
- **Límite:** esto reduce el daño posible, no lo elimina. Lo completan la aprobación manual de dev/prod, la validación de la rama de lanzamiento y las validaciones previas. La rama de lanzamiento se valida dentro del workflow, así que quien pueda editarlo podría quitar ese chequeo: lo refuerza restringir las ramas permitidas en cada Environment de GitHub.
- **Recomendado:** proteger las ramas de `deploy-hub-api` (PR y revisión obligatorios). Esa configuración está en GitHub, no en el código.

Otros beneficios:

- **Un solo lugar:** la lógica del release, los manifiestos y los pasos de rollout están en un repo, no copiados en cada app. Un arreglo en `deploy.yml` o en un script aplica a las 5 apps.
- **Traspaso a otro equipo:** si un equipo (por ejemplo, plataforma o DevOps) asume los deploys, se lleva `deploy-hub-api` completo sin tocar las apps. Para que siga así, las apps solo conocen del deploy el nombre del workflow de local, la rama `local` y el token de dispatch.
- **Se publica lo que pasó los controles:** antes de compilar se valida que los tags sean correctos y que el código pase lint y tests, y el tag de git se crea sobre el mismo commit.
- **Control por ambiente:** dev y prod exigen aprobación manual; local es directo para iterar rápido.
- **Scripts en vez de YAML largo:** la lógica está en scripts con nombre claro, que se leen y prueban por separado.

<p align="right"><a href="operation.md">← Back</a></p>
