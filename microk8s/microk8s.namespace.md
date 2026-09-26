# Crear namespaces en MicroK8s

Configuración inicial de los namespaces del cluster MicroK8s en el servidor `pcbox`.

## 1. Conectarse al servidor

Desde la PC cliente, conéctate al servidor mediante SSH usando la clave privada configurada en `pcbox.bootstrap.md`:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Todos los comandos siguientes se ejecutan dentro de la sesión SSH del servidor `pcbox`.

## 2. Crear los namespaces

Crear el namespace para los componentes de infraestructura:

```bash
microk8s kubectl create namespace infra-hub
```

Crear el namespace para las bases de datos:

```bash
microk8s kubectl create namespace databases
```

## 3. Verificar

Comprobar que ambos namespaces fueron creados correctamente:

```bash
microk8s kubectl get namespaces
```

La salida debe incluir `infra-hub` y `databases` con estado `Active`.
