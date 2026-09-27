SELECT 'CREATE DATABASE ticket_hub_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ticket_hub_api')\gexec

CREATE TABLE IF NOT EXISTS database_management_tickets (
  id            SERIAL PRIMARY KEY,
  number        SERIAL UNIQUE,
  informer      VARCHAR(50) NOT NULL,
  assignee      VARCHAR(50) NOT NULL,
  department    VARCHAR(50) NOT NULL,
  subject       VARCHAR(500) NOT NULL,
  status        TEXT NOT NULL CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED')),
  description   VARCHAR(500) NOT NULL,
  response      TEXT NOT NULL,
  db_namespace  VARCHAR(50) NOT NULL,
  db_deployment VARCHAR(50) NOT NULL,
  db_name       VARCHAR(50) NOT NULL,
  sql_code      TEXT NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT now(),
  updated_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS database_provisioning_tickets (
  id            SERIAL PRIMARY KEY,
  number        SERIAL UNIQUE,
  informer      VARCHAR(50) NOT NULL,
  assignee      VARCHAR(50) NOT NULL,
  department    VARCHAR(50) NOT NULL,
  subject       VARCHAR(500) NOT NULL,
  status        TEXT NOT NULL CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED')),
  description   VARCHAR(500) NOT NULL,
  response      TEXT NOT NULL,
  db_namespace  VARCHAR(50) NOT NULL,
  db_deployment VARCHAR(50) NOT NULL,
  new_db_name   VARCHAR(63) NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT now(),
  updated_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kubectl_command_tickets (
  id              SERIAL PRIMARY KEY,
  number          SERIAL UNIQUE,
  informer        VARCHAR(50) NOT NULL,
  assignee        VARCHAR(50) NOT NULL,
  department      VARCHAR(50) NOT NULL,
  subject         VARCHAR(500) NOT NULL,
  status          TEXT NOT NULL CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED')),
  description     VARCHAR(500) NOT NULL,
  kubectl_command TEXT NOT NULL,
  response        TEXT NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT now(),
  updated_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kubernetes_manifest_tickets (
  id          SERIAL PRIMARY KEY,
  number      SERIAL UNIQUE,
  informer    VARCHAR(50) NOT NULL,
  assignee    VARCHAR(50) NOT NULL,
  department  VARCHAR(50) NOT NULL,
  subject     VARCHAR(500) NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED')),
  description VARCHAR(500) NOT NULL,
  namespace   VARCHAR(50) NOT NULL,
  action      TEXT NOT NULL CHECK (action IN ('apply', 'delete', 'create')),
  code_yaml   TEXT NOT NULL,
  response    TEXT NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT now(),
  updated_at  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS server_management_tickets (
  id            SERIAL PRIMARY KEY,
  number        SERIAL UNIQUE,
  informer      VARCHAR(50) NOT NULL,
  assignee      VARCHAR(50) NOT NULL,
  department    VARCHAR(50) NOT NULL,
  subject       VARCHAR(500) NOT NULL,
  status        TEXT NOT NULL CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED')),
  description   VARCHAR(500) NOT NULL,
  code_ansible  TEXT NOT NULL,
  response      TEXT NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT now(),
  updated_at    TIMESTAMP NOT NULL DEFAULT now()
);
