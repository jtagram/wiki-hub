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

<p align="right"><a href="../operation.md">← Back</a></p>
