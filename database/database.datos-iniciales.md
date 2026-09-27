# Datos iniciales: primeros usuarios ADMIN

Instructivo para insertar, en la base `iam_api`, los datos mínimos que hacen falta para poder usar el sistema por primera vez:

- El primer usuario **ADMIN**, con acceso tanto a `iam` como a `ticket-hub` (mismas credenciales para loguearse en los dos frontends) — nombre, apellido, email y hash de la contraseña generados por `wiki-hub/script/generate_admin_user_credentials.sh` (parte de `main.sh`).
- El primer **apps-user** de `ticket-hub-api`, con rol ADMIN sobre `infra-hub-api` y sobre `ticket-hub` — es el mismo `CLIENT_ID`/`CLIENT_SECRET` que generó `wiki-hub/script/main.sh` (ver `secrets-for-github-actions`/`microk8s.secrets.md`, Secret `ticket-hub-api-service-credentials`) y que `ticket-hub-api` usa para loguearse contra `iam-api` (`POST /apps-users/login`).

Sin esto, `database.crear-bases.md` te deja las tablas creadas pero completamente vacías — no hay ninguna cuenta con la que entrar a nada.

Requisito: haber corrido `database.crear-bases.md` (las 3 bases y sus tablas ya tienen que existir) y `wiki-hub/script/main.sh` (con la salida a mano: `ADMIN_NAME`, `ADMIN_LASTNAME`, `ADMIN_EMAIL`, `ADMIN_PASSWORD_HASH`, `CLIENT_SECRET`).

## 1. El `cliente_secret` del apps-user también necesita su hash

`internal_users.password` ya te lo da hasheado `generate_admin_user_credentials.sh` (usa el mismo `bcrypt` de `iam-api`, 10 rounds). Pero `apps_users.cliente_secret` no lo genera ningún script todavía — `generate_client_credentials.sh` solo te da el `CLIENT_SECRET` en texto plano (lo necesitás así, sin hashear, para el Secret real que consume `ticket-hub-api`). Para el `INSERT` de más abajo hace falta hashearlo aparte, con el mismo criterio:

```bash
cd iam-api
node -e "console.log(require('bcrypt').hashSync(process.argv[1], 10))" '<CLIENT_SECRET-real>'
```

## 2. El SQL

Todo esto es idempotente (se puede correr más de una vez sin duplicar nada), porque ninguna de estas tablas tiene una restricción `UNIQUE` sobre `name` (`apps_applications`, `apps_roles`) — hay que chequear "si no existe" a mano con `WHERE NOT EXISTS` en vez de `ON CONFLICT`.

```sql
-- =============================================================================
-- Datos iniciales de iam-api: aplicaciones, rol ADMIN de cada una, el primer
-- usuario humano ADMIN (con acceso a "iam" y a "ticket-hub"), y el primer
-- apps-user de servicio (ticket-hub-api -> infra-hub-api y ticket-hub).
-- Correr contra la base "iam_api".
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Aplicaciones (si ya las cargaste por otro medio, esto no duplica nada)
-- -----------------------------------------------------------------------------
INSERT INTO apps_applications (name, description)
SELECT 'iam', 'Identity provider'
WHERE NOT EXISTS (SELECT 1 FROM apps_applications WHERE name = 'iam');

INSERT INTO apps_applications (name, description)
SELECT 'ticket-hub', 'Frontend de tickets de infraestructura'
WHERE NOT EXISTS (SELECT 1 FROM apps_applications WHERE name = 'ticket-hub');

INSERT INTO apps_applications (name, description)
SELECT 'infra-hub-api', 'Ejecucion de operaciones de infraestructura'
WHERE NOT EXISTS (SELECT 1 FROM apps_applications WHERE name = 'infra-hub-api');

-- -----------------------------------------------------------------------------
-- 2) Rol ADMIN por aplicación
-- -----------------------------------------------------------------------------
INSERT INTO apps_roles (application_id, name, description)
SELECT a.id, 'ADMIN', 'Acceso total a la aplicacion'
FROM apps_applications a
WHERE a.name = 'iam'
  AND NOT EXISTS (
    SELECT 1 FROM apps_roles r WHERE r.application_id = a.id AND r.name = 'ADMIN'
  );

INSERT INTO apps_roles (application_id, name, description)
SELECT a.id, 'ADMIN', 'Acceso total a la aplicacion'
FROM apps_applications a
WHERE a.name = 'ticket-hub'
  AND NOT EXISTS (
    SELECT 1 FROM apps_roles r WHERE r.application_id = a.id AND r.name = 'ADMIN'
  );

INSERT INTO apps_roles (application_id, name, description)
SELECT a.id, 'ADMIN', 'Acceso total a la aplicacion'
FROM apps_applications a
WHERE a.name = 'infra-hub-api'
  AND NOT EXISTS (
    SELECT 1 FROM apps_roles r WHERE r.application_id = a.id AND r.name = 'ADMIN'
  );

-- -----------------------------------------------------------------------------
-- 3) Primer usuario ADMIN, con acceso a "iam" y a "ticket-hub"
--    name/lastname/email/password salen tal cual de generate_admin_user_credentials.sh
--    (ADMIN_NAME, ADMIN_LASTNAME, ADMIN_EMAIL, ADMIN_PASSWORD_HASH).
-- -----------------------------------------------------------------------------
INSERT INTO internal_users (name, lastname, email, password)
VALUES ('<ADMIN_NAME-real>', '<ADMIN_LASTNAME-real>', '<ADMIN_EMAIL-real>', '<ADMIN_PASSWORD_HASH-real>')
ON CONFLICT (email) DO NOTHING;

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = '<ADMIN_EMAIL-real>'
  AND a.name = 'iam'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = '<ADMIN_EMAIL-real>'
  AND a.name = 'ticket-hub'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

-- -----------------------------------------------------------------------------
-- 4) apps-user de servicio: ticket-hub-api -> infra-hub-api y ticket-hub
--    cliente_id tiene que ser exactamente "ticket-hub-api" (coincide con el
--    CLIENT_ID hardcodeado en generate_client_credentials.sh). cliente_secret
--    es el hash bcrypt del CLIENT_SECRET real generado por wiki-hub/script/main.sh.
--    Se le asigna rol ADMIN sobre las dos aplicaciones: "infra-hub-api" y
--    "ticket-hub" (esta última ya insertada en la sección 2).
-- -----------------------------------------------------------------------------
INSERT INTO apps_users (cliente_id, cliente_secret, name, description)
VALUES ('ticket-hub-api', '<hash-bcrypt-del-CLIENT_SECRET>', 'ticket-hub-api', 'Usuario de servicio de ticket-hub-api')
ON CONFLICT (cliente_id) DO NOTHING;

INSERT INTO apps_users_roles (app_user_id, application_id, role_id)
SELECT au.id, a.id, r.id
FROM apps_users au, apps_applications a, apps_roles r
WHERE au.cliente_id = 'ticket-hub-api'
  AND a.name = 'infra-hub-api'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM apps_users_roles aur
    WHERE aur.app_user_id = au.id AND aur.application_id = a.id AND aur.role_id = r.id
  );

INSERT INTO apps_users_roles (app_user_id, application_id, role_id)
SELECT au.id, a.id, r.id
FROM apps_users au, apps_applications a, apps_roles r
WHERE au.cliente_id = 'ticket-hub-api'
  AND a.name = 'ticket-hub'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM apps_users_roles aur
    WHERE aur.app_user_id = au.id AND aur.application_id = a.id AND aur.role_id = r.id
  );
```

## 3. Cómo correrlo

Igual que en `database.crear-bases.md`: conectado por SSH a `pcbox`, con este archivo en el mismo directorio (`wiki-hub/database/`), después de reemplazar los placeholders:

```bash
cat datos-iniciales.sql | microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -d iam_api -v ON_ERROR_STOP=1
```

(a diferencia de los 3 archivos de `database.crear-bases.md`, este SQL no crea ninguna base ni se conecta con `\c` — asume que ya estás en `iam_api`, por eso el `-d iam_api` explícito en el comando).

## 4. Verificar

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -d iam_api -c "
SELECT u.email, a.name AS aplicacion, r.name AS rol
FROM internal_users u
JOIN internal_users_roles ir ON ir.internal_user_id = u.id
JOIN apps_applications a ON a.id = ir.application_id
JOIN apps_roles r ON r.id = ir.role_id;
"
```

Tiene que aparecer una fila por cada aplicación a la que le diste acceso al admin (`iam` y `ticket-hub`), con el rol `ADMIN` en ambas. Para confirmar el apps-user de servicio:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -d iam_api -c "
SELECT au.cliente_id, a.name AS aplicacion, r.name AS rol
FROM apps_users au
JOIN apps_users_roles aur ON aur.app_user_id = au.id
JOIN apps_applications a ON a.id = aur.application_id
JOIN apps_roles r ON r.id = aur.role_id;
"
```
