-- =============================================================
-- 05_grants.sql
-- Grants INSERT and PIPE privileges to the ingestion role.
-- Run as: SNOWPIPE_STREAMING_INGEST_ROLE_<ENV>
-- Note: ownership alone is insufficient for streaming ingest.
-- =============================================================

USE ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT INSERT ON TABLE STREAMING_DB_{{ env | upper }}.RAW.STREAM_T1
    TO ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT CREATE PIPE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};
