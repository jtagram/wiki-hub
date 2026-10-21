# Crear rol de aplicación

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

## Crear rol

```mermaid
sequenceDiagram
    actor U as Persona
    participant UI as iam (Next.js)
    participant API as iam-api
    participant DB as DB de iam-api

    U->>UI: Completa el formulario y lo envía
    UI->>UI: Lee el token de la cookie httpOnly
    UI->>API: POST /roles<br/>Bearer (JWT del usuario)
    API->>API: Valida el JWT, que sea de iam y el rol ADMIN
    API->>DB: Busca la aplicación
    DB-->>API: Aplicación (si no existe: 404)
    API->>DB: Busca un rol con ese nombre en la aplicación
    DB-->>API: No existe (si existe: 409)
    API->>DB: Guarda el rol
    DB-->>API: Rol creado
    API-->>UI: 201 con el rol
    UI-->>U: Muestra el resultado
```

<p align="right"><a href="../../operation.md">← Back</a></p>
