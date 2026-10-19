# Instalar Multipass en Ubuntu Server

Multipass crea máquinas virtuales Ubuntu desde la terminal.

## 0. Acceder a pcbox por SSH

Desde la terminal de la PC cliente, accede a `pcbox` con la llave `deploy_key` ([pcbox-bootstrap.md](pcbox-bootstrap.md)):

```bash
ssh -i deploy_key jhon@IP_TAILSCALE_SERVER_PCBOX
```

Los comandos de los pasos siguientes se ejecutan en esa sesión.

## 1. Instalar

```bash
sudo snap install multipass
```

## 2. Verificar

```bash
multipass version
```

Debe mostrar la versión instalada, por ejemplo:

```
multipass   1.14.0
multipassd  1.14.0
```

<div align="right">

[← Back](set-up-the-ecosystem-jtagram.md)

</div>
