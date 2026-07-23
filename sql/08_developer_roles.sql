-- =============================================================
-- 08_developer_roles.sql
-- Creates a developer role with read access to all schemas.
-- Grants are issued by each schema's owner role.
--
-- To assign to a developer (run manually):
--   GRANT ROLE STREAMING_DEVELOPER_ROLE_<ENV> TO USER <username>;
--
-- Run as: SECURITYADMIN \u2192 role creation
--         SYSADMIN \u2192 DB/warehouse grants
--         STREAMING_INGEST_ROLE_<ENV>   \u2192 RAW grants
--         STREAMING_TRANSFORM_ROLE_<ENV> \u2192 STG/INT/MART grants
-- =============================================================

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS STREAMING_DEVELOPER_ROLE_{{ env | upper }}
    COMMENT = 'SELECT on all schemas in STREAMING_DB_{{ env | upper }}. Assign to human developers in all environments. No write access -- read-only for data exploration and debugging.';

GRANT ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }}
    TO ROLE STREAMING_ADMIN_ROLE_{{ env | upper }};

-- Database and warehouse (SYSADMIN owns these)
USE ROLE SYSADMIN;
GRANT USAGE ON DATABASE  STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT USAGE ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

-- RAW: read access -- granted by STREAMING_INGEST_ROLE (RAW owner)
USE ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

-- STG, INT, MART: read access -- granted by STREAMING_TRANSFORM_ROLE (owner)
USE ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL VIEWS  IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE VIEWS IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL STREAMS IN SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE STREAMS IN SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};
