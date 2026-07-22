-- =============================================================
-- 03_tables.sql
-- Creates the streaming target table.
-- Run as: SNOWPIPE_STREAMING_INGEST_ROLE_<ENV>
-- =============================================================

USE ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};

CREATE OR REPLACE TABLE STREAMING_DB_{{ env | upper }}.RAW.STREAM_T1 (
    id    STRING,
    ts    TIMESTAMP,
    data  VARIANT
);
