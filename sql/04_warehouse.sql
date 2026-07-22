-- =============================================================
-- 04_warehouse.sql
-- Creates the virtual warehouse and transfers ownership.
-- Run as: SYSADMIN
-- =============================================================

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS STREAMING_PIPE_WH_{{ env | upper }}
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE;

GRANT OWNERSHIP ON WAREHOUSE STREAMING_PIPE_WH_{{ env | upper }}
    TO ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};
