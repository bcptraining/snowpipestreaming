-- =============================================================
-- 01_roles.sql
-- Creates all service roles for the Snowpipe Streaming solution.
--
-- Role hierarchy (Snowflake best practice):
--
--   SYSADMIN
--   '-- STREAMING_ADMIN_ROLE_<ENV>          ← solution umbrella (grant this to new admins)
--       +-- STREAMING_OBJECT_OWNER_ROLE_<ENV>  owns DB/schemas/warehouse; issues grants
--       +-- STREAMING_INGEST_ROLE_<ENV>        INSERT on RAW; used by PySpark service user
--       +-- STREAMING_TRANSFORM_ROLE_<ENV>     CREATE on STG/INT/MART; used by transforms
--       +-- STREAMING_API_ROLE_<ENV>           SELECT on MART; used by API service accounts
--       '-- STREAMING_DEVELOPER_ROLE_<ENV>     SELECT on all schemas; human developers
--
-- Run as: SECURITYADMIN
-- =============================================================

USE ROLE SECURITYADMIN;

-- Admin role: top-level umbrella for this solution.
-- Inherits all child roles -- grant this single role to anyone who needs
-- full access to manage or operate the streaming pipeline.
-- All child roles roll up here rather than directly to SYSADMIN.
CREATE ROLE IF NOT EXISTS STREAMING_ADMIN_ROLE_{{ env | upper }}
    COMMENT = 'Top-level umbrella role for the Snowpipe Streaming solution ({{ env | upper }} environment). Inherits all streaming child roles. Grant this to pipeline admins and tech leads who need full solution access.';

GRANT OWNERSHIP ON ROLE STREAMING_ADMIN_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

-- Admin role sits directly under SYSADMIN in the hierarchy
GRANT ROLE STREAMING_ADMIN_ROLE_{{ env | upper }} TO ROLE SYSADMIN;

-- Object owner role: scopes infrastructure management away from broad SYSADMIN.
-- SYSADMIN still creates the DB/warehouse (requires account-level privileges)
-- but immediately transfers ownership here.
CREATE ROLE IF NOT EXISTS STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }}
    COMMENT = 'Owns STREAMING_DB_{{ env | upper }} database, all schemas, and warehouse. Issues all privilege grants. Used by CI/CD only -- never grant to human users.';

GRANT OWNERSHIP ON ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

GRANT ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }}
    TO ROLE STREAMING_ADMIN_ROLE_{{ env | upper }};

-- Ingest role: used by the PySpark streaming service user
CREATE ROLE IF NOT EXISTS STREAMING_INGEST_ROLE_{{ env | upper }}
    COMMENT = 'INSERT on RAW tables + CREATE PIPE. Assigned to PYSPARK_USER_{{ env | upper }} service account only. Never grant to human users.';

GRANT OWNERSHIP ON ROLE STREAMING_INGEST_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

GRANT ROLE STREAMING_INGEST_ROLE_{{ env | upper }}
    TO ROLE STREAMING_ADMIN_ROLE_{{ env | upper }};

-- Transform role: used by transformation tools (dbt, etc.)
-- POLICY: In DEV, this role may be granted to individual developer personal accounts
--         to allow direct iteration on STG/INT/MART objects.
--         In PROD (and any higher environment), this role must NEVER be granted
--         to a human user -- all changes must flow through CI/CD only.
CREATE ROLE IF NOT EXISTS STREAMING_TRANSFORM_ROLE_{{ env | upper }}
    COMMENT = 'CREATE TABLE/VIEW/DYNAMIC TABLE/STREAM on STG/INT/MART + READ on RAW. DEV: may be granted to developer personal accounts for iteration. PROD: CI/CD pipeline only -- do not grant to human users.';

GRANT OWNERSHIP ON ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

GRANT ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }}
    TO ROLE STREAMING_ADMIN_ROLE_{{ env | upper }};

-- API role: read-only access to MART layer for application/API consumers
CREATE ROLE IF NOT EXISTS STREAMING_API_ROLE_{{ env | upper }}
    COMMENT = 'SELECT on MART schema only. Assign to API service accounts that consume finished MART data. No access to RAW, STG, or INT.';

GRANT OWNERSHIP ON ROLE STREAMING_API_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

GRANT ROLE STREAMING_API_ROLE_{{ env | upper }}
    TO ROLE STREAMING_ADMIN_ROLE_{{ env | upper }};
