-- =============================================================
-- 04_warehouse.sql
-- Creates the virtual warehouse. SYSADMIN retains ownership;
-- USAGE is granted to both service roles.
-- Run as: SYSADMIN
-- =============================================================

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS STREAMING_PIPE_WH_{{ env | upper }}
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE;

GRANT USAGE ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT USAGE ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};
