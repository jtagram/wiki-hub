# Crear namespaces en los 3 ambientes

Cada VM tiene su propio MicroK8s y solo necesita los namespaces de su ambiente.

Necesitas MicroK8s instalado en las 3 VMs — [install-microk8s-for-three-environments.md](install-microk8s-for-three-environments.md).

Todos los comandos se ejecutan desde tu PC cliente, dentro de cada VM.

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM:

```bash
microk8s kubectl create namespace microk8s-access
microk8s kubectl create namespace iam
microk8s kubectl create namespace iam-api
microk8s kubectl create namespace infra-hub-api
microk8s kubectl create namespace ticket-hub
microk8s kubectl create namespace ticket-hub-api
microk8s kubectl create namespace databases
microk8s kubectl create namespace tailscale
microk8s kubectl get namespaces
exit
```

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM:

```bash
microk8s kubectl create namespace microk8s-access
microk8s kubectl create namespace iam
microk8s kubectl create namespace iam-api
microk8s kubectl create namespace infra-hub-api
microk8s kubectl create namespace ticket-hub
microk8s kubectl create namespace ticket-hub-api
microk8s kubectl create namespace databases
microk8s kubectl create namespace tailscale
microk8s kubectl get namespaces
exit
```

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM:

```bash
microk8s kubectl create namespace microk8s-access
microk8s kubectl create namespace iam
microk8s kubectl create namespace iam-api
microk8s kubectl create namespace infra-hub-api
microk8s kubectl create namespace ticket-hub
microk8s kubectl create namespace ticket-hub-api
microk8s kubectl create namespace databases
microk8s kubectl create namespace tailscale
microk8s kubectl get namespaces
exit
```

## Verificar

En cada VM, `get namespaces` debe mostrar los 8 namespaces de su ambiente en estado `Active`, además de los del sistema (`default`, `kube-system`, etc.). Ejemplo en `dev`:

```
NAME                       STATUS   AGE
databases              Active   1m
iam                    Active   1m
iam-api                Active   1m
infra-hub-api          Active   1m
microk8s-access        Active   1m
tailscale              Active   1m
ticket-hub             Active   1m
ticket-hub-api         Active   1m
```
