-- =============================================================
-- 03_tables.sql
-- Creates the streaming target table.
-- Run as: SYSADMIN (owns RAW schema)
-- =============================================================

USE ROLE SYSADMIN;

CREATE TABLE IF NOT EXISTS STREAMING_DB_{{ env | upper }}.RAW.STREAM_T1 (
    id    STRING,
    ts    TIMESTAMP,
    data  VARIANT
);
