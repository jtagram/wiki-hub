CREATE TABLE IF NOT EXISTS apps_applications (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(30)  NOT NULL UNIQUE,
    description VARCHAR(200) NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS apps_users (
    id              SERIAL PRIMARY KEY,
    cliente_id      VARCHAR(30)  NOT NULL UNIQUE,
    cliente_secret  VARCHAR(60)  NOT NULL,
    name            VARCHAR(30)  NOT NULL,
    description     VARCHAR(200) NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS internal_users (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(30) NOT NULL,
    lastname   VARCHAR(30) NOT NULL,
    email      VARCHAR(30) NOT NULL UNIQUE,
    password   VARCHAR(60) NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT now(),
    updated_at TIMESTAMP   NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS apps_roles (
    id             SERIAL PRIMARY KEY,
    application_id INTEGER      NOT NULL REFERENCES apps_applications(id),
    name           VARCHAR(30)  NOT NULL,
    description    VARCHAR(200) NOT NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP    NOT NULL DEFAULT now(),
    UNIQUE (application_id, name)
);

-- User -> application assignments. Roles hang off these rows (see the *_roles tables).
CREATE TABLE IF NOT EXISTS apps_users_applications (
    id             SERIAL PRIMARY KEY,
    app_user_id    INTEGER   NOT NULL REFERENCES apps_users(id),
    application_id INTEGER   NOT NULL REFERENCES apps_applications(id),
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (app_user_id, application_id)
);

-- The application of a role assignment is derived from its application assignment.
CREATE TABLE IF NOT EXISTS apps_users_roles (
    id                      SERIAL PRIMARY KEY,
    app_user_application_id INTEGER   NOT NULL REFERENCES apps_users_applications(id) ON DELETE CASCADE,
    role_id                 INTEGER   NOT NULL REFERENCES apps_roles(id),
    created_at              TIMESTAMP NOT NULL DEFAULT now(),
    updated_at              TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (app_user_application_id, role_id)
);

CREATE TABLE IF NOT EXISTS internal_users_applications (
    id               SERIAL PRIMARY KEY,
    internal_user_id INTEGER   NOT NULL REFERENCES internal_users(id),
    application_id   INTEGER   NOT NULL REFERENCES apps_applications(id),
    created_at       TIMESTAMP NOT NULL DEFAULT now(),
    updated_at       TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (internal_user_id, application_id)
);

CREATE TABLE IF NOT EXISTS internal_users_roles (
    id                           SERIAL PRIMARY KEY,
    internal_user_application_id INTEGER   NOT NULL REFERENCES internal_users_applications(id) ON DELETE CASCADE,
    role_id                      INTEGER   NOT NULL REFERENCES apps_roles(id),
    created_at                   TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (internal_user_application_id, role_id)
);


CREATE TABLE IF NOT EXISTS internal_users_connections (
    id                         SERIAL PRIMARY KEY,
    internal_user_id           INTEGER   NOT NULL REFERENCES internal_users(id),
    origin_application_id      INTEGER   NOT NULL REFERENCES apps_applications(id),
    destination_application_id INTEGER   NOT NULL REFERENCES apps_applications(id),
    created_at                 TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                 TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (internal_user_id, origin_application_id, destination_application_id)
);

CREATE TABLE IF NOT EXISTS apps_users_connections (
    id                         SERIAL PRIMARY KEY,
    app_user_id                INTEGER   NOT NULL REFERENCES apps_users(id),
    origin_application_id      INTEGER   NOT NULL REFERENCES apps_applications(id),
    destination_application_id INTEGER   NOT NULL REFERENCES apps_applications(id),
    created_at                 TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                 TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (app_user_id, origin_application_id, destination_application_id)
);
