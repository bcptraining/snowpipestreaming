-- =============================================================
-- 01_roles.sql
-- Creates service roles and transfers ownership to SYSADMIN.
--
-- STREAMING_INGEST_ROLE  : owns RAW schema; used by PySpark
-- STREAMING_TRANSFORM_ROLE: owns STG/INT/MART; used by transforms
--
-- Run as: SECURITYADMIN
-- =============================================================

USE ROLE SECURITYADMIN;

-- Ingest role: owns RAW, used by the PySpark streaming service user
CREATE ROLE IF NOT EXISTS STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON ROLE STREAMING_INGEST_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

GRANT ROLE STREAMING_INGEST_ROLE_{{ env | upper }} TO ROLE SYSADMIN;

-- Transform role: owns STG, INT, MART; reads from RAW
CREATE ROLE IF NOT EXISTS STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }}
    TO ROLE SYSADMIN;

GRANT ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }} TO ROLE SYSADMIN;
