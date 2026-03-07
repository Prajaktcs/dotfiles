---
name: emr-serverless
description: Applies EMR Serverless configuration, tuning, and cost optimization conventions for Spark workloads. Use when the user asks about EMR Serverless, Spark job configuration, executor sizing, worker pre-initialization, S3 access patterns, or Spark performance tuning on AWS.
---

# EMR Serverless Skill

## When to use this skill
- Writing EMR Serverless job run configurations
- Tuning Spark executor and driver sizing
- Optimizing for cost vs. performance on EMR Serverless
- Troubleshooting job failures, OOM errors, or slow performance
- Configuring application-level settings (pre-initialized workers, idle timeout)
- Setting up S3 access with proper IAM and bucket key configurations

## Do not use this skill when
- Working with EMR on EC2 or EKS (different tuning surface)
- Non-Spark workloads (Hive, Presto) unless asked

## Application Configuration

### Pre-Initialized Workers
- Use pre-initialized capacity for latency-sensitive or frequent small jobs to avoid cold start overhead
- Set `initialCapacity` conservatively — pre-initialized workers incur cost even when idle
- Always set `idleTimeoutMinutes` to avoid paying for idle pre-initialized capacity

```json
{
  "initialCapacity": {
    "DRIVER": { "workerCount": 1, "workerConfiguration": { "cpu": "4vCPU", "memory": "16GB" } },
    "EXECUTOR": { "workerCount": 5, "workerConfiguration": { "cpu": "4vCPU", "memory": "16GB" } }
  },
  "maximumCapacity": { "cpu": "200vCPU", "memory": "800GB" },
  "idleTimeoutMinutes": 15
}
```

### Auto-Scaling
- Set `maximumCapacity` based on peak workload estimates — EMR Serverless will not exceed this
- For multi-tenant platforms: set per-application limits to prevent one tenant from starving others
- Monitor `ApplicationCapacityUsage` CloudWatch metric to right-size limits

## Spark Job Configuration

### Driver Sizing
```python
spark_conf = {
  "spark.driver.cores": "4",
  "spark.driver.memory": "14g",
  "spark.driver.memoryOverhead": "2g",  # Always set overhead explicitly
}
```

### Executor Sizing
- Match executor size to EMR Serverless worker tiers (2/4/8/16 vCPU)
- Rule of thumb: `executor.memory` + `memoryOverhead` ≤ worker memory limit
- For Iceberg writes: increase `memoryOverhead` to handle large shuffle/sort buffers

```python
spark_conf = {
  "spark.executor.cores": "4",
  "spark.executor.memory": "12g",
  "spark.executor.memoryOverhead": "3g",
  "spark.executor.instances": "10",
  "spark.dynamicAllocation.enabled": "true",
  "spark.dynamicAllocation.minExecutors": "2",
  "spark.dynamicAllocation.maxExecutors": "50",
}
```

### S3 Optimization
- Always enable S3 Bucket Keys on all buckets used for Iceberg/output — reduces KMS cost dramatically
- Set `fs.s3a.connection.maximum` and `fs.s3a.threads.max` for high-throughput jobs
- Use `committer.magic` or Iceberg's atomic commit to avoid partial writes

```python
spark_conf = {
  "spark.hadoop.fs.s3a.connection.maximum": "200",
  "spark.hadoop.fs.s3a.multipart.size": "67108864",  # 64MB
  "spark.hadoop.fs.s3.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
}
```

## Cost Optimization Rules
- Never leave applications in `STARTED` state with no jobs — they accrue pre-initialized capacity cost
- Use Spot instances (via application configuration) for fault-tolerant batch workloads
- Avoid over-provisioning executors — EMR Serverless bills per vCPU-second and GB-second used
- For small/medium jobs: skip pre-initialized workers, accept cold start (~30s)
- Right-size `maximumCapacity` — unused ceiling capacity is free, but it signals poor planning

## Logging & Monitoring
- Always configure `monitoringConfiguration` with S3 log URI and CloudWatch metrics enabled
- Set structured logging in Spark (`log4j2` with JSON output) for Datadog ingestion
- Key metrics to alert on:
  - Job run duration P95 regression
  - OOM errors (`ApplicationAborted` with memory cause)
  - Executor failure rate
  - S3 throttling errors (`SlowDown` in logs)

## Common Failure Patterns
| Symptom | Likely Cause | Fix |
|---|---|---|
| OOM on executor | `memoryOverhead` too low | Increase to 20–30% of `executor.memory` |
| Job hangs at shuffle | Skewed data / too few partitions | Repartition or use AQE (`spark.sql.adaptive.enabled=true`) |
| S3 throttling | Too many LIST/GET calls | Enable S3 Bucket Keys; reduce small file writes |
| Cold start latency | No pre-initialized workers | Add initial capacity for hot path jobs |
| Application won't stop | Stuck pre-initialized workers | Use `StopApplication` API; verify idle timeout |
