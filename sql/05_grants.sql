-- =============================================================
-- 05_grants.sql
-- Grants operational privileges to the ingest role.
-- SYSADMIN owns all objects so all grants are issued centrally.
-- Run as: SYSADMIN
-- =============================================================

USE ROLE SYSADMIN;

-- Ingest role: insert data and manage streaming pipe channels
GRANT INSERT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT INSERT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT CREATE PIPE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};
