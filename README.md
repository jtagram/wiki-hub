# wiki-hub

Documentación para montar el entorno de trabajo `jtagram` completo en tu propio home lab: un servidor (`pcbox`) con MicroK8s, los 7 repositorios de la organización, y todo lo necesario para deployar y correr `iam`, `iam-api`, `ticket-hub`, `ticket-hub-api` e `infra-hub-api`.

Seguí estos instructivos **en este orden** — cada uno da por sentado que los anteriores ya se hicieron:

1. [`pcbox/pcbox.bootstrap.md`](pcbox/pcbox.bootstrap.md) — Instalación del servidor `pcbox` (Ubuntu Server, OpenSSH, Tailscale, clave SSH sin contraseña, sudo sin contraseña para CI).
2. [`pcbox/pcbox.microk8s-setup.md`](pcbox/pcbox.microk8s-setup.md) — Instalación de MicroK8s en `pcbox`, extensión del certificado del API server para Tailscale, y kubeconfig para administración remota.
3. [`pcbox/pcbox.microk8s-usuario-viewer-secretos.md`](pcbox/pcbox.microk8s-usuario-viewer-secretos.md) — Usuario de Kubernetes restringido para conectarse desde la PC cliente: lectura total del cluster y gestión completa de Secrets, sin permisos para crear, borrar o modificar ningún otro recurso (esos cambios pasan por la ticketera).
4. [`microk8s/microk8s.namespace.md`](microk8s/microk8s.namespace.md) — Namespaces del cluster: uno por aplicación (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`) más `databases`.
5. [`script/README.md`](script/README.md) — Generación de todos los valores de secretos del sistema (`main.sh`): credenciales de Postgres, par de claves JWT, clave SSH de servicio y credenciales de aplicación. Guardá su salida, la vas a necesitar en los pasos que siguen.
6. [`microk8s/microk8s.secrets.md`](microk8s/microk8s.secrets.md) — Carga esos valores generados en el paso anterior como Secrets de Kubernetes, uno por aplicación (más el de Postgres en `databases`).
7. [`repositories/repositories.clonar-organizacion.md`](repositories/repositories.clonar-organizacion.md) — Clonar los 7 repositorios de la organización `jtagram` a tu propia organización de GitHub.
8. [`secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md`](secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md) — Crear los secretos que usan los workflows de GitHub Actions (Docker Hub, `KUBECONFIG_MICROK8S`, OAuth de Tailscale, y los `DISPATCH_TOKEN` de cada app) en tus propios repositorios.
9. [`database/database.crear-bases.md`](database/database.crear-bases.md) — Desplegar el servidor de PostgreSQL en el cluster y crear las 3 bases de datos (`iam_api`, `infra_hub_api`, `ticket_hub_api`) con sus tablas.
10. [`database/database.datos-iniciales.md`](database/database.datos-iniciales.md) — Insertar el primer usuario ADMIN (con acceso a `iam` y a `ticket-hub`) y el apps-user de servicio de `ticket-hub-api` (con rol ADMIN sobre `infra-hub-api` y `ticket-hub`).

Con estos 10 pasos completos, el cluster tiene todo lo que las apps necesitan para arrancar (namespaces, Secrets, base de datos) y las cuentas mínimas para empezar a usar el sistema, y los repositorios están listos para disparar sus workflows de release/deploy.
