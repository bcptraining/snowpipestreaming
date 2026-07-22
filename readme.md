# Snowpipe Streaming — High-Performance Architecture

This repo implements [Snowflake's Snowpipe Streaming high-performance SDK](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-getting-started) with automated Snowflake object provisioning via GitHub Actions. No Terraform required.

---

## What this repo does

Provisions all Snowflake infrastructure needed to run the Snowpipe Streaming SDK demo:

| Object | Name (DEV) | Name (PROD) |
|---|---|---|
| Role | `SNOWPIPE_STREAMING_INGEST_ROLE_DEV` | `SNOWPIPE_STREAMING_INGEST_ROLE_PROD` |
| Database | `STREAMING_DB_DEV` | `STREAMING_DB_PROD` |
| Schema | `STREAMING_DB_DEV.RAW` | `STREAMING_DB_PROD.RAW` |
| Table | `STREAMING_DB_DEV.RAW.STREAM_T1` | `STREAMING_DB_PROD.RAW.STREAM_T1` |
| Warehouse | `STREAMING_PIPE_WH_DEV` | `STREAMING_PIPE_WH_PROD` |
| Service User | `PYSPARK_USER_DEV` | `PYSPARK_USER_PROD` |

---

## Repo structure

```
.github/
  workflows/
    deploy-snowflake.yml    # CI/CD pipeline — deploys on push to develop or main
sql/
  01_roles.sql              # Role creation and ownership
  02_database_schema.sql    # Database and schema
  03_tables.sql             # Target streaming table
  04_warehouse.sql          # Virtual warehouse
  05_grants.sql             # INSERT and PIPE grants
  06_users.sql              # PySpark service user
  07_rsa_key.sql            # RSA public key assignment (injected from secrets)
scripts/
  deploy.ps1                # Local deployment script (Windows/PowerShell)
```

---

## Prerequisites

- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation) (`pip install snowflake-cli-labs`)
- [SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql-install-config) (for bootstrap steps)
- OpenSSL
- A Snowflake account with a user that has `ACCOUNTADMIN` or `SECURITYADMIN` + `SYSADMIN` + `USERADMIN`

---

## Applying this to a new Snowflake account

### Step 1 — Bootstrap the CI/CD deploy user (one-time, run manually)

These commands are run once by a human admin. After this, everything else is automated.

```powershell
# 1. Create the CI/CD service account
snowsql -q "CREATE USER IF NOT EXISTS CICD_DEPLOY_USER
    DEFAULT_ROLE = SYSADMIN
    MUST_CHANGE_PASSWORD = FALSE;"

# 2. Grant it the roles needed to run the SQL files
snowsql -q "USE ROLE SECURITYADMIN;
GRANT ROLE SYSADMIN      TO USER CICD_DEPLOY_USER;
GRANT ROLE SECURITYADMIN TO USER CICD_DEPLOY_USER;
GRANT ROLE USERADMIN     TO USER CICD_DEPLOY_USER;"

# 3. Generate a dedicated RSA key pair for CICD_DEPLOY_USER

# Windows (PowerShell):
openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out cicd_rsa_key.p8
openssl rsa -in cicd_rsa_key.p8 -pubout -out cicd_rsa_key.pub

# macOS/Linux (bash):
# openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out cicd_rsa_key.p8
# openssl rsa -in cicd_rsa_key.p8 -pubout -out cicd_rsa_key.pub

# 4. Set the public key on the user

# Windows (PowerShell):
$cicdPubk = (Get-Content cicd_rsa_key.pub | Select-Object -Skip 1 | Select-Object -SkipLast 1) -join ""

# macOS/Linux (bash):
# cicdPubk=$(grep -v "KEY-" cicd_rsa_key.pub | tr -d '\n')

snowsql -q "ALTER USER CICD_DEPLOY_USER SET RSA_PUBLIC_KEY='$cicdPubk';"
```

> **Security:** `cicd_rsa_key.p8` and `*.pub` are gitignored. Never commit key files.

### Step 2 — Generate a key pair for the PySpark service user

**Windows (PowerShell):**
```powershell
openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out pyspark_user_rsa_key.p8
openssl rsa -in pyspark_user_rsa_key.p8 -pubout -out pyspark_user_rsa_key.pub

# Get the stripped public key value (no headers) — you'll need this for GitHub Secrets
(Get-Content pyspark_user_rsa_key.pub | Select-Object -Skip 1 | Select-Object -SkipLast 1) -join ""
```

**macOS/Linux (bash):**
```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out pyspark_user_rsa_key.p8
openssl rsa -in pyspark_user_rsa_key.p8 -pubout -out pyspark_user_rsa_key.pub

# Get the stripped public key value (no headers)
grep -v "KEY-" pyspark_user_rsa_key.pub | tr -d '\n'
```

### Step 3 — Configure the Snowflake CLI local connection

```powershell
snow connection add --connection-name default `
  --account <your_account_identifier> `
  --user CICD_DEPLOY_USER `
  --authenticator snowflake_jwt `
  --private-key-path "$PWD\cicd_rsa_key.p8"
```

### Step 4 — Configure GitHub Environments and Secrets

In the GitHub repo go to **Settings → Environments** and create two environments:
- `development` — no restrictions
- `production` — add required reviewers for manual approval

Add the following **Secrets** to each environment (Settings → Environments → \<env\> → Add secret):

| Secret | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | Your account identifier, e.g. `xy12345.us-east-1` |
| `SNOWFLAKE_ADMIN_USER` | `CICD_DEPLOY_USER` |
| `SNOWFLAKE_ADMIN_PRIVATE_KEY` | Full contents of `cicd_rsa_key.p8` including `-----BEGIN/END-----` headers |
| `SNOWFLAKE_PYSPARK_RSA_PUBLIC_KEY` | Stripped public key string from Step 2 (no headers) |

### Step 5 — Test locally before pushing

```powershell
# Optional: also run step 07 (RSA key assignment)
$env:SNOWFLAKE_RSA_PUBLIC_KEY = (Get-Content pyspark_user_rsa_key.pub | Select-Object -Skip 1 | Select-Object -SkipLast 1) -join ""

.\scripts\deploy.ps1 -Env dev
```

### Step 6 — Push to trigger CI/CD

```
feature/* → develop   →  DEV deploy (automatic)
develop   → main      →  PROD deploy (requires approval)
```

---

## Branching strategy

| Branch | Purpose | Deploys to |
|---|---|---|
| `feature/*` | New work — branch from `develop`, merged via PR | Nothing (no direct push) |
| `develop` | Integration branch — receives feature PRs | DEV (automatic on PR merge) |
| `main` | Production-ready — receives `develop` PRs | PROD (manual approval required) |

**Workflow:**
```
git checkout develop && git pull origin develop
git checkout -b feature/my-change
# ... make changes, commit ...
git push origin feature/my-change
# Open PR on GitHub: feature/my-change → develop
# PR merge triggers DEV deployment automatically
```

> Never push directly to `develop` or `main`.

---

## Tutorial progress

| Step | Description | Status |
|---|---|---|
| Step 1 | Configure Snowflake objects | Done |
| Step 2 | Configure `profile.json` authentication profile | Pending |
| Step 3 | Set up the SDK demo project | Pending |
| Step 4 | Run the demo application | Pending |
| Step 5 | Verify ingested data | Pending |

Full tutorial: https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-getting-started
