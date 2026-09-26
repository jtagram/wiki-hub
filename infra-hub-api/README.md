# infra-hub-api — Namespace y Secretos en microk8s

Instructivo para dejar el clúster de microk8s (servidor pcbox) listo antes de
correr el workflow de deploy de `infra-hub-api`. Estos pasos son manuales,
no los ejecuta el pipeline de GitHub Actions.

Repos involucrados:
- `deploy-hub-api` → manifiestos de Kubernetes (`.github/workflows/infra-hub-api/manifests/`).
- `infra-hub-api` → código de la app, define qué variables de entorno exige (`src/common/config/env.validation.ts`).

## 1. Crear el namespace

```bash
microk8s kubectl apply -f deploy-hub-api/.github/workflows/infra-hub-api/manifests/namespace.yaml
```

Verificar:

```bash
microk8s kubectl get namespace infra-hub
```

## 2. Crear los Secrets

Los Secrets son un recurso *namespaced*: tienen que existir en el **mismo
namespace** que el Deployment (`infra-hub`), no alcanza con que existan en
otro namespace del clúster (por ejemplo `pcbox-api`, donde viven versiones
anteriores de alguno de estos secretos).

### 2.1. `postgres-credentials`

Leído por `deployment.yaml` para `DB_USERNAME` y `DB_PASSWORD`.

```bash
microk8s kubectl create secret generic postgres-credentials \
  -n infra-hub \
  --from-literal=POSTGRES_USER='<usuario-real>' \
  --from-literal=POSTGRES_PASSWORD='<password-real>'
```

### 2.2. `server-ssh-key`

Leído por `deployment.yaml` para `SERVER_SSH_HOST`, `SERVER_SSH_USER` y
`SERVER_SSH_PRIVATE_KEY` — las tres variables que `AnsibleService`
(`infra-hub-api/src/modules/ansible/ansible.service.ts` y
`ansible.connector.ts`) necesita para conectarse por SSH al servidor pcbox
real y ejecutar playbooks de administración.

```bash
microk8s kubectl create secret generic server-ssh-key \
  -n infra-hub \
  --from-literal=SERVER_SSH_HOST='<host-o-ip-de-pcbox>' \
  --from-literal=SERVER_SSH_USER='<usuario-ssh>' \
  --from-file=SERVER_SSH_PRIVATE_KEY='<ruta-a-la-clave-privada>'
```

> El Secret viejo `pcbox-ssh-key` (namespace `pcbox-api`) contenía solo la
> clave privada. Este `server-ssh-key` nuevo consolida host + usuario + clave
> en un solo Secret, con nombres de key iguales al nombre de la env var que
> representan.

## 3. Verificar

```bash
microk8s kubectl get secrets -n infra-hub
microk8s kubectl describe secret postgres-credentials -n infra-hub
microk8s kubectl describe secret server-ssh-key -n infra-hub
```

`describe` no expone los valores, solo confirma qué keys tiene cada Secret
(deben coincidir exactamente con los `key:` que usa `deployment.yaml`).

## Pendientes conocidos (a la fecha de este documento)

- `deployment.yaml` todavía **no** define la env var `SERVER_SSH_PRIVATE_KEY`
  (solo `SERVER_SSH_HOST` y `SERVER_SSH_USER` vía `server-ssh-key`). Falta
  agregarla como `secretKeyRef` antes de que `AnsibleService` funcione en
  producción — sin ella, `env.validation.ts` frena el arranque del proceso.
- El `volumeMounts`/`volumes` de `pcbox-ssh-key` que monta un archivo en
  `/etc/ssh-keys` no lo usa el código (`AnsibleService` lee la clave desde
  una env var, no desde un archivo montado) — es seguro eliminarlo una vez
  que `SERVER_SSH_PRIVATE_KEY` esté resuelto por Secret.
- El workflow `deploy-infra-hub-api.yml` usa `-n infra-hub-api` en los pasos
  posteriores al `kubectl apply` (rollout, get pods, get service, etc.),
  pero los manifiestos deployan en el namespace `infra-hub`. Hay que
  unificar a uno de los dos nombres antes del primer deploy real.
