# Cómo usar el ecosistema

## Índice

- [iam](#iam)
  - [Aplicaciones](#iam-aplicaciones)
    - [Crear aplicación](#iam-create-application)
    - [Ver aplicaciones](#iam-view-applications)
    - [Crear rol de aplicación](#iam-create-role)
    - [Ver roles de aplicaciones](#iam-view-application-roles)
  - [Usuarios de aplicación](#iam-usuarios-de-aplicacion)
    - [Crear usuario de aplicación](#iam-create-app-user)
    - [Asignar aplicación a usuario de aplicación](#iam-assign-application-to-app-user)
    - [Asignar rol a usuarios de aplicación](#iam-assign-role-to-app-user)
    - [Relacionar aplicaciones para usuarios de aplicación](#iam-connect-applications-for-app-user)
    - [Ver usuarios de aplicación](#iam-view-app-users)
  - [Usuarios internos](#iam-usuarios-internos)
    - [Crear usuario interno](#iam-create-internal-user)
    - [Asignar aplicación a usuario interno](#iam-assign-application-to-internal-user)
    - [Asignar rol a usuario interno](#iam-assign-role-to-internal-user)
    - [Relacionar aplicaciones para usuarios internos](#iam-connect-applications-for-internal-user)
    - [Ver usuarios internos](#iam-view-internal-users)
- [ticket-hub](#ticket-hub)
  - [Base de datos](#ticket-hub-base-de-datos)
    - [Solicitar gestión de base de datos](#ticket-hub-request-database-management)
    - [Ver ticket de gestión de base de datos](#ticket-hub-view-database-management-tickets)
    - [Buscar ticket de gestión de base de datos](#ticket-hub-search-database-management-ticket)
    - [Solicitar aprovisionamiento de base de datos](#ticket-hub-request-database-provisioning)
    - [Ver tickets de aprovisionamiento de base de datos](#ticket-hub-view-database-provisioning-tickets)
    - [Buscar ticket de aprovisionamiento de base de datos](#ticket-hub-search-database-provisioning-ticket)
  - [Servidor](#ticket-hub-servidor)
    - [Solicitar gestión de servidor](#ticket-hub-request-server-management)
    - [Ver tickets de gestión de servidor](#ticket-hub-view-server-management-tickets)
    - [Buscar ticket de gestión de servidor](#ticket-hub-search-server-management-ticket)
  - [Kubernetes](#ticket-hub-kubernetes)
    - [Solicitar gestión de manifiestos de Kubernetes](#ticket-hub-request-kubernetes-manifest)
    - [Ver tickets de gestión de manifiestos de Kubernetes](#ticket-hub-view-kubernetes-manifest-tickets)
    - [Buscar ticket de gestión de manifiestos de Kubernetes](#ticket-hub-search-kubernetes-manifest-ticket)
    - [Solicitar ejecución de comando kubectl](#ticket-hub-request-kubectl-command)
    - [Ver tickets de ejecución de comando kubectl](#ticket-hub-view-kubectl-command-tickets)
    - [Buscar ticket de ejecución de comando kubectl](#ticket-hub-search-kubectl-command-ticket)
- [Cómo deployar](#deploy)
  - [En local](#deploy-local)
  - [En dev](#deploy-dev)
  - [En prod](#deploy-prod)

<a id="iam"></a>

## iam

<a id="iam-aplicaciones"></a>

### Aplicaciones

<a id="iam-create-application"></a>

#### Crear aplicación

**Para qué sirve:** Registrar una aplicación nueva en IAM.

**Cómo se usa:** Completa **Nombre** (máx. 15 caracteres) y **Descripción** (máx. 200) y pulsa **Crear**. Verás un aviso de éxito.

<a id="iam-view-applications"></a>

#### Ver aplicaciones

**Para qué sirve:** Consultar las aplicaciones creadas.

**Cómo se usa:** Se abre una lista con el nombre y la descripción de cada aplicación. Si no hay ninguna, lo indica.

<a id="iam-create-role"></a>

#### Crear rol de aplicación

**Para qué sirve:** Crear un rol dentro de una aplicación.

**Cómo se usa:** Elige la **Aplicación**, completa **Nombre** (máx. 20 caracteres) y **Descripción** (máx. 200) y pulsa **Crear**.

<a id="iam-view-application-roles"></a>

#### Ver roles de aplicaciones

**Para qué sirve:** Consultar los roles que tiene cada aplicación.

**Cómo se usa:** Se muestra una lista con un resumen de roles por aplicación. No requiere completar nada.

<a id="iam-usuarios-de-aplicacion"></a>

### Usuarios de aplicación

<a id="iam-create-app-user"></a>

#### Crear usuario de aplicación

**Para qué sirve:** Crear un usuario de aplicación y obtener sus credenciales.

**Cómo se usa:** Completa **Nombre** (máx. 20) y **Descripción** (máx. 200) y pulsa **Crear**. Copia **clienteId** y **clienteSecret** de inmediato: el secreto se muestra solo esta vez.

<a id="iam-assign-application-to-app-user"></a>

#### Asignar aplicación a usuario de aplicación

**Para qué sirve:** Dar a un usuario de aplicación acceso a una aplicación.

**Cómo se usa:** Elige el **Usuario de aplicación** y la **Aplicación**, y pulsa **Asignar**.

<a id="iam-assign-role-to-app-user"></a>

#### Asignar rol a usuarios de aplicación

**Para qué sirve:** Darle a un usuario de aplicación un rol dentro de una aplicación.

**Cómo se usa:** Elige **Usuario de aplicación** y **Aplicación**; luego aparece la lista de **Rol**. Selecciona uno y pulsa **Asignar**.

<a id="iam-connect-applications-for-app-user"></a>

#### Relacionar aplicaciones para usuarios de aplicación

**Para qué sirve:** Conectar dos aplicaciones para un usuario de aplicación.

**Cómo se usa:** Elige el **Usuario de aplicación**, la **Aplicación origen** y la **Aplicación destino** (deben ser distintas) y pulsa **Relacionar**. Abajo ves las **Conexiones existentes**.

<a id="iam-view-app-users"></a>

#### Ver usuarios de aplicación

**Para qué sirve:** Consultar los usuarios de aplicación y sus accesos.

**Cómo se usa:** Se lista cada usuario con su descripción, las aplicaciones asignadas y los roles en cada una. Si no tiene, indica «Sin aplicaciones asignadas».

<a id="iam-usuarios-internos"></a>

### Usuarios internos

<a id="iam-create-internal-user"></a>

#### Crear usuario interno

**Para qué sirve:** Dar de alta a una persona como usuario interno.

**Cómo se usa:** Completa **Nombre**, **Apellido**, **Correo electrónico** y **Contraseña** (entre 8 y 72 caracteres) y pulsa **Crear**.

<a id="iam-assign-application-to-internal-user"></a>

#### Asignar aplicación a usuario interno

**Para qué sirve:** Dar a un usuario interno acceso a una aplicación.

**Cómo se usa:** Elige el **Usuario interno** y la **Aplicación**, y pulsa **Asignar**.

<a id="iam-assign-role-to-internal-user"></a>

#### Asignar rol a usuario interno

**Para qué sirve:** Darle a un usuario interno un rol dentro de una aplicación.

**Cómo se usa:** Elige **Usuario interno** y **Aplicación**, luego el **Rol**, y pulsa **Asignar**.

<a id="iam-connect-applications-for-internal-user"></a>

#### Relacionar aplicaciones para usuarios internos

**Para qué sirve:** Conectar dos aplicaciones para un usuario interno.

**Cómo se usa:** Elige el **Usuario interno**, la **Aplicación origen** y la **Aplicación destino** (deben ser distintas) y pulsa **Relacionar**. Abajo ves las **Conexiones existentes**.

<a id="iam-view-internal-users"></a>

#### Ver usuarios internos

**Para qué sirve:** Consultar los usuarios internos y sus accesos.

**Cómo se usa:** Se lista cada usuario con nombre, correo, aplicaciones asignadas y roles en cada una. Si no tiene, indica «Sin aplicaciones asignadas».

<a id="ticket-hub"></a>

## ticket-hub

<a id="ticket-hub-base-de-datos"></a>

### Base de datos

<a id="ticket-hub-request-database-management"></a>

#### Solicitar gestión de base de datos

**Para qué sirve:** Crear un ticket de gestión de base de datos.

**Cómo se usa:** Completa **Asunto** y **Descripción** y elige el **Responsable**, el **Deployment**, la **Base de datos** y escribe el **SQL a ejecutar**. Pulsa **Solicitar**. El ticket queda en estado Abierto; se aprueba o rechaza desde la opción de búsqueda.

<a id="ticket-hub-view-database-management-tickets"></a>

#### Ver ticket de gestión de base de datos

**Para qué sirve:** Ver los tickets de gestión de base de datos creados.

**Cómo se usa:** Se muestra la lista con el número, la fecha, el asunto y el informante de cada ticket. Si no hay, lo indica.

<a id="ticket-hub-search-database-management-ticket"></a>

#### Buscar ticket de gestión de base de datos

**Para qué sirve:** Buscar un ticket de gestión de base de datos por su número y resolverlo.

**Cómo se usa:** Escribe el **Número de ticket** y pulsa **Buscar**. Si el estado es Abierto, aparecen **Aprobar** y **Rechazar**.

<a id="ticket-hub-request-database-provisioning"></a>

#### Solicitar aprovisionamiento de base de datos

**Para qué sirve:** Crear un ticket de aprovisionamiento de base de datos.

**Cómo se usa:** Completa **Asunto** y **Descripción** y elige el **Responsable**, el **Deployment** y el **Nombre de la nueva base de datos**. Pulsa **Solicitar**. El ticket queda en estado Abierto; se aprueba o rechaza desde la opción de búsqueda.

<a id="ticket-hub-view-database-provisioning-tickets"></a>

#### Ver tickets de aprovisionamiento de base de datos

**Para qué sirve:** Ver los tickets de aprovisionamiento de base de datos creados.

**Cómo se usa:** Se muestra la lista con el número, la fecha, el asunto y el informante de cada ticket. Si no hay, lo indica.

<a id="ticket-hub-search-database-provisioning-ticket"></a>

#### Buscar ticket de aprovisionamiento de base de datos

**Para qué sirve:** Buscar un ticket de aprovisionamiento de base de datos por su número y resolverlo.

**Cómo se usa:** Escribe el **Número de ticket** y pulsa **Buscar**. Si el estado es Abierto, aparecen **Aprobar** y **Rechazar**.

<a id="ticket-hub-servidor"></a>

### Servidor

<a id="ticket-hub-request-server-management"></a>

#### Solicitar gestión de servidor

**Para qué sirve:** Crear un ticket de gestión de servidor.

**Cómo se usa:** Completa **Asunto** y **Descripción** y elige el **Responsable** y escribe el **Código Ansible**. Pulsa **Solicitar**. El ticket queda en estado Abierto; se aprueba o rechaza desde la opción de búsqueda.

<a id="ticket-hub-view-server-management-tickets"></a>

#### Ver tickets de gestión de servidor

**Para qué sirve:** Ver los tickets de gestión de servidor creados.

**Cómo se usa:** Se muestra la lista con el número, la fecha, el asunto y el informante de cada ticket. Si no hay, lo indica.

<a id="ticket-hub-search-server-management-ticket"></a>

#### Buscar ticket de gestión de servidor

**Para qué sirve:** Buscar un ticket de gestión de servidor por su número y resolverlo.

**Cómo se usa:** Escribe el **Número de ticket** y pulsa **Buscar**. Si el estado es Abierto, aparecen **Aprobar** y **Rechazar**.

<a id="ticket-hub-kubernetes"></a>

### Kubernetes

<a id="ticket-hub-request-kubernetes-manifest"></a>

#### Solicitar gestión de manifiestos de Kubernetes

**Para qué sirve:** Crear un ticket de gestión de manifiestos de Kubernetes.

**Cómo se usa:** Completa **Asunto** y **Descripción** y elige el **Responsable**, la **Acción** y pega el **Manifiesto YAML**. Pulsa **Solicitar**. El ticket queda en estado Abierto; se aprueba o rechaza desde la opción de búsqueda.

<a id="ticket-hub-view-kubernetes-manifest-tickets"></a>

#### Ver tickets de gestión de manifiestos de Kubernetes

**Para qué sirve:** Ver los tickets de gestión de manifiestos de Kubernetes creados.

**Cómo se usa:** Se muestra la lista con el número, la fecha, el asunto y el informante de cada ticket. Si no hay, lo indica.

<a id="ticket-hub-search-kubernetes-manifest-ticket"></a>

#### Buscar ticket de gestión de manifiestos de Kubernetes

**Para qué sirve:** Buscar un ticket de gestión de manifiestos de Kubernetes por su número y resolverlo.

**Cómo se usa:** Escribe el **Número de ticket** y pulsa **Buscar**. Si el estado es Abierto, aparecen **Aprobar** y **Rechazar**.

<a id="ticket-hub-request-kubectl-command"></a>

#### Solicitar ejecución de comando kubectl

**Para qué sirve:** Crear un ticket de ejecución de comando kubectl.

**Cómo se usa:** Completa **Asunto** y **Descripción** y elige el **Responsable** y escribe el **Comando kubectl**. Pulsa **Solicitar**. El ticket queda en estado Abierto; se aprueba o rechaza desde la opción de búsqueda.

<a id="ticket-hub-view-kubectl-command-tickets"></a>

#### Ver tickets de ejecución de comando kubectl

**Para qué sirve:** Ver los tickets de ejecución de comando kubectl creados.

**Cómo se usa:** Se muestra la lista con el número, la fecha, el asunto y el informante de cada ticket. Si no hay, lo indica.

<a id="ticket-hub-search-kubectl-command-ticket"></a>

#### Buscar ticket de ejecución de comando kubectl

**Para qué sirve:** Buscar un ticket de ejecución de comando kubectl por su número y resolverlo.

**Cómo se usa:** Escribe el **Número de ticket** y pulsa **Buscar**. Si el estado es Abierto, aparecen **Aprobar** y **Rechazar**.

<a id="deploy"></a>

## Cómo deployar

Las aplicaciones son `iam`, `iam-api`, `ticket-hub`, `ticket-hub-api` e `infra-hub-api`.

<a id="deploy-local"></a>

### En local

**Para qué sirve:** Probar un cambio de una aplicación en el ambiente local, sin validaciones ni aprobación.

**Cómo se usa:**

1. Haz push de tu cambio a la rama `local` de la aplicación.
2. El workflow `release-<app>-local.yml` de esa aplicación dispara el deploy en `deploy-hub-api`.
3. `deploy-hub-api` construye la imagen con el tag fijo `local` y la despliega en el microk8s local.

<a id="deploy-dev"></a>

### En dev

**Para qué sirve:** Publicar una versión nueva de una aplicación en el ambiente dev, con validaciones, pruebas y aprobación manual.

**Cómo se usa:**

1. En GitHub abre `jtagram/deploy-hub-api` → **Actions** → `deploy-<app>-dev.yml` → **Run workflow** y elige la rama `dev`.
2. Completa `previous_stable_tag` (la última versión estable, que ya debe existir en git y en Docker Hub) y `new_tag` (la versión nueva, que no debe existir todavía). Formato: `dev-vNUMERO.NUMERO.NUMERO`. Ejemplo: `dev-v0.1.4` y `dev-v0.1.5`.
3. El workflow valida, ejecuta los tests, publica la imagen en Docker Hub y crea el tag en el repo de la aplicación.
4. Aprueba el deploy pendiente del environment `development-approver`.
5. Se despliega en el cluster de dev.

Por consola:

```bash
gh workflow run deploy-<app>-dev.yml --repo jtagram/deploy-hub-api --ref dev \
  -f previous_stable_tag=dev-v0.1.4 -f new_tag=dev-v0.1.5
```

<a id="deploy-prod"></a>

### En prod

**Para qué sirve:** Publicar una versión nueva de una aplicación en el ambiente prod, con validaciones, pruebas y aprobación manual.

**Cómo se usa:**

1. En GitHub abre `jtagram/deploy-hub-api` → **Actions** → `deploy-<app>-prod.yml` → **Run workflow** y elige la rama `master`.
2. Completa `previous_stable_tag` (la última versión estable, que ya debe existir en git y en Docker Hub) y `new_tag` (la versión nueva, que no debe existir todavía). Formato: `prod-vNUMERO.NUMERO.NUMERO`. Ejemplo: `prod-v0.1.4` y `prod-v0.1.5`.
3. El workflow valida, ejecuta los tests, publica la imagen en Docker Hub y crea el tag en el repo de la aplicación.
4. Aprueba el deploy pendiente del environment `production-approver`.
5. Se despliega en el cluster de prod.

Por consola:

```bash
gh workflow run deploy-<app>-prod.yml --repo jtagram/deploy-hub-api --ref master \
  -f previous_stable_tag=prod-v0.1.4 -f new_tag=prod-v0.1.5
```

<p align="right"><a href="../README.md">← Back</a></p>
