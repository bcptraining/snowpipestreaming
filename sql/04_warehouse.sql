-- =============================================================
-- 04_warehouse.sql
-- SYSADMIN creates the warehouse (requires CREATE WAREHOUSE on account).
-- Ownership is transferred to STREAMING_OBJECT_OWNER_ROLE which then
-- issues USAGE grants to service roles.
-- =============================================================

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS STREAMING_PIPE_WH_{{ env | upper }}
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE;

-- Transfer ownership via SECURITYADMIN (idempotent on re-runs)
USE ROLE SECURITYADMIN;

GRANT OWNERSHIP ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

USE ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

GRANT USAGE ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT USAGE ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};
