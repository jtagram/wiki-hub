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

### Si falta una variable

`EnvModule` lanza `Missing required environment variable(s): <nombres>` y el proceso termina. En el deploy, el pod no queda listo y el paso `rollout status` del workflow falla ([workflow.md](workflow.md)). Para ver cuál falta: `kubectl logs` del pod.

## Dónde está implementado

En cada API, en `src/common/config/`:

| Archivo | Qué hace |
|---|---|
| `env.validation.ts` | Lista **todas** las variables que la API necesita y su regla (`@IsString`, `@IsIn`, etc.) |
| `env.module.ts` | Módulo global que carga y valida las variables al arrancar |
| `__tests__/env.validation.spec.ts` | Tests de la validación |

Es el **único lugar** donde se declaran las variables de una API, y la lista completa vive en `env.validation.ts`. Además, cada API tiene un `.env.example` para desarrollo local.

El código de negocio nunca lee `process.env`: pide el valor a `ConfigService`.

## Por qué centralizarlo

- **Falla temprano:** un error de configuración se detecta al arrancar, con el nombre de la variable, no en medio de un request.
- **Contrato explícito:** `env.validation.ts` es la lista de lo que la API necesita; no hay que buscar usos sueltos en el código.
- **Secretos fuera del código:** los valores sensibles llegan desde Secrets de Kubernetes, nunca desde archivos del repo.
- **Un cambio, un lugar:** agregar una variable se hace en `env.validation.ts`, `deployment.yaml` y `.env.example`.
- **Testeable:** `validate` es una función pura, se prueba sin levantar la app.

<p align="right"><a href="operation.md">← Back</a></p>
