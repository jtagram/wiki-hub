# Swagger

## Qué es

La documentación interactiva de cada API (OpenAPI), generada desde el propio código con `@nestjs/swagger`. Lista cada endpoint con su descripción, parámetros, respuestas posibles y los roles que exige, y permite probarlo desde el navegador.

### Flujo: del código a la página

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. Controlador   │   │ 2. Archivo       │   │ 3. setupSwagger  │
│ @ApiTags y un    │──▶│ swagger/ del     │──▶│ lee todo y arma  │
│ decorador por    │   │ módulo: describe │   │ el documento     │
│ endpoint         │   │ el endpoint      │   │ OpenAPI (main.ts)│
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │
                              ┌────────────────────────▼─────────┐
                              │ 4. Página interactiva en /docs   │
                              │ con el botón Authorize (Bearer)  │
                              └──────────────────────────────────┘
```

| Paso | Qué pasa | Dónde se configura |
|---|---|---|
| 1 | El controlador declara `@ApiTags` y un decorador por endpoint | `<módulo>.controller.ts` |
| 2 | Un decorador compuesto describe el endpoint: resumen, respuestas y errores | `modules/<módulo>/swagger/` |
| 3 | `setupSwagger` lee todo y arma el documento OpenAPI | `common/swagger/setup-swagger.ts`, llamado desde `main.ts` |
| 4 | Se publica la página interactiva en `/docs` | URL de cada API (ver abajo) |

### URL

Cada API sirve su documentación en la ruta `/docs`. Se accede desde la tailnet:

| API | Dev (ejemplo) |
|---|---|
| `iam-api` | `https://dev-iam-api.tu-tailnet.ts.net/docs` |
| `infra-hub-api` | `https://dev-infra-hub-api.tu-tailnet.ts.net/docs` |
| `ticket-hub-api` | `https://dev-ticket-hub-api.tu-tailnet.ts.net/docs` |

Para otro ambiente, cambia el prefijo `dev-` por `local-` o `prod-`. Reemplaza `tu-tailnet` por el nombre de tu tailnet ([expose-apps-to-tailscale-network-for-three-environments.md](../expose-apps-to-tailscale-network-for-three-environments.md)).

### Probar un endpoint protegido

1. Obtén un token con el login ([authentication.md](authentication.md)).
2. En `/docs`, pulsa **Authorize** y pega el token (sin la palabra `Bearer`).
3. Abre un endpoint, pulsa **Try it out** y **Execute**.

La página `/docs` no pide token; cada endpoint protegido sí.

## Cómo está organizado

En cada API, la configuración general está separada de la descripción de cada endpoint:

```text
<api>/src/
├── common/swagger/
│   ├── setup-swagger.ts              # Título, versión, Bearer y ruta /docs
│   ├── api-protected.decorator.ts    # Bearer + respuestas 401 y 403 comunes
│   └── api-response-body.decorator.ts
└── modules/
    └── roles/
        ├── roles.controller.ts       # @ApiTags('Roles') + un decorador por endpoint
        └── swagger/
            └── roles.swagger.ts      # ApiCreateRole, ApiFindRoles...
```

- **El controlador queda limpio:** cada método lleva un solo decorador (`@ApiCreateRole()`), no una pila de decoradores de Swagger.
- **Un archivo `swagger/` por módulo** reúne toda la descripción: resumen, respuestas de éxito y de error con su causa.
- **Piezas reutilizables** en `common/swagger/`: `ApiProtected()` agrega el Bearer y las respuestas 401/403 de los guards; `iam-api` suma `ApiApplicationHeaders()` para los headers `x-origin-application` y `x-target-application` del login.

## Dónde está implementado

| API | Configuración | Descripciones |
|---|---|---|
| `iam-api` | `src/common/swagger/` | `src/modules/<módulo>/swagger/` |
| `infra-hub-api` | `src/common/swagger/` | `src/modules/<módulo>/swagger/` y `src/swagger/` |
| `ticket-hub-api` | `src/common/swagger/` | `src/modules/<módulo>/swagger/` y `src/swagger/` |

`setupSwagger(app)` se llama una sola vez, en el `main.ts` de cada API.

## Cómo documentar un endpoint nuevo

1. En `swagger/<módulo>.swagger.ts`, crea un decorador compuesto (`ApiCreateX`) con `applyDecorators(...)`: resumen, descripción, `ApiProtected()` y las respuestas posibles.
2. En el controlador, agrega `@ApiTags('<Módulo>')` a la clase y el decorador al método.
3. Declara en la descripción el rol que exige `@Roles(...)` ([authorization.md](authorization.md)).

## Por qué organizarlo así

- **Documentación junto al código:** al cambiar un endpoint, la doc está en el mismo módulo y no se desactualiza en otro sitio.
- **Controladores legibles:** la lógica y la descripción viven en archivos separados.
- **Sin repetir:** el Bearer y los errores 401/403 se definen una vez en `ApiProtected()`.
- **Consistente:** las tres APIs tienen la misma estructura y la misma ruta `/docs`.
- **Probable en el momento:** quien integra una API puede ver y ejecutar sus endpoints sin herramientas extra.

<p align="right"><a href="operation.md">← Back</a></p>
