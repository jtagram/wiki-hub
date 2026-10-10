# Instalar MicroK8s en los 3 ambientes

Instala MicroK8s en las VMs `local`, `dev` y `prod`.

Necesitas el acceso por llave a las 3 VMs — [configure-access-key-for-three-environments..md](configure-access-key-for-three-environments..md).

Todos los comandos se ejecutan desde tu PC cliente, dentro de cada VM.

Se habilita el addon `rbac`. Sin él, MicroK8s autoriza todo (`AlwaysAllow`) y los permisos que se crean en [create-users-with-permissions-for-three-environments.md](create-users-with-permissions-for-three-environments.md) no se aplican: cualquier usuario tendría acceso total. Tras habilitarlo se reinicia `kubelite` para que el API server cargue la configuración nueva, y en `microk8s status` debe aparecer `rbac` en `enabled`.

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM:

```bash
sudo snap install microk8s --classic --channel=1.31/stable
sudo usermod -aG microk8s ubuntu
newgrp microk8s
microk8s status --wait-ready
sudo microk8s enable rbac
sudo snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
microk8s kubectl get nodes
exit
```

Debe aparecer el nodo `local` en estado `Ready`.

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM:

```bash
sudo snap install microk8s --classic --channel=1.31/stable
sudo usermod -aG microk8s ubuntu
newgrp microk8s
microk8s status --wait-ready
sudo microk8s enable rbac
sudo snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
microk8s kubectl get nodes
exit
```

Debe aparecer el nodo `dev` en estado `Ready`.

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM:

```bash
sudo snap install microk8s --classic --channel=1.31/stable
sudo usermod -aG microk8s ubuntu
newgrp microk8s
microk8s status --wait-ready
sudo microk8s enable rbac
sudo snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
microk8s kubectl get nodes
exit
```

Debe aparecer el nodo `prod` en estado `Ready`.
