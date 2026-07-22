-- =============================================================
-- 06_users.sql
-- Creates the PySpark service user and assigns the ingestion role.
-- Run as: USERADMIN
-- NOTE: RSA_PUBLIC_KEY is set separately via a secrets pipeline
--       step and is NOT stored in source control.
-- =============================================================

USE ROLE USERADMIN;

CREATE USER IF NOT EXISTS PYSPARK_USER_{{ env | upper }}
    DEFAULT_ROLE      = STREAMING_INGEST_ROLE_{{ env | upper }}
    DEFAULT_WAREHOUSE = STREAMING_PIPE_WH_{{ env | upper }}
    MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE STREAMING_INGEST_ROLE_{{ env | upper }}
    TO USER PYSPARK_USER_{{ env | upper }};
