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

| Paso | Qué pasa |
|---|---|
| 1 | El cliente envía el login con sus credenciales y los 2 headers |
| 2 | `iam-api` valida las credenciales y los permisos de acceso |
| 3 | `iam-api` firma el JWT con RS256 y devuelve `access_token` |
| 4 | El cliente envía el token en cada petición como `Bearer` |
| 5 | `JwtAuthGuard` verifica firma y expiración con la clave pública |
| 6 | La API responde; si el token es inválido, `401` |

<p align="right"><a href="../operation.md">← Back</a></p>
