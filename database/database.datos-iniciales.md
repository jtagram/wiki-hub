# Datos iniciales: primeros usuarios ADMIN

Instructivo para insertar, en la base `iam_api`, los datos mínimos que hacen falta para poder usar el sistema por primera vez:

Requisito: haber corrido `database.crear-bases.md` (las 3 bases y sus tablas ya tienen que existir) y `wiki-hub/script/main.sh` (con la salida a mano: `ADMIN_NAME`, `ADMIN_LASTNAME`, `ADMIN_EMAIL`, `ADMIN_PASSWORD_HASH`, `CLIENT_SECRET_HASH`).

Conectate por SSH al servidor `pcbox` sobre su IP de Tailscale (ver `pcbox/pcbox.bootstrap.md`):

```bash
ssh -i deploy_key jhon@IP_TAILSCALE
```

## 1. El SQL

Creá un archivo `datos-iniciales.sql`. Antes de usarlo, reemplazá cada placeholder `<...-real>` por el valor real correspondiente, generado por `wiki-hub/script/main.sh`:

- `<ADMIN_NAME-real>` / `<ADMIN_LASTNAME-real>` / `<ADMIN_EMAIL-real>` / `<ADMIN_PASSWORD_HASH-real>` → `ADMIN_NAME` / `ADMIN_LASTNAME` / `ADMIN_EMAIL` / `ADMIN_PASSWORD_HASH` de la salida del script.
- `<CLIENT_SECRET_HASH-real>` → `CLIENT_SECRET_HASH` de la misma salida.

```sql
-- -----------------------------------------------------------------------------
-- 1) Aplicaciones
-- -----------------------------------------------------------------------------
INSERT INTO apps_applications (name, description)
VALUES ('iam', 'Identity provider')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('ticket-hub', 'Frontend de tickets de infraestructura')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('infra-hub-api', 'Ejecucion de operaciones de infraestructura')
ON CONFLICT (name) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2) Rol ADMIN por aplicación
-- -----------------------------------------------------------------------------
INSERT INTO apps_roles (application_id, name, description)
SELECT a.id, 'ADMIN', 'Acceso total a la aplicacion'
FROM apps_applications a
WHERE a.name = 'iam'
ON CONFLICT (application_id, name) DO NOTHING;

INSERT INTO apps_roles (application_id, name, description)
SELECT a.id, 'ADMIN', 'Acceso total a la aplicacion'
FROM apps_applications a
WHERE a.name = 'ticket-hub'
ON CONFLICT (application_id, name) DO NOTHING;

INSERT INTO apps_roles (application_id, name, description)
SELECT a.id, 'ADMIN', 'Acceso total a la aplicacion'
FROM apps_applications a
WHERE a.name = 'infra-hub-api'
ON CONFLICT (application_id, name) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3) Primer usuario ADMIN, con acceso a "iam" y a "ticket-hub"
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
-- -----------------------------------------------------------------------------
INSERT INTO apps_users (cliente_id, cliente_secret, name, description)
VALUES ('ticket-hub-api', '<CLIENT_SECRET_HASH-real>', 'ticket-hub-api', 'Usuario de servicio de ticket-hub-api')
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

## 2. Cómo correrlo

Con el archivo `datos-iniciales.sql` ya creado y sus placeholders reemplazados, ejecutá:

```bash
cat datos-iniciales.sql | microk8s kubectl exec -i -n databases deploy/postgres -- psql -U <POSTGRES_USER-real> -d iam_api -v ON_ERROR_STOP=1
```

## 3. Verificar

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
