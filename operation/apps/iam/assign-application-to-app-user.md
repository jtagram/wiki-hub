# Asignar aplicación a usuario de aplicación

## Login

```mermaid
sequenceDiagram
    actor U as Persona
    participant UI as iam (Next.js)
    participant API as iam-api

    U->>UI: Ingresa email y contraseña
    UI->>API: POST /internal-users/login<br/>x-origin-application y x-target-application
    API->>API: Valida credenciales, acceso a las aplicaciones, conexión y roles
    API-->>UI: access_token (JWT RS256)
    UI->>UI: Guarda el token en la cookie httpOnly iam_access_token
    UI-->>U: Entra a iam
```

## Asignar aplicación

```mermaid
sequenceDiagram
    actor U as Persona
    participant UI as iam (Next.js)
    participant API as iam-api
    participant DB as DB de iam-api

    U->>UI: Elige usuario y aplicación y envía
    UI->>UI: Lee el token y valida que el id sea numérico
    UI->>API: POST /apps-users/{id}/applications<br/>Bearer (JWT del usuario)
    API->>API: Valida el JWT, que sea de iam y el rol ADMIN
    API->>DB: Busca el usuario y la aplicación
    DB-->>API: Ambos existen (si no: 404)
    API->>DB: Verifica que no esté ya asignada
    DB-->>API: No asignada (si lo está: 409)
    API->>DB: Guarda la asignación
    DB-->>API: Asignación creada
    API-->>UI: 201 con la asignación
    UI-->>U: Muestra el resultado
```

<p align="right"><a href="../../operation.md">← Back</a></p>
