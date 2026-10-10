# Cargar los secretos de GitHub Actions por CLI en los 3 ambientes

Carga con la CLI de `gh` los secretos de cada ambiente como **Environment secrets**. Los bloques están listos para copiar y pegar: solo cambia `<tu-organizacion>` y cada `<VALOR>` por el valor real.

Los valores se obtienen en [generate-secret-values-for-github-action-for-three-environments.md](generate-secret-values-for-github-action-for-three-environments.md).

Necesitas:

- Los Environments creados en cada repositorio — [create-environment-in-github.md](create-environment-in-github.md). Un Environment secret solo se puede cargar si el Environment ya existe.
- La CLI `gh` autenticada con permisos de administración sobre los repositorios (`gh auth status`).
- En la carpeta desde la que pegas los comandos, los kubeconfig de administración que bajaste en el paso anterior: `pcbox-kubeconfig-prod.yaml`, `pcbox-kubeconfig-dev.yaml` y `pcbox-kubeconfig-local.yaml`.

Cada ambiente usa el mismo nombre de secreto con su propio valor, en el Environment del mismo nombre (`prod`, `dev` o `local`). No cargues secretos en `production-approver` ni en `development-approver`.

Los valores quedan en el historial de la terminal. Al terminar de cargar un ambiente, borra las variables:

```bash
unset DOCKERHUB_USERNAME DOCKERHUB_TOKEN TS_OAUTH_CLIENT_ID TS_OAUTH_SECRET DISPATCH_TOKEN
```

---

## prod

Ejecuta los comandos **desde la carpeta donde está `pcbox-kubeconfig-prod.yaml`**. El comando de `KUBECONFIG_MICROK8S` lo lee con una ruta relativa y, si estás en otra carpeta, falla con "No such file or directory".

Pega el bloque completo. Reemplaza `<tu-organizacion>` y cada `<VALOR>`:

```bash
ORG=<tu-organizacion>

DOCKERHUB_USERNAME='<VALOR>'
DOCKERHUB_TOKEN='<VALOR>'
TS_OAUTH_CLIENT_ID='<VALOR>'
TS_OAUTH_SECRET='<VALOR>'
DISPATCH_TOKEN='<VALOR>'

# deploy-hub-api
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set TS_OAUTH_CLIENT_ID --env prod --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_CLIENT_ID"
gh secret set TS_OAUTH_SECRET --env prod --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_SECRET"
gh secret set KUBECONFIG_MICROK8S --env prod --repo "$ORG/deploy-hub-api" < pcbox-kubeconfig-prod.yaml

# iam
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/iam" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env prod --repo "$ORG/iam" --body "$DOCKERHUB_TOKEN"
gh secret set IAM_DISPATCH_TOKEN --env prod --repo "$ORG/iam" --body "$DISPATCH_TOKEN"

# iam-api
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/iam-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env prod --repo "$ORG/iam-api" --body "$DOCKERHUB_TOKEN"
gh secret set IAM_API_DISPATCH_TOKEN --env prod --repo "$ORG/iam-api" --body "$DISPATCH_TOKEN"

# infra-hub-api
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/infra-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env prod --repo "$ORG/infra-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set INFRA_HUB_API_DISPATCH_TOKEN --env prod --repo "$ORG/infra-hub-api" --body "$DISPATCH_TOKEN"

# ticket-hub
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/ticket-hub" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env prod --repo "$ORG/ticket-hub" --body "$DOCKERHUB_TOKEN"
gh secret set TICKET_HUB_DISPATCH_TOKEN --env prod --repo "$ORG/ticket-hub" --body "$DISPATCH_TOKEN"

# ticket-hub-api
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/ticket-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env prod --repo "$ORG/ticket-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set TICKET_HUB_API_DISPATCH_TOKEN --env prod --repo "$ORG/ticket-hub-api" --body "$DISPATCH_TOKEN"
```

Verifica que cada repositorio tenga sus secretos en el Environment `prod`:

```bash
ORG=<tu-organizacion>

echo "deploy-hub-api"; gh secret list --env prod --repo "$ORG/deploy-hub-api"
echo "iam"; gh secret list --env prod --repo "$ORG/iam"
echo "iam-api"; gh secret list --env prod --repo "$ORG/iam-api"
echo "infra-hub-api"; gh secret list --env prod --repo "$ORG/infra-hub-api"
echo "ticket-hub"; gh secret list --env prod --repo "$ORG/ticket-hub"
echo "ticket-hub-api"; gh secret list --env prod --repo "$ORG/ticket-hub-api"
```

`deploy-hub-api` debe listar `DOCKERHUB_USERNAME`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`. Cada app debe listar `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` y su `*_DISPATCH_TOKEN`.

---

## dev

Ejecuta los comandos **desde la carpeta donde está `pcbox-kubeconfig-dev.yaml`**. El comando de `KUBECONFIG_MICROK8S` lo lee con una ruta relativa y, si estás en otra carpeta, falla con "No such file or directory".

Pega el bloque completo. Reemplaza `<tu-organizacion>` y cada `<VALOR>`:

```bash
ORG=<tu-organizacion>

DOCKERHUB_USERNAME='<VALOR>'
DOCKERHUB_TOKEN='<VALOR>'
TS_OAUTH_CLIENT_ID='<VALOR>'
TS_OAUTH_SECRET='<VALOR>'
DISPATCH_TOKEN='<VALOR>'

# deploy-hub-api
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set TS_OAUTH_CLIENT_ID --env dev --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_CLIENT_ID"
gh secret set TS_OAUTH_SECRET --env dev --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_SECRET"
gh secret set KUBECONFIG_MICROK8S --env dev --repo "$ORG/deploy-hub-api" < pcbox-kubeconfig-dev.yaml

# iam
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/iam" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env dev --repo "$ORG/iam" --body "$DOCKERHUB_TOKEN"
gh secret set IAM_DISPATCH_TOKEN --env dev --repo "$ORG/iam" --body "$DISPATCH_TOKEN"

# iam-api
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/iam-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env dev --repo "$ORG/iam-api" --body "$DOCKERHUB_TOKEN"
gh secret set IAM_API_DISPATCH_TOKEN --env dev --repo "$ORG/iam-api" --body "$DISPATCH_TOKEN"

# infra-hub-api
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/infra-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env dev --repo "$ORG/infra-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set INFRA_HUB_API_DISPATCH_TOKEN --env dev --repo "$ORG/infra-hub-api" --body "$DISPATCH_TOKEN"

# ticket-hub
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/ticket-hub" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env dev --repo "$ORG/ticket-hub" --body "$DOCKERHUB_TOKEN"
gh secret set TICKET_HUB_DISPATCH_TOKEN --env dev --repo "$ORG/ticket-hub" --body "$DISPATCH_TOKEN"

# ticket-hub-api
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/ticket-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env dev --repo "$ORG/ticket-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set TICKET_HUB_API_DISPATCH_TOKEN --env dev --repo "$ORG/ticket-hub-api" --body "$DISPATCH_TOKEN"
```

Verifica que cada repositorio tenga sus secretos en el Environment `dev`:

```bash
ORG=<tu-organizacion>

echo "deploy-hub-api"; gh secret list --env dev --repo "$ORG/deploy-hub-api"
echo "iam"; gh secret list --env dev --repo "$ORG/iam"
echo "iam-api"; gh secret list --env dev --repo "$ORG/iam-api"
echo "infra-hub-api"; gh secret list --env dev --repo "$ORG/infra-hub-api"
echo "ticket-hub"; gh secret list --env dev --repo "$ORG/ticket-hub"
echo "ticket-hub-api"; gh secret list --env dev --repo "$ORG/ticket-hub-api"
```

`deploy-hub-api` debe listar `DOCKERHUB_USERNAME`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`. Cada app debe listar `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` y su `*_DISPATCH_TOKEN`.

---

## local

Ejecuta los comandos **desde la carpeta donde está `pcbox-kubeconfig-local.yaml`**. El comando de `KUBECONFIG_MICROK8S` lo lee con una ruta relativa y, si estás en otra carpeta, falla con "No such file or directory".

Pega el bloque completo. Reemplaza `<tu-organizacion>` y cada `<VALOR>`:

```bash
ORG=<tu-organizacion>

DOCKERHUB_USERNAME='<VALOR>'
DOCKERHUB_TOKEN='<VALOR>'
TS_OAUTH_CLIENT_ID='<VALOR>'
TS_OAUTH_SECRET='<VALOR>'
DISPATCH_TOKEN='<VALOR>'

# deploy-hub-api
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set TS_OAUTH_CLIENT_ID --env local --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_CLIENT_ID"
gh secret set TS_OAUTH_SECRET --env local --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_SECRET"
gh secret set KUBECONFIG_MICROK8S --env local --repo "$ORG/deploy-hub-api" < pcbox-kubeconfig-local.yaml

# iam
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/iam" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env local --repo "$ORG/iam" --body "$DOCKERHUB_TOKEN"
gh secret set IAM_DISPATCH_TOKEN --env local --repo "$ORG/iam" --body "$DISPATCH_TOKEN"

# iam-api
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/iam-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env local --repo "$ORG/iam-api" --body "$DOCKERHUB_TOKEN"
gh secret set IAM_API_DISPATCH_TOKEN --env local --repo "$ORG/iam-api" --body "$DISPATCH_TOKEN"

# infra-hub-api
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/infra-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env local --repo "$ORG/infra-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set INFRA_HUB_API_DISPATCH_TOKEN --env local --repo "$ORG/infra-hub-api" --body "$DISPATCH_TOKEN"

# ticket-hub
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/ticket-hub" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env local --repo "$ORG/ticket-hub" --body "$DOCKERHUB_TOKEN"
gh secret set TICKET_HUB_DISPATCH_TOKEN --env local --repo "$ORG/ticket-hub" --body "$DISPATCH_TOKEN"

# ticket-hub-api
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/ticket-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env local --repo "$ORG/ticket-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set TICKET_HUB_API_DISPATCH_TOKEN --env local --repo "$ORG/ticket-hub-api" --body "$DISPATCH_TOKEN"
```

Verifica que cada repositorio tenga sus secretos en el Environment `local`:

```bash
ORG=<tu-organizacion>

echo "deploy-hub-api"; gh secret list --env local --repo "$ORG/deploy-hub-api"
echo "iam"; gh secret list --env local --repo "$ORG/iam"
echo "iam-api"; gh secret list --env local --repo "$ORG/iam-api"
echo "infra-hub-api"; gh secret list --env local --repo "$ORG/infra-hub-api"
echo "ticket-hub"; gh secret list --env local --repo "$ORG/ticket-hub"
echo "ticket-hub-api"; gh secret list --env local --repo "$ORG/ticket-hub-api"
```

`deploy-hub-api` debe listar `DOCKERHUB_USERNAME`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`. Cada app debe listar `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` y su `*_DISPATCH_TOKEN`.
