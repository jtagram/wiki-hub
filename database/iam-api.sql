SELECT 'CREATE DATABASE iam_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'iam_api')\gexec

\c iam_api

CREATE TABLE IF NOT EXISTS apps_applications (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(30)  NOT NULL,
    description VARCHAR(200) NOT NULL
);

CREATE TABLE IF NOT EXISTS apps_users (
    id              SERIAL PRIMARY KEY,
    cliente_id      VARCHAR(30)  NOT NULL UNIQUE,
    cliente_secret  VARCHAR(60)  NOT NULL,
    name            VARCHAR(30)  NOT NULL,
    description     VARCHAR(200) NOT NULL
);

CREATE TABLE IF NOT EXISTS internal_users (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(30) NOT NULL,
    lastname VARCHAR(30) NOT NULL,
    email    VARCHAR(30) NOT NULL UNIQUE,
    password VARCHAR(60) NOT NULL
);

CREATE TABLE IF NOT EXISTS apps_roles (
    id             SERIAL PRIMARY KEY,
    application_id INTEGER      NOT NULL REFERENCES apps_applications(id),
    name           VARCHAR(30)  NOT NULL,
    description    VARCHAR(200) NOT NULL
);

CREATE TABLE IF NOT EXISTS apps_users_roles (
    id             SERIAL PRIMARY KEY,
    app_user_id    INTEGER NOT NULL REFERENCES apps_users(id),
    application_id INTEGER NOT NULL REFERENCES apps_applications(id),
    role_id        INTEGER NOT NULL REFERENCES apps_roles(id)
);

CREATE TABLE IF NOT EXISTS apps_users_applications (
    id             SERIAL PRIMARY KEY,
    app_user_id    INTEGER NOT NULL REFERENCES apps_users(id),
    application_id INTEGER NOT NULL REFERENCES apps_applications(id)
);

CREATE TABLE IF NOT EXISTS internal_users_roles (
    id               SERIAL PRIMARY KEY,
    internal_user_id INTEGER NOT NULL REFERENCES internal_users(id),
    application_id   INTEGER NOT NULL REFERENCES apps_applications(id),
    role_id          INTEGER NOT NULL REFERENCES apps_roles(id)
);

CREATE TABLE IF NOT EXISTS internal_users_applications (
    id               SERIAL PRIMARY KEY,
    internal_user_id INTEGER NOT NULL REFERENCES internal_users(id),
    application_id   INTEGER NOT NULL REFERENCES apps_applications(id)
);
