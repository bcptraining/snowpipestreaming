-- =============================================================
-- 03_tables.sql
-- Creates the streaming target table.
-- Run as: STREAMING_INGEST_ROLE_<ENV>
-- =============================================================

USE ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

CREATE TABLE IF NOT EXISTS STREAMING_DB_{{ env | upper }}.RAW.STREAM_T1 (
    id    STRING,
    ts    TIMESTAMP,
    data  VARIANT
);
