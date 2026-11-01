# Cargar los secretos de GitHub Actions por CLI en los 3 ambientes

## prod

Ejecuta los comandos **desde la carpeta donde está `pcbox-kubeconfig-deployer-prod.yaml`**. El comando de `KUBECONFIG_MICROK8S` lo lee con una ruta relativa y, si estás en otra carpeta, falla con "No such file or directory".

Pega el bloque completo. Reemplaza `<tu-organizacion>` y cada `<VALOR>`:

```bash
ORG=<tu-organizacion>

DOCKERHUB_USERNAME='<VALOR>'
DOCKERHUB_TOKEN='<VALOR>'
TS_OAUTH_CLIENT_ID='<VALOR>'
TS_OAUTH_SECRET='<VALOR>'
APP_REPO_TOKEN='<VALOR>'

# deploy-hub-api
gh secret set DOCKERHUB_USERNAME --env prod --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env prod --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set TS_OAUTH_CLIENT_ID --env prod --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_CLIENT_ID"
gh secret set TS_OAUTH_SECRET --env prod --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_SECRET"
gh secret set APP_REPO_TOKEN --env prod --repo "$ORG/deploy-hub-api" --body "$APP_REPO_TOKEN"
gh secret set KUBECONFIG_MICROK8S --env prod --repo "$ORG/deploy-hub-api" < pcbox-kubeconfig-deployer-prod.yaml
```

Verifica que cada repositorio tenga sus secretos en el Environment `prod`:

```bash
ORG=<tu-organizacion>

echo "deploy-hub-api"; gh secret list --env prod --repo "$ORG/deploy-hub-api"
```

`deploy-hub-api` debe listar `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET` y `APP_REPO_TOKEN`. Las apps no llevan secretos en `prod`: sus workflows de prod ya no existen, porque todo el flujo corre en `deploy-hub-api`.

Al terminar, borra las variables:

```bash
unset DOCKERHUB_USERNAME DOCKERHUB_TOKEN TS_OAUTH_CLIENT_ID TS_OAUTH_SECRET APP_REPO_TOKEN DISPATCH_DEPLOY_HUB_API_LOCAL
```

---

## dev

Ejecuta los comandos **desde la carpeta donde está `pcbox-kubeconfig-deployer-dev.yaml`**. El comando de `KUBECONFIG_MICROK8S` lo lee con una ruta relativa y, si estás en otra carpeta, falla con "No such file or directory".

Pega el bloque completo. Reemplaza `<tu-organizacion>` y cada `<VALOR>`:

```bash
ORG=<tu-organizacion>

DOCKERHUB_USERNAME='<VALOR>'
DOCKERHUB_TOKEN='<VALOR>'
TS_OAUTH_CLIENT_ID='<VALOR>'
TS_OAUTH_SECRET='<VALOR>'
APP_REPO_TOKEN='<VALOR>'

# deploy-hub-api
gh secret set DOCKERHUB_USERNAME --env dev --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env dev --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set TS_OAUTH_CLIENT_ID --env dev --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_CLIENT_ID"
gh secret set TS_OAUTH_SECRET --env dev --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_SECRET"
gh secret set APP_REPO_TOKEN --env dev --repo "$ORG/deploy-hub-api" --body "$APP_REPO_TOKEN"
gh secret set KUBECONFIG_MICROK8S --env dev --repo "$ORG/deploy-hub-api" < pcbox-kubeconfig-deployer-dev.yaml
```

Verifica que cada repositorio tenga sus secretos en el Environment `dev`:

```bash
ORG=<tu-organizacion>

echo "deploy-hub-api"; gh secret list --env dev --repo "$ORG/deploy-hub-api"
```

`deploy-hub-api` debe listar `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET` y `APP_REPO_TOKEN`. Las apps no llevan secretos en `dev`: sus workflows de dev ya no existen, porque todo el flujo corre en `deploy-hub-api`.

Al terminar, borra las variables:

```bash
unset DOCKERHUB_USERNAME DOCKERHUB_TOKEN TS_OAUTH_CLIENT_ID TS_OAUTH_SECRET APP_REPO_TOKEN DISPATCH_DEPLOY_HUB_API_LOCAL
```

---

## local

Ejecuta los comandos **desde la carpeta donde está `pcbox-kubeconfig-deployer-local.yaml`**. El comando de `KUBECONFIG_MICROK8S` lo lee con una ruta relativa y, si estás en otra carpeta, falla con "No such file or directory".

Pega el bloque completo. Reemplaza `<tu-organizacion>` y cada `<VALOR>`:

```bash
ORG=<tu-organizacion>

DOCKERHUB_USERNAME='<VALOR>'
DOCKERHUB_TOKEN='<VALOR>'
TS_OAUTH_CLIENT_ID='<VALOR>'
TS_OAUTH_SECRET='<VALOR>'
DISPATCH_DEPLOY_HUB_API_LOCAL='<VALOR>'

# deploy-hub-api
gh secret set DOCKERHUB_USERNAME --env local --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_USERNAME"
gh secret set DOCKERHUB_TOKEN --env local --repo "$ORG/deploy-hub-api" --body "$DOCKERHUB_TOKEN"
gh secret set TS_OAUTH_CLIENT_ID --env local --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_CLIENT_ID"
gh secret set TS_OAUTH_SECRET --env local --repo "$ORG/deploy-hub-api" --body "$TS_OAUTH_SECRET"
gh secret set KUBECONFIG_MICROK8S --env local --repo "$ORG/deploy-hub-api" < pcbox-kubeconfig-deployer-local.yaml

# apps (solo local: el token con el que cada app dispara el deploy en deploy-hub-api)
gh secret set DISPATCH_DEPLOY_HUB_API_LOCAL --env local --repo "$ORG/iam" --body "$DISPATCH_DEPLOY_HUB_API_LOCAL"
gh secret set DISPATCH_DEPLOY_HUB_API_LOCAL --env local --repo "$ORG/iam-api" --body "$DISPATCH_DEPLOY_HUB_API_LOCAL"
gh secret set DISPATCH_DEPLOY_HUB_API_LOCAL --env local --repo "$ORG/infra-hub-api" --body "$DISPATCH_DEPLOY_HUB_API_LOCAL"
gh secret set DISPATCH_DEPLOY_HUB_API_LOCAL --env local --repo "$ORG/ticket-hub" --body "$DISPATCH_DEPLOY_HUB_API_LOCAL"
gh secret set DISPATCH_DEPLOY_HUB_API_LOCAL --env local --repo "$ORG/ticket-hub-api" --body "$DISPATCH_DEPLOY_HUB_API_LOCAL"
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

`deploy-hub-api` debe listar `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `KUBECONFIG_MICROK8S`, `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET`. Cada app debe listar solo `DISPATCH_DEPLOY_HUB_API_LOCAL`.

Al terminar, borra las variables:

```bash
unset DOCKERHUB_USERNAME DOCKERHUB_TOKEN TS_OAUTH_CLIENT_ID TS_OAUTH_SECRET APP_REPO_TOKEN DISPATCH_DEPLOY_HUB_API_LOCAL
```

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
