---
name: kafka-connect-cdc
description: Applies Kafka Connect and Debezium CDC pipeline conventions including connector configuration, error handling, schema registry patterns, and replication slot management. Use when the user asks about Kafka Connect, Debezium, CDC pipelines, connectors, replication slots, or streaming ingestion from databases.
---

# Kafka Connect & Debezium CDC Skill

## When to use this skill
- Writing or modifying Kafka Connect connector configs
- Debugging Debezium CDC failures or replication slot issues
- Designing CDC ingestion pipelines from PostgreSQL or other sources
- Handling schema changes in CDC streams
- Configuring dead-letter queues or error policies
- Troubleshooting Kafka Connect worker failures

## Do not use this skill when
- Working with Spark Structured Streaming directly (no Kafka Connect involvement)
- Writing Kafka producer/consumer application code unrelated to connectors

## Connector Configuration Principles
- Always set `errors.tolerance=all` with a configured dead-letter queue (DLQ) — never silently drop records
- Always configure `errors.deadletterqueue.topic.name` and `errors.deadletterqueue.context.headers.enable=true`
- Set `max.poll.interval.ms` and `session.timeout.ms` conservatively for high-latency sources
- Use `transforms` sparingly — complex transformations belong in the pipeline (Spark/dbt), not in connectors

## Debezium PostgreSQL Source

### Replication Slot Management
- **Never let a replication slot fall behind** — stale slots cause PostgreSQL WAL bloat and disk exhaustion
- Monitor slot lag with:
  ```sql
  SELECT slot_name, active, pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) AS lag_bytes
  FROM pg_replication_slots;
  ```
- Set `slot.drop.on.stop=false` in production (default) — dropping and recreating means full re-snapshot
- Always name slots with a prefix that identifies the connector: `debezium_<service>_<table>`
- If a slot is inactive and lagging >1GB, alert and investigate before the connector restarts

### Required Connector Properties
```json
{
  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
  "plugin.name": "pgoutput",
  "publication.autocreate.mode": "filtered",
  "heartbeat.interval.ms": "30000",
  "snapshot.mode": "initial",
  "tombstones.on.delete": "true",
  "decimal.handling.mode": "string",
  "time.precision.mode": "connect"
}
```

### Snapshot Strategy
- Use `snapshot.mode=initial` for new connectors on existing tables
- Use `snapshot.mode=never` when reconnecting to an existing slot after a brief outage
- Never use `snapshot.mode=always` in production — it causes full re-reads on every restart
- For large tables: configure `snapshot.fetch.size` and `snapshot.max.threads`

## S3 Sink Connector
- Always partition output by date using `TimestampRouter` or `TimeBasedPartitioner`
- Set `flush.size` and `rotate.interval.ms` to avoid tiny files in S3
- Enable `s3.ssea.name=aws:kms` for encrypted buckets; set `s3.part.size` to at least 5MB
- Use `storage.class=io.confluent.connect.s3.storage.S3Storage` explicitly

## Error Handling Pattern
Every connector must have:
```json
{
  "errors.tolerance": "all",
  "errors.log.enable": "true",
  "errors.log.include.messages": "true",
  "errors.deadletterqueue.topic.name": "<connector-name>-dlq",
  "errors.deadletterqueue.topic.replication.factor": "3",
  "errors.deadletterqueue.context.headers.enable": "true"
}
```

## Schema Changes in CDC Streams
- When source schema changes, Debezium emits a new schema envelope — downstream consumers must handle this gracefully
- For Iceberg sinks: use schema evolution (add columns) rather than failing on unknown fields
- Always test schema change handling in staging before applying DDL in production
- For `ALTER TABLE ADD COLUMN`: safe, Debezium handles automatically
- For `ALTER TABLE DROP COLUMN` or renames: requires connector pause + consumer update coordination

## Monitoring Checklist
- Replication slot lag (bytes and seconds behind)
- Connector status (`RUNNING` / `FAILED` / `PAUSED`)
- DLQ topic message count (should always be zero in steady state)
- Consumer group lag on sink connector topics
- Worker JVM heap and GC metrics
