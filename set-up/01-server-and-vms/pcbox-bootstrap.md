# Bootstrap del servidor pcbox

Configuración inicial manual en el servidor `pcbox`, el equipo físico que aloja las 3 VMs de los ambientes (local, dev y prod).

## 0. Instalación de Ubuntu Server

Configuración elegida durante el instalador de Ubuntu Server:

| Opción | Valor |
|---|---|
| Lenguaje | Español |
| Teclado | Inglés EEUU (Internacional con teclas muertas) |
| Tipo de instalación | Por defecto |
| Comunicación con otros equipos | Type eth |
| Proxy address | (vacío) |
| Disco | Kingston |
| Nombre | Jhonny Berdeja |
| Nombre del server | pcbox |
| Nombre de usuario | jhon |
| Contraseña | (ver nota abajo) |

Conserva este dato, ya que se utilizará más adelante como `SERVER_SSH_USER` en el Secret `server-ssh-key` de `infra-hub-api`:

```
SERVER_SSH_USER=jhon
```

> **Nota sobre la contraseña:** Conserva la contraseña. Se usa más adelante en este procedimiento y es la que te permite entrar por SSH a `pcbox` sin llave:
```
SSH_PASSWORD=*********
```

## 1. Instalar OpenSSH en el Ubuntu Server

Como el servidor todavía no tiene SSH instalado, no se puede entrar por red — hay que conectarle un teclado y un monitor directamente, y conectarlo a internet (cable de red o WiFi, según lo que tenga disponible) para poder descargar el paquete.

Ya con acceso directo a la terminal del servidor:

```bash
sudo apt update
sudo apt install openssh-server -y
```

Verificar que el servicio esté corriendo:

```bash
sudo systemctl status ssh
```

Si no está activo:

```bash
sudo systemctl enable --now ssh
```

Obtener la IP local del servidor (la que se usa para conectarse por la red local, antes de tener Tailscale configurado):

```bash
ip addr show
```

o más simple:

```bash
hostname -I
```

Conserva esta IP_LOCAL_DEL_SERVIDOR, ya que se utilizará para conectarse por SSH al sevidor:

```
IP_LOCAL_DEL_SERVIDOR
```

## 2. Instalar y configurar Tailscale en el servidor pcbox desde la PC cliente

Desde una PC cliente **conectada a la misma red local que el servidor** `pcbox`, accede a `pcbox` por SSH ejecutando este comando en la terminal de la PC cliente:

```bash
ssh jhon@IP_LOCAL_DEL_SERVIDOR
```

El comando solicitará la contraseña definida en el paso 0 (`SSH_PASSWORD`).

Una vez conectado a `pcbox` por SSH, instala y configura Tailscale para incorporarlo a la red de Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Luego, inicia sesión y conecta el equipo a la red de Tailscale:

```bash
sudo tailscale up
```

Este comando muestra un enlace de autenticación. Ábrelo en un navegador (puede ser desde el celular) e inicia sesión con tu cuenta de Google.

Obtén la IP de Tailscale de `pcbox` (`100.x.x.x`) ejecutando en la misma terminal:

```bash
tailscale ip -4
```

Conserva esta dirección como `IP_TAILSCALE_SERVER_PCBOX`, ya que se utilizará más adelante para las conexiones SSH a `pcbox`:

```
IP_TAILSCALE_SERVER_PCBOX=100.x.x.x
```

## 3. Instalar y configurar Tailscale en la PC cliente

Abre una terminal en la PC cliente, instala y configura Tailscale para incorporarla a la red de Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Luego, inicia sesión y conecta el equipo a la red de Tailscale:

```bash
sudo tailscale up
```

Este comando muestra un enlace de autenticación. Ábrelo en un navegador e inicia sesión con la misma cuenta de Google que usaste para `pcbox`.

Obtén la IP de Tailscale de la PC cliente (`100.x.x.x`) ejecutando en la misma terminal:

```bash
tailscale ip -4
```

Conserva esta dirección como `IP_TAILSCALE_PC_CLIENTE`:

```
IP_TAILSCALE_PC_CLIENTE=100.x.x.x
```

Para comprobar que la conexión funciona a través de Tailscale, en lugar de la red local, ejecuta en la terminal de la PC cliente:

```bash
ssh jhon@IP_TAILSCALE_SERVER_PCBOX
```

Cuando lo solicite, introduce la contraseña del usuario `jhon`, guardada como `SSH_PASSWORD` en el paso 0. Si la conexión se establece correctamente, Tailscale quedó configurado en el servidor `pcbox` y en la PC cliente.

## 4. Configurar la llave SSH para conectar la PC cliente con el servidor pcbox

En la terminal de la PC cliente, genera una llave SSH y cópiala a `pcbox` para entrar sin contraseña. Se hace una sola vez:

```bash
ssh-keygen -t ed25519 -f ./deploy_key -N ""
ssh-copy-id -i deploy_key.pub jhon@IP_TAILSCALE_SERVER_PCBOX
```

`ssh-copy-id` pide la contraseña `SSH_PASSWORD` por última vez. La llave privada `deploy_key` queda en la PC cliente y no debe subirse a ningún repositorio.

Comprueba que conecta sin pedir contraseña:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE_SERVER_PCBOX
```

## 5. Permitir el acceso por contraseña solo con monitor y teclado

Por SSH, `pcbox` debe aceptar únicamente la llave del paso 4. La contraseña de `jhon` queda para el acceso físico (monitor y teclado), que no depende de SSH.

Conéctate a `pcbox` por SSH con la llave (`ssh -i deploy_key jhon@IP_TAILSCALE_SERVER_PCBOX`) y ejecuta:

```bash
sudo rm -f /etc/ssh/sshd_config.d/01-allow-password.conf
sudo sh -c "printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPubkeyAuthentication yes\nPermitRootLogin no\n' > /etc/ssh/sshd_config.d/01-keys-only.conf"
sudo sshd -t && sudo systemctl reload ssh
```

`sshd -t` valida la sintaxis antes de recargar el servicio. Verifica la configuración activa:

```bash
sudo sshd -T | grep -E "^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin)"
```

Debe mostrar:

```
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
permitrootlogin no
```

Sin cerrar la sesión actual, prueba desde la PC cliente:

```bash
# Solo con contraseña: debe fallar con "Permission denied (publickey)"
ssh -o PubkeyAuthentication=no jhon@IP_TAILSCALE_SERVER_PCBOX

# Con llave: debe entrar sin pedir nada
ssh -i deploy_key jhon@IP_TAILSCALE_SERVER_PCBOX
```

Para comprobar el acceso físico, conecta monitor y teclado a `pcbox` e inicia sesión con `jhon` y `SSH_PASSWORD`.

## 6. Datos que quedan de este proceso

| Dato | Qué es |
|---|---|
| `SERVER_SSH_USER` | El usuario del servidor, `jhon` |
| `SSH_PASSWORD` | La contraseña de `jhon` |
| `IP_TAILSCALE_SERVER_PCBOX` | La IP de Tailscale del servidor (`100.x.x.x`) |
| `deploy_key` | La clave privada generada con `ssh-keygen` |

<div align="right">

[← Back](../set-up-the-ecosystem-jtagram.md)

</div>
