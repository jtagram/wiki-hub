# Crear los tokens en los 3 ambientes

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
