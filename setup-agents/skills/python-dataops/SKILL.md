---
name: python-dataops
description: Applies Python coding conventions for data engineering including type hints, PySpark patterns, logging, error handling, and testing with pytest. Use when the user asks about Python code for data pipelines, PySpark jobs, ETL scripts, or data transformation logic.
---

# Python DataOps Skill

## When to use this skill
- Writing PySpark jobs or transformation scripts
- Building data pipeline utilities or helper libraries
- Writing Python-based Kafka consumers or producers
- Any Python code for data engineering workflows

## Do not use this skill when
- Writing Python for web APIs or non-data applications (use general Python conventions instead)
- Ruby, Java, or other language tasks

## Core Rules
- **Always use type hints** — every function signature must include parameter and return types
- **Never use `pandas` for large-scale data** — use PySpark or Polars instead; pandas is acceptable only for local config parsing or small reference data (<10K rows)
- **Use `ruff` for linting** — do not use `flake8` or `pylint` unless the project already uses them
- **Use dataclasses or Pydantic** for structured data; avoid plain dicts for anything that crosses a function boundary

## Type Hints & Structure

```python
from dataclasses import dataclass
from typing import Optional
from pyspark.sql import DataFrame, SparkSession


@dataclass
class PipelineConfig:
    source_table: str
    target_table: str
    partition_date: str
    tenant_id: str
    batch_size: int = 1000


def load_bronze(
    spark: SparkSession,
    config: PipelineConfig,
) -> DataFrame:
    """Load raw data from the bronze layer for a given tenant and date."""
    return spark.table(config.source_table).filter(
        (spark.col("tenant_id") == config.tenant_id)
        & (spark.col("partition_date") == config.partition_date)
    )
```

## Logging
- Use Python's `logging` module with structured output — never use `print()` in production code
- Always get a named logger per module: `logger = logging.getLogger(__name__)`
- Log at appropriate levels: `DEBUG` for trace, `INFO` for milestones, `WARNING` for recoverable issues, `ERROR` for failures
- Include context in log messages (tenant_id, job_id, record counts)

```python
import logging

logger = logging.getLogger(__name__)

def process_tenant(tenant_id: str, df: DataFrame) -> int:
    logger.info("Starting processing", extra={"tenant_id": tenant_id})
    result = df.filter(df.tenant_id == tenant_id)
    count = result.count()
    logger.info("Processing complete", extra={"tenant_id": tenant_id, "record_count": count})
    return count
```

## Error Handling
- Catch specific exceptions — never bare `except:` or `except Exception:` without logging and re-raising
- Fail fast at the boundary: validate inputs at the top of functions, not deep in logic
- Use custom exception classes for domain errors (e.g., `TenantNotFoundError`, `SchemaValidationError`)

```python
class TenantNotFoundError(Exception):
    pass


def get_tenant_config(tenant_id: str, configs: dict[str, dict]) -> dict:
    if tenant_id not in configs:
        raise TenantNotFoundError(f"No config found for tenant: {tenant_id}")
    return configs[tenant_id]
```

## PySpark Patterns
- Use `spark.sql()` for complex queries; use DataFrame API for programmatic transformations
- Always call `.cache()` explicitly when a DataFrame is reused more than once — never assume Spark will optimize this
- Repartition before large writes: `df.repartition(n, "partition_col").write...`
- Use `broadcast()` for small lookup tables in joins
- Avoid `.collect()` on large DataFrames — use `.take(n)` or `.show()` for debugging only

## Testing with pytest
- Every module must have a corresponding `test_<module>.py`
- Use `pyspark.sql.SparkSession` fixtures with `scope="session"` for test performance
- Mock external calls (S3, APIs) with `unittest.mock.patch`
- Test: happy path, edge cases (empty DataFrame, single row, null values), error cases

```python
import pytest
from pyspark.sql import SparkSession


@pytest.fixture(scope="session")
def spark() -> SparkSession:
    return (
        SparkSession.builder
        .master("local[2]")
        .appName("test")
        .getOrCreate()
    )


def test_load_bronze_filters_by_tenant(spark: SparkSession) -> None:
    data = [("t1", "2024-01-01", "event_a"), ("t2", "2024-01-01", "event_b")]
    df = spark.createDataFrame(data, ["tenant_id", "partition_date", "event_type"])
    result = df.filter(df.tenant_id == "t1")
    assert result.count() == 1
```

## Idempotency
- Write pipeline steps so they're safe to re-run: overwrite or upsert, never append blindly
- Use `mode="overwrite"` with partition overwrite for Iceberg writes
- Validate output record counts against input before committing writes
