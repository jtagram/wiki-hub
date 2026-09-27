SELECT 'CREATE DATABASE infra_hub_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'infra_hub_api')\gexec

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS infrastructure_operations_log (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department       TEXT NOT NULL CHECK (department IN ('DATABASE', 'KUBERNETES', 'SERVER')),
  number_of_ticket INTEGER NOT NULL,
  instruction      TEXT NOT NULL,
  response         TEXT NOT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT now(),
  updated_at       TIMESTAMP NOT NULL DEFAULT now()
);
