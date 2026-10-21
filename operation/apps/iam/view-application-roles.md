# Ver roles de aplicaciones

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

## Ver roles

```mermaid
sequenceDiagram
    actor U as Persona
    participant UI as iam (Next.js)
    participant API as iam-api
    participant DB as DB de iam-api

    U->>UI: Abre la opción del menú
    UI->>UI: Lee el token de la cookie httpOnly
    UI->>API: GET /applications<br/>Bearer (JWT del usuario)
    API->>API: Valida el JWT, que sea de iam y el rol ADMIN
    API->>DB: Consulta todas las aplicaciones
    DB-->>API: Lista de aplicaciones
    API-->>UI: 200 con la lista
    UI->>API: GET /roles?applicationId=n<br/>una vez por aplicación
    API->>API: Valida el JWT, que sea de iam y el rol ADMIN
    API->>DB: Consulta los roles de la aplicación
    DB-->>API: Roles
    API-->>UI: 200 con los roles
    UI-->>U: Muestra cada aplicación con sus roles
```

<p align="right"><a href="iam.md">← Back</a></p>
