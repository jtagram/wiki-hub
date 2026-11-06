-- One-off migration for EXISTING iam-api databases.
--
-- Moves role assignments under the user-application assignment:
--   internal_users_roles(internal_user_id, application_id, role_id)
--     -> internal_users_roles(internal_user_application_id, role_id)
--   apps_users_roles(app_user_id, application_id, role_id)
--     -> apps_users_roles(app_user_application_id, role_id)
--
-- Run once with: psql -v ON_ERROR_STOP=1 -f iam-api-migrate-roles-to-assignments.sql
-- Fresh databases do not need it: create-tables/iam-api.sql already has the new shape.
-- Re-running it is safe: every step checks the current state first.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) Internal users: UNIQUE (internal_user_id, application_id) on assignments
-- ---------------------------------------------------------------------------

-- Drop duplicate assignment rows, keeping the lowest id of each pair.
DELETE FROM internal_users_applications a
USING internal_users_applications b
WHERE a.internal_user_id = b.internal_user_id
  AND a.application_id = b.application_id
  AND a.id > b.id;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'internal_users_applications_user_application_key'
    ) THEN
        ALTER TABLE internal_users_applications
            ADD CONSTRAINT internal_users_applications_user_application_key
            UNIQUE (internal_user_id, application_id);
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2) Internal users: create the assignments that only existed through a role
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'internal_users_roles' AND column_name = 'application_id'
    ) THEN
        INSERT INTO internal_users_applications (internal_user_id, application_id)
        SELECT DISTINCT r.internal_user_id, r.application_id
        FROM internal_users_roles r
        WHERE NOT EXISTS (
            SELECT 1 FROM internal_users_applications a
            WHERE a.internal_user_id = r.internal_user_id
              AND a.application_id = r.application_id
        );
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3) Internal users: point each role at its assignment, then drop application_id
-- ---------------------------------------------------------------------------

ALTER TABLE internal_users_roles
    ADD COLUMN IF NOT EXISTS internal_user_application_id INTEGER;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'internal_users_roles' AND column_name = 'application_id'
    ) THEN
        UPDATE internal_users_roles r
        SET internal_user_application_id = a.id
        FROM internal_users_applications a
        WHERE a.internal_user_id = r.internal_user_id
          AND a.application_id = r.application_id
          AND r.internal_user_application_id IS NULL;
    END IF;
END $$;

-- Collapse repeated (assignment, role) pairs, keeping the lowest id.
DELETE FROM internal_users_roles a
USING internal_users_roles b
WHERE a.internal_user_application_id = b.internal_user_application_id
  AND a.role_id = b.role_id
  AND a.id > b.id;

ALTER TABLE internal_users_roles
    ALTER COLUMN internal_user_application_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'internal_users_roles_internal_user_application_id_fkey'
    ) THEN
        ALTER TABLE internal_users_roles
            ADD CONSTRAINT internal_users_roles_internal_user_application_id_fkey
            FOREIGN KEY (internal_user_application_id)
            REFERENCES internal_users_applications(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'internal_users_roles_assignment_role_key'
    ) THEN
        ALTER TABLE internal_users_roles
            ADD CONSTRAINT internal_users_roles_assignment_role_key
            UNIQUE (internal_user_application_id, role_id);
    END IF;
END $$;

-- 4) The application is now derived from the assignment. Dropping the column
--    also drops its foreign key.
ALTER TABLE internal_users_roles DROP COLUMN IF EXISTS application_id;
ALTER TABLE internal_users_roles DROP COLUMN IF EXISTS internal_user_id;

-- ---------------------------------------------------------------------------
-- App users: same steps, mirrored
-- ---------------------------------------------------------------------------

-- 1) Unique assignments
DELETE FROM apps_users_applications a
USING apps_users_applications b
WHERE a.app_user_id = b.app_user_id
  AND a.application_id = b.application_id
  AND a.id > b.id;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'apps_users_applications_user_application_key'
    ) THEN
        ALTER TABLE apps_users_applications
            ADD CONSTRAINT apps_users_applications_user_application_key
            UNIQUE (app_user_id, application_id);
    END IF;
END $$;

-- 2) Assignments that only existed through a role
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'apps_users_roles' AND column_name = 'application_id'
    ) THEN
        INSERT INTO apps_users_applications (app_user_id, application_id)
        SELECT DISTINCT r.app_user_id, r.application_id
        FROM apps_users_roles r
        WHERE NOT EXISTS (
            SELECT 1 FROM apps_users_applications a
            WHERE a.app_user_id = r.app_user_id
              AND a.application_id = r.application_id
        );
    END IF;
END $$;

-- 3) Point each role at its assignment
ALTER TABLE apps_users_roles
    ADD COLUMN IF NOT EXISTS app_user_application_id INTEGER;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'apps_users_roles' AND column_name = 'application_id'
    ) THEN
        UPDATE apps_users_roles r
        SET app_user_application_id = a.id
        FROM apps_users_applications a
        WHERE a.app_user_id = r.app_user_id
          AND a.application_id = r.application_id
          AND r.app_user_application_id IS NULL;
    END IF;
END $$;

DELETE FROM apps_users_roles a
USING apps_users_roles b
WHERE a.app_user_application_id = b.app_user_application_id
  AND a.role_id = b.role_id
  AND a.id > b.id;

ALTER TABLE apps_users_roles
    ALTER COLUMN app_user_application_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'apps_users_roles_app_user_application_id_fkey'
    ) THEN
        ALTER TABLE apps_users_roles
            ADD CONSTRAINT apps_users_roles_app_user_application_id_fkey
            FOREIGN KEY (app_user_application_id)
            REFERENCES apps_users_applications(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'apps_users_roles_assignment_role_key'
    ) THEN
        ALTER TABLE apps_users_roles
            ADD CONSTRAINT apps_users_roles_assignment_role_key
            UNIQUE (app_user_application_id, role_id);
    END IF;
END $$;

-- 4) Drop the redundant columns
ALTER TABLE apps_users_roles DROP COLUMN IF EXISTS application_id;
ALTER TABLE apps_users_roles DROP COLUMN IF EXISTS app_user_id;

COMMIT;
