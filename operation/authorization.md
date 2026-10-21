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

<p align="right"><a href="operation.md">← Back</a></p>
