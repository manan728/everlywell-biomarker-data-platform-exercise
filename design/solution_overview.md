# Solution Overview

Assume a health diagnostics platform like Everlywell, where customer support needs to search user and address records in RDS PostgreSQL. The immediate database issue is a slow lookup query caused by a function-wrapped email predicate and a missing join-key index. The broader operating model is to pair query-level observability, safe migration practices, and AI-assisted analysis so performance work becomes repeatable.

## Architecture Sketch

```text
Application services
        |
        v
AWS RDS PostgreSQL
        |
        +--> pg_stat_statements / slow query logs
        +--> CloudWatch metrics and alarms
        +--> Datadog APM, dashboards, and monitors

Future option:
RDS logical replication / CDC --> Kafka --> OpenSearch / analytics consumers
```

## Key Recommendations

| Area | Recommendation | Why it matters |
| --- | --- | --- |
| Slow query | Add `users(lower(email))` expression index and `user_addresses(user_id)` index | Matches the predicate and join pattern from the exercise query |
| Search | Start with exact indexed lookup, add trigram/full-text only where needed, consider OpenSearch for broader support workflows | Keeps operational complexity proportional to the use case |
| Monitoring | Combine RDS metrics, `pg_stat_statements`, slow logs, and APM traces | Lets the DBA connect database symptoms to application owners |
| Product launches | Require data model review, migration plan, backfill plan, rollback plan, and data-quality checks | Protects existing data and reduces launch risk |

## Product Launch Schema Change Process

For question 4, I propose a repeatable launch process that lets the business move quickly without putting existing users, support workflows, or downstream data consumers at risk.

1. Requirements and modeling: partner with product, engineering, analytics, compliance, and security to define entities, relationships, ownership, PHI/PII classification, retention, expected growth, and data consumers.
2. Schema design review: review physical schema choices for data types, constraints, indexes, partitioning, naming standards, default values, and nullable vs non-nullable behavior before implementation.
3. Data quality and governance: define validation rules at the database and pipeline layers, register new fields in a data catalog where possible, and add CI/data tests for constraints, referential integrity, and expected distributions.
4. Migration rollout: use backward-compatible expand/contract migrations, add columns safely, backfill in controlled batches, use feature flags, and keep rollback plans and snapshots ready for destructive changes.
5. Performance and observability: load-test critical queries with realistic volume, inspect `EXPLAIN (ANALYZE, BUFFERS)`, and add monitoring for query latency, locks, table growth, errors, and replication lag.
6. Security and auditability: enforce least-privilege access, encryption (at-rest and in-transit), access logging, retention rules, and documented decisions for HIPAA/SOC2-style audit readiness and safe AI usage.

The short version: high-profile launch changes should be delivered as smaller reversible steps with clear owners, automated validation, observability, and compliance signoff.

## AI-First Angle

- Analyze `pg_stat_statements` and slow logs with AI to cluster expensive query patterns, summarize deltas, and suggest likely missing indexes.
- Use anomaly detection for query latency, error-rate changes, lock waits, and connection saturation after deployments.
- Let LLMs summarize daily performance reports and incident timelines for on-call rotation, while humans verify any tuning recommendation before implementation.
