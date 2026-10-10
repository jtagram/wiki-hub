# Crear los environments en GitHub

Los workflows usan dos tipos de Environment:

- **Environments con secretos** (`prod`, `dev`, `local`): guardan los secretos de ese ambiente. Todo job que lee `secrets.*` declara uno de ellos. No llevan regla de protección, así el job nunca queda esperando por culpa de los secretos.
- **Environments de aprobación** (`production-approver`, `development-approver`): solo tienen la regla de aprobación manual y **no llevan secretos**. Los usa únicamente el job `gate` (vacío) de `release-<app>.yml` y `release-<app>-dev.yml`, que se detiene a esperar la aprobación antes de que el job `dispatch` dispare el deploy. El botón de aprobación solo aparece si el Environment tiene una regla de protección; sin regla, el job pasa sin pedir nada.

Los Environments no se comparten entre repositorios. Se crean una sola vez por repositorio.

## 1. Datos

Repositorios de apps: `iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`.

| Environment | Para qué sirve | Secretos | Aprobación manual |
|---|---|---|---|
| `prod` | Secretos de producción | Sí | No |
| `dev` | Secretos de desarrollo | Sí | No |
| `local` | Secretos de local | Sí | No |
| `production-approver` | Aprobar el release a producción | No | Sí (Required reviewers) |
| `development-approver` | Aprobar el release a desarrollo | No | Sí (Required reviewers) |

Cada repositorio de app necesita los 5 Environments. `deploy-hub-api` solo necesita `prod`, `dev` y `local`: sus workflows de deploy no piden aprobación (la aprobación ya se dio en el release de la app).

## 2. Crear los environments

Por cada repositorio, desde la web:

1. `<repo>` → **Settings** → **Environments** → **New environment**.
2. Escribe el nombre exacto de la tabla y pulsa **Configure environment**.
3. Repite para cada Environment que corresponda al repositorio.

O con la CLI. Pega el bloque completo y cambia solo `<tu-organizacion>`:

```bash
NUEVA_ORG=<tu-organizacion>

# iam
gh api -X PUT "repos/$NUEVA_ORG/iam/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/iam/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/iam/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/iam/environments/production-approver"
gh api -X PUT "repos/$NUEVA_ORG/iam/environments/development-approver"

# iam-api
gh api -X PUT "repos/$NUEVA_ORG/iam-api/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/iam-api/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/iam-api/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/iam-api/environments/production-approver"
gh api -X PUT "repos/$NUEVA_ORG/iam-api/environments/development-approver"

# infra-hub-api
gh api -X PUT "repos/$NUEVA_ORG/infra-hub-api/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/infra-hub-api/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/infra-hub-api/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/infra-hub-api/environments/production-approver"
gh api -X PUT "repos/$NUEVA_ORG/infra-hub-api/environments/development-approver"

# ticket-hub
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub/environments/production-approver"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub/environments/development-approver"

# ticket-hub-api
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub-api/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub-api/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub-api/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub-api/environments/production-approver"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub-api/environments/development-approver"

# deploy-hub-api
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/local"
```

## 3. Agregar la aprobación manual en los approvers

Solo en los repositorios de apps, y solo en `production-approver` y `development-approver`. Repite estos pasos en cada uno de estos 5 repositorios:

- `iam`
- `iam-api`
- `infra-hub-api`
- `ticket-hub`
- `ticket-hub-api`

`deploy-hub-api` no se toca: no tiene Environments de aprobación.

1. `<app>` → **Settings** → **Environments** → `production-approver` (luego repite con `development-approver`).
2. Marca **Required reviewers** y agrega al menos una persona.
3. Pulsa **Save protection rules**.

No agregues secretos a estos dos Environments, ni reglas a `prod`, `dev` y `local`.

Si no aparece "Required reviewers": en el plan Free esa opción solo existe para repositorios públicos (o para cualquier repositorio si la organización es Team o Enterprise). Haz el repositorio público (**Settings** → **Danger Zone** → **Change visibility**) o sube el plan de la organización.

## 4. Verificar

Lista los environments de cada repositorio. Pega el bloque completo y cambia solo `<tu-organizacion>`:

```bash
NUEVA_ORG=<tu-organizacion>

echo "iam"; gh api "repos/$NUEVA_ORG/iam/environments" --jq '.environments[].name'
echo "iam-api"; gh api "repos/$NUEVA_ORG/iam-api/environments" --jq '.environments[].name'
echo "infra-hub-api"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments" --jq '.environments[].name'
echo "ticket-hub"; gh api "repos/$NUEVA_ORG/ticket-hub/environments" --jq '.environments[].name'
echo "ticket-hub-api"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments" --jq '.environments[].name'
echo "deploy-hub-api"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments" --jq '.environments[].name'
```

Cada app debe mostrar los 5 nombres (el orden puede variar):

```
dev
development-approver
local
prod
production-approver
```

`deploy-hub-api` debe mostrar solo `dev`, `local` y `prod`.

Comprueba que los approvers tienen la regla de aprobación:

```bash
NUEVA_ORG=<tu-organizacion>

echo "iam/production-approver"; gh api "repos/$NUEVA_ORG/iam/environments/production-approver" --jq '.protection_rules[].type'
echo "iam/development-approver"; gh api "repos/$NUEVA_ORG/iam/environments/development-approver" --jq '.protection_rules[].type'
echo "iam-api/production-approver"; gh api "repos/$NUEVA_ORG/iam-api/environments/production-approver" --jq '.protection_rules[].type'
echo "iam-api/development-approver"; gh api "repos/$NUEVA_ORG/iam-api/environments/development-approver" --jq '.protection_rules[].type'
echo "infra-hub-api/production-approver"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/production-approver" --jq '.protection_rules[].type'
echo "infra-hub-api/development-approver"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/development-approver" --jq '.protection_rules[].type'
echo "ticket-hub/production-approver"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/production-approver" --jq '.protection_rules[].type'
echo "ticket-hub/development-approver"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/development-approver" --jq '.protection_rules[].type'
echo "ticket-hub-api/production-approver"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/production-approver" --jq '.protection_rules[].type'
echo "ticket-hub-api/development-approver"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/development-approver" --jq '.protection_rules[].type'
```

Cada comando debe mostrar `required_reviewers`. Si no imprime nada, el Environment existe pero no tiene aprobación: el release pasaría sin pedir confirmación. Vuelve al paso 3.

Haz la comprobación inversa en `prod`, `dev` y `local`: no deben mostrar ninguna regla.

```bash
NUEVA_ORG=<tu-organizacion>

echo "iam/prod"; gh api "repos/$NUEVA_ORG/iam/environments/prod" --jq '.protection_rules[].type'
echo "iam/dev"; gh api "repos/$NUEVA_ORG/iam/environments/dev" --jq '.protection_rules[].type'
echo "iam/local"; gh api "repos/$NUEVA_ORG/iam/environments/local" --jq '.protection_rules[].type'
echo "iam-api/prod"; gh api "repos/$NUEVA_ORG/iam-api/environments/prod" --jq '.protection_rules[].type'
echo "iam-api/dev"; gh api "repos/$NUEVA_ORG/iam-api/environments/dev" --jq '.protection_rules[].type'
echo "iam-api/local"; gh api "repos/$NUEVA_ORG/iam-api/environments/local" --jq '.protection_rules[].type'
echo "infra-hub-api/prod"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/prod" --jq '.protection_rules[].type'
echo "infra-hub-api/dev"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/dev" --jq '.protection_rules[].type'
echo "infra-hub-api/local"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/local" --jq '.protection_rules[].type'
echo "ticket-hub/prod"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/prod" --jq '.protection_rules[].type'
echo "ticket-hub/dev"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/dev" --jq '.protection_rules[].type'
echo "ticket-hub/local"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/local" --jq '.protection_rules[].type'
echo "ticket-hub-api/prod"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/prod" --jq '.protection_rules[].type'
echo "ticket-hub-api/dev"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/dev" --jq '.protection_rules[].type'
echo "ticket-hub-api/local"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/local" --jq '.protection_rules[].type'
```

Por último, confirma que los approvers no tienen secretos (cada comando debe imprimir `0`):

```bash
NUEVA_ORG=<tu-organizacion>

echo "iam/production-approver"; gh api "repos/$NUEVA_ORG/iam/environments/production-approver/secrets" --jq '.total_count'
echo "iam/development-approver"; gh api "repos/$NUEVA_ORG/iam/environments/development-approver/secrets" --jq '.total_count'
echo "iam-api/production-approver"; gh api "repos/$NUEVA_ORG/iam-api/environments/production-approver/secrets" --jq '.total_count'
echo "iam-api/development-approver"; gh api "repos/$NUEVA_ORG/iam-api/environments/development-approver/secrets" --jq '.total_count'
echo "infra-hub-api/production-approver"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/production-approver/secrets" --jq '.total_count'
echo "infra-hub-api/development-approver"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments/development-approver/secrets" --jq '.total_count'
echo "ticket-hub/production-approver"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/production-approver/secrets" --jq '.total_count'
echo "ticket-hub/development-approver"; gh api "repos/$NUEVA_ORG/ticket-hub/environments/development-approver/secrets" --jq '.total_count'
echo "ticket-hub-api/production-approver"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/production-approver/secrets" --jq '.total_count'
echo "ticket-hub-api/development-approver"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments/development-approver/secrets" --jq '.total_count'
```
