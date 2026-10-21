# Crear el usuario y su token en los 3 ambientes

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Usuario

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
```

### Token

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Este token no expira.

```bash
microk8s kubectl apply -f - <<'EOF'
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

```bash
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

### Usuario

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
```

### Token

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Este token no expira.

```bash
microk8s kubectl apply -f - <<'EOF'
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

```bash
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

### Usuario

```bash
microk8s kubectl create serviceaccount viewer-secrets-editor -n microk8s-access
```

### Token

Desde Kubernetes 1.24 no se crea un token de larga duración por cada `ServiceAccount`: hay que pedirlo. Este token no expira.

```bash
microk8s kubectl apply -f - <<'EOF'
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

```bash
exit
```

## Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `viewer-secrets-editor` | `ServiceAccount` en `microk8s-access` | Identidad del usuario de cada ambiente |
| `viewer-secrets-editor-token` | Secret con el token de cada usuario | Fuente del token. Para revocar el acceso, bórralo |

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
