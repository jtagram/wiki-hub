# Montar el ecosistema jtagram

Pasos para preparar las 3 máquinas virtuales (`local`, `dev` y `prod`) donde corre el ecosistema.

Sigue los pasos en este orden. Cada uno da por hecho que los anteriores ya se completaron.

## Pasos

## Grupo 1: Servidor y VMs (pasos 0 al 4)

Preparar el servidor `pcbox` y las 3 máquinas virtuales.

### 0. Preparar el servidor pcbox

Preparar el servidor `pcbox`, que aloja las 3 VMs: instalar Ubuntu Server y OpenSSH, conectarlo a la tailnet y configurar el acceso por SSH solo con llave, dejando la contraseña únicamente para el acceso físico con monitor y teclado.

<p align="right"><a href="01-server-and-vms/pcbox-bootstrap.md">Ir →</a></p>

---

### 1. Instalar Multipass

Instalar Multipass en el servidor `pcbox`.

<p align="right"><a href="01-server-and-vms/install-multipass.md">Ir →</a></p>

---

### 2. Crear las VMs con Ubuntu Server

Crear las 3 VMs con Ubuntu Server.

<p align="right"><a href="01-server-and-vms/create-ubuntu-server-on-multipass-vm.md">Ir →</a></p>

---

### 3. Conectar las VMs a la tailnet

Conectar las VMs a la tailnet.

<p align="right"><a href="01-server-and-vms/configure-tailscale-for-three-environments.md">Ir →</a></p>

---

### 4. Configurar el acceso a las VMs

Configurar el acceso con llave y contraseña, y `sudo` sin contraseña.

<p align="right"><a href="01-server-and-vms/configure-access-key-for-three-environments..md">Ir →</a></p>

---

## Grupo 2: Base de MicroK8s (pasos 5 al 6)

Instalar MicroK8s y crear los namespaces de cada ambiente.

### 5. Instalar MicroK8s

Instalar MicroK8s en cada VM.

<p align="right"><a href="02-microk8s-base/install-microk8s-for-three-environments.md">Ir →</a></p>

---

### 6. Crear los namespaces

Crear los namespaces de cada ambiente en su VM.

<p align="right"><a href="02-microk8s-base/create-namespaces-for-three-environments.md">Ir →</a></p>

---

## Grupo 3: Secretos y accesos en el cluster (pasos 7 al 12)

Cargar los Secrets y crear los usuarios, roles y ServiceAccounts.

### 7. Generar los valores de los secretos

Generar los valores de los secretos de cada ambiente. Guarda la salida.

<p align="right"><a href="03-cluster-secrets-and-access/generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md">Ir →</a></p>

---

### 8. Crear los Secrets de Kubernetes

Cargar esos valores como Secrets de Kubernetes en el namespace de cada app.

<p align="right"><a href="03-cluster-secrets-and-access/create-secrets-for-three-environments.md">Ir →</a></p>

---

### 9. Crear el usuario de acceso

Crear en cada ambiente el usuario `viewer-secrets-editor` con su token y su kubeconfig para la PC cliente.

<p align="right"><a href="03-cluster-secrets-and-access/create-users-for-three-environments.md">Ir →</a></p>

---

### 10. Crear los roles

Crear los roles de solo lectura y de edición de Secrets.

<p align="right"><a href="03-cluster-secrets-and-access/create-roles-for-three-environments.md">Ir →</a></p>

---

### 11. Asignar los roles al usuario

Asignar los roles al usuario de cada ambiente: ve todo y edita Secrets solo en su ambiente.

<p align="right"><a href="03-cluster-secrets-and-access/create-rolebindings-for-three-environments.md">Ir →</a></p>

---

### 12. Crear los ServiceAccounts

Crear el ServiceAccount de cada app en su ambiente.

<p align="right"><a href="03-cluster-secrets-and-access/create-serviceaccounts-for-three-environments.md">Ir →</a></p>

---

## Grupo 4: Base de datos (pasos 13 al 16)

Desplegar PostgreSQL, crear las bases y las tablas, y cargar los datos iniciales.

### 13. Desplegar PostgreSQL

Desplegar PostgreSQL en cada ambiente.

<p align="right"><a href="04-database/deploy-postgres-for-three-environments.md">Ir →</a></p>

---

### 14. Crear las bases de datos

Crear las bases `iam_api`, `infra_hub_api` y `ticket_hub_api` en cada ambiente.

<p align="right"><a href="04-database/create-databases-for-three-environments.md">Ir →</a></p>

---

### 15. Crear las tablas

Crear las tablas de cada base en cada ambiente.

<p align="right"><a href="04-database/create-tables-for-three-environments.md">Ir →</a></p>

---

### 16. Cargar los datos iniciales

Insertar los datos iniciales (primer usuario administrador y cuenta de servicio) en cada ambiente.

<p align="right"><a href="04-database/initialize-values-in-the-database-for-three-environments.md">Ir →</a></p>

---

## Grupo 5: GitHub y CI/CD (pasos 17 al 21)

Clonar los repositorios, configurar los environments y secretos de GitHub, y crear el primer tag.

### 17. Clonar los repositorios

Clonar los repositorios de la organización `jtagram` a tu organización de GitHub.

<p align="right"><a href="05-github-and-cicd/clone-organization-repositories.md">Ir →</a></p>

---

### 18. Crear los environments de GitHub

Crear los environments de GitHub: en `deploy-hub-api`, `prod`, `dev` y `local` con secretos y `production-approver` y `development-approver` solo con la aprobación manual; en cada app, solo `local`.

<p align="right"><a href="05-github-and-cicd/create-environment-in-github.md">Ir →</a></p>

---

### 19. Obtener los valores de los secretos de GitHub Actions

Obtener los valores de los secretos de GitHub Actions de cada ambiente. Guárdalos.

<p align="right"><a href="05-github-and-cicd/generate-secret-values-for-github-action-for-three-environments.md">Ir →</a></p>

---

### 20. Cargar los secretos en GitHub

Cargar esos valores por CLI como Environment secrets: casi todos en `deploy-hub-api`, y en cada app solo el token con el que dispara el deploy de local.

<p align="right"><a href="05-github-and-cicd/load-secrets-for-github-action-for-three-environments.md">Ir →</a></p>

---

### 21. Crear el primer tag

Crear el primer tag en GitHub y Docker Hub.

<p align="right"><a href="05-github-and-cicd/create-tag-for-dockerhub-and-github.md">Ir →</a></p>

---

## Grupo 6: Despliegue y operación (pasos 22 al 24)

Hacer el primer deploy, exponer las apps y ver los logs.

### 22. Hacer el primer deploy

Hacer el primer deploy de cada app en cada ambiente.

<p align="right"><a href="06-deploy-and-operation/first-deploy-for-three-environments.md">Ir →</a></p>

---

### 23. Exponer las apps a Tailscale

Exponer las apps de cada ambiente a la red de Tailscale con nombre propio y HTTPS.

<p align="right"><a href="06-deploy-and-operation/expose-apps-to-tailscale-network-for-three-environments.md">Ir →</a></p>

---

### 24. Implementar la observabilidad

Instalar Loki, Alloy y Grafana en cada ambiente para ver los logs de las apps, y exponer Grafana a la tailnet.

<p align="right"><a href="06-deploy-and-operation/implement-observability.md">Ir →</a></p>

---

<p align="right"><a href="README.md">← Back</a></p>
