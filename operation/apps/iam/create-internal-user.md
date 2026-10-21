# Crear usuario interno

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

## Crear usuario interno

```mermaid
sequenceDiagram
    actor U as Persona
    participant UI as iam (Next.js)
    participant API as iam-api
    participant DB as DB de iam-api

    U->>UI: Completa el formulario y lo envía
    UI->>UI: Lee el token de la cookie httpOnly
    UI->>API: POST /internal-users<br/>Bearer (JWT del usuario)
    API->>API: Valida el JWT, que sea de iam y el rol ADMIN
    API->>DB: Busca un usuario con ese email
    DB-->>API: No existe (si existe: 409)
    API->>API: Aplica hash bcrypt a la contraseña
    API->>DB: Guarda el usuario con la contraseña hasheada
    DB-->>API: Usuario creado
    API-->>UI: 201 con el usuario
    UI-->>U: Muestra el resultado
```

<p align="right"><a href="iam.md">← Back</a></p>
