# Montar el ecosistema jtagram

Pasos para preparar las 3 máquinas virtuales (`local`, `dev` y `prod`) donde corre el ecosistema.

Sigue los pasos en este orden. Cada uno da por hecho que los anteriores ya se completaron.

## Pasos

## Grupo 1: Servidor y VMs

Preparar el servidor `pcbox` y las 3 máquinas virtuales.

| Qué se hace | Descripción | Documento |
|---|---|---|
| 0. Preparar el servidor pcbox | Instalar Ubuntu Server y OpenSSH en `pcbox`, conectarlo a la tailnet y dejar el acceso por SSH solo con llave. | [Ir →](01-server-and-vms/pcbox-bootstrap.md) |
| 1. Instalar Multipass | Instalar Multipass en el servidor `pcbox`. | [Ir →](01-server-and-vms/install-multipass.md) |
| 2. Crear las VMs con Ubuntu Server | Crear las 3 VMs con Ubuntu Server. | [Ir →](01-server-and-vms/create-ubuntu-server-on-multipass-vm.md) |
| 3. Conectar las VMs a la tailnet | Conectar las VMs a la tailnet. | [Ir →](01-server-and-vms/configure-tailscale-for-three-environments.md) |
| 4. Configurar el acceso a las VMs | Configurar el acceso con llave y contraseña, y `sudo` sin contraseña. | [Ir →](01-server-and-vms/configure-access-key-for-three-environments..md) |

## Grupo 2: Base de MicroK8s

Instalar MicroK8s y crear los namespaces de cada ambiente.

| Qué se hace | Descripción | Documento |
|---|---|---|
| 5. Instalar MicroK8s | Instalar MicroK8s en cada VM. | [Ir →](02-microk8s-base/install-microk8s-for-three-environments.md) |
| 6. Crear los namespaces | Crear los namespaces de cada ambiente en su VM. | [Ir →](02-microk8s-base/create-namespaces-for-three-environments.md) |

## Grupo 3: Secretos y accesos en el cluster

Cargar los Secrets y crear los usuarios, roles y ServiceAccounts.

| Qué se hace | Descripción | Documento |
|---|---|---|
| 7. Generar los valores de los secretos | Generar los valores de los secretos de cada ambiente. Guarda la salida. | [Ir →](03-cluster-secrets-and-access/generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md) |
| 8. Crear los Secrets de Kubernetes | Cargar esos valores como Secrets de Kubernetes en el namespace de cada app. | [Ir →](03-cluster-secrets-and-access/create-secrets-for-three-environments.md) |
| 9. Configurar el certificado del API server | Agregar la IP de Tailscale de cada VM al certificado del API server y regenerarlo. | [Ir →](03-cluster-secrets-and-access/configure-api-server-certificate-for-three-environments.md) |
| 10. Crear el usuario y su token | Crear el usuario `viewer-secrets-editor` y el Secret con su token en cada ambiente. | [Ir →](03-cluster-secrets-and-access/create-users-for-three-environments.md) |
| 11. Crear el kubeconfig del usuario | Armar el kubeconfig del usuario en cada VM y bajarlo a la PC cliente. | [Ir →](03-cluster-secrets-and-access/create-kubeconfig-for-three-environments.md) |
| 12. Crear los roles | Crear los roles de solo lectura y de edición de Secrets. | [Ir →](03-cluster-secrets-and-access/create-roles-for-three-environments.md) |
| 13. Asignar los roles al usuario | Asignar los roles al usuario de cada ambiente: ve todo y edita Secrets solo en su ambiente. | [Ir →](03-cluster-secrets-and-access/create-rolebindings-for-three-environments.md) |
| 14. Crear los ServiceAccounts | Crear el ServiceAccount de cada app en su ambiente. | [Ir →](03-cluster-secrets-and-access/create-serviceaccounts-for-three-environments.md) |

## Grupo 4: Base de datos

Desplegar PostgreSQL, crear las bases y las tablas, y cargar los datos iniciales.

| Qué se hace | Descripción | Documento |
|---|---|---|
| 15. Desplegar PostgreSQL | Desplegar PostgreSQL en cada ambiente. | [Ir →](04-database/deploy-postgres-for-three-environments.md) |
| 16. Crear las bases de datos | Crear las bases `iam_api`, `infra_hub_api` y `ticket_hub_api` en cada ambiente. | [Ir →](04-database/create-databases-for-three-environments.md) |
| 17. Crear las tablas | Crear las tablas de cada base en cada ambiente. | [Ir →](04-database/create-tables-for-three-environments.md) |
| 18. Cargar los datos iniciales | Insertar los datos iniciales (primer usuario administrador y cuenta de servicio) en cada ambiente. | [Ir →](04-database/initialize-values-in-the-database-for-three-environments.md) |

## Grupo 5: GitHub y CI/CD

Clonar los repositorios, configurar los environments y secretos de GitHub, y crear el primer tag.

| Qué se hace | Descripción | Documento |
|---|---|---|
| 19. Clonar los repositorios | Clonar los repositorios de la organización `jtagram` a tu organización de GitHub. | [Ir →](05-github-and-cicd/clone-organization-repositories.md) |
| 20. Crear los environments de GitHub | En `deploy-hub-api`: `prod`, `dev` y `local`, con secretos y aprobadores. En cada app: solo `local`. | [Ir →](05-github-and-cicd/create-environment-in-github.md) |
| 21. Obtener los valores de los secretos de GitHub Actions | Obtener los valores de los secretos de GitHub Actions de cada ambiente. Guárdalos. | [Ir →](05-github-and-cicd/generate-secret-values-for-github-action-for-three-environments.md) |
| 22. Cargar los secretos en GitHub | Cargar los valores como Environment secrets: casi todos en `deploy-hub-api` y, en cada app, solo el token del deploy de local. | [Ir →](05-github-and-cicd/load-secrets-for-github-action-for-three-environments.md) |
| 23. Crear el primer tag | Crear el primer tag en GitHub y Docker Hub. | [Ir →](05-github-and-cicd/create-tag-for-dockerhub-and-github.md) |

## Grupo 6: Despliegue y operación

Hacer el primer deploy, exponer las apps y ver los logs.

| Qué se hace | Descripción | Documento |
|---|---|---|
| 24. Hacer el primer deploy | Hacer el primer deploy de cada app en cada ambiente. | [Ir →](06-deploy-and-operation/first-deploy-for-three-environments.md) |
| 25. Exponer las apps a Tailscale | Exponer las apps de cada ambiente a la red de Tailscale con nombre propio y HTTPS. | [Ir →](06-deploy-and-operation/expose-apps-to-tailscale-network-for-three-environments.md) |
| 26. Implementar la observabilidad | Instalar Loki, Alloy y Grafana en cada ambiente y exponer Grafana a la tailnet. | [Ir →](06-deploy-and-operation/implement-observability.md) |

<p align="right"><a href="../README.md">← Back</a></p>
