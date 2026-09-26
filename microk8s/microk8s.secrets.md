# Crear secretos en MicroK8s

Configuración inicial de los secretos utilizados por los servicios del cluster MicroK8s. Por el momento solo se creará el secreto con las credenciales de PostgreSQL; los demás secretos se agregarán más adelante cuando sean necesarios.

## 1. Conectarse al servidor

Desde la PC cliente, conéctate al servidor `pcbox` mediante SSH usando la clave privada configurada en `pcbox.bootstrap.md`:

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

Todos los comandos siguientes se ejecutan dentro de la sesión SSH del servidor `pcbox`.

Antes de crear el secreto, asegúrate de que el namespace `databases` ya exista. Si todavía no lo creaste, sigue el instructivo de `pcbox.namespace.md`.

## 2. Crear el secreto de PostgreSQL

Ejecuta el siguiente comando para crear el secreto `postgres-credentials` en el namespace `databases`:

```bash
microk8s kubectl create secret generic postgres-credentials \
	-n databases \
	--from-literal=POSTGRES_USER=usuario_db \
	--from-literal=POSTGRES_PASSWORD=clave_segura
```

Reemplaza `usuario_db` y `clave_segura` por las credenciales reales antes de ejecutar el comando. No incluyas esas credenciales en el repositorio ni las compartas en texto plano.

## 3. Verificar

Comprobar que el secreto fue creado en el namespace correcto:

```bash
microk8s kubectl get secret postgres-credentials -n databases
```

La salida debe mostrar el secreto `postgres-credentials` dentro del namespace `databases`. Este comando no muestra los valores de las credenciales.
