# Filtros de errores de las APIs

## Qué es

Un conjunto de 3 filtros de excepciones de NestJS que atrapan **todo** error que sale de un endpoint y hacen dos cosas: lo registran en el log y arman la respuesta que ve el cliente.

### Flujo: del error a la respuesta

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. Endpoint      │   │ 2. NestJS elige  │   │ 3. Filtro        │
│    lanza un      │──▶│    el filtro     │──▶│    registra el   │
│    error         │   │    por tipo de   │   │    error con     │
│                  │   │    error         │   │    el Logger     │
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │
┌──────────────────┐   ┌──────────────────┐   ┌────────▼─────────┐
│ 6. Grafana       │   │ 5. Cliente       │   │ 4. Filtro        │
│    (log del      │   │    recibe el     │◀──│    responde el   │
│    error)        │   │    JSON          │   │    JSON          │
└──────────────────┘   └──────────────────┘   └──────────────────┘
          ▲                                              
          └── el paso 3 también llega aquí: Logger → stdout → Alloy → Loki → Grafana
```

| Paso | Qué pasa | Dónde se configura |
|---|---|---|
| 1 | Un controlador o servicio lanza un error (HTTP, de base de datos u otro) | Código de negocio |
| 2 | NestJS elige el filtro por el tipo de error | `APP_FILTER` en `FilterModule` o `app.module.ts` |
| 3 | El filtro registra el error con el `Logger` | `<tipo>-exception.filter.ts` |
| 4 | El filtro arma y envía el JSON de respuesta | `<tipo>-exception.filter.ts` |
| 5 | El cliente recibe el JSON | — |
| 6 | El log llega a Grafana por stdout, Alloy y Loki | [logger.md](logger.md) |

| Filtro | Atrapa | Log | Respuesta al cliente |
|---|---|---|---|
| `HttpExceptionFilter` | Errores HTTP esperados (400, 401, 403, 404...) | `warn` si es menor a 500, `error` si es 500 o más | El mismo cuerpo del error y su código |
| `DatabaseExceptionFilter` | Errores de TypeORM | `error`, con el mensaje, el stack y la consulta | `500` con mensaje genérico |
| `UnknownExceptionFilter` | Cualquier otro error | `error` con `Unhandled exception` | `500` con mensaje genérico |

El mensaje genérico es `An unexpected error occurred. Please try again later.` y está definido una sola vez en `generic-error-message.ts`.

### Cómo se elige el filtro

NestJS evalúa los filtros globales en **orden inverso** al registro y usa el primero cuyo `@Catch()` coincide. Por eso el filtro que atrapa todo (`UnknownExceptionFilter`) se registra **primero**: así se prueba **último**, solo si ningún filtro específico coincide.

### Qué ve el cliente y qué ve el log

| | Cliente | Log (Grafana) |
|---|---|---|
| Errores esperados | El detalle del error | Mensaje, stack y detalle |
| Errores internos o de base de datos | Solo el mensaje genérico | Mensaje, stack y, si es de base de datos, la consulta |

Los parámetros de la consulta no se escriben en el log: `err.parameters` se oculta con `redact` ([logger.md](logger.md)).

## Dónde está implementado

| API | Carpeta | Dónde se registran |
|---|---|---|
| `iam-api` | `src/common/filters/` | `app.module.ts`, con `APP_FILTER` |
| `ticket-hub-api` | `src/common/filter/` | `FilterModule` (`filter.module.ts`) |
| `infra-hub-api` | `src/common/filter/` | `FilterModule` (`filter.module.ts`) |

Los 3 filtros y `generic-error-message.ts` son idénticos en las 3 APIs, con sus tests en `__tests__/`.

Es el **único lugar** donde se decide qué se loguea y qué se responde ante un error. Los controladores y servicios solo lanzan el error; no lo registran ni lo formatean.

## Por qué centralizarlo

- **Respuestas uniformes:** todos los errores de la API salen con la misma forma.
- **Sin filtrar información interna:** el stack, el SQL y los detalles de la base de datos van al log, nunca al cliente.
- **Logs consistentes:** todo error queda con los mismos campos (`err`, `errorType`, `msg`), así una consulta en Grafana sirve para cualquier error.
- **Código de negocio más simple:** no hace falta `try/catch` en cada endpoint solo para dar formato a la respuesta.
- **Testeable:** cada filtro se prueba por separado, sin levantar la app.

<p align="right"><a href="operation.md">← Back</a></p>
