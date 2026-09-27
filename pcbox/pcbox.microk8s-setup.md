# Instalación de microk8s (servidor pcbox)

Instalación de microk8s en el servidor `pcbox`, extensión del certificado del API server para que sea alcanzable por Tailscale, y generación del kubeconfig para administrarlo de forma remota.

## 0. Punto de partida

Conectarse al servidor por SSH sobre la IP de Tailscale (secret `SSH_HOST`, obtenida en `pcbox.bootstrap.md`, paso 2):

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Todos los comandos de este documento se corren desde esa sesión.

## 1. Instalar microk8s

A diferencia de los pasos anteriores, esto se instala a mano y se mantiene fuera de Ansible/CI a propósito (no hay ningún playbook que lo instale ni lo gestione).

```bash
sudo snap install microk8s --classic --channel=1.31/stable
```

Agregar al usuario `jhon` al grupo `microk8s` para no necesitar `sudo` en los comandos de `kubectl`:

```bash
sudo usermod -aG microk8s $USER
```

Esto no toma efecto en la sesión SSH actual hasta refrescar el grupo:

```bash
newgrp microk8s
```

(o cerrar y volver a entrar por SSH — cualquiera de las dos sirve).

Esperar a que el cluster esté listo (tarda un rato la primera vez, está bajando imágenes de containerd):

```bash
microk8s status --wait-ready
```

Verificar:

```bash
microk8s kubectl get nodes
```

Debería aparecer el nodo `pcbox` en estado `Ready`.

## 2. Extender el certificado del API server para Tailscale y preparar el kubeconfig para CI

Por defecto, el certificado que el API server de microk8s le muestra a quien se conecta solo es válido para la IP local del servidor — no para la IP de Tailscale (`100.x.x.x`, la misma ya guardada como secret `SSH_HOST` en `pcbox.bootstrap.md`, paso 2). Como el runner de GitHub Actions se conecta por Tailscale, hay que extender ese certificado para que también sea válido desde esa IP.

Editar la plantilla del certificado:

```bash
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]` va a haber algo como:

```ini
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = 10.152.183.1
IP.3 = 192.168.x.x   ← la IP local del servidor
```

**Sin reemplazar ninguna línea existente**, agregar una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

con la IP de Tailscale del servidor. Guardar y salir, y regenerar el certificado del API server a partir de la plantilla actualizada (sin reiniciar todo el cluster):

```bash
sudo microk8s refresh-certs -e server.crt
```

Debería mostrar algo así:

```
Taking a backup of the current certificates under /var/snap/microk8s/current/certs-backup/
Creating new certificates
Signature ok
subject=CN = kubernetes
Getting CA Private Key
Restarting service kubelite.
```

Lo importante es que termine con `Restarting service kubelite.` sin errores — eso confirma que el certificado nuevo (con la IP de Tailscale agregada) ya está en uso.

> **Nota:** el flag es `-e`/`--cert`, no `-c` (`-c`/`--check` solo revisa vencimientos, no regenera nada — da un error de "Path does not exist" si se confunde).

Esperar a que se estabilice y verificar que la IP de Tailscale quedó en el certificado:

```bash
microk8s status --wait-ready
openssl x509 -in /var/snap/microk8s/current/certs/server.crt -noout -text | grep -A5 "Subject Alternative Name"
```

El primer comando debería devolver `microk8s is running` (si tarda, es que todavía está reiniciando el API server tras el `refresh-certs`). El segundo debería mostrar algo así:

```
X509v3 Subject Alternative Name:
    DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster, DNS:kubernetes.default.svc.cluster.local, IP Address:127.0.0.1, IP Address:10.152.183.1, IP Address:192.168.x.x, IP Address:100.x.x.x
```

Lo que hay que confirmar ahí es que la IP de Tailscale (`100.x.x.x`) aparezca al final de la lista como `IP Address:100.x.x.x` — eso es lo que agregamos en `csr.conf.template` como `IP.4`. Si no aparece, el certificado no se regeneró bien y hay que repetir el `refresh-certs`.

Generar el kubeconfig y editar el campo `server:` para que apunte a la IP de Tailscale en vez de a la IP local (la CA no cambia, el resto del archivo queda igual):

```bash
microk8s config > ~/pcbox-kubeconfig.yaml
nano ~/pcbox-kubeconfig.yaml
```

El archivo generado debería verse así (antes de editar el `server:`):

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <base64 largo, es el CA>
    server: https://192.168.x.x:16443   # todavía la IP local, esto es lo que hay que cambiar
  name: microk8s-cluster
contexts:
- context:
    cluster: microk8s-cluster
    user: admin
  name: microk8s
current-context: microk8s
kind: Config
preferences: {}
users:
- name: admin
  user:
    token: <token largo>
```

Dentro de `nano`, cambiar únicamente la línea `server:`:

```yaml
server: https://100.x.x.x:16443   # IP de Tailscale, no la local
```

Sacar el archivo del servidor a la PC cliente (contiene una clave privada — es un secreto, no se commitea al repo):

```bash
scp jhon@IP_TAILSCALE:~/pcbox-kubeconfig.yaml .
```

## 3. Datos que quedan de este proceso

| Dato | Qué es | De qué paso salió | Para qué es |
|---|---|---|---|
| `pcbox-kubeconfig.yaml` | El kubeconfig de microk8s, con `server:` editado para apuntar a la IP de Tailscale en vez de a la IP local | Paso 2 (`microk8s config` + edición manual) | Credencial para administrar el cluster de forma remota — vive solo en la PC cliente, pendiente de decidir cómo se le entrega a CI cuando haga falta desplegar |
