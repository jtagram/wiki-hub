# Crear el kubeconfig de administración en los 3 ambientes

Arma los kubeconfig de **administración** (`pcbox-kubeconfig-local.yaml`, `pcbox-kubeconfig-dev.yaml` y `pcbox-kubeconfig-prod.yaml`) y los baja a tu PC cliente. Los usan los pasos que instalan componentes en el cluster con `helm` y `kubectl` desde tu PC, como [implement-observability.md](../06-deploy-and-operation/implement-observability.md).

> **Cuidado:** estos kubeconfig dan control total sobre el cluster. No son los de `viewer` ni `deployer`, que tienen permisos acotados. Guárdalos fuera de cualquier repositorio, no los subas a GitHub y no los compartas.

Requisito: el certificado del API server ya incluye la IP de Tailscale de cada VM — [configure-api-server-certificate-for-three-environments.md](configure-api-server-certificate-for-three-environments.md). Sin eso, el cliente rechaza la conexión por TLS.

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, toma el kubeconfig que trae MicroK8s y cambia el `server` por la IP de Tailscale:

```bash
SERVER_IP=$(tailscale ip -4)
microk8s config | sed "s#server: https://.*:16443#server: https://${SERVER_IP}:16443#" > ~/pcbox-kubeconfig-local.yaml
chmod 600 ~/pcbox-kubeconfig-local.yaml
exit
```

Cópialo a tu PC cliente:

```bash
scp -i ~/.ssh/pcbox_local ubuntu@pcbox-local:~/pcbox-kubeconfig-local.yaml .
chmod 600 pcbox-kubeconfig-local.yaml
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM:

```bash
SERVER_IP=$(tailscale ip -4)
microk8s config | sed "s#server: https://.*:16443#server: https://${SERVER_IP}:16443#" > ~/pcbox-kubeconfig-dev.yaml
chmod 600 ~/pcbox-kubeconfig-dev.yaml
exit
```

Cópialo a tu PC cliente:

```bash
scp -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev:~/pcbox-kubeconfig-dev.yaml .
chmod 600 pcbox-kubeconfig-dev.yaml
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM:

```bash
SERVER_IP=$(tailscale ip -4)
microk8s config | sed "s#server: https://.*:16443#server: https://${SERVER_IP}:16443#" > ~/pcbox-kubeconfig-prod.yaml
chmod 600 ~/pcbox-kubeconfig-prod.yaml
exit
```

Cópialo a tu PC cliente:

```bash
scp -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod:~/pcbox-kubeconfig-prod.yaml .
chmod 600 pcbox-kubeconfig-prod.yaml
```

---

## Verificar

Desde tu PC cliente, en la carpeta donde guardaste los archivos. Cada comando debe listar el nodo del ambiente en `Ready`:

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml get nodes
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml get nodes
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml get nodes
```

Si falla con `x509: certificate is valid for ..., not <IP>`, falta agregar esa IP al certificado del API server.

Los comandos que usan estos archivos con una ruta relativa (`--kubeconfig pcbox-kubeconfig-local.yaml`) se ejecutan desde la carpeta donde están. Si estás en otra, fallan con `no such file or directory`.

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
