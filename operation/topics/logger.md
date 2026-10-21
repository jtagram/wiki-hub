# Logger de las APIs

## Qué es

Un módulo de logging estructurado (JSON) basado en [`nestjs-pino`](https://github.com/iamolegga/nestjs-pino). Cada línea que la API escribe en stdout es un objeto JSON.

### Flujo: del log a Grafana

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. Código de     │   │ 2. Logger        │   │ 3. stdout del    │
│    la API        │──▶│    (pino)        │──▶│    pod           │
│ logger.error({}) │   │ JSON + redact    │   │ 1 línea = 1 JSON │
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │
┌──────────────────┐   ┌──────────────────┐   ┌────────▼─────────┐
│ 6. Grafana       │   │ 5. Loki          │   │ 4. Alloy         │
│    Explore       │◀──│    guarda y      │◀──│    lee los logs  │
│    (consultas)   │   │    indexa 3 días │   │    de los pods   │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

| Paso | Qué pasa | Dónde se configura |
|---|---|---|
| 1-2 | La API loguea un objeto; pino lo serializa a JSON y oculta los secretos | `src/instrument/logger/` de cada API |
| 3 | El JSON sale por stdout del contenedor | — |
| 4 | Alloy (uno por VM) lee los logs de todos los pods y los etiqueta | `alloy-values.yaml` |
| 5 | Loki los almacena | `loki-values.yaml` |
| 6 | Grafana los muestra | `grafana-values.yaml` |

Los pasos 4-6 se instalan en [implement-observability.md](../../set-up/06-deploy-and-operation/implement-observability.md).

### URL de Grafana

Cada ambiente tiene su propio Grafana, accesible solo desde la tailnet:

| Ambiente | URL |
|---|---|
| local | `https://local-grafana.tu-tailnet.ts.net` |
| dev | `https://dev-grafana.tu-tailnet.ts.net` |
| prod | `https://prod-grafana.tu-tailnet.ts.net` |

Reemplaza `tu-tailnet` por el nombre de tu tailnet. Usuario `admin`; la contraseña se generó al instalar (recuperarla: paso 3 de [implement-observability.md](../../set-up/06-deploy-and-operation/implement-observability.md)).

Para ver los logs: menú **Explore** → fuente de datos **Loki** → por ejemplo `{namespace="iam-api"} | json | level >= 50` (solo errores).

<p align="right"><a href="../operation.md">← Back</a></p>
