# Configurar el certificado del API server en los 3 ambientes

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

### Certificado del API server

El API server solo acepta conexiones a las IPs de su certificado. Hay que agregar la IP de Tailscale de la VM.

Obtén la IP y edita la plantilla del certificado:

```bash
tailscale ip -4
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]`, **sin reemplazar ninguna línea existente**, agrega una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

Regenera el certificado y espera a que el cluster esté listo:

```bash
sudo microk8s refresh-certs -e server.crt
microk8s status --wait-ready
```

```bash
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

### Certificado del API server

El API server solo acepta conexiones a las IPs de su certificado. Hay que agregar la IP de Tailscale de la VM.

Obtén la IP y edita la plantilla del certificado:

```bash
tailscale ip -4
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]`, **sin reemplazar ninguna línea existente**, agrega una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

Regenera el certificado y espera a que el cluster esté listo:

```bash
sudo microk8s refresh-certs -e server.crt
microk8s status --wait-ready
```

```bash
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

### Certificado del API server

El API server solo acepta conexiones a las IPs de su certificado. Hay que agregar la IP de Tailscale de la VM.

Obtén la IP y edita la plantilla del certificado:

```bash
tailscale ip -4
sudo nano /var/snap/microk8s/current/certs/csr.conf.template
```

En la sección `[alt_names]`, **sin reemplazar ninguna línea existente**, agrega una entrada nueva con el próximo número disponible (si la última es `IP.3`, la nueva es `IP.4`):

```ini
IP.4 = 100.x.x.x
```

Regenera el certificado y espera a que el cluster esté listo:

```bash
sudo microk8s refresh-certs -e server.crt
microk8s status --wait-ready
```

```bash
exit
```

<p align="right"><a href="../set-up-the-ecosystem-jtagram.md">← Back</a></p>
