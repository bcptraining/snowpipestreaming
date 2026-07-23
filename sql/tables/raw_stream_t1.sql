-- =============================================================
-- raw_stream_t1.sql
-- RAW landing table for Snowpipe Streaming ingest.
-- Run as: STREAMING_OBJECT_OWNER_ROLE_<ENV> (owns RAW schema)
--
-- Add new RAW tables as separate files in this folder.
-- Naming convention: <layer>_<table_name>.sql
-- =============================================================

USE ROLE STREAMING_OBJECT_OWNER_ROLE_{{ env | upper }};

CREATE TABLE IF NOT EXISTS STREAMING_DB_{{ env | upper }}.RAW.STREAM_T1 (
    id    STRING,
    ts    TIMESTAMP,
    data  VARIANT
);
