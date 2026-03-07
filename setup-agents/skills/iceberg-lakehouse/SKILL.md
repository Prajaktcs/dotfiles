---
name: iceberg-lakehouse
description: Applies Apache Iceberg table conventions including partitioning strategies, compaction, file sizing, and schema evolution. Use when the user asks about Iceberg tables, partitioning, compaction, lakehouse architecture, bronze/silver/gold layers, or file size optimization.
---

# Iceberg Lakehouse Skill

## When to use this skill
- Creating or modifying Iceberg tables
- Designing or evolving partition strategies
- Writing or tuning compaction jobs
- Troubleshooting small file problems
- Working on bronze, silver, or gold layer transformations
- Multi-tenant data isolation at the table or partition level

## Do not use this skill when
- Working with non-Iceberg table formats (Delta, Hudi)
- Pure Snowflake or RDBMS work with no Iceberg involvement

## Architecture: Bronze / Silver / Gold

| Layer  | Purpose                              | Key Properties                                     |
|--------|--------------------------------------|----------------------------------------------------|
| Bronze | Raw ingestion, append-only CDC       | Partition by `ingestion_date`, preserve source schema |
| Silver | Cleaned, deduplicated, typed         | Partition by business key + date, apply schema evolution |
| Gold   | Aggregated, tenant-facing            | Partition by `tenant_id` + time bucket, optimized for query |

## Partitioning Rules
- Always use partition evolution (`ALTER TABLE ... ADD PARTITION FIELD`) rather than recreating tables
- For multi-tenant tables: partition by `tenant_id` first, then time (e.g., `days(event_date)`)
- Avoid high-cardinality partition fields (e.g., user_id) — aim for 100MB–1GB per partition
- For append-heavy bronze tables: use `hours()` or `days()` transforms on ingestion timestamp
- Never use hidden partitioning without documenting the transform in a table comment

## File Size Targets
- Target file size: **128MB–512MB** for query-optimized tables
- Bronze (raw/streaming): accept smaller files (32MB+), compact frequently
- Use `write.target-file-size-bytes` property:
  ```sql
  ALTER TABLE my_table SET TBLPROPERTIES (
    'write.target-file-size-bytes' = '268435456'  -- 256MB
  );
  ```

## Compaction
- Always run compaction after bulk writes or streaming micro-batches
- Use `rewrite_data_files` for file size optimization
- Use `rewrite_manifests` after heavy partition evolution
- Compaction jobs must be idempotent and safe to re-run
- Schedule compaction off-peak; never block reads with aggressive locking

```python
# PySpark compaction pattern
from pyspark.sql import SparkSession
spark.sql("""
  CALL catalog.system.rewrite_data_files(
    table => 'db.table_name',
    options => map(
      'target-file-size-bytes', '268435456',
      'min-input-files', '5'
    )
  )
""")
```

## Schema Evolution
- Always use `ALTER TABLE ... ADD COLUMN` — never recreate tables to add columns
- Use optional (nullable) columns when adding to existing tables
- Document every schema change in a migration log comment or changelog table
- Never rename columns in-place on high-traffic tables without a deprecation window

## Multi-Tenant Isolation
- Tenant data must be partition-isolated — no cross-tenant data in a single partition
- Apply row-level filtering in silver/gold views using `tenant_id` predicate pushdown
- Never expose raw bronze tables to tenant-facing queries

## Cost Guardrails
- Always predicate-push on partition columns to avoid full table scans
- Use `SELECT` with explicit column lists — never `SELECT *` in production pipelines
- Expire snapshots regularly to control S3 storage costs:
  ```sql
  CALL catalog.system.expire_snapshots(
    table => 'db.table_name',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 5
  );
  ```
