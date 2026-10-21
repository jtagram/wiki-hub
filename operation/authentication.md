# Autenticación

## Qué es

Cómo el ecosistema comprueba **quién** hace una petición. `iam-api` es el único que valida credenciales y emite tokens JWT; las demás APIs solo verifican esos tokens.

Hay dos tipos de usuario, con el mismo flujo y credenciales distintas:

| | Usuario interno | Usuario de aplicación |
|---|---|---|
| Quién es | Una persona | Una aplicación (máquina a máquina) |
| Credenciales | `email` + `password` | `clienteId` + `clienteSecret` |
| Endpoint | `POST /internal-users/login` | `POST /apps-users/login` |
| Quién lo usa | Los frontends `iam` y `ticket-hub` | `ticket-hub-api`, para llamar a `infra-hub-api` e `iam-api` |

### Flujo: del login a la petición autenticada

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. Cliente       │   │ 2. iam-api       │   │ 3. iam-api       │
│ POST /login con  │──▶│ valida las       │──▶│ firma el JWT     │
│ credenciales y 2 │   │ credenciales y   │   │ (RS256) con su   │
│ headers          │   │ los permisos     │   │ clave privada    │
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │ { access_token }
┌──────────────────┐   ┌──────────────────┐   ┌────────▼─────────┐
│ 6. La API        │   │ 5. JwtAuthGuard  │   │ 4. Cliente       │
│ responde         │◀──│ verifica firma y │◀──│ Authorization:   │
│                  │   │ expiración (JWKS)│   │ Bearer <token>   │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

| Paso | Qué pasa | Dónde se configura |
|---|---|---|
| 1 | El cliente envía el login con sus credenciales y los 2 headers | Frontend: `<frontend>/app/api/auth/`. Servicio: `ticket-hub-api/src/common/iam-api-auth/` |
| 2 | `iam-api` valida las credenciales y los permisos de acceso | `iam-api/src/modules/internal-users/` y `apps-users/` |
| 3 | `iam-api` firma el JWT con RS256 y devuelve `access_token` | `JWT_PRIVATE_KEY` y `JWT_EXPIRES_IN` |
| 4 | El cliente envía el token en cada petición como `Bearer` | Frontend: cookie `httpOnly`. Servicio: token en caché |
| 5 | `JwtAuthGuard` verifica firma y expiración con la clave pública | `<api>/src/common/guards/jwt-auth.guard.ts` |
| 6 | La API responde; si el token es inválido, `401` | — |

### Headers del login

Los dos tipos de usuario envían:

| Header | Qué indica |
|---|---|
| `x-origin-application` | Desde qué aplicación se hace el login |
| `x-target-application` | A qué aplicación se quiere acceder |

Si falta alguno, la respuesta es `400`.

### Validaciones del login

Se aplican en este orden, igual para los dos tipos de usuario:

| # | Qué falla | Respuesta |
|---|---|---|
| 1 | Usuario inexistente o contraseña/secreto incorrecto | `401 Invalid credentials` (mismo mensaje para ambos casos) |
| 2 | La aplicación de origen o destino no existe | `404` |
| 3 | El usuario no tiene acceso al origen o al destino | `403` |
| 4 | No hay conexión permitida origen → destino | `403` |
| 5 | El usuario no tiene roles en el destino | `403` |

### El token

- **Algoritmo:** RS256. Solo `iam-api` firma, con `JWT_PRIVATE_KEY`.
- **Expiración:** `JWT_EXPIRES_IN`, configurada por ambiente ([environment-variables.md](environment-variables.md)).
- **Contenido:** `sub`, `origin`, la aplicación de destino con los roles del usuario en ella, y `email` (usuario interno) o `clienteId` (usuario de aplicación).
- **Verificación:** `ticket-hub-api` e `infra-hub-api` descargan la clave pública de `GET /.well-known/jwks.json` de `iam-api` y la refrescan cada 5 minutos. Si el servicio no responde al arrancar, la API no inicia.
- **No hay** refresh token, logout en el servidor ni revocación: un token vale hasta que vence.

## Usuarios internos

Personas que usan los frontends.

- **Login:** `POST /internal-users/login` con `email` y `password`. La contraseña se guarda con bcrypt (10 rondas).
- **En el frontend:** `iam` y `ticket-hub` reenvían el login desde su servidor y guardan el token en una cookie `httpOnly` (`iam_access_token` y `ticket_hub_access_token`). El navegador nunca maneja el token directamente: el servidor lo envía como `Bearer` a las APIs.
- **Logout:** borra la cookie. El token sigue siendo válido en el servidor hasta que vence.

## Usuarios de aplicación

Credenciales de máquina para que una aplicación llame a otra.

- **Login:** `POST /apps-users/login` con `clienteId` y `clienteSecret`. El secreto se guarda con bcrypt y se muestra **una sola vez**, al crear el usuario.
- **Quién lo usa:** `ticket-hub-api`, con las variables `TICKET_HUB_API_SERVICE_CLIENT_ID` y `TICKET_HUB_API_SERVICE_CLIENT_SECRET`. Pide un token por cada aplicación de destino (`infra-hub-api`, `iam-api`).
- **Caché:** guarda el token por destino y lo renueva 60 segundos antes de que venza.
- **Importante:** `ticket-hub-api` no reenvía el token del usuario final a `infra-hub-api`; usa el suyo.

## Dónde está implementado

| Qué | Dónde |
|---|---|
| Login de usuarios internos | `iam-api/src/modules/internal-users/` |
| Login de usuarios de aplicación | `iam-api/src/modules/apps-users/` |
| Clave pública (JWKS) | `iam-api/src/modules/jwks/` |
| Verificación del token | `<api>/src/common/guards/jwt-auth.guard.ts` y `<api>/src/common/jwt/` |
| Token de servicio | `ticket-hub-api/src/common/iam-api-auth/` |
| Login en el frontend | `iam/app/api/auth/` y `ticket-hub/app/api/auth/` |

Rutas públicas (sin token): los dos logins, `GET /health` y `GET /.well-known/jwks.json` en `iam-api`; `GET /` y `GET /health` en las otras dos APIs.

<p align="right"><a href="operation.md">← Back</a></p>
