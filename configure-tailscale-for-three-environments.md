# Configurar Tailscale en las 3 VMs

Conecta las VMs `local`, `dev` y `prod` a la tailnet para acceder a cada una por SSH con llave desde tu PC cliente.

Necesitas:

- Las 3 VMs creadas — [create-ubuntu-server-on-multipass-vm.md](create-ubuntu-server-on-multipass-vm.md).
- Tu PC cliente conectada a la tailnet — sección "Configurar Tailscale en la PC cliente" de [pcbox-bootstrap.md](pcbox-bootstrap.md).

## 1. Instalar Tailscale

Desde `pcbox`:

```bash
multipass exec local -- sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'
multipass exec dev -- sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'
multipass exec prod -- sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'
```

## 2. Conectar cada VM a la tailnet

```bash
multipass exec local -- sudo tailscale up --hostname=pcbox-local
multipass exec dev -- sudo tailscale up --hostname=pcbox-dev
multipass exec prod -- sudo tailscale up --hostname=pcbox-prod
```

Cada comando muestra un link. Ábrelo en un navegador e inicia sesión con la misma cuenta de Tailscale. Hazlo uno por uno.

## 3. Verificar

Desde tu PC cliente:

```bash
tailscale status
```

Deben aparecer `pcbox-local`, `pcbox-dev` y `pcbox-prod`, cada uno con su IP `100.x.x.x`.
