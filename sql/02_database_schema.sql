-- =============================================================
-- 02_database_schema.sql
-- Creates the database and all schemas. SYSADMIN owns everything.
-- Service roles receive only the privileges they need to operate
-- (principle of least privilege — no ownership for service accounts).
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

-- Ingest role: navigate to database and RAW schema only
GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT USAGE ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_INGEST_ROLE_{{ env | upper }};

-- Transform role: navigate to database + read RAW + create objects in STG/INT/MART
GRANT USAGE ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE  ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT SELECT ON ALL TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT SELECT ON FUTURE TABLES IN SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE       ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE VIEW  ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE TABLE ON SCHEMA STREAMING_DB_{{ env | upper }}.STG
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE       ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE TABLE ON SCHEMA STREAMING_DB_{{ env | upper }}.INT
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT USAGE       ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};

GRANT CREATE TABLE ON SCHEMA STREAMING_DB_{{ env | upper }}.MART
    TO ROLE STREAMING_TRANSFORM_ROLE_{{ env | upper }};
