# Autorización

## Qué es

Cómo el ecosistema decide qué **puede hacer** quien ya se autenticó ([authentication.md](authentication.md)). Se decide con **roles por aplicación**: un usuario tiene roles distintos en cada aplicación, y cada token trae solo los roles de la aplicación de destino.

### Modelo

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ Aplicación       │   │ Rol              │   │ Usuario          │
│ iam, ticket-hub, │◀──│ ADMIN, DATABASE, │◀──│ interno o de     │
│ infra-hub-api    │   │ SERVER...        │   │ aplicación       │
│                  │   │ (por aplicación) │   │ (con sus roles)  │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

| Pieza | Qué es |
|---|---|
| Aplicación | Un sistema del ecosistema: `iam`, `ticket-hub`, `infra-hub-api` |
| Rol | Un permiso con nombre que pertenece a una aplicación (`ADMIN`, `DATABASE`...) |
| Usuario | Interno o de aplicación; tiene aplicaciones, roles y conexiones asignados |

Para obtener un token, el usuario necesita: acceso a la aplicación de origen y de destino, una conexión permitida entre ambas, y al menos un rol en el destino.

### Flujo: de la petición a la decisión

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. Petición con  │   │ 2. JwtAuthGuard  │   │ 3. RolesGuard    │
│ Bearer <token>   │──▶│ ¿token válido?   │──▶│ ¿token de esta   │
│                  │   │ si no: 401       │   │ aplicación?      │
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │ si no: 403
                                             ┌─────────▼────────┐
                                             │ 4. ¿tiene alguno │
                                             │ de los roles de  │
                                             │ @Roles(...)?     │
                                             └─────────┬────────┘
                                                       │ si no: 403
                                             ┌─────────▼────────┐
                                             │ 5. Se ejecuta el │
                                             │ endpoint         │
                                             └──────────────────┘
```

| Paso | Qué pasa | Dónde se configura |
|---|---|---|
| 1 | La petición llega con `Authorization: Bearer <token>` | — |
| 2 | `JwtAuthGuard` verifica el token; si no es válido, `401` | `<api>/src/common/guards/jwt-auth.guard.ts` |
| 3 | Se comprueba que el token sea de esta aplicación; si no, `403` | `RolesGuard` (en `iam-api`, `ApplicationAccessGuard`) |
| 4 | Se comprueba que tenga alguno de los roles de `@Roles(...)`; si no, `403` | `@Roles(...)` en el controlador |
| 5 | Se ejecuta el endpoint | — |

| Respuesta | Cuándo |
|---|---|
| `401` | Falta el token, está mal formado, es inválido o venció |
| `403` | El token es de otra aplicación, o no tiene el rol que pide el endpoint |

Los guards revisan solo la aplicación y los roles del token. **No distinguen** si quien llama es un usuario interno o de aplicación.

## Usuarios internos

Personas. Sus roles definen qué pueden hacer en cada aplicación.

- **Administración de IAM:** el rol `ADMIN` en la aplicación `iam` permite crear aplicaciones, roles y usuarios, y asignarles aplicaciones, roles y conexiones.
- **Tickets:** en `ticket-hub-api`, cada área tiene un rol para crear y consultar y otro para aprobar o rechazar.

## Usuarios de aplicación

Aplicaciones que llaman a otras. Se autorizan igual, con roles asignados a su usuario.

- **Servicio de ticket-hub-api:** necesita `ADMIN` en `infra-hub-api` para ejecutar operaciones, y `ADMIN` en `iam` para consultar la lista de responsables.
- **Gestión:** los administra un `ADMIN` de `iam`, con endpoints equivalentes a los de usuarios internos bajo `/apps-users`.

## Roles por API

| API | Roles | Qué permiten |
|---|---|---|
| `iam-api` | `ADMIN` | Todos los endpoints de gestión (`/applications`, `/roles`, `/internal-users`, `/apps-users`) |
| `infra-hub-api` | `ADMIN` | Todas las operaciones de bases de datos, servidor y Kubernetes. Solo las llama el usuario de servicio de `ticket-hub-api` |
| `ticket-hub-api` | `ADMIN` | Todo |
| | `DATABASE`, `SERVER`, `KUBERNATES` | Crear y consultar tickets de su área |
| | `DATABASE_APPROVER`, `SERVER_APPROVER`, `KUBERNATES_APPROVER` | Crear y consultar tickets de su área y además aprobarlos o rechazarlos |
| | `COMMON_USER` | Solo iniciar sesión; ningún endpoint lo pide |

Los nombres de los roles se escriben tal cual en el código (incluido `KUBERNATES`).

## Dónde está implementado

| Qué | Dónde |
|---|---|
| Aplicaciones, roles y asignaciones | `iam-api/src/common/database/` y `iam-api/src/modules/` |
| Guards | `<api>/src/common/guards/` (`jwt-auth.guard.ts`, `roles.guard.ts`; en `iam-api` también `application-access.guard.ts`) |
| Marcar un endpoint con sus roles | Decoradores `@Roles(...)` y `@Public()` en cada controlador |
| Lista de roles de cada API | `<api>/src/common/roles/role.enum.ts` (`iam-api`: `common/database/role/`) |

Los guards se registran como globales (`APP_GUARD`), así que aplican a toda la API sin repetirlos en cada controlador. En `iam-api`, una ruta que no es pública y no declara `@Roles` se **deniega**; en `ticket-hub-api` e `infra-hub-api`, la deja pasar si el token es válido.

## Por qué centralizarlo

- **La regla vive junto al endpoint:** `@Roles(...)` dice quién puede entrar, sin lógica de permisos dentro del código de negocio.
- **Guards globales:** una ruta nueva queda protegida por el token sin trabajo extra.
- **Un solo modelo de permisos:** personas y aplicaciones usan los mismos roles y las mismas reglas.
- **Permisos por aplicación:** un usuario puede ser administrador de una aplicación y no tener acceso a otra.

<p align="right"><a href="operation.md">← Back</a></p>
