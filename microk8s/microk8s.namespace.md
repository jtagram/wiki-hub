# Crear namespaces en MicroK8s

Configuración inicial de los namespaces del cluster MicroK8s en el servidor `pcbox`.

## 1. Conectarse al servidor

Desde la PC cliente, conéctate al servidor mediante SSH usando la clave privada configurada en `pcbox.bootstrap.md`:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Todos los comandos siguientes se ejecutan dentro de la sesión SSH del servidor `pcbox`.

## 2. Crear los namespaces

Un namespace por aplicación:

```bash
microk8s kubectl create namespace iam
microk8s kubectl create namespace iam-api
microk8s kubectl create namespace infra-hub-api
microk8s kubectl create namespace ticket-hub
microk8s kubectl create namespace ticket-hub-api
```

Crear además el namespace para las bases de datos:

```bash
microk8s kubectl create namespace databases
```

## 3. Verificar

Comprobar que todos los namespaces fueron creados correctamente:

```bash
microk8s kubectl get namespaces
```

La salida debe incluir `iam`, `iam-api`, `infra-hub-api`, `ticket-hub`,
`ticket-hub-api` y `databases`, todos con estado `Active`.
