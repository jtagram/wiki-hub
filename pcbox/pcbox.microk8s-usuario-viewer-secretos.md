# Usuario restringido: lectura total + gestión completa de Secrets (servidor pcbox)

Instructivo para crear, en el cluster MicroK8s de `pcbox`, un usuario de Kubernetes pensado para conectarse desde una PC cliente por Tailscale con permisos acotados:

- **Lectura (`get`/`list`/`watch`) de absolutamente todo** el cluster — pods, deployments, servicios, namespaces, y también los Secrets (valores incluidos).
- **Escritura sobre Secrets: crearlos, editarlos y borrarlos** (`create`/`update`/`patch`/`delete`) — pero no puede crear, borrar ni modificar ningún otro recurso del cluster.

Esto es intencional: cualquier otro cambio en el cluster (deploys, escalado, borrado de recursos, etc.) tiene que pasar por la ticketera, no por acceso directo a `kubectl`. Este documento aplica el control técnico (RBAC) que hace cumplir esa regla — la ticketera sigue siendo el proceso, esto es lo que evita que alguien la evite.

## 0. Punto de partida

Conectarse al servidor por SSH sobre la IP de Tailscale, igual que en el resto de los instructivos:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Los pasos 1 a 4 se ejecutan en esa sesión, con el usuario admin de microk8s (el mismo que ya usaste en `pcbox.microk8s-setup.md` y `microk8s.namespace.md`). El `scp` final del paso 4 se corre aparte, desde la PC cliente, como el resto de los `scp` de este wiki.

## 1. Namespace para el usuario restringido

El `ServiceAccount` que va a representar a este usuario necesita vivir en algún namespace. Como no es propio de ninguna app, se le da uno propio:

```bash
microk8s kubectl create namespace microk8s-access
```

## 2. ClusterRole: lectura total + gestión completa de Secrets

Crear el `ClusterRole` con las dos reglas de permisos — una de solo lectura sobre todo el cluster, y otra que agrega `create`/`update`/`patch`/`delete` (crear, editar y borrar) exclusivamente sobre Secrets:

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer-secrets-editor
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "delete"]
EOF
```
## 3. ServiceAccount y binding

Crear el `ServiceAccount` en el namespace del paso 1, y el `ClusterRoleBinding` que lo conecta con el `ClusterRole` del paso 2:

```bash
microk8s kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: viewer-secrets-editor
  namespace: microk8s-access
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: viewer-secrets-editor-binding
subjects:
  - kind: ServiceAccount
    name: viewer-secrets-editor
    namespace: microk8s-access
roleRef:
  kind: ClusterRole
  name: cluster-viewer-secrets-editor
  apiGroup: rbac.authorization.k8s.io
EOF
```

## 4. Token de acceso permanente y kubeconfig para la PC cliente

Desde 1.24, Kubernetes ya no crea automáticamente un Secret con token de larga duración para cada `ServiceAccount` — hay que pedirlo explícitamente. Para un usuario que se va a usar desde una PC cliente (no algo efímero), conviene el token clásico que no expira, en vez de uno acotado en el tiempo:

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

Esperar un par de segundos (Kubernetes tarda un momento en rellenar el campo `token` de ese Secret) y comprobar que ya tiene valor:

```bash
microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d
```

Debería devolver un JWT largo (empieza con `eyJ...` y tiene dos puntos `.` — tres bloques: header, payload y firma).

> Si el comando devuelve vacío, el Secret todavía no fue rellenado por el controlador — esperar unos segundos más y repetir el `get`.

**No copies este token a mano a otro archivo.** Es un JWT de 800+ caracteres — pegarlo en `nano` sobre una sesión SSH es la forma más fácil de perder o duplicar un carácter sin darte cuenta, y el resultado sigue *pareciendo* un token válido (mismo formato, dos puntos) pero el API server lo rechaza igual (`the server has asked for the client to provide credentials`). Armá el kubeconfig completo en el propio servidor, usando el valor real por variable de shell, y sacalo ya terminado:

```bash
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

cat > ~/pcbox-kubeconfig-viewer.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: microk8s-cluster
    cluster:
      certificate-authority-data: $CA
      server: https://100.x.x.x:16443
contexts:
  - name: microk8s-viewer
    context:
      cluster: microk8s-cluster
      user: viewer-secrets-editor
current-context: microk8s-viewer
users:
  - name: viewer-secrets-editor
    user:
      token: $TOKEN
EOF
```

reemplazando `100.x.x.x` por la IP de Tailscale del servidor (la misma que usaste para el SSH del paso 0).

Sacar el archivo del servidor a la PC cliente (contiene un token — es un secreto, no se commitea al repo, igual que `pcbox-kubeconfig.yaml`):

```bash
scp jhon@IP_TAILSCALE:~/pcbox-kubeconfig-viewer.yaml .
```

## 5. Instalar `kubectl` en la PC cliente (Linux)

El paso 6 corre `kubectl` directo desde la PC cliente contra la IP de Tailscale del servidor — hasta acá todo se ejecutó por SSH (`microk8s kubectl` del lado de `pcbox`). Si la PC cliente todavía no tiene `kubectl`, instalarlo con el binario oficial:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

Verificar que quedó instalado:

```bash
kubectl version --client
```

Debería devolver la versión del cliente (algo como `Client Version: v1.31.x`). No hace falta que coincida exactamente con la versión de microk8s del servidor — `kubectl` es compatible con versiones de API server cercanas a la propia (una minor arriba o abajo).

## 6. Verificar los permisos

Con Tailscale conectado desde la PC cliente, probar lo que **debería funcionar**:

```bash
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml get pods -A
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml get secrets -n iam-api
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml get secret postgres-credentials -n iam-api -o yaml
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml edit secret postgres-credentials -n iam-api
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml create secret generic test-secret -n iam-api --from-literal=x=1
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml delete secret test-secret -n iam-api
```

Los `get` deberían devolver los recursos normalmente (los Secrets, con sus valores en el `-o yaml`). El `edit` debería abrir el editor con el YAML del Secret y, al guardar, aplicar el cambio sin error. El `create` y el `delete` deberían aplicarse sin error — este mismo usuario puede limpiar el `test-secret` que acaba de crear, sin necesitar la sesión admin.

Y probar lo que **debería fallar** — esto es lo que confirma que la restricción funciona de verdad, no solo que "no se probó a romperla":

```bash
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml delete pod <nombre-de-un-pod> -n iam-api
kubectl --kubeconfig=pcbox-kubeconfig-viewer.yaml scale deployment iam-api --replicas=2 -n iam-api
```

Los dos deberían devolver un error `Forbidden`, con esta forma (el mensaje exacto cambia el verbo/recurso/namespace según el comando):

```
Error from server (Forbidden): pods "nombre-de-un-pod" is forbidden: User "system:serviceaccount:microk8s-access:viewer-secrets-editor" cannot delete resource "pods" in API group "" in the namespace "iam-api"
```

Si alguno de estos dos comandos **no** falla, algo quedó mal configurado en el `ClusterRole` del paso 2 — revisar que no haya quedado ningún verbo de escritura fuera de la regla de Secrets.

## 7. Datos que quedan de este proceso

| Dato | Qué es | De qué paso salió | Para qué es |
|---|---|---|---|
| `viewer-secrets-editor` | El `ServiceAccount` en el namespace `microk8s-access` | Paso 3 | Identidad del usuario restringido dentro del cluster |
| `cluster-viewer-secrets-editor` | El `ClusterRole` con lectura total + creación/edición/borrado de Secrets | Paso 2 | Define qué puede y qué no puede hacer este usuario |
| `viewer-secrets-editor-token` | El Secret con el JWT de acceso, en `microk8s-access` | Paso 4 | Fuente del token — no expira solo, hay que revocarlo a mano si hace falta (borrando el Secret) |
| `pcbox-kubeconfig-viewer.yaml` | Kubeconfig con la CA del cluster + el token del `ServiceAccount` restringido, armado en el servidor y bajado por `scp` | Paso 4 | Lo que usa la PC cliente para conectarse a microk8s con estos permisos acotados |
