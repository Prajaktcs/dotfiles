---
name: terraform-aws-dataops
description: Applies Terraform conventions for AWS data infrastructure including S3, EMR Serverless, Glue, IAM, and Kafka MSK. Use when the user asks about Terraform modules, AWS infrastructure-as-code, S3 bucket configuration, IAM roles for data pipelines, or provisioning data platform resources.
---

# Terraform AWS DataOps Skill

## When to use this skill
- Writing or modifying Terraform for AWS data infrastructure
- Designing IAM roles and policies for data pipelines
- Configuring S3 buckets for lakehouse storage
- Provisioning EMR Serverless applications or MSK clusters
- Structuring Terraform modules for a multi-tenant data platform
- Reviewing Terraform plans for data-related resources

## Do not use this skill when
- Writing application code (Python, Java, etc.)
- Non-AWS infrastructure targets (GCP, Azure)

## Module Structure
- Use one module per logical resource group (e.g., `s3-lakehouse`, `emr-serverless-app`, `kafka-msk`)
- Always include `description` on every `variable` and `output`
- Use `locals` for computed or reused values — never duplicate expressions
- Pin provider versions in modules; use `>= x.y, < x+1.0` ranges

```hcl
# Good: locals for reused values
locals {
  bucket_name = "${var.environment}-${var.tenant_id}-lakehouse"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Team        = "data-ops"
  }
}
```

## S3 Bucket Conventions

### Always include:
- `server_side_encryption_configuration` with `aws:kms`
- `bucket_key_enabled = true` on the encryption rule (reduces KMS API costs significantly)
- `versioning` enabled for production buckets
- `lifecycle_rule` for cost management (transition to Glacier or expire old snapshots)
- `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` all `true`

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "lakehouse" {
  bucket = aws_s3_bucket.lakehouse.id

  rule {
    bucket_key_enabled = true  # Critical for KMS cost reduction

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}
```

## IAM Role Conventions
- Use least-privilege IAM — never use `*` for actions or resources in production policies
- Separate roles per service: one for EMR Serverless, one for Kafka Connect, one for Glue, etc.
- Use `aws_iam_role_policy_attachment` with managed policies where possible; inline policies for resource-specific rules
- Always tag IAM roles with `Environment` and `Service`
- Avoid hardcoding account IDs — use `data.aws_caller_identity.current.account_id`

```hcl
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "emr_s3_access" {
  name = "${var.app_name}-emr-s3-policy"
  role = aws_iam_role.emr_serverless.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.lakehouse.arn,
          "${aws_s3_bucket.lakehouse.arn}/*"
        ]
      }
    ]
  })
}
```

## EMR Serverless Application
- Parameterize `release_label` as a variable — don't hardcode EMR versions
- Set `maximum_capacity` per application to prevent runaway costs in multi-tenant setups
- Use `initial_capacity` only for hot-path applications with latency requirements
- Always configure `network_configuration` with private subnets for security

## Variable & Output Standards
```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

output "lakehouse_bucket_arn" {
  description = "ARN of the lakehouse S3 bucket"
  value       = aws_s3_bucket.lakehouse.arn
  sensitive   = false
}
```

## What to Avoid
- Never use `count` for resources that need stable addressing — use `for_each` with a map
- Never hardcode AWS region — use `data.aws_region.current.name`
- Never commit `.tfstate` files — always use remote state (S3 + DynamoDB lock)
- Never use `terraform taint` carelessly on stateful resources (RDS, MSK) — data loss risk
- Never remove a `lifecycle { prevent_destroy = true }` block without a deliberate review
