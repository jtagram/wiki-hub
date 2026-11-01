# Crear las VMs con Multipass

## 0. Acceder a pcbox por SSH

Desde la terminal de la PC cliente, accede a `pcbox` con la llave `deploy_key` ([pcbox-bootstrap.md](pcbox-bootstrap.md)):

```bash
ssh -i deploy_key jhon@IP_TAILSCALE_SERVER_PCBOX
```

Los comandos de los pasos siguientes se ejecutan en esa sesión.

## 1. Crear las VMs

| VM | Memoria | CPUs | Disco |
|---|---|---|---|
| `local` | 5 GB | 2 | 25 GB |
| `dev` | 5 GB | 2 | 25 GB |
| `prod` | 6 GB | 2 | 30 GB |

```bash
multipass launch --name local --memory 5G --cpus 2 --disk 25G
multipass launch --name dev --memory 5G --cpus 2 --disk 25G
multipass launch --name prod --memory 6G --cpus 2 --disk 30G
```

## 2. Verificar

```bash
multipass list
```

Las 3 VMs deben aparecer en estado `Running`:

```
Name     State     IPv4            Image
local    Running   10.x.x.x        Ubuntu 24.04 LTS
dev      Running   10.x.x.x        Ubuntu 24.04 LTS
prod     Running   10.x.x.x        Ubuntu 24.04 LTS
```

<div align="right">

[← Back](../set-up-the-ecosystem-jtagram.md)

</div>

