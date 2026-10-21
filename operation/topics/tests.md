# Tests

## Qué es

Las pruebas automáticas del ecosistema. Hay tres tipos, y los workflows de dev y prod las ejecutan **antes de publicar la imagen**: si algo falla, no se publica ni se despliega ([workflow.md](workflow.md)).

| Tipo | Qué prueba | Herramienta | Dónde vive | Archivos |
|---|---|---|---|---|
| Unitario | Una pieza aislada (servicio, guard, filtro, DTO) | Jest | Junto al código, en `__tests__/` | `*.spec.ts` |
| e2e (APIs) | Un endpoint completo, con la app real levantada | Jest + Supertest | `test/` de cada API | `*.e2e-spec.ts` |
| Frontend | Rutas de la API del frontend y componentes | Vitest | Junto al código, en `__tests__/` | `*.test.ts`, `*.test.tsx` |

### Flujo: del código a la imagen

```text
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 1. ESLint        │   │ 2. Prettier      │   │ 3. Unitarios     │
│ npm run lint     │──▶│ npm run          │──▶│ npm test         │
│                  │   │ format:check     │   │                  │
└──────────────────┘   └──────────────────┘   └────────┬─────────┘
                                                       │
┌──────────────────┐   ┌──────────────────┐   ┌────────▼─────────┐
│ 6. Deploy        │   │ 5. Build y push  │   │ 4. e2e (APIs)    │
│                  │◀──│ de la imagen     │◀──│ npm run test:e2e │
│                  │   │                  │   │                  │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

| Paso | Qué pasa | Comando o dónde |
|---|---|---|
| 1 | ESLint revisa el código | `npm run lint` |
| 2 | Prettier verifica el formato sin modificar archivos | `npm run format:check` |
| 3 | Se ejecutan los tests unitarios | `npm test` |
| 4 | Se ejecutan los tests e2e con la app real | `npm run test:e2e` |
| 5 | Se construye y publica la imagen | Job `build-and-push` ([workflow.md](workflow.md)) |
| 6 | Se despliega, tras la aprobación manual | Job `deploy` ([workflow.md](workflow.md)) |

Los pasos 1 a 4 son el job `quality` de `deploy.yml`, en `deploy-hub-api`. Los frontends ejecutan los pasos 1 a 3: su workflow pasa `run_e2e_tests: false`. El flujo de local no ejecuta tests.

<p align="right"><a href="../operation.md">← Back</a></p>
