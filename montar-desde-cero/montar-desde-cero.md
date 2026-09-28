# Montar todo el ecosistema desde cero

Documentación para montar el entorno de trabajo `jtagram` completo en tu propio home lab: un servidor (`pcbox`) con MicroK8s, los 7 repositorios de la organización, y todo lo necesario para deployar y correr `iam`, `iam-api`, `ticket-hub`, `ticket-hub-api` e `infra-hub-api`.

Seguí estos instructivos **en este orden** — cada uno da por sentado que los anteriores ya se hicieron:

1. [`pcbox/pcbox.bootstrap.md`](../pcbox/pcbox.bootstrap.md) — Instalación del servidor `pcbox` (Ubuntu Server, OpenSSH, Tailscale, clave SSH sin contraseña, sudo sin contraseña para CI).
2. [`pcbox/pcbox.microk8s-setup.md`](../pcbox/pcbox.microk8s-setup.md) — Instalación de MicroK8s en `pcbox`, extensión del certificado del API server para Tailscale, y kubeconfig para administración remota.
3. [`pcbox/pcbox.microk8s-usuario-viewer-secretos.md`](../pcbox/pcbox.microk8s-usuario-viewer-secretos.md) — Usuario de Kubernetes restringido para conectarse desde la PC cliente: lectura total del cluster y gestión completa de Secrets, sin permisos para crear, borrar o modificar ningún otro recurso (esos cambios pasan por la ticketera).
4. [`microk8s/microk8s.namespace.md`](../microk8s/microk8s.namespace.md) — Namespaces del cluster: uno por aplicación (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`) más `databases`.
5. [`script/README.md`](../script/README.md) — Generación de todos los valores de secretos del sistema (`main.sh`): credenciales de Postgres, par de claves JWT, clave SSH de servicio y credenciales de aplicación. Guardá su salida, la vas a necesitar en los pasos que siguen.
6. [`microk8s/microk8s.secrets.md`](../microk8s/microk8s.secrets.md) — Carga esos valores generados en el paso anterior como Secrets de Kubernetes, uno por aplicación (más el de Postgres en `databases`).
7. [`repositories/repositories.clonar-organizacion.md`](../repositories/repositories.clonar-organizacion.md) — Clonar los 7 repositorios de la organización `jtagram` a tu propia organización de GitHub.
8. [`secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md`](../secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md) — Crear los secretos que usan los workflows de GitHub Actions (Docker Hub, `KUBECONFIG_MICROK8S`, OAuth de Tailscale, y los `DISPATCH_TOKEN` de cada app) en tus propios repositorios.
9. [`database/database.crear-bases.md`](../database/database.crear-bases.md) — Desplegar el servidor de PostgreSQL en el cluster y crear las 3 bases de datos (`iam_api`, `infra_hub_api`, `ticket_hub_api`) con sus tablas.
10. [`database/database.datos-iniciales.md`](../database/database.datos-iniciales.md) — Insertar el primer usuario ADMIN (con acceso a `iam` y a `ticket-hub`) y el apps-user de servicio de `ticket-hub-api` (con rol ADMIN sobre `infra-hub-api` y `ticket-hub`).
11. [`first-deploy/first-deploy.service-account.md`](../first-deploy/first-deploy.service-account.md) — Crear a mano, una vez por app en las 5, el ServiceAccount que su `Deployment` referencia pero que no viene versionado en ningún manifiesto.
12. [`first-deploy/first-deploy.primer-tag.md`](../first-deploy/first-deploy.primer-tag.md) — Crear a mano, una vez por repo en las 5 apps, el primer tag de la primera release (en git y en Docker Hub).
13. [`first-deploy/first-deploy.environment-produccion.md`](../first-deploy/first-deploy.environment-produccion.md) — Configurar, una vez por repo en las 5 apps, el botón de aprobación manual del Environment `production`.
14. [`first-deploy/first-deploy.iam-api.md`](../first-deploy/first-deploy.iam-api.md) — Primer deploy de las 5 apps (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`): disparar el release con las versiones correctas y verificar que el rollout quedó arriba.

Con estos 14 pasos completos, el cluster tiene todo lo que las apps necesitan para arrancar (namespaces, Secrets, base de datos), las cuentas mínimas para empezar a usar el sistema, y las 5 apps corriendo por primera vez en microk8s a través de sus workflows de release/deploy.

## Opcional: acceder a `iam` y `ticket-hub` desde una PC cliente

Los pasos anteriores dejan `iam` y `ticket-hub` corriendo, pero solo alcanzables dentro del cluster (Service `ClusterIP`, sin `Ingress`). Para entrar desde una PC cliente de la tailnet con una URL propia y HTTPS:

15. [`acceso-externo/acceso-externo.tailscale-operator.md`](../acceso-externo/acceso-externo.tailscale-operator.md) — Instalar el Tailscale Operator en el cluster y crear el `Ingress` de `iam` y `ticket-hub` para acceder por `https://iam.tu-tailnet.ts.net` y `https://ticket-hub.tu-tailnet.ts.net`.
