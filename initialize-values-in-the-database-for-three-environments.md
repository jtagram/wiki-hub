# Inicializar los valores en las bases de datos de los 3 ambientes

Inserta en la base `iam_api` de cada VM los datos mínimos para usar el sistema por primera vez: aplicaciones, rol `ADMIN`, primer usuario administrador y la cuenta de servicio de `ticket-hub-api`.

Necesitas:

- Bases y tablas creadas en las 3 VMs — [create-databases-for-three-environments.md](create-databases-for-three-environments.md).
- El bloque de cada ambiente generado por [main.sh](generate-secret-values-for-microk8s/generate-secret-values-for-microk8s.md). Cada ambiente tiene su propio bloque, con valores distintos.

## Valores aleatorios a agregar

Cada SQL de este instructivo ya trae el nombre, el apellido y el email del administrador de su ambiente. Solo debes reemplazar a mano dos valores, que salen del bloque de ese ambiente generado por `main.sh`:

| Placeholder | Valor |
|---|---|
| `<ADMIN_PASSWORD_HASH>` | `ADMIN_PASSWORD_HASH` del bloque del ambiente |
| `<CLIENT_SECRET_HASH>` | `CLIENT_SECRET_HASH` del bloque del ambiente |

`ADMIN_EMAIL` es el usuario para iniciar sesión en `iam` y `ticket-hub`. `ADMIN_PASSWORD` no va en el SQL: es la contraseña con la que el admin inicia sesión. Guárdala en un lugar seguro.

`CLIENT_SECRET_HASH` debe corresponder al `CLIENT_SECRET` del Secret del mismo ambiente.

Los `INSERT` son idempotentes: se pueden volver a ejecutar sin duplicar datos. El archivo contiene datos sensibles: se borra de la VM al terminar cada ambiente.

---

## local

```bash
ssh -i ~/.ssh/pcbox_local ubuntu@pcbox-local
```

Dentro de la VM, crea el archivo:

```bash
nano initial-values.sql
```

Pega este SQL y reemplaza `<ADMIN_PASSWORD_HASH>` y `<CLIENT_SECRET_HASH>` por los valores del bloque `LOCAL`:

```sql
-- 1) Aplicaciones
INSERT INTO apps_applications (name, description)
VALUES ('iam', 'Identity provider')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('ticket-hub', 'Frontend de tickets de infraestructura')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('infra-hub-api', 'Ejecucion de operaciones de infraestructura')
ON CONFLICT (name) DO NOTHING;

-- 2) Rol ADMIN por aplicación
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

-- 3) Primer usuario ADMIN, con acceso a "iam" y a "ticket-hub"
INSERT INTO internal_users (name, lastname, email, password)
VALUES ('Admin', 'Local', 'admin.local@jtagram.local', '<ADMIN_PASSWORD_HASH>')
ON CONFLICT (email) DO NOTHING;

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = 'admin.local@jtagram.local'
  AND a.name = 'iam'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = 'admin.local@jtagram.local'
  AND a.name = 'ticket-hub'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

-- 4) Cuenta de servicio: ticket-hub-api -> infra-hub-api y ticket-hub
INSERT INTO apps_users (cliente_id, cliente_secret, name, description)
VALUES ('ticket-hub-api', '<CLIENT_SECRET_HASH>', 'ticket-hub-api', 'Usuario de servicio de ticket-hub-api')
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

Ejecútalo:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d iam_api -v ON_ERROR_STOP=1 < initial-values.sql
```

Verifica el usuario administrador:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d iam_api -c "
SELECT u.email, a.name AS aplicacion, r.name AS rol
FROM internal_users u
JOIN internal_users_roles ir ON ir.internal_user_id = u.id
JOIN apps_applications a ON a.id = ir.application_id
JOIN apps_roles r ON r.id = ir.role_id;
"
```

Verifica la cuenta de servicio:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_local -d iam_api -c "
SELECT au.cliente_id, a.name AS aplicacion, r.name AS rol
FROM apps_users au
JOIN apps_users_roles aur ON aur.app_user_id = au.id
JOIN apps_applications a ON a.id = aur.application_id
JOIN apps_roles r ON r.id = aur.role_id;
"
```

Borra el archivo y sal:

```bash
rm initial-values.sql
exit
```

---

## dev

```bash
ssh -i ~/.ssh/pcbox_dev ubuntu@pcbox-dev
```

Dentro de la VM, crea el archivo:

```bash
nano initial-values.sql
```

Pega este SQL y reemplaza `<ADMIN_PASSWORD_HASH>` y `<CLIENT_SECRET_HASH>` por los valores del bloque `DEV`:

```sql
-- 1) Aplicaciones
INSERT INTO apps_applications (name, description)
VALUES ('iam', 'Identity provider')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('ticket-hub', 'Frontend de tickets de infraestructura')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('infra-hub-api', 'Ejecucion de operaciones de infraestructura')
ON CONFLICT (name) DO NOTHING;

-- 2) Rol ADMIN por aplicación
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

-- 3) Primer usuario ADMIN, con acceso a "iam" y a "ticket-hub"
INSERT INTO internal_users (name, lastname, email, password)
VALUES ('Admin', 'Dev', 'admin.dev@jtagram.local', '<ADMIN_PASSWORD_HASH>')
ON CONFLICT (email) DO NOTHING;

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = 'admin.dev@jtagram.local'
  AND a.name = 'iam'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = 'admin.dev@jtagram.local'
  AND a.name = 'ticket-hub'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

-- 4) Cuenta de servicio: ticket-hub-api -> infra-hub-api y ticket-hub
INSERT INTO apps_users (cliente_id, cliente_secret, name, description)
VALUES ('ticket-hub-api', '<CLIENT_SECRET_HASH>', 'ticket-hub-api', 'Usuario de servicio de ticket-hub-api')
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

Ejecútalo:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d iam_api -v ON_ERROR_STOP=1 < initial-values.sql
```

Verifica el usuario administrador:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d iam_api -c "
SELECT u.email, a.name AS aplicacion, r.name AS rol
FROM internal_users u
JOIN internal_users_roles ir ON ir.internal_user_id = u.id
JOIN apps_applications a ON a.id = ir.application_id
JOIN apps_roles r ON r.id = ir.role_id;
"
```

Verifica la cuenta de servicio:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_dev -d iam_api -c "
SELECT au.cliente_id, a.name AS aplicacion, r.name AS rol
FROM apps_users au
JOIN apps_users_roles aur ON aur.app_user_id = au.id
JOIN apps_applications a ON a.id = aur.application_id
JOIN apps_roles r ON r.id = aur.role_id;
"
```

Borra el archivo y sal:

```bash
rm initial-values.sql
exit
```

---

## prod

```bash
ssh -i ~/.ssh/pcbox_prod ubuntu@pcbox-prod
```

Dentro de la VM, crea el archivo:

```bash
nano initial-values.sql
```

Pega este SQL y reemplaza `<ADMIN_PASSWORD_HASH>` y `<CLIENT_SECRET_HASH>` por los valores del bloque `PROD`:

```sql
-- 1) Aplicaciones
INSERT INTO apps_applications (name, description)
VALUES ('iam', 'Identity provider')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('ticket-hub', 'Frontend de tickets de infraestructura')
ON CONFLICT (name) DO NOTHING;

INSERT INTO apps_applications (name, description)
VALUES ('infra-hub-api', 'Ejecucion de operaciones de infraestructura')
ON CONFLICT (name) DO NOTHING;

-- 2) Rol ADMIN por aplicación
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

-- 3) Primer usuario ADMIN, con acceso a "iam" y a "ticket-hub"
INSERT INTO internal_users (name, lastname, email, password)
VALUES ('Admin', 'Prod', 'admin.prod@jtagram.local', '<ADMIN_PASSWORD_HASH>')
ON CONFLICT (email) DO NOTHING;

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = 'admin.prod@jtagram.local'
  AND a.name = 'iam'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

INSERT INTO internal_users_roles (internal_user_id, application_id, role_id)
SELECT u.id, a.id, r.id
FROM internal_users u, apps_applications a, apps_roles r
WHERE u.email = 'admin.prod@jtagram.local'
  AND a.name = 'ticket-hub'
  AND r.application_id = a.id AND r.name = 'ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM internal_users_roles ir
    WHERE ir.internal_user_id = u.id AND ir.application_id = a.id AND ir.role_id = r.id
  );

-- 4) Cuenta de servicio: ticket-hub-api -> infra-hub-api y ticket-hub
INSERT INTO apps_users (cliente_id, cliente_secret, name, description)
VALUES ('ticket-hub-api', '<CLIENT_SECRET_HASH>', 'ticket-hub-api', 'Usuario de servicio de ticket-hub-api')
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

Ejecútalo:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d iam_api -v ON_ERROR_STOP=1 < initial-values.sql
```

Verifica el usuario administrador:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d iam_api -c "
SELECT u.email, a.name AS aplicacion, r.name AS rol
FROM internal_users u
JOIN internal_users_roles ir ON ir.internal_user_id = u.id
JOIN apps_applications a ON a.id = ir.application_id
JOIN apps_roles r ON r.id = ir.role_id;
"
```

Verifica la cuenta de servicio:

```bash
microk8s kubectl exec -i -n databases deploy/postgres -- \
  psql -U jtagram_prod -d iam_api -c "
SELECT au.cliente_id, a.name AS aplicacion, r.name AS rol
FROM apps_users au
JOIN apps_users_roles aur ON aur.app_user_id = au.id
JOIN apps_applications a ON a.id = aur.application_id
JOIN apps_roles r ON r.id = aur.role_id;
"
```

Borra el archivo y sal:

```bash
rm initial-values.sql
exit
```

---

## Salida esperada

Las salidas son iguales en los tres ambientes, salvo el email. Ejemplo con `dev`. El orden de las filas puede variar.

Usuario administrador: una fila por aplicación, con rol `ADMIN` en ambas.

```
           email            | aplicacion | rol
----------------------------+------------+-------
 admin.dev@jtagram.local    | iam        | ADMIN
 admin.dev@jtagram.local    | ticket-hub | ADMIN
(2 rows)
```

Cuenta de servicio: `ticket-hub-api` con acceso a las dos aplicaciones.

```
   cliente_id   |  aplicacion   |  rol
----------------+---------------+-------
 ticket-hub-api | infra-hub-api | ADMIN
 ticket-hub-api | ticket-hub    | ADMIN
(2 rows)
```
