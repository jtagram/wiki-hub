# Workflows de GitHub Actions

## Qué es

El pipeline que lleva el código de una app hasta el cluster de cada ambiente (local, dev, prod). Son dos capas de workflows:

- **release** (en el repo de cada app): valida, prueba, construye la imagen, la publica en Docker Hub y crea el tag de git.
- **deploy** (en `deploy-hub-api`): aplica los manifiestos en el microk8s del ambiente con la imagen indicada.

La app nunca toca el cluster. Solo `deploy-hub-api` tiene el kubeconfig.

### Flujo: dev y prod

Se dispara a mano (`workflow_dispatch`) con dos inputs: `previous_stable_tag` y `new_tag`, con el prefijo del ambiente:

| Ambiente | Formato | Ejemplo |
|---|---|---|
| dev | `dev-vNUMERO.NUMERO.NUMERO` | `dev-v0.1.5` |
| prod | `prod-vNUMERO.NUMERO.NUMERO` | `prod-v0.1.5` |

El prefijo evita que los tags de dev y prod choquen, porque un tag de git y una imagen de Docker Hub son únicos por repositorio. Más detalle en [create-tag-for-dockerhub-and-github.md](../create-tag-for-dockerhub-and-github.md).

```text
 REPO DE LA APP  (release-<app>-<ambiente>.yml)
┌────────────┐  ┌────────────┐  ┌────────────────┐  ┌────────────┐  ┌────────────┐
│ 1.validate │─▶│ 2.quality  │─▶│ 3.build-and-   │─▶│ 4.gate     │─▶│ 5.dispatch │
│ secrets,   │  │ lint,      │  │   push         │  │ aprobación │  │ dispara el │
│ tags y     │  │ prettier,  │  │ imagen a       │  │ manual     │  │ deploy y   │
│ Docker Hub │  │ tests, e2e │  │ Docker Hub +   │  │            │  │ espera     │
│            │  │            │  │ tag de git     │  │            │  │            │
└────────────┘  └────────────┘  └────────────────┘  └────────────┘  └─────┬──────┘
                                                                          │
 DEPLOY-HUB-API  (deploy-<app>-<ambiente>.yml)                            ▼
┌────────────────────┐   ┌──────────────────────────────┐   ┌───────────────────────┐
│ 6.validate         │──▶│ 7.deploy                     │   │ 8.cleanup-tags        │
│ secrets, YAML,     │   │ Tailscale → kubeconfig →     │──▶│ borra de Docker Hub   │
│ tag en GitHub y    │   │ kubectl apply → rollout      │   │ todos los tags menos  │
│ Docker Hub         │   │ restart y status             │   │ el anterior y el nuevo│
└────────────────────┘   └──────────────────────────────┘   └───────────────────────┘
```

| Paso | Qué hace |
|---|---|
| 1 | Verifica secrets, formato de tags, que el anterior exista y el nuevo no (en git y Docker Hub) |
| 2 | `npm run lint`, `format:check`, tests unitarios y e2e |
| 3 | Construye y sube `<usuario>/<app>:<new_tag>`; crea el tag en git |
| 4 | Espera la aprobación del environment `development-approver` (dev) o `production-approver` (prod) |
| 5 | Dispara el workflow de deploy en `deploy-hub-api` y espera a que termine |
| 6-7 | Valida y despliega en el cluster; si falla, muestra `describe` y eventos |
| 8 | Deja en Docker Hub solo `previous_stable_tag` y `new_tag` (el anterior sirve para rollback) |

### Flujo: local

Sin validaciones ni aprobación. Un `push` a la rama `local` construye la imagen con el tag fijo `local` (se sobrescribe en cada push) y dispara el deploy local. No usa versiones: `local-v0.1.0` solo existe como tag semilla creado a mano.

```text
 push a la rama `local` ──▶ build-and-push (imagen :local) ──▶ deploy-<app>-local.yml ──▶ microk8s local
```

| Paso | Qué hace |
|---|---|
| `push` a `local` | Dispara `release-<app>-local.yml` en el repo de la app |
| `build-and-push` | Construye y sube `<usuario>/<app>:local` a Docker Hub |
| `deploy-<app>-local.yml` | En `deploy-hub-api`, aplica los manifiestos en el microk8s local y reinicia el deployment |

### Dónde ver las ejecuciones

| Qué | URL |
|---|---|
| Release de una app | `https://github.com/jtagram/<app>/actions` |
| Deploy de cualquier app | `https://github.com/jtagram/deploy-hub-api/actions` |

Cada ejecución de release deja en el *Summary* el link al deploy y a los tags de Docker Hub.

## Dónde está implementado

5 apps × 3 ambientes = 15 workflows de cada capa.

| Qué | Ruta |
|---|---|
| Release | `<app>/.github/workflows/release-<app>-<ambiente>.yml` |
| Scripts del release | `<app>/.github/scripts/` |
| Deploy | `deploy-hub-api/.github/workflows/deploy-<app>-<ambiente>.yml` |
| Manifiestos de k8s | `deploy-hub-api/.github/workflows/<app>/manifests/` (`namespace`, `deployment`, `service`) |
| Scripts del deploy | `deploy-hub-api/scripts/` |

Apps: `iam`, `iam-api`, `ticket-hub`, `ticket-hub-api`, `infra-hub-api`.

Los secrets se cargan por environment de GitHub (`local`, `dev`, `prod`): [load-secrets-for-github-action-for-three-environments.md](../load-secrets-for-github-action-for-three-environments.md).

## Por qué separar release y deploy

**Criterio principal: que un cambio accidental o hecho con IA en una app no pueda desplegar directo.**

El código de una app se modifica seguido (a mano o con IA) y una aprobación puede darse sin revisar todo. Por eso lo que toca el cluster vive aparte, en `deploy-hub-api`, que se cambia con más cuidado.

- **Las apps no tienen credenciales del cluster:** el kubeconfig y los secrets de Tailscale viven solo en `deploy-hub-api`. Un workflow de app solo puede publicar una imagen y pedir un deploy; no puede cambiar manifiestos, pasos de rollout ni secrets.
- **Límite:** esto reduce el daño posible, no lo elimina. Lo completan la aprobación manual de dev/prod y las validaciones del deploy.
- **Recomendado:** proteger las ramas de `deploy-hub-api` (PR y revisión obligatorios). Esa configuración está en GitHub, no en el código.

Otros beneficios:

- **Un solo lugar para desplegar:** manifiestos y pasos de rollout están en un repo, no copiados en cada app.
- **Traspaso a otro equipo:** si un equipo (por ejemplo, plataforma o DevOps) asume los deploys, se lleva `deploy-hub-api` completo sin tocar las apps. Para que siga así, hay que mantener estable lo que las apps conocen del deploy: el nombre de cada workflow, el input `image_tag`, las ramas (`local`, `dev`, `master`) y los tokens de dispatch.
- **Se despliega lo ya publicado:** el deploy valida que el tag exista en git y Docker Hub; nunca despliega algo que no se construyó.
- **Control por ambiente:** dev y prod exigen aprobación manual; local es directo para iterar rápido.
- **Rollback simple:** se conserva el tag anterior y basta con relanzar el deploy con él.
- **Scripts en vez de YAML largo:** la lógica está en scripts con nombre claro, que se leen y prueban por separado.

<p align="right"><a href="operation.md">← Back</a></p>
