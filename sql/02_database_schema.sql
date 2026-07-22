-- =============================================================
-- 02_database_schema.sql
-- Creates the database and all schemas. SYSADMIN retains database
-- ownership; schema ownership is split by responsibility:
--   RAW  → STREAMING_INGEST_ROLE
--   STG/INT/MART → STREAMING_TRANSFORM_ROLE
-- Run as: SYSADMIN
-- =============================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS STREAMING_DB_{{ env | upper }};

-- RAW: landing zone for Snowpipe Streaming ingest — no transforms
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.RAW;

-- STG: light transforms on top of RAW (views only, no stored data)
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.STG;

-- INT: intermediate joins and business logic — building blocks for MART (tables)
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.INT;

-- MART: modeled/aggregated layer for consumers (facts and dims)
CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.MART;

-- Both service roles need USAGE on the database
GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

-- RAW owned by ingest role
GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

-- STG, INT, MART owned by transform role
GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};
