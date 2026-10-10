# Bootstrap del servidor pcbox

Configuración inicial manual en el servidor `pcbox`, el equipo físico que aloja las 3 VMs de los ambientes (local, dev y prod).

Al terminar, `pcbox` queda con:

- Acceso por SSH a través de Tailscale, con **llave** (la usa `infra-hub-api` y también puedes usarla tú) y con **contraseña** (para entrar tú manualmente). Los dos métodos quedan habilitados.
- `sudo` sin pedir contraseña para el usuario `jhon`, para que Ansible (`infra-hub-api`) pueda ejecutar comandos de administración sin intervención.

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

## 3. Configurar la llave SSH

Desde la PC cliente, crea un par de claves SSH para conectarte a `pcbox` sin tener que introducir la contraseña en cada acceso. Es la misma llave que usará `infra-hub-api` para conectarse al servidor. Este procedimiento se realiza una sola vez:

```bash
ssh-keygen -t ed25519 -f ./deploy_key -N ""
ssh-copy-id -i deploy_key.pub jhon@IP_TAILSCALE
```

El primer comando genera dos archivos: `deploy_key` (la clave **privada**) y `deploy_key.pub` (la clave **pública**, que es la que se copia al servidor). El segundo copia la clave pública a `pcbox` y solicitará la contraseña `SSH_PASSWORD` para autorizar la instalación. La clave privada `deploy_key` permanece en tu PC cliente y no debe subirse a ningún repositorio.

(Si ya existe una clave que se usa para conectarse al servidor, se puede saltar el `ssh-keygen` y pasar directo al `ssh-copy-id` con esa clave.)

En estos comandos, `jhon` es el usuario del servidor e `IP_TAILSCALE` es la dirección IP de Tailscale de `pcbox`, obtenida en el paso 2.

Probar que la conexión funciona con la clave privada, sin que pida contraseña:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Si conecta sin pedir contraseña, la clave quedó bien configurada.

Para ver el contenido de la clave privada y usarla como `SERVER_SSH_PRIVATE_KEY`:

```bash
cat deploy_key
```

Copia toda la salida, incluyendo las líneas `-----BEGIN...-----` y `-----END...-----`. Ese bloque completo es el valor de `SERVER_SSH_PRIVATE_KEY` del Secret `server-ssh-key`, que se carga en cada ambiente según [create-secrets-for-three-environments.md](create-secrets-for-three-environments.md).

## 4. Mantener también el acceso por contraseña

Copiar la llave no desactiva la contraseña, pero conviene dejar los dos métodos habilitados de forma explícita, para que un cambio en la configuración del servidor no te deje sin uno de los dos accesos.

Conéctate a `pcbox` (con la llave o con la contraseña) y ejecuta:

```bash
sudo sh -c "printf 'PasswordAuthentication yes\nPubkeyAuthentication yes\n' > /etc/ssh/sshd_config.d/01-allow-password.conf"
sudo sshd -t && sudo systemctl reload ssh
```

`sshd -t` valida la sintaxis antes de recargar el servicio. Verifica que los dos métodos quedaron activos:

```bash
sudo sshd -T | grep -E "^(passwordauthentication|pubkeyauthentication)"
```

Debe mostrar:

```
pubkeyauthentication yes
passwordauthentication yes
```

Prueba cada método por separado desde la PC cliente:

```bash
# Solo con contraseña: debe pedir SSH_PASSWORD
ssh -o PubkeyAuthentication=no jhon@IP_TAILSCALE

# Solo con llave: debe entrar sin pedir nada
ssh -i deploy_key -o PasswordAuthentication=no jhon@IP_TAILSCALE
```

## 5. Configurar sudo sin contraseña

Ansible (`infra-hub-api`) se conecta por SSH y ejecuta comandos con `sudo`, pero no puede escribir la contraseña de forma interactiva. Por eso el usuario `jhon` debe poder usar `sudo` sin que se la pida.

Conéctate a `pcbox` con el usuario `jhon` (con la llave o con la contraseña):

```bash
ssh jhon@IP_TAILSCALE
```

Crea un archivo aparte en `/etc/sudoers.d/` en lugar de editar `/etc/sudoers` directamente. Si `jhon` no es tu usuario, reemplázalo en el comando por el valor real de `SERVER_SSH_USER`:

```bash
echo "jhon ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-jhon-nopasswd
sudo chmod 440 /etc/sudoers.d/90-jhon-nopasswd
sudo visudo -cf /etc/sudoers.d/90-jhon-nopasswd
```

`sudo` pedirá la contraseña una última vez, al ejecutar el primer comando. `visudo -cf` valida la sintaxis del archivo: debe responder `parsed OK`. Si hay un error, no cierres la sesión SSH y corrígelo antes de salir, para no perder el acceso de administración.

Verifica, sin salir de la sesión SSH:

```bash
sudo -n true && echo "OK, no pide password"
```

## 6. Datos que quedan de este proceso

| Dato | Qué es | De qué paso salió | Para qué es |
|---|---|---|---|
| `SERVER_SSH_USER` | El usuario del servidor, `jhon` | Paso 0 (usuario creado durante la instalación de Ubuntu Server) | Usuario con el que `infra-hub-api` se conecta por SSH a `pcbox` |
| `SSH_PASSWORD` | La contraseña de `jhon` | Paso 0 | Entrar tú manualmente a `pcbox` sin llave |
| `IP_TAILSCALE` | La IP de Tailscale del servidor (`100.x.x.x`) | Paso 2 (`tailscale status` desde la PC cliente) | Dirección para conectarte por SSH a `pcbox` desde la tailnet |
| `SERVER_SSH_PRIVATE_KEY` | La clave privada `deploy_key` generada con `ssh-keygen` | Paso 3 | Autenticación SSH de `infra-hub-api` sin contraseña. Se carga en el Secret `server-ssh-key` de cada ambiente |
