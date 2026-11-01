# Instalar MicroK8s en los 3 ambientes

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

<div align="right">

[← Back](../set-up-the-ecosystem-jtagram.md)

</div>
