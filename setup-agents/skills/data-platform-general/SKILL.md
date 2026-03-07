---
name: data-platform-general
description: Applies general data platform engineering principles for multi-tenant lakehouse platforms including observability, cost awareness, idempotency, and operational patterns. Use when the user asks about data platform architecture, pipeline design, multi-tenant data isolation, operational runbooks, or general engineering decisions on a data platform.
---

# Data Platform General Skill

## When to use this skill
- Making architectural decisions for data pipelines
- Designing multi-tenant data isolation strategies
- Writing operational runbooks or documentation
- Reviewing pipeline designs for operational gaps
- Discussions about platform cost, reliability, or scalability

## Platform Context
This is a multi-tenant data platform serving 200+ customers, using a bronze/silver/gold lakehouse architecture on AWS with Apache Iceberg, EMR Serverless, Kafka Connect, Debezium CDC, and Snowflake. Compute costs and tenant isolation are primary constraints.

## Foundational Principles

### Idempotency
- Every pipeline step must be safe to re-run without side effects
- Use Iceberg's atomic commit + overwrite semantics for writes
- Validate that re-running a job produces the same output, not duplicates
- Design CDC consumers to handle at-least-once delivery (deduplicate on `event_id` or primary key)

### Fail Fast
- Validate inputs (schema, null checks, tenant existence) at the top of every job
- Surface failures loudly — prefer a job failure over silent bad data propagating downstream
- Use schema validation before writing to silver or gold layers

### Observability First
- New pipelines must include: structured logging, record count metrics, processing latency, and error rate
- Use consistent log field names across all pipelines: `tenant_id`, `job_id`, `pipeline_name`, `record_count`, `duration_ms`
- Emit CloudWatch custom metrics for key pipeline checkpoints
- Every pipeline should have an SLA and an alert when it misses it

### Cost Awareness
- Always estimate compute cost before proposing a solution
- Prefer partition pruning and predicate pushdown over full scans
- S3 Bucket Keys must be enabled on all lakehouse buckets
- Avoid EMR Serverless pre-initialized capacity for non-latency-sensitive jobs
- Snowflake warehouses must auto-suspend; never leave them running idle

## Multi-Tenant Isolation Rules
- Tenant data must never comingle in the same Iceberg partition
- All tenant-facing Snowflake views must be `SECURE` views
- IAM policies must be scoped per tenant where applicable
- Audit logs must capture `tenant_id` on every data access operation
- Never use `tenant_id` from a user-controlled input without validation against an allowlist

## Pipeline Design Checklist
Before implementing a new pipeline, confirm:
- [ ] Source schema documented and change detection strategy defined
- [ ] Target table/partition design reviewed for query patterns
- [ ] Idempotency strategy defined (overwrite, upsert, or dedup)
- [ ] Error handling and DLQ strategy in place
- [ ] Record count and data quality checks included
- [ ] Monitoring and alerting configured
- [ ] Runbook written for common failure modes
- [ ] Cost estimate reviewed and approved
- [ ] Tenant isolation verified

## Operational Patterns

### Backfill Strategy
- Always implement backfill as a separate, parameterized job path — not a special case in the main pipeline
- Backfills run in isolation (separate EMR application or Spark session) to avoid impacting production
- Log backfill runs with `is_backfill=true` flag for auditability

### Schema Evolution
- Additive changes (new columns): safe, apply directly
- Breaking changes (rename, type change, drop): require a migration plan with rollback steps
- Document every schema change in a changelog table or migration tracking system

### Incident Response
- Check Kafka Connect replication slot lag first for CDC-based pipelines
- Check EMR Serverless job run status and logs in S3 before escalating
- Validate Iceberg snapshot integrity with `SHOW TBLPROPERTIES` before data quality investigation
- Check Snowflake query history for warehouse credit spikes before assuming a data issue

## What to Always Avoid
- Hardcoded tenant IDs, dates, or environment values in pipeline code
- `SELECT *` in any silver or gold layer query
- Sharing raw bronze data directly with tenants — always go through secure views
- Skipping tests because "it's just a small pipeline"
- Deploying schema changes to production without testing on a staging copy of tenant data
