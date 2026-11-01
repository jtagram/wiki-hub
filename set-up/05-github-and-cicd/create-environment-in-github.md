# Crear los environments en GitHub

## 1. Crear los environments

Por cada repositorio, desde la web:

1. `<repo>` → **Settings** → **Environments** → **New environment**.
2. Escribe el nombre exacto del Environment y pulsa **Configure environment**.
3. Repite para cada Environment del repositorio: `prod`, `dev`, `local`, `production-approver` y `development-approver` en `deploy-hub-api`; solo `local` en cada app (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`).

O con la CLI. Pega el bloque completo y cambia solo `<tu-organizacion>`:

```bash
NUEVA_ORG=<tu-organizacion>

# deploy-hub-api
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/prod"
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/dev"
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/production-approver"
gh api -X PUT "repos/$NUEVA_ORG/deploy-hub-api/environments/development-approver"

# apps (solo local)
gh api -X PUT "repos/$NUEVA_ORG/iam/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/iam-api/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/infra-hub-api/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub/environments/local"
gh api -X PUT "repos/$NUEVA_ORG/ticket-hub-api/environments/local"
```

## 2. Agregar la aprobación manual en los approvers

Solo en `deploy-hub-api`, y solo en `production-approver` y `development-approver`. Las apps no tienen Environments de aprobación.

1. `deploy-hub-api` → **Settings** → **Environments** → `production-approver` (luego repite con `development-approver`).
2. Marca **Required reviewers** y agrega al menos una persona.
3. Pulsa **Save protection rules**.

No agregues secretos a estos dos Environments, ni reglas de aprobación a `prod`, `dev` y `local`.

Si no aparece "Required reviewers": en el plan Free esa opción solo existe para repositorios públicos (o para cualquier repositorio si la organización es Team o Enterprise). Haz el repositorio público (**Settings** → **Danger Zone** → **Change visibility**) o sube el plan de la organización.

### Recomendado: restringir las ramas

El workflow ya rechaza un lanzamiento desde una rama equivocada (job `validate-branch`), pero ese chequeo está en el propio workflow y quien lo edite podría quitarlo. Para que lo haga cumplir GitHub, en `deploy-hub-api` → **Settings** → **Environments** → el Environment → **Deployment branches and tags** → **Selected branches**:

| Environment | Rama permitida |
|---|---|
| `dev` y `development-approver` | `dev` |
| `prod` y `production-approver` | `master` |

## 3. Verificar

Lista los environments de cada repositorio. Pega el bloque completo y cambia solo `<tu-organizacion>`:

```bash
NUEVA_ORG=<tu-organizacion>

echo "deploy-hub-api"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments" --jq '.environments[].name'
echo "iam"; gh api "repos/$NUEVA_ORG/iam/environments" --jq '.environments[].name'
echo "iam-api"; gh api "repos/$NUEVA_ORG/iam-api/environments" --jq '.environments[].name'
echo "infra-hub-api"; gh api "repos/$NUEVA_ORG/infra-hub-api/environments" --jq '.environments[].name'
echo "ticket-hub"; gh api "repos/$NUEVA_ORG/ticket-hub/environments" --jq '.environments[].name'
echo "ticket-hub-api"; gh api "repos/$NUEVA_ORG/ticket-hub-api/environments" --jq '.environments[].name'
```

`deploy-hub-api` debe mostrar los 5 nombres (el orden puede variar):

```
dev
development-approver
local
prod
production-approver
```

Cada app debe mostrar solo `local`.

Comprueba que los approvers tienen la regla de aprobación:

```bash
NUEVA_ORG=<tu-organizacion>

echo "deploy-hub-api/production-approver"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/production-approver" --jq '.protection_rules[].type'
echo "deploy-hub-api/development-approver"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/development-approver" --jq '.protection_rules[].type'
```

Cada comando debe mostrar `required_reviewers`. Si no imprime nada, el Environment existe pero no tiene aprobación: el deploy pasaría sin pedir confirmación. Vuelve al paso 2.

Haz la comprobación inversa en `prod`, `dev` y `local` de `deploy-hub-api`: no deben mostrar ninguna regla de aprobación. Si restringiste las ramas, aparecerá una regla de tipo `branch_policy`, y eso es correcto: lo que no debe aparecer es `required_reviewers`.

```bash
NUEVA_ORG=<tu-organizacion>

echo "deploy-hub-api/prod"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/prod" --jq '.protection_rules[].type'
echo "deploy-hub-api/dev"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/dev" --jq '.protection_rules[].type'
echo "deploy-hub-api/local"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/local" --jq '.protection_rules[].type'
```

Por último, confirma que los approvers no tienen secretos (cada comando debe imprimir `0`):

```bash
NUEVA_ORG=<tu-organizacion>

echo "deploy-hub-api/production-approver"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/production-approver/secrets" --jq '.total_count'
echo "deploy-hub-api/development-approver"; gh api "repos/$NUEVA_ORG/deploy-hub-api/environments/development-approver/secrets" --jq '.total_count'
```

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
