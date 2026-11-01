# Crear los tokens en los 3 ambientes

Desde tu PC cliente. Cada comando se ejecuta en la VM por SSH, sin abrir sesión.

Necesitas los `ServiceAccount` `viewer-secrets-editor` y `deployer`, creados en [create-serviceaccounts-for-three-environments.md](create-serviceaccounts-for-three-environments.md).

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Estos tokens no expiran.

Se crea un `Secret` por `ServiceAccount` en cada ambiente:

- `viewer-secrets-editor-token`: el token del usuario que usa el kubeconfig de [create-kubeconfig-for-three-environments.md](create-kubeconfig-for-three-environments.md).
- `deployer-token`: el token del que usa `deploy-hub-api` para desplegar. Con él se arma el kubeconfig de [generate-secret-values-for-github-action-for-three-environments.md](../05-github-and-cicd/generate-secret-values-for-github-action-for-three-environments.md).

## local

Token de `viewer-secrets-editor`:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local 'microk8s kubectl apply -f -' <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: viewer-secrets-editor-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: viewer-secrets-editor
type: kubernetes.io/service-account-token
EOF
```

Token de `deployer`:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local 'microk8s kubectl apply -f -' <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
EOF
```

## dev

Token de `viewer-secrets-editor`:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev 'microk8s kubectl apply -f -' <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: viewer-secrets-editor-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: viewer-secrets-editor
type: kubernetes.io/service-account-token
EOF
```

Token de `deployer`:

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev 'microk8s kubectl apply -f -' <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
EOF
```

## prod

Token de `viewer-secrets-editor`:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod 'microk8s kubectl apply -f -' <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: viewer-secrets-editor-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: viewer-secrets-editor
type: kubernetes.io/service-account-token
EOF
```

Token de `deployer`:

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod 'microk8s kubectl apply -f -' <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: microk8s-access
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
EOF
```

## Verificar

Cada ambiente debe mostrar los dos Secrets con `DATA` igual a `3` (`ca.crt`, `namespace` y `token`). Si muestra `2`, espera unos segundos a que Kubernetes rellene el campo `token` y repite:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local 'microk8s kubectl get secret viewer-secrets-editor-token deployer-token -n microk8s-access'
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev 'microk8s kubectl get secret viewer-secrets-editor-token deployer-token -n microk8s-access'
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod 'microk8s kubectl get secret viewer-secrets-editor-token deployer-token -n microk8s-access'
```

<div align="right">

[← Back](../set-up-the-ecosystem-jtagram.md)

</div>
