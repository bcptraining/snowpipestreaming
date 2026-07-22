-- =============================================================
-- 01_roles.sql
-- Creates the ingestion role and transfers ownership to SYSADMIN.
-- Run as: SECURITYADMIN
-- =============================================================

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

-- Grant the role to SYSADMIN so CI/CD (which runs as SYSADMIN) can USE it
GRANT ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }} TO ROLE SYSADMIN;
