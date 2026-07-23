-- =============================================================
-- 05_grants.sql
-- Grants operational privileges to the ingest role.
-- Run as: STREAMING_OBJECT_OWNER_ROLE_<ENV> (owns all objects)
-- =============================================================

USE ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

-- Ingest role: insert data and manage streaming pipe channels.
-- ALL/FUTURE TABLES is intentional -- RAW is exclusively the Snowpipe
-- Streaming landing zone. Every table here is an ingest target.
-- If a table in RAW should NOT be writable by this role, it belongs
-- in a separate schema, not RAW.
GRANT INSERT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT INSERT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
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
