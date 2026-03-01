# Global Claude Code Instructions

## Who I Am

I'm a Staff Data Pipeline Engineer specializing in data operations and modern data infrastructure. My work spans building and maintaining large-scale, multi-tenant data platforms using lakehouse architectures (bronze/silver/gold), streaming pipelines, and cloud-native tooling on AWS.

---

## Languages & Tooling

I work across the following languages and tools — apply the conventions below in each:

- **Python** — use type hints everywhere, prefer dataclasses or Pydantic for structured data, avoid pandas for large-scale data (use PySpark or Polars instead), use `ruff` for linting
- **Java** — follow standard Java conventions, prefer immutability, use streams over explicit loops where readable
- **Ruby** — follow community style (RuboCop conventions), prefer idiomatic Ruby over verbose imperative code
- **SQL (Spark SQL / Snowflake SQL)** — use CTEs over nested subqueries, always alias columns explicitly, avoid `SELECT *` in production code, prefer explicit column lists
- **HCL (Terraform)** — use modules for reusable infrastructure, always include `description` on variables and outputs, never hardcode values that belong in variables or locals
- **YAML (Kubernetes with Helm & Kustomize)** — keep base manifests clean, use Kustomize overlays for environment-specific config, avoid duplicating values across patches

---

## How I Like to Work

**Before starting any non-trivial task:**
- Ask clarifying questions if the scope, constraints, or approach aren't clear
- Identify ambiguities upfront rather than making silent assumptions
- If there are multiple valid approaches, briefly surface them before proceeding

**When writing code:**
- Write the code first, then explain what you did and why — don't narrate while coding
- Keep explanations concise and focused on non-obvious decisions
- If you deviated from what was asked, say so and explain why

**Tests:**
- Always write tests alongside any new code — this is non-negotiable
- Tests should cover the happy path, edge cases, and failure modes
- Match the testing framework already in use in the project; if none exists, ask before introducing one

---

## General Engineering Principles

These apply across all languages and projects:

- **Never hardcode credentials, secrets, or environment-specific values** — use environment variables, secret managers, or config files
- **Prefer explicitness over cleverness** — readable code beats compact code
- **Handle errors explicitly** — don't swallow exceptions silently; log or surface them meaningfully
- **Think about observability** — new code should be loggable and debuggable; include structured logging where appropriate
- **Idempotency matters** — pipelines and infrastructure changes should be safe to re-run
- **Fail fast** — validate inputs early, surface problems at the boundary rather than deep in execution
- **Document the "why", not the "what"** — comments should explain intent and constraints, not restate what the code does

---

## Cost & Operational Awareness

I work on platforms where compute and storage costs are a real concern. Keep this in mind:

- Prefer solutions that minimize unnecessary compute, data scanning, or API calls
- Flag if a proposed solution has non-obvious cost implications (e.g., full table scans, excessive S3 LIST operations, unpartitioned queries)
- Lean toward approaches that scale down gracefully for small tenants and up for large ones

---

## What I Don't Want

- Don't add placeholder comments like `# TODO: implement this` without flagging it explicitly
- Don't use `print()` for debugging in production code — use proper logging
- Don't generate boilerplate I didn't ask for (e.g., unsolicited README sections, unnecessary wrapper classes)
- Don't make assumptions about infrastructure (cloud provider, region, account IDs) without asking
- Don't produce code that works "in theory" but ignores operational realities like retries, partial failures, or schema drift
