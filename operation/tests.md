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

## Estructura de carpetas

### APIs (`iam-api`, `infra-hub-api`, `ticket-hub-api`)

```text
<api>/
├── jest.config.json               # Config de los unitarios (rootDir: src)
├── src/
│   └── modules/
│       └── internal-users/
│           ├── internal-users.service.ts
│           └── __tests__/
│               └── service/
│                   ├── create.spec.ts          # Un archivo por método
│                   └── find-all.spec.ts
└── test/
    ├── jest-e2e.json              # Config de los e2e (testRegex: .e2e-spec.ts)
    ├── helpers/                   # Utilidades compartidas por los e2e
    │   ├── app-test-app.ts        # Levanta la app real con las piezas externas reemplazadas
    │   ├── in-memory-db.ts        # Base de datos en memoria (pg-mem)
    │   ├── test-auth.ts           # Tokens JWT de prueba
    │   └── ...
    └── <area>/                    # Una carpeta por área funcional
        └── <accion>.e2e-spec.ts   # Un archivo por endpoint o acción
```

Ejemplo real en `iam-api/test/`:

```text
test/
├── helpers/
├── app.e2e-spec.ts
├── applications/    create-application · find-all-applications
├── auth/            internal-user-login · app-user-login
├── internal-users/  create-internal-user · assign-internal-user-role · ...
├── apps-users/      create-app-user · assign-app-user-role · ...
├── roles/           create-role · find-roles-by-application
└── jwks/            get-jwks
```

Las carpetas de `ticket-hub-api` son `create-ticket/`, `search-ticket/`, `update-ticket/` y `search-for-value-lists/`; las de `infra-hub-api`, `database-hub-api/`, `server-hub-api/` y `kubernates-hub-api/`.

### Frontends (`iam`, `ticket-hub`)

```text
<frontend>/
├── vitest.config.ts               # Dos proyectos: node (*.test.ts) y jsdom (*.test.tsx)
├── vitest.setup.ts
└── app/
    ├── api/
    │   └── applications/
    │       ├── route.ts
    │       └── __tests__/         # Pruebas de la ruta
    └── components/
        ├── Button.tsx
        └── __tests__/             # Pruebas de componentes (*.test.tsx)
```

## Cómo funcionan los e2e

Levantan el `AppModule` **real** (validación de entorno, logger, guards, filtros, módulos) y le hacen peticiones HTTP con Supertest. Solo se reemplazan los bordes externos:

| Borde | Cómo se reemplaza |
|---|---|
| Base de datos PostgreSQL | `pg-mem`: una base en memoria con las mismas entidades |
| Variables de entorno | Valores válidos de prueba, restaurados al cerrar |
| Tokens JWT | Se firman con un par de claves RSA generado en el test, con los mismos claims que emite el login real |
| Otras APIs | `ticket-hub-api` reemplaza sus conectores a `iam-api` e `infra-hub-api`; las descargas de JWKS se interceptan |

Así los e2e no necesitan Postgres ni red, y prueban de punta a punta la autenticación, los roles y los filtros de error ([authentication.md](authentication.md), [authorization.md](authorization.md), [error-filters.md](error-filters.md)).

## Cómo ejecutarlos

Desde la carpeta de cada API o frontend:

| Comando | Qué hace |
|---|---|
| `npm test` | Unitarios (en frontends, Vitest) |
| `npm run test:watch` | Unitarios, re-ejecutando al guardar |
| `npm run test:cov` | Unitarios con cobertura (solo APIs) |
| `npm run test:e2e` | e2e (solo APIs) |
| `npm run lint` | ESLint |
| `npm run format:check` | Verifica Prettier sin modificar |

## Cómo agregar un test

- **Código nuevo:** crea el `*.spec.ts` en el `__tests__/` de esa carpeta, con el nombre de lo que prueba.
- **Endpoint nuevo:** crea `test/<area>/<accion>.e2e-spec.ts`. Prueba el caso correcto y los de seguridad: sin token (`401`) y sin el rol necesario (`403`).
- **Utilidad de test compartida:** va en `test/helpers/`, no dentro de un spec.

## Dónde está implementado

| Qué | Dónde |
|---|---|
| Config de unitarios | `<api>/jest.config.json` |
| Config de e2e | `<api>/test/jest-e2e.json` |
| Utilidades de e2e | `<api>/test/helpers/` |
| Config de frontends | `<frontend>/vitest.config.ts` |
| Ejecución automática | Job `quality` en `deploy-hub-api/.github/workflows/deploy.yml` |

## Por qué esta organización

- **Los unitarios junto al código:** se encuentran fácil y se mueven con el archivo que prueban.
- **e2e aparte, por endpoint:** un archivo por acción mantiene cada prueba corta y fácil de ubicar.
- **App real, bordes reemplazados:** se prueba lo que de verdad corre, sin depender de servicios externos.
- **Compuerta antes de publicar:** ninguna imagen llega a Docker Hub con pruebas fallando.
- **Mismos comandos en todas las apps:** `npm test`, `npm run test:e2e`, `npm run lint`.

<p align="right"><a href="operation.md">← Back</a></p>
