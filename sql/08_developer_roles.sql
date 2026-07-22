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

CREATE ROLE IF NOT EXISTS STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }} TO ROLE SYSADMIN;

-- Database and warehouse (SYSADMIN owns all objects)
USE ROLE SYSADMIN;

GRANT USAGE ON DATABASE  STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT USAGE ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

-- RAW: read access
GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

-- STG: read access
GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL VIEWS IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE VIEWS IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

-- INT: read access
GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_DEVELOPER_ROLE_{{ env | upper }};
