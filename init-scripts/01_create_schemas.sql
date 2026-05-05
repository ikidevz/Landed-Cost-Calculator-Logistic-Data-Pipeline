-- =============================================================================
-- 01_create_schemas.sql
-- Creates schemas in landed_cost_db (database already created by 00_create_all_databases.sql)
-- =============================================================================

\c landed_cost_db

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS seeds;
CREATE SCHEMA IF NOT EXISTS marts;

ALTER DATABASE landed_cost_db SET search_path TO staging, seeds, marts;

ALTER SCHEMA staging OWNER TO CURRENT_USER;
ALTER SCHEMA seeds   OWNER TO CURRENT_USER;
ALTER SCHEMA marts   OWNER TO CURRENT_USER;