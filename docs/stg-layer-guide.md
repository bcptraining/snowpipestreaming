# Developer Guide: Building the Staging Layer for VARIANT Source Data

This guide applies when your `RAW` tables contain Snowpipe Streaming data where the `data` column is `VARIANT` (JSON/semi-structured). For simple typed sources, standard STG views are sufficient — this guide covers the materialized table pattern required for large or complex VARIANT payloads.

> **DEV vs PROD access model**
>
> | Environment | Who can write to STG/INT/MART |
> |---|---|
> | DEV | CI/CD pipeline **and** developers with `STREAMING_TRANSFORM_ROLE_DEV` on their personal account |
> | PROD (and higher) | CI/CD pipeline only — `STREAMING_TRANSFORM_ROLE_PROD` must never be granted to a human user |
>
> The INSERT/MERGE patterns in this guide are intended for DEV iteration. In PROD, equivalent logic is deployed through the CI/CD pipeline via a PR. This separation ensures that PROD changes are always reviewed, versioned, and auditable.

---

## Why STG views don't work for VARIANT at scale

The default STG pattern uses views — a stateless lens over RAW that renames and casts columns. This is fine for structured sources. For VARIANT:

| Problem | Impact |
|---|---|
| JSON parsing runs on every query | Expensive at scale |
| Views cannot prune micro-partitions on parsed fields | Full scans on every downstream query |
| No incremental loading | Entire RAW table reprocessed each time |
| Lateral flattening inside views causes row explosion | Unpredictable compute cost |

**Solution:** Materialize STG as an **incremental table** that parses once and stores the result.

---

## Goals — the staging layer contract

The STG layer must remain:

- **Thin** — extract top-level fields only; preserve raw for everything else
- **Incremental** — load only new rows since the last run
- **Predictable** — stable schema that downstream INT/MART models can depend on
- **Cheap** — parse once, read many times
- **Schema-stable** — when the JSON schema evolves, add columns; don't break existing ones
- **Flexible** — keep `data_raw VARIANT` so downstream consumers can access fields not yet extracted

STG is **not** a modeling layer. No joins. No business logic. No aggregations.

---

## Naming conventions for this repo

Following the project's double-underscore convention for VARIANT sources:

| Object | Pattern | Example |
|---|---|---|
| Main staging table | `STG_<source>__<entity>` | `STG_STREAM__T1` |
| Flattened array table | `STG_<source>__<entity>__<array>` | `STG_STREAM__T1__ITEMS` |

All STG objects live in `STREAMING_DB_<ENV>.STG` and are created/owned by `STREAMING_TRANSFORM_ROLE_<ENV>`.

---

## 1. Create a materialized staging table (not a view)

```sql
CREATE TABLE IF NOT EXISTS STREAMING_DB_DEV.STG.STG_STREAM__T1 (
    -- Extracted top-level fields (typed)
    event_id        STRING,
    event_ts        TIMESTAMP,
    device_id       STRING,
    event_type      STRING,

    -- Ingestion metadata (required — see section 6)
    ingest_time     TIMESTAMP,
    source_pipe     STRING,

    -- Raw payload preserved for schema evolution and replay
    data_raw        VARIANT
);
```

---

## 2. Load incrementally using a watermark

Use `ingest_time` from `RAW.STREAM_T1` as the watermark. Insert only new rows.

**Insert pattern (append-only sources):**
```sql
INSERT INTO STREAMING_DB_DEV.STG.STG_STREAM__T1
SELECT
    data:id::string           AS event_id,
    ts                        AS event_ts,
    data:device_id::string    AS device_id,
    data:event_type::string   AS event_type,
    CURRENT_TIMESTAMP()       AS ingest_time,
    'STREAM_T1'               AS source_pipe,
    data                      AS data_raw
FROM STREAMING_DB_DEV.RAW.STREAM_T1
WHERE ts > (SELECT COALESCE(MAX(event_ts), '1970-01-01') FROM STREAMING_DB_DEV.STG.STG_STREAM__T1);
```

**MERGE pattern (sources with updates/deduplication):**
```sql
MERGE INTO STREAMING_DB_DEV.STG.STG_STREAM__T1 t
USING (
    SELECT
        data:id::string           AS event_id,
        ts                        AS event_ts,
        data:device_id::string    AS device_id,
        data:event_type::string   AS event_type,
        CURRENT_TIMESTAMP()       AS ingest_time,
        'STREAM_T1'               AS source_pipe,
        data                      AS data_raw
    FROM STREAMING_DB_DEV.RAW.STREAM_T1
    WHERE ts > (SELECT COALESCE(MAX(event_ts), '1970-01-01') FROM STREAMING_DB_DEV.STG.STG_STREAM__T1)
) s
ON t.event_id = s.event_id
WHEN NOT MATCHED THEN INSERT (event_id, event_ts, device_id, event_type, ingest_time, source_pipe, data_raw)
    VALUES (s.event_id, s.event_ts, s.device_id, s.event_type, s.ingest_time, s.source_pipe, s.data_raw)
WHEN MATCHED AND s.event_ts > t.event_ts THEN UPDATE SET
    event_ts = s.event_ts,
    device_id = s.device_id,
    event_type = s.event_type,
    data_raw = s.data_raw;
```

---

## 3. Preserve the raw VARIANT column

Every STG table must include the original JSON payload as `data_raw VARIANT`. This enables:
- Downstream access to fields not yet extracted
- Schema evolution without reprocessing
- Replay/reprocessing from STG without going back to RAW

Name it consistently: `data_raw`, `event_raw`, or `payload_raw` — pick one and use it everywhere.

---

## 4. Extract only top-level fields

Extract **only the fields required by downstream INT/MART models**. Do not extract everything upfront.

```sql
-- ✅ Extract what's needed
data:device_id::string    AS device_id,
data:event_type::string   AS event_type,
data                      AS data_raw   -- keep full payload

-- ❌ Do not do this
data:metrics.clicks::number          AS clicks,
data:metrics.impressions::number     AS impressions,
data:location.lat::float             AS lat,
data:location.lon::float             AS lon
-- ... extracting 40 fields that INT doesn't use yet
```

---

## 5. Flatten arrays into separate staging tables

If the JSON payload contains arrays, create a **separate STG table** for each array. Do not flatten inside the main staging table.

```sql
CREATE TABLE IF NOT EXISTS STREAMING_DB_DEV.STG.STG_STREAM__T1__ITEMS (
    event_id    STRING,
    event_ts    TIMESTAMP,
    item_id     STRING,
    price       FLOAT,
    ingest_time TIMESTAMP
);

INSERT INTO STREAMING_DB_DEV.STG.STG_STREAM__T1__ITEMS
SELECT
    s.event_id,
    s.event_ts,
    f.value:item_id::string  AS item_id,
    f.value:price::float     AS price,
    CURRENT_TIMESTAMP()      AS ingest_time
FROM STREAMING_DB_DEV.STG.STG_STREAM__T1 s,
     LATERAL FLATTEN(input => s.data_raw:items) f
WHERE s.ingest_time > (SELECT COALESCE(MAX(ingest_time), '1970-01-01') FROM STREAMING_DB_DEV.STG.STG_STREAM__T1__ITEMS);
```

---

## 6. Always include ingestion metadata

Every STG table must include these columns:

| Column | Type | Purpose |
|---|---|---|
| `ingest_time` | TIMESTAMP | Watermark for incremental loads |
| `source_pipe` | STRING | Which RAW table/pipe produced this row |
| `event_ts` | TIMESTAMP | Business timestamp for partition pruning |

---

## 7. Use safe casting

Always cast with `::type` (Snowflake's safe cast — returns NULL on failure rather than erroring):

```sql
-- ✅ Safe
data:clicks::number AS clicks

-- ❌ Unsafe
CAST(data:clicks AS NUMBER)  -- errors on NULL or malformed data
```

---

## What NOT to do in STG

| Do not | Why |
|---|---|
| Create views over VARIANT | JSON re-parsed on every query |
| Flatten arrays in the main staging table | Row explosion, unpredictable cost |
| Extract every nested field | Over-extraction — wait for downstream need |
| Reprocess the entire dataset on each load | Use incremental watermark |
| Apply business logic | STG is transform-only, not modeling |
| Join staging tables | Joins belong in INT |
| Use `PARSE_JSON()` on already-parsed VARIANT | Double-parsing, wasteful |

---

## Automation with Dynamic Tables (alternative to manual MERGE)

For Snowpipe Streaming use cases, Dynamic Tables in `INT` can replace manual incremental loads. The stream on `RAW.STREAM_T1` (created in `INT` schema) feeds a Dynamic Table that refreshes automatically:

```sql
-- Stream lives in INT schema (created by STREAMING_TRANSFORM_ROLE)
CREATE OR REPLACE STREAM STREAMING_DB_DEV.INT.STREAM_ON_T1
    ON TABLE STREAMING_DB_DEV.RAW.STREAM_T1;

-- Dynamic Table consumes the stream incrementally
CREATE OR REPLACE DYNAMIC TABLE STREAMING_DB_DEV.INT.INT_STREAM__T1__ENRICHED
    TARGET_LAG = '1 minute'
    WAREHOUSE = STREAMING_PIPE_WH_DEV
AS
SELECT
    data:id::string         AS event_id,
    ts                      AS event_ts,
    data:device_id::string  AS device_id,
    data                    AS data_raw
FROM STREAMING_DB_DEV.INT.STREAM_ON_T1;
```

This eliminates the need for scheduled tasks or manual watermark management. See [Snowflake Dynamic Tables documentation](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro) for refresh strategies.
