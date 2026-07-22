-- =============================================================
-- 07_rsa_key.sql
-- Sets the RSA public key on the PySpark service user.
-- This file is rendered at runtime by the CI/CD pipeline;
-- RSA_PUBLIC_KEY_VALUE is injected from a GitHub Secret and
-- is NEVER stored in source control.
-- Run as: SECURITYADMIN
-- =============================================================

USE ROLE SECURITYADMIN;

ALTER USER PYSPARK_USER_{{ env | upper }}
    SET RSA_PUBLIC_KEY = '{{ rsa_public_key }}';
