# Crear los roles de lectura y de edición de Secrets en los 3 ambientes

Crea en cada VM (`local`, `dev` y `prod`) los dos `ClusterRole` que definen qué puede hacer el usuario `viewer-secrets-editor`:

- **`cluster-viewer`**: solo lectura (`get`, `list`, `watch`) sobre todos los recursos.
- **`secrets-editor`**: crear, actualizar, modificar y borrar Secrets.

Un rol por sí solo no da permisos a nadie: se asigna al usuario en [create-rolebindings-for-three-environments.md](create-rolebindings-for-three-environments.md).

Necesitas:

- El addon `rbac` habilitado en las 3 VMs — [install-microk8s-for-three-environments.md](install-microk8s-for-three-environments.md). Compruébalo con `microk8s status | grep rbac` dentro de cada VM: debe aparecer bajo `enabled`. Sin RBAC los permisos de este instructivo no se aplican.

Los pasos de cada ambiente se ejecutan desde tu PC cliente, dentro de la VM.

---

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

<p align="right"><a href="set-up-the-ecosystem-jtagram.md">← Back</a></p>
