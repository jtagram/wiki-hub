# Crear los roles de lectura y de edición de Secrets en los 3 ambientes

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Roles

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-editor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```

Verifica que existen:

```bash
microk8s kubectl get clusterrole cluster-viewer secrets-editor
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

### Roles

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-editor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```

Verifica que existen:

```bash
microk8s kubectl get clusterrole cluster-viewer secrets-editor
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

### Roles

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-editor
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```

Verifica que existen:

```bash
microk8s kubectl get clusterrole cluster-viewer secrets-editor
exit
```

## Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `cluster-viewer` | `ClusterRole` de solo lectura | Permite ver todo el cluster de la VM |
| `secrets-editor` | `ClusterRole` que escribe Secrets | Se asigna con un `RoleBinding` en cada namespace del ambiente, así que solo vale ahí |

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
