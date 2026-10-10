# Configurar llaves de acceso para los 3 ambientes

Deja el acceso por SSH a las VMs `local`, `dev` y `prod` con llave y también con contraseña. El usuario `ubuntu` usa `sudo` sin pedir contraseña.

Necesitas:

- Las 3 VMs conectadas a la tailnet — [configure-tailscale-for-three-environments.md](configure-tailscale-for-three-environments.md).
- Tu PC cliente conectada a la tailnet — [pcbox-bootstrap.md](pcbox-bootstrap.md).

## 1. Crear una llave por ambiente

Desde tu PC cliente:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/pcbox_local -N ""
ssh-keygen -t ed25519 -f ~/.ssh/pcbox_dev -N ""
ssh-keygen -t ed25519 -f ~/.ssh/pcbox_prod -N ""
```

Las llaves privadas (`pcbox_*`) se quedan en tu PC. No las copies ni las subas a un repositorio.

## 2. Copiar las llaves públicas a pcbox

Desde tu PC cliente:

```bash
scp ~/.ssh/pcbox_local.pub jhon@IP_TAILSCALE:~/
scp ~/.ssh/pcbox_dev.pub jhon@IP_TAILSCALE:~/
scp ~/.ssh/pcbox_prod.pub jhon@IP_TAILSCALE:~/
```

`IP_TAILSCALE` es la IP de `pcbox` que guardaste en [pcbox-bootstrap.md](pcbox-bootstrap.md).

Entra a `pcbox`. Los pasos 3, 4 y 5 se ejecutan desde ahí:

```bash
ssh jhon@IP_TAILSCALE
```

## 3. Autorizar cada llave en su VM

```bash
multipass transfer ~/pcbox_local.pub local:/tmp/pcbox_local.pub
multipass exec local -- sh -c 'cat /tmp/pcbox_local.pub >> ~/.ssh/authorized_keys'
```

```bash
multipass transfer ~/pcbox_dev.pub dev:/tmp/pcbox_dev.pub
multipass exec dev -- sh -c 'cat /tmp/pcbox_dev.pub >> ~/.ssh/authorized_keys'
```

```bash
multipass transfer ~/pcbox_prod.pub prod:/tmp/pcbox_prod.pub
multipass exec prod -- sh -c 'cat /tmp/pcbox_prod.pub >> ~/.ssh/authorized_keys'
```

## 4. Sudo sin contraseña

```bash
multipass exec local -- sudo sh -c "echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu-nopasswd"
multipass exec local -- sudo chmod 440 /etc/sudoers.d/90-ubuntu-nopasswd
multipass exec local -- sudo visudo -cf /etc/sudoers.d/90-ubuntu-nopasswd
```

```bash
multipass exec dev -- sudo sh -c "echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu-nopasswd"
multipass exec dev -- sudo chmod 440 /etc/sudoers.d/90-ubuntu-nopasswd
multipass exec dev -- sudo visudo -cf /etc/sudoers.d/90-ubuntu-nopasswd
```

```bash
multipass exec prod -- sudo sh -c "echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu-nopasswd"
multipass exec prod -- sudo chmod 440 /etc/sudoers.d/90-ubuntu-nopasswd
multipass exec prod -- sudo visudo -cf /etc/sudoers.d/90-ubuntu-nopasswd
```

## 5. Permitir SSH con contraseña

El usuario `ubuntu` no tiene contraseña. Cada comando `passwd` te pide definir una. Guárdala: es el `SSH_PASSWORD` de ese ambiente.

El archivo se llama `01-` para que se lea antes que los de cloud-init, que desactivan la contraseña.

```bash
multipass exec local -- sudo passwd ubuntu
multipass exec local -- sudo sh -c "printf 'PasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/01-allow-password.conf"
multipass exec local -- sudo sshd -t
multipass exec local -- sudo systemctl restart ssh
```

```bash
multipass exec dev -- sudo passwd ubuntu
multipass exec dev -- sudo sh -c "printf 'PasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/01-allow-password.conf"
multipass exec dev -- sudo sshd -t
multipass exec dev -- sudo systemctl restart ssh
```

```bash
multipass exec prod -- sudo passwd ubuntu
multipass exec prod -- sudo sh -c "printf 'PasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/01-allow-password.conf"
multipass exec prod -- sudo sshd -t
multipass exec prod -- sudo systemctl restart ssh
```

Sal de `pcbox` con `exit`.

## 6. Verificar

Desde tu PC cliente. Con llave, cada comando debe imprimir `OK` sin pedir contraseña:

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local 'sudo -n true && echo OK'
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev 'sudo -n true && echo OK'
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod 'sudo -n true && echo OK'
```

Con contraseña, cada comando pide la contraseña del paso 5 e imprime `OK`:

```bash
ssh -o PubkeyAuthentication=no ubuntu@pcbox-local 'sudo -n true && echo OK'
ssh -o PubkeyAuthentication=no ubuntu@pcbox-dev 'sudo -n true && echo OK'
ssh -o PubkeyAuthentication=no ubuntu@pcbox-prod 'sudo -n true && echo OK'
```

`ubuntu` es el usuario por defecto de las VMs de Multipass.
