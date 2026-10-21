# Crear el kubeconfig del usuario en los 3 ambientes

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Kubeconfig

Espera unos segundos a que Kubernetes rellene el campo `token` y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-viewer-local.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-local
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-viewer-local
    context:
      cluster: pcbox-local
      user: viewer-local
current-context: microk8s-viewer-local
users:
  - name: viewer-local
    user:
      token: $TOKEN
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

### Kubeconfig

Espera unos segundos a que Kubernetes rellene el campo `token` y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-viewer-dev.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-dev
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-viewer-dev
    context:
      cluster: pcbox-dev
      user: viewer-dev
current-context: microk8s-viewer-dev
users:
  - name: viewer-dev
    user:
      token: $TOKEN
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

### Kubeconfig

Espera unos segundos a que Kubernetes rellene el campo `token` y arma el kubeconfig en la propia VM. No copies el token a mano: es un JWT de más de 800 caracteres y perder un carácter lo vuelve inválido sin que lo notes.

```bash
SERVER_IP=$(tailscale ip -4)
CA=$(microk8s kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(microk8s kubectl get secret viewer-secrets-editor-token -n microk8s-access -o jsonpath='{.data.token}' | base64 -d)

cat > ~/pcbox-kubeconfig-viewer-prod.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: pcbox-prod
    cluster:
      certificate-authority-data: $CA
      server: https://${SERVER_IP}:16443
contexts:
  - name: microk8s-viewer-prod
    context:
      cluster: pcbox-prod
      user: viewer-prod
current-context: microk8s-viewer-prod
users:
  - name: viewer-prod
    user:
      token: $TOKEN
EOF
```

```bash
exit
```

## Bajar los kubeconfig a la PC cliente

Desde la PC cliente. Los archivos contienen tokens: no se commitean.

```bash
scp -i ~/.ssh/pcbox_local ubuntu@pcbox-local:~/pcbox-kubeconfig-viewer-local.yaml .
scp -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev:~/pcbox-kubeconfig-viewer-dev.yaml .
scp -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod:~/pcbox-kubeconfig-viewer-prod.yaml .
```

## Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `pcbox-kubeconfig-viewer-<ambiente>.yaml` | Kubeconfig del usuario | Lo que usa la PC cliente para conectarse |

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
