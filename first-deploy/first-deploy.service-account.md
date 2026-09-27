# ServiceAccount de cada app

El `Deployment` de las 5 apps (`deploy-hub-api/.github/workflows/<app>/manifests/deployment.yaml`) referencia `serviceAccountName: <app>`, pero ese ServiceAccount no está versionado en ningún manifiesto del repo. Hay que crearlo a mano, una sola vez por app, antes de su primer deploy — si falta, el Pod de esa app queda sin crearse (`FailedCreate`).

```bash
microk8s kubectl create serviceaccount iam -n iam
microk8s kubectl create serviceaccount iam-api -n iam-api
microk8s kubectl create serviceaccount infra-hub-api -n infra-hub-api
microk8s kubectl create serviceaccount ticket-hub -n ticket-hub
microk8s kubectl create serviceaccount ticket-hub-api -n ticket-hub-api
```
