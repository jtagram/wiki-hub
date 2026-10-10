# Montar el ecosistema jtagram

Pasos para preparar las 3 máquinas virtuales (`local`, `dev` y `prod`) donde corre el ecosistema.

Sigue los pasos en este orden. Cada uno da por hecho que los anteriores ya se completaron.

## Pasos

0. [pcbox-bootstrap.md](pcbox-bootstrap.md): preparar el servidor `pcbox`, que aloja las 3 VMs: instalar Ubuntu Server y OpenSSH, conectarlo a la tailnet, y dejar el acceso por SSH con llave y contraseña y `sudo` sin contraseña.
1. [install-multipass.md](install-multipass.md): instalar Multipass en el servidor `pcbox`.
2. [create-ubuntu-server-on-multipass-vm.md](create-ubuntu-server-on-multipass-vm.md): crear las 3 VMs con Ubuntu Server.
3. [configure-tailscale-for-three-environments.md](configure-tailscale-for-three-environments.md): conectar las VMs a la tailnet.
4. [configure-access-key-for-three-environments..md](configure-access-key-for-three-environments..md): configurar el acceso con llave y contraseña, y `sudo` sin contraseña.
5. [install-microk8s-for-three-environments.md](install-microk8s-for-three-environments.md): instalar MicroK8s en cada VM.
6. [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md): crear los namespaces de cada ambiente en su VM.
7. [generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md](generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md): generar los valores de los secretos de cada ambiente. Guarda la salida.
8. [create-secrets-for-three-environments.md](create-secrets-for-three-environments.md): cargar esos valores como Secrets de Kubernetes en el namespace de cada app.
9. [create-users-with-permissions-for-three-environments.md](create-users-with-permissions-for-three-environments.md): crear un usuario por ambiente que ve todo y edita Secrets.
10. [create-serviceaccounts-for-three-environments.md](create-serviceaccounts-for-three-environments.md): crear el ServiceAccount de cada app en su ambiente.
11. [create-databases-for-three-environments.md](create-databases-for-three-environments.md): desplegar PostgreSQL y crear las bases y tablas en cada ambiente.
12. [initialize-values-in-the-database-for-three-environments.md](initialize-values-in-the-database-for-three-environments.md): insertar los datos iniciales (primer usuario administrador y cuenta de servicio) en cada ambiente.
13. [clone-organization-repositories.md](clone-organization-repositories.md): clonar los repositorios de la organización `jtagram` a tu organización de GitHub.
14. [create-environment-in-github.md](create-environment-in-github.md): crear los environments de GitHub (`prod`, `dev`, `local` con secretos; `production-approver` y `development-approver` solo con la aprobación manual).
15. [generate-secret-values-for-github-action-for-three-environments.md](generate-secret-values-for-github-action-for-three-environments.md): obtener los valores de los secretos de GitHub Actions de cada ambiente. Guárdalos.
16. [load-secrets-for-github-action-for-three-environments.md](load-secrets-for-github-action-for-three-environments.md): cargar esos valores por CLI como Environment secrets de cada ambiente.
17. [create-tag-for-dockerhub-and-github.md](create-tag-for-dockerhub-and-github.md): crear el primer tag en GitHub y Docker Hub.
18. [first-deploy-for-three-environments.md](first-deploy-for-three-environments.md): hacer el primer deploy de cada app en cada ambiente.
19. [expose-apps-to-tailscale-network-for-three-environments.md](expose-apps-to-tailscale-network-for-three-environments.md): exponer las apps de cada ambiente a la red de Tailscale con nombre propio y HTTPS.

