# Variables de entorno de las APIs

## Qué es

Las APIs (`iam-api`, `infra-hub-api`, `ticket-hub-api`) reciben su configuración solo por variables de entorno. Al arrancar, un módulo las lee y las valida. Si falta o es inválida alguna, la API **no arranca**.

### Flujo: del Secret a la API

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. Secret de k8s │   │ 2. deployment    │   │ 3. Contenedor    │
│ postgres-        │──▶│    .yaml         │──▶│    de la API     │
│ credentials,     │   │ secretKeyRef o   │   │ variables en el  │
│ jwt-keys, etc.   │   │ value fijo       │   │ proceso          │
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │
┌──────────────────┐   ┌──────────────────┐   ┌────────▼─────────┐
│ 6. Servicios     │   │ 5. ConfigService │   │ 4. EnvModule     │
│ usan             │◀──│    valores ya    │◀──│    valida con    │
│ configService    │   │    validados     │   │    class-        │
│ .get('VAR')      │   │                  │   │    validator     │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

| Paso | Qué pasa | Dónde se define |
|---|---|---|
| 1 | Los valores sensibles viven en Secrets de Kubernetes del namespace de cada app | [create-secrets-for-three-environments.md](../03-cluster-secrets-and-access/create-secrets-for-three-environments.md) |
| 2 | El Deployment inyecta cada variable: desde un Secret (`secretKeyRef`) o con un valor fijo (`value`) | `deploy-hub-api/.github/workflows/<app>/manifests/deployment.yaml` |
| 3 | Kubernetes arranca el contenedor con esas variables | — |
| 4 | `EnvModule` valida que existan y tengan el tipo correcto | `<app>/src/common/config/` |
| 5-6 | El resto del código lee los valores con `ConfigService` | Servicios, conectores y módulos de cada API |

<p align="right"><a href="operation.md">← Back</a></p>
