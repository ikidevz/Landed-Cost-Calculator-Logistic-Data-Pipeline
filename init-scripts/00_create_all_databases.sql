-- =============================================================================
-- 00_create_all_databases.sql (FIXED)
-- =============================================================================

-- Switch to default database
\c postgres

-- -----------------------------------------------------------------------------
-- 1. CREATE DATABASES (no DO block)
-- -----------------------------------------------------------------------------

CREATE DATABASE landed_cost_db
    WITH ENCODING = 'UTF8'
    TEMPLATE = template0;

CREATE DATABASE metabase_db
    WITH ENCODING = 'UTF8'
    TEMPLATE = template0;

-- -----------------------------------------------------------------------------
-- 2. CREATE USER
-- -----------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = 'metabase_admin_user'
    ) THEN
        CREATE ROLE metabase_admin_user
            WITH LOGIN
            PASSWORD 'metabase_admin_password'
            NOSUPERUSER NOCREATEDB NOCREATEROLE;
    END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- 3. LANDED COST SETUP
-- -----------------------------------------------------------------------------

\c landed_cost_db

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS seeds;
CREATE SCHEMA IF NOT EXISTS marts;

ALTER DATABASE landed_cost_db SET search_path TO staging, seeds, marts;

ALTER SCHEMA staging OWNER TO CURRENT_USER;
ALTER SCHEMA seeds   OWNER TO CURRENT_USER;
ALTER SCHEMA marts   OWNER TO CURRENT_USER;

-- -----------------------------------------------------------------------------
-- 4. METABASE FIX (IMPORTANT)
-- -----------------------------------------------------------------------------

\c metabase_db

GRANT ALL ON SCHEMA public TO metabase_admin_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO metabase_admin_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO metabase_admin_user;

-- -----------------------------------------------------------------------------
-- 5. DB PERMISSIONS
-- -----------------------------------------------------------------------------

\c postgres

GRANT ALL PRIVILEGES ON DATABASE landed_cost_db TO CURRENT_USER;
GRANT ALL PRIVILEGES ON DATABASE metabase_db TO metabase_admin_user;

-- -----------------------------------------------------------------------------
-- 6. VERIFY
-- -----------------------------------------------------------------------------

\echo '=== DATABASES ==='
SELECT datname FROM pg_database 
WHERE datname IN ('airflow', 'landed_cost_db', 'metabase_db');

\echo '=== DONE ==='