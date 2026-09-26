# Bootstrap del servidor pcbox

Configuración inicial manual en el servidor `pcbox`

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

Conserva este dato, ya que se utilizará más adelante para configurar el secret `SSH_USER`:

```
SSH_USER=jhon
```

> **Nota sobre la contraseña:** Conserva la contraseña, ya que se utilizará más adelante en este procedimiento:
```
SSH_PASSWORD=*********
```
.

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

## 2. Instalar y configurar Tailscale

Con OpenSSH ya instalado (paso 1) y la IP local guardada, ya no hace falta teclado ni monitor — de acá en adelante se trabaja conectándose por SSH desde una PC cliente:

```bash
ssh jhon@IP_LOCAL_DEL_SERVIDOR
```

El comando solicitará la contraseña definida en el paso 0 (`SSH_PASSWORD`).

Una vez conectado al servidor por SSH, instala y configura Tailscale para incorporarlo a la red de Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Luego, inicia sesión y conecta el equipo a la red de Tailscale:

```bash
sudo tailscale up
```

Esto da un link para autenticarse con una cuenta (Google, Microsoft, GitHub, etc.). Se abre desde cualquier navegador (puede ser desde el celular) y se hace login ahí.

### Configurar Tailscale en la PC cliente

La PC cliente también debe estar conectada a la misma tailnet que el servidor. Esto permite que la PC cliente se comunique con `pcbox` mediante su IP de Tailscale, aunque no se encuentre en la misma red local. Desde la PC cliente, instala Tailscale y autentícala con la misma cuenta utilizada para configurar el servidor:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

El segundo comando mostrará un enlace de autenticación. Ábrelo en un navegador e inicia sesión con la misma cuenta usada en el servidor. Una vez completado este paso, la PC cliente y `pcbox` formarán parte de la misma tailnet.

Con ambos equipos conectados a la tailnet, obtén la IP de Tailscale del servidor (`100.x.x.x`) desde la PC cliente ejecutando:

```bash
tailscale status
```

Ahí aparecerá el servidor `pcbox` junto a su IP `100.x.x.x`. También puedes consultarla desde la [consola web de Tailscale](https://login.tailscale.com/admin/machines). Conserva esta dirección como `IP_TAILSCALE`, ya que se utilizará más adelante para las conexiones SSH:

```
IP_TAILSCALE=100.x.x.x
```

Para comprobar que la conexión funciona a través de Tailscale, en lugar de la red local, ejecuta desde la misma PC cliente:

```bash
ssh jhon@IP_TAILSCALE
```

Cuando lo solicite, introduce la contraseña del usuario `jhon`, guardada como `SSH_PASSWORD` en el paso 0. Si la conexión se establece correctamente, Tailscale quedó configurado en el servidor.

## 3. Configurar una llave privada y pública para conectarse por SSH sin contraseña

Desde la PC cliente, crea un par de claves SSH para conectarte al servidor `pcbox` sin tener que introducir la contraseña en cada acceso. Este procedimiento se realiza una sola vez:

```bash
ssh-keygen -t ed25519 -f ./deploy_key -N ""
ssh-copy-id -i deploy_key.pub jhon@IP_TAILSCALE
```

El primer comando genera el par de claves en la PC cliente. El segundo copia la clave pública `deploy_key.pub` al servidor `pcbox` y solicitará la contraseña `SSH_PASSWORD` para autorizar la instalación. La clave privada `deploy_key` permanece en la PC cliente y no debe copiarse ni subirse al repositorio.

(Si ya existe una clave que se usa para conectarse al servidor, se puede saltar el `ssh-keygen` y pasar directo al `ssh-copy-id` con esa clave.)

En este comando, `jhon` es el usuario del servidor y `IP_TAILSCALE` representa la dirección IP de Tailscale de `pcbox`, obtenida en el paso 2.

Este comando genera dos archivos: `deploy_key` (la clave **privada**) y `deploy_key.pub` (la clave **pública**, que es la que se copia al servidor).

Probar que la conexión funciona con la clave privada, sin que pida contraseña:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Si conecta sin pedir password, la clave quedó bien configurada.

Para ver el contenido de la clave privada y poder usarla desde otro cliente

```bash
cat deploy_key
```

Copiar toda la salida, incluyendo las líneas `-----BEGIN...-----` y `-----END...-----`, y pegarla completa como valor del secret.

## 4. Configurar el usuario para que no tenga que escribir la contraseña de sudo

Ya que GitHub Actions no puede escribir la contraseña de forma interactiva.

Entrar al servidor con un usuario que tenga privilegios de admin (puede ser el mismo, si todavía deja loguearse y pedir la clave a mano):

```bash
ssh usuario@IP_TAILSCALE
```

Editar los sudoers de forma segura (mejor crear un archivo aparte en vez de tocar `/etc/sudoers` directo):

```bash
sudo visudo -f /etc/sudoers.d/github-deploy
```

Agregar esta línea (reemplazando `usuario` por el valor real del secret `SSH_USER`):

```
usuario ALL=(ALL) NOPASSWD:ALL
```

Guardar y salir. `visudo` valida la sintaxis automáticamente antes de guardar, así que si hay un error de tipeo avisa y no rompe nada.

Verificar sin salir de la sesión SSH (por si el paso anterior tuvo un error, no se pierde el acceso):

```bash
sudo -n true && echo "OK, no pide password"
```

## 5. Datos que quedan de este proceso

| Dato | Qué es | De qué paso salió | Para qué es |
|---|---|---|---|
| `SSH_USER` | El usuario del servidor, `jhon` | Paso 0 (usuario creado durante la instalación de Ubuntu Server) | Usuario con el que GitHub Actions se conecta por SSH al servidor |
| `IP_TAILSCALE` | La IP de Tailscale del servidor (`100.x.x.x`) | Paso 2 (`tailscale status` desde la PC cliente) | Dirección que se utiliza para conectarse por SSH al servidor `pcbox` |
| `SSH_PRIVATE_KEY` | La clave privada `deploy_key` generada con `ssh-keygen` | Paso 3 | Autenticación SSH del runner sin contraseña |