# Snowpipe Streaming — High-Performance Architecture

> **This is a platform/infrastructure repo.** It provisions and manages Snowflake objects only — roles, schemas, tables, warehouses, and access grants. It does not contain transformation logic (dbt models, Snowpark code, etc.). Those belong in a separate transform repo that uses the roles and schemas this repo creates.

This repo implements [Snowflake's Snowpipe Streaming high-performance SDK](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-getting-started) with automated Snowflake object provisioning via GitHub Actions.

## Purpose

This repo serves two goals:

**1. Working example of Snowpipe Streaming**
A deployable, end-to-end implementation of the Snowflake Snowpipe Streaming high-performance SDK — from infrastructure provisioning through CI/CD to RSA key authentication. Use it as a reference or starting point for real streaming pipelines.

**2. Conversation-starter for architecture standards**
The RBAC model and layered schema design (`RAW → STG → INT → MART`) are intentionally aligned with [dbt](https://docs.getdbt.com/docs/build/projects) conventions, even though dbt is not currently in scope. The goal is to establish naming and access patterns now that will feel natural if/when a transformation tool is introduced. Consider this a working draft of your team's data platform standards — the structure is here to provoke discussion, not prescribe answers.

> **Note on dbt:** The transform layer design (role names, schema names, object naming conventions) is dbt-ready but not dbt-dependent. The same patterns apply whether you use dbt, pure SQL, Snowpark, or any other transformation approach.

---

## Deployment safety

### Is it safe to merge when there is already data in Snowflake?

**Generally yes** — the pipeline is designed to be idempotent:

| Operation | Safe? | Why |
|---|---|---|
| `CREATE ROLE/DATABASE/SCHEMA/TABLE IF NOT EXISTS` | ✅ | Skips if object already exists |
| `GRANT ...` | ✅ | Grants are additive — never remove access |
| `CREATE WAREHOUSE IF NOT EXISTS` | ✅ | Skips if already exists |
| `GRANT OWNERSHIP ON SCHEMA/DATABASE/WAREHOUSE` | ⚠️ | Re-asserts ownership on every deploy — intended, but could surprise if ownership was manually changed |
| `ALTER USER ... SET RSA_PUBLIC_KEY` | ⚠️ | Replaces the service user's RSA key on every deploy — see key rotation guidance below |

**What would cause harm:** Introducing a `DROP`, `TRUNCATE`, or `CREATE OR REPLACE TABLE` statement into a SQL file. The pipeline has no such statements today. Code review (Sourcery + PR approvals) is the protection against this.

### RSA key rotation

The PySpark service user (`PYSPARK_USER_<ENV>`) authenticates via RSA key. Every deploy sets the key from the `SNOWFLAKE_PYSPARK_RSA_PUBLIC_KEY` GitHub Secret. Rotation procedure:

1. Generate a new key pair locally
2. Set the **new** public key as `RSA_PUBLIC_KEY_2` on the user (Snowflake supports two keys simultaneously — zero-downtime rotation):
   ```sql
   ALTER USER PYSPARK_USER_DEV SET RSA_PUBLIC_KEY_2 = '<new_public_key>';
   ```
3. Update `SNOWFLAKE_PYSPARK_RSA_PUBLIC_KEY` GitHub Secret with the new public key
4. Verify the streaming client connects successfully with the new key
5. Remove the old key:
   ```sql
   ALTER USER PYSPARK_USER_DEV UNSET RSA_PUBLIC_KEY;
   ```
6. The next deploy will set `RSA_PUBLIC_KEY` from the updated secret — this is now the new key

> Never update the GitHub Secret and trigger a deploy simultaneously with a live streaming client — the deploy will overwrite the key before the client has been updated.

### Making infrastructure changes safely

| Change type | Guidance |
|---|---|
| Add a new role or schema | Safe — `IF NOT EXISTS` patterns prevent conflicts |
| Add a new table to RAW | Add to a new `SQL` file — `CREATE TABLE IF NOT EXISTS` is safe with existing data |
| Modify a table schema (add column) | Use `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` — do NOT use `CREATE OR REPLACE TABLE` |
| Rename a role | Manual step required — drop old role grants, create new role, re-grant; cannot be done idempotently |
| Remove a role or schema | Manual cleanup required before merging — DROP statements should never be in the pipeline |
| Rotate RSA keys | Follow the two-key rotation procedure above |

---

## What this repo does

Provisions all Snowflake infrastructure needed to run the Snowpipe Streaming SDK demo:

| Object | Pattern | Purpose |
|---|---|---|
| Object Owner Role | `STREAMING_OBJECT_OWNER_ROLE_<ENV>` | Owns DB, schemas, warehouse; issues all grants |
| Ingest Role | `STREAMING_INGEST_ROLE_<ENV>` | INSERT on RAW + CREATE PIPE; used by PySpark service user |
| Transform Role | `STREAMING_TRANSFORM_ROLE_<ENV>` | CREATE on STG/INT/MART + READ on RAW by a developer (in DEV) or transform tool (dbt) |
| Developer Role | `STREAMING_DEVELOPER_ROLE_<ENV>` | SELECT on all schemas; assigned to human developers |
| Database | `STREAMING_DB_<ENV>` | Single database containing all schemas for this pipeline |
| Schema (RAW) | `STREAMING_DB_<ENV>.RAW` | Snowpipe Streaming landing zone — no transforms |
| Schema (STG) | `STREAMING_DB_<ENV>.STG` | Light transforms on RAW — views only, no stored data |
| Schema (INT) | `STREAMING_DB_<ENV>.INT` | Intermediate joins and business logic — materialized tables |
| Schema (MART) | `STREAMING_DB_<ENV>.MART` | Consumer-facing facts and dimensions |
| Tables (1 example) | `STREAMING_DB_<ENV>.RAW.STREAM_T1` | Target table for Snowpipe Streaming ingest |
| Warehouse | `STREAMING_PIPE_WH_<ENV>` | Virtual warehouse for query execution |
| Service User | `PYSPARK_USER_<ENV>` | RSA key-authenticated user for PySpark streaming client |

---

## Repo structure

```
.github/
  workflows/
    deploy-snowflake.yml    # CI/CD pipeline — deploys on push to develop or main
sql/
  01_roles.sql              # Role creation and hierarchy
  02_database_schema.sql    # Database, schemas, and privilege grants
  03_tables.sql             # Placeholder — table definitions moved to sql/tables/
  04_warehouse.sql          # Virtual warehouse
  05_grants.sql             # Operational grants (INSERT, CREATE PIPE)
  06_users.sql              # PySpark service user
  07_rsa_key.sql            # RSA public key assignment (injected from secrets)
  08_developer_roles.sql    # Developer and API read roles
  tables/
    raw_stream_t1.sql       # Add new tables here — one file per table
docs/
  stg-layer-guide.md        # Developer guide: staging layer for VARIANT sources
scripts/
  deploy.ps1                # Local deployment script (Windows/PowerShell)
```

---

## Naming conventions

### Schemas

| Schema | Purpose | Object types |
|---|---|---|
| `RAW` | Raw Snowpipe Streaming ingest — no transforms | Tables |
| `STG` | Light transforms on RAW — rename, cast, type, deduplicate | Views (default) or **Tables** for VARIANT/large sources — see [STG Developer Guide](docs/stg-layer-guide.md) |
| `INT` | Intermediate joins and business logic — building blocks for MART | Tables (materialized) |
| `MART` | Modeled/aggregated layer for consumers | Tables |

### Object names

Given source table `RAW.STREAM_T1`:

| Layer | Pattern | Example |
|---|---|---|
| RAW | `<stream_name>` | `STREAM_T1` |
| STG | `STG_<source>__<object>` | `STG_STREAM__T1` |
| INT | `INT_<subject>__<verb>` | `INT_STREAM_EVENTS__JOINED` |
| MART facts | `FCT_<business_process>` | `FCT_STREAM_EVENTS` |
| MART dims | `DIM_<entity>` | `DIM_DEVICE` |

> The double underscore in STG names (`__`) is the dbt convention for separating source system from object name.

### Roles

| Role | Purpose |
|---|---|
| `STREAMING_ADMIN_ROLE_<ENV>` | Solution umbrella — inherits all child roles; grant to pipeline admins instead of individual child roles |
| `STREAMING_OBJECT_OWNER_ROLE_<ENV>` | Owns DB, schemas, warehouse — issues all grants; minimizes SYSADMIN footprint |
| `STREAMING_INGEST_ROLE_<ENV>` | INSERT on RAW + CREATE PIPE — used by PySpark streaming service user only |
| `STREAMING_TRANSFORM_ROLE_<ENV>` | CREATE TABLE/VIEW/DYNAMIC TABLE/STREAM on STG/INT/MART + READ on RAW. DEV: grant to developers for direct iteration. PROD: assign to transformation tool service account (dbt, Snowpark, etc.) running via its own CI/CD pipeline |
| `STREAMING_API_ROLE_<ENV>` | SELECT on MART only — assigned to API/application service accounts |
| `STREAMING_DEVELOPER_ROLE_<ENV>` | Human developer role — SELECT on all schemas |

> **`CICD_DEPLOY_USER`** is a Snowflake **user** (not a role) bootstrapped manually in Step 1. It is granted SYSADMIN + SECURITYADMIN + USERADMIN and authenticates via RSA key. It is the identity the GitHub Actions pipeline runs as. It is not provisioned by the deploy pipeline itself.

---

## Prerequisites

- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation) (`pip install snowflake-cli-labs`)
- [SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql-install-config) (for bootstrap steps)
- OpenSSL
- A Snowflake account with a user that has `ACCOUNTADMIN` or `SECURITYADMIN` + `SYSADMIN` + `USERADMIN`

---

## Applying this to a new Snowflake account

> **Who does what:**
> - **Steps 1–2** — Run once by a single admin when bootstrapping a new account. No other team member repeats these.
> - **Step 3A** — Read-only developers (analysts): request `STREAMING_DEVELOPER_ROLE_DEV`, use Snowsight.
> - **Step 3B** — Transform developers (data engineers): request `STREAMING_TRANSFORM_ROLE_DEV`, iterate on models in DEV.
> - **Step 4** — Local infrastructure deploys: requires SYSADMIN-level access. Practical only on personal trial accounts.
> - **Steps 5–7** — One-time repo setup, then CI/CD handles all subsequent deployments automatically.

### Step 1 — Bootstrap the CI/CD deploy user (admin only, one-time)

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

### Step 2 — Generate a key pair for the PySpark service user (admin only, one-time)

> This key authenticates the `PYSPARK_USER_<ENV>` service account used by the streaming client. Generate it once, put the public key in GitHub Secrets, and store the private key securely. **No other developer needs this key.**

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

### Step 3 — Get DEV environment access

This step is about getting the right Snowflake role for your work. Choose based on what you need to do — none of these options allow you to run `deploy.ps1` (that requires SYSADMIN-level access, covered in Step 4).

**Option A — Read-only access (analysts, BI consumers)**

Request `STREAMING_DEVELOPER_ROLE_DEV` from your Snowflake admin:
```sql
GRANT ROLE STREAMING_DEVELOPER_ROLE_DEV TO USER <your_username>;
```
Connect via Snowsight or SnowSQL with standard credentials. No CLI needed. SELECT on all schemas.

**Option B — Transform development (data engineers building STG/INT/MART models in DEV)**

Request `STREAMING_TRANSFORM_ROLE_DEV` from your Snowflake admin:
```sql
GRANT ROLE STREAMING_TRANSFORM_ROLE_DEV TO USER <your_username>;
```
This gives CREATE TABLE/VIEW/DYNAMIC TABLE on STG/INT/MART plus INSERT/MERGE for iterating on transform models directly in DEV. Use Snowsight for most work, or configure the Snowflake CLI for running SQL scripts:

```powershell
# Windows (PowerShell)
snow connection add --connection-name default `
  --account <your_account_identifier> `
  --user <your_snowflake_username> `
  --role STREAMING_TRANSFORM_ROLE_DEV `
  --authenticator snowflake_jwt `
  --private-key-path "$PWD\<your_rsa_key>.p8"
```

```bash
# macOS/Linux
snow connection add --connection-name default \
  --account <your_account_identifier> \
  --user <your_snowflake_username> \
  --role STREAMING_TRANSFORM_ROLE_DEV \
  --authenticator snowflake_jwt \
  --private-key-path ./your_rsa_key.p8
```

> This role allows direct development in DEV only. In PROD all changes go through CI/CD — do not request `STREAMING_TRANSFORM_ROLE_PROD` for personal accounts.

### Step 4 — Run infrastructure deployments locally (optional — tech leads / personal trial account only)

Running `deploy.ps1` provisions Snowflake infrastructure (roles, schemas, warehouses). It requires SYSADMIN + SECURITYADMIN + USERADMIN — the same privileges as `CICD_DEPLOY_USER`. In a shared corporate account, most developers will not have these. **This is most practical on a personal Snowflake trial account.**

Configure the CLI connection with admin-level access:

```powershell
# Windows (PowerShell)
snow connection add --connection-name default `
  --account <your_account_identifier> `
  --user <your_snowflake_username> `
  --role SYSADMIN `
  --authenticator snowflake_jwt `
  --private-key-path "$PWD\<your_rsa_key>.p8"
```

```bash
# macOS/Linux
snow connection add --connection-name default \
  --account <your_account_identifier> \
  --user <your_snowflake_username> \
  --role SYSADMIN \
  --authenticator snowflake_jwt \
  --private-key-path ./your_rsa_key.p8
```

Then run the deploy:

```powershell
# Set the PySpark RSA public key so step 07 runs
$env:SNOWFLAKE_RSA_PUBLIC_KEY = (Get-Content pyspark_user_rsa_key.pub | Select-Object -Skip 1 | Select-Object -SkipLast 1) -join ""

.\scripts\deploy.ps1 -Env dev
```

### Step 5 — Configure GitHub Environments and Secrets

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
