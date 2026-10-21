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
| 4 | Se publica la página interactiva en `/docs` | Ruta `/docs` de cada API |

<p align="right"><a href="../operation.md">← Back</a></p>
