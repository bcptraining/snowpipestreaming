-- =============================================================
-- 05_grants.sql
-- 1. Grants INSERT and PIPE privileges to STREAMING_INGEST_ROLE.
-- 2. Grants RAW read access to STREAMING_TRANSFORM_ROLE so STG
--    views can read from RAW tables.
-- Run as: STREAMING_INGEST_ROLE_<ENV> (RAW owner)
-- =============================================================

USE ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

-- Streaming ingest privileges
GRANT INSERT ON TABLE STREAMING_DB_{{ env | upper }}.RAW.STREAM_T1
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT CREATE PIPE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

-- Allow transform role to read RAW (required to build STG views)
GRANT USAGE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};
