-- =============================================================
-- 02_database_schema.sql
-- Creates the database and raw schema, then transfers ownership
-- to the ingestion role.
-- Run as: SYSADMIN
-- =============================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS STREAMING_DB_{{ env | upper }};

CREATE SCHEMA IF NOT EXISTS STREAMING_DB_{{ env | upper }}.RAW;

GRANT OWNERSHIP ON DATABASE STREAMING_DB_{{ env | upper }}
    TO ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};

GRANT OWNERSHIP ON SCHEMA STREAMING_DB_{{ env | upper }}.RAW
    TO ROLE SNOWPIPE_STREAMING_INGEST_ROLE_{{ env | upper }};
