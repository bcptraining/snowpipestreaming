-- =============================================================
-- 02_database_schema.sql
-- SYSADMIN creates the database and schemas (requires account-level
-- CREATE DATABASE privilege). SECURITYADMIN then transfers ownership
-- to STREAMING_OBJECT_OWNER_ROLE (MANAGE GRANTS makes this idempotent
-- on re-runs). All grants are issued by the owner role.
-- =============================================================

-- Step 1: Create objects as SYSADMIN
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS STREAMING_DB_{{ env | upper }};

-- RAW: landing zone for Snowpipe Streaming ingest -- no transforms
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.RAW;

-- STG: light transforms on top of RAW (views only, no stored data)
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.STG;

-- INT: intermediate joins and business logic -- building blocks for MART (tables)
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.INT;

-- MART: modeled/aggregated layer for consumers (facts and dims)
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.MART;

-- Step 2: Transfer ownership via SECURITYADMIN (MANAGE GRANTS = idempotent)
USE ROLE SECURITYADMIN;

GRANT OWNERSHIP ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

-- Step 3: Issue all grants as the object owner
USE ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

-- Ingest role: navigate to database and RAW schema only
GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

-- Ingest role: USAGE on RAW schema only (STREAMING_OBJECT_OWNER_ROLE retains ownership)
GRANT USAGE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

-- Transform role: USAGE on RAW (read source data) + USAGE on STG/INT/MART (create objects)
GRANT USAGE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE       ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE VIEW  ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE TABLE ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

-- DML on STG tables: needed when CI/CD defines the STG table schema
-- and STREAMING_TRANSFORM_ROLE performs INSERT/MERGE (VARIANT materialization pattern)
GRANT SELECT   ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT INSERT   ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT UPDATE   ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT TRUNCATE ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE              ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE TABLE       ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE VIEW        ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE DYNAMIC TABLE ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE STREAM  ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE                  ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE TABLE           ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE VIEW            ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE DYNAMIC TABLE   ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE MATERIALIZED VIEW ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

-- API role: read-only access to MART only -- no visibility into RAW/STG/INT
GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_API_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_API_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_API_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_API_ROLE_{{ env | upper }};

GRANT SELECT ON ALL VIEWS IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_API_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE VIEWS IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_API_ROLE_{{ env | upper }};
