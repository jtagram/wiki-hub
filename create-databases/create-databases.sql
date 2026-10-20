SELECT 'CREATE DATABASE iam_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'iam_api')\gexec

SELECT 'CREATE DATABASE infra_hub_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'infra_hub_api')\gexec

SELECT 'CREATE DATABASE ticket_hub_api'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ticket_hub_api')\gexec
