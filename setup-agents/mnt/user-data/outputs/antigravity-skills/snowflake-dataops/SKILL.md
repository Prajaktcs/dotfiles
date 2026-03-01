---
name: snowflake-dataops
description: Applies Snowflake SQL conventions, secure view patterns, data sharing, and warehouse sizing best practices. Use when the user asks about Snowflake queries, secure views, data sharing, dynamic data masking, Snowflake warehouses, or cross-account data access.
---

# Snowflake DataOps Skill

## When to use this skill
- Writing Snowflake SQL queries or stored procedures
- Designing secure views for tenant data isolation
- Setting up Snowflake data sharing (provider or consumer side)
- Configuring dynamic data masking policies
- Sizing or optimizing Snowflake virtual warehouses
- Writing dbt models targeting Snowflake

## Do not use this skill when
- Working with Spark SQL or non-Snowflake targets
- Generic SQL that isn't Snowflake-specific

## SQL Conventions
- Always use explicit column lists — never `SELECT *` in production views or models
- Use CTEs for readability; avoid deeply nested subqueries
- Always alias columns and tables explicitly
- Use `ILIKE` instead of `LIKE` for case-insensitive matching
- Prefer `QUALIFY` over nested window function subqueries
- Use `MERGE` with care — always test in a transaction with `ROLLBACK` before committing

```sql
-- Good pattern: CTE + explicit columns + QUALIFY
WITH ranked AS (
  SELECT
    tenant_id,
    event_id,
    event_ts,
    event_type,
    ROW_NUMBER() OVER (PARTITION BY tenant_id, event_id ORDER BY event_ts DESC) AS rn
  FROM bronze.events
  WHERE event_date >= DATEADD(day, -7, CURRENT_DATE)
)
SELECT tenant_id, event_id, event_ts, event_type
FROM ranked
QUALIFY rn = 1;
```

## Secure Views for Multi-Tenant Isolation

### Rules
- All tenant-facing views **must** be `SECURE` views to prevent query plan inference attacks
- Always filter on `tenant_id` using `CURRENT_ROLE()` or a context function — never rely on the caller to filter
- Test secure views with `SHOW VIEWS` to confirm `is_secure = true`

```sql
CREATE OR REPLACE SECURE VIEW gold.v_tenant_events AS
SELECT
  event_id,
  event_ts,
  event_type,
  payload
FROM silver.events
WHERE tenant_id = GET_PATH(PARSE_JSON(CURRENT_AVAILABLE_ROLES()), '[0]')::STRING;
```

### Data Masking
- Apply dynamic data masking policies on PII columns (email, phone, SSN, etc.)
- Masking policies must be created at the schema level and assigned explicitly — never rely on view-level obfuscation alone
- Test masking with a role that lacks the `UNMASK` privilege

```sql
CREATE OR REPLACE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_ADMIN', 'SUPPORT_TIER2') THEN val
    ELSE REGEXP_REPLACE(val, '(^[^@]+)', '****')
  END;

ALTER TABLE silver.users MODIFY COLUMN email SET MASKING POLICY email_mask;
```

## Data Sharing

### Provider Side
- Create a dedicated share per customer or customer group — never share a database directly
- Only share objects explicitly; use `GRANT REFERENCE_USAGE` for underlying tables referenced in shared views
- Secure views are the preferred share target (not raw tables)
- Always test the share from a reader account before handing it to the customer

```sql
CREATE SHARE customer_abc_share;
GRANT USAGE ON DATABASE gold TO SHARE customer_abc_share;
GRANT USAGE ON SCHEMA gold.public TO SHARE customer_abc_share;
GRANT SELECT ON VIEW gold.public.v_tenant_events TO SHARE customer_abc_share;
ALTER SHARE customer_abc_share ADD ACCOUNTS = <customer_snowflake_account>;
```

### Consumer Side
- Create the database from share with a meaningful name: `<provider>_<share_name>_db`
- Never write back to a shared database — it's read-only by definition
- Monitor `SNOWFLAKE.ACCOUNT_USAGE.DATA_TRANSFER_HISTORY` for cross-region transfer costs

## Warehouse Sizing
- Start with `SMALL` or `MEDIUM` and scale up based on query profiling, not assumption
- Use separate warehouses for ingestion, transformation, and serving — avoids contention
- Enable auto-suspend (60–120 seconds for dev, 300 seconds for prod serving)
- Enable auto-resume always
- Use multi-cluster warehouses only for serving layers with concurrent user load
- Monitor `WAREHOUSE_METERING_HISTORY` weekly for cost anomalies

## Cost Guardrails
- Always set `STATEMENT_TIMEOUT_IN_SECONDS` on warehouses to kill runaway queries
- Use `RESULT_SCAN` to avoid re-running expensive queries when only formatting differs
- Cluster keys on large tables should match your most common filter patterns — but only add them if query pruning is measurably poor
- Avoid `COPY INTO` with `PURGE=TRUE` in dev — you'll lose source files on failure
