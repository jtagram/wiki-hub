# Crear las VMs con Multipass

Crea una máquina virtual Ubuntu Server por ambiente: `local`, `dev` y `prod`.

Necesitas Multipass instalado — [install-multipass.md](install-multipass.md).

## 0. Acceder a pcbox por SSH

Desde la terminal de la PC cliente, accede a `pcbox` con la llave `deploy_key` ([pcbox-bootstrap.md](pcbox-bootstrap.md)):

```bash
ssh -i deploy_key jhon@IP_TAILSCALE_SERVER_PCBOX
```

Los comandos de los pasos siguientes se ejecutan en esa sesión.

## 1. Crear las VMs

| VM | Memoria | CPUs | Disco |
|---|---|---|---|
| `local` | 3 GB | 2 | 20 GB |
| `dev` | 3 GB | 2 | 20 GB |
| `prod` | 4 GB | 2 | 20 GB |

```bash
multipass launch --name local --memory 3G --cpus 2 --disk 20G
multipass launch --name dev --memory 3G --cpus 2 --disk 20G
multipass launch --name prod --memory 4G --cpus 2 --disk 20G
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

