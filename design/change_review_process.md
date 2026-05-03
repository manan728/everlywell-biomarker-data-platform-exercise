# Q4: Change Review Process

For new columns and tables supporting a high-profile product launch, I would use a repeatable process that protects existing systems, prevents data corruption, and gives product teams a safe path to move quickly. A launch deadline should change the urgency, not the engineering controls.

## 1. Requirements And Modeling

- Partner with product, application engineering, analytics, support, compliance, and security to clarify the new product workflow.
- Identify entities, relationships, lifecycle, retention rules, reporting needs, and whether each field is PHI, PII, financial, operational, or derived data.
- Build conceptual and logical models first: ERD, data flow, cardinality, ownership boundaries, and consumer contracts.
- Define ownership for each new table and column: who produces it, who can change it, who consumes it, and what breaks if it changes.
- Capture expected volume, growth rate, read/write patterns, archival needs, and downstream analytics or AI use cases before physical schema design.

## 2. Schema Design And Review

- Draft the physical schema with data types, constraints, indexes, foreign keys, partitioning considerations, default values, and nullability.
- Prefer explicit constraints for business rules: `NOT NULL`, `CHECK`, `UNIQUE`, foreign keys, and reference tables where appropriate.
- Use PostgreSQL-safe rollout patterns for large tables: additive changes first, `CREATE INDEX CONCURRENTLY`, `NOT VALID` constraints followed by `VALIDATE CONSTRAINT`, and no long blocking transactions.
- Consider future warehouse, lake, and AI usage: stable surrogate keys, clear timestamps, consistent naming, source-system fields, soft-delete semantics if needed, and audit-friendly history.
- Run a formal schema review with DBAs, data engineering, application engineering, analytics, and security/privacy.
- Check for anti-patterns such as unbounded text without a reason, missing ownership, missing indexes for known access patterns, ambiguous booleans, overloaded JSON, weak referential integrity, or columns that encode multiple concepts.

## 3. Data Quality, Lineage, And Governance

- Define validation rules at the database and pipeline layers: not-null expectations, range checks, allowed values, uniqueness, referential integrity, and freshness.
- Register new tables and fields in a data catalog or lineage tool when available, including definitions, owners, sensitivity classification, and downstream consumers.
- Add automated tests in CI, such as schema checks, migration linting, dbt-style data tests, and custom checks for expected row counts or referential integrity.
- Add anomaly monitoring for sudden drops to zero rows, unexpected growth, skewed distributions, missing required values, or new error patterns.
- Document semantics carefully so analytics, support, and future AI workflows do not infer the wrong meaning from a field name.

## 4. Migration Strategy And Rollout

- Use backward-compatible expand/contract migrations: add new structures, dual-write or backfill, shift reads, validate, then remove old structures later.
- Add new columns as nullable or with safe defaults; avoid table rewrites and blocking locks on large production tables.
- Backfill data in controlled batches using a worker, batch job, or AWS Lambda-style process, with throttling and RDS impact monitoring.
- Use feature flags on the application side so the launch can be enabled, disabled, or gradually rolled out without emergency database changes.
- Plan rollback before deployment: snapshots, restore path, reversible application flags, and a multi-phase deprecation plan for destructive changes.
- For drops or type changes, use a delayed cleanup phase after confirming no application, analytics, support, or AI consumer still depends on the old structure.

## 5. Performance, Observability, And DR

- Load-test critical read/write paths using realistic data volumes and examine `EXPLAIN (ANALYZE, BUFFERS)` plans before launch.
- Add indexes, partitioning, or query rewrites based on measured access patterns rather than guesswork.
- Extend dashboards for the new schema: query latency, rows scanned, lock waits, deadlocks, connection pressure, table growth, replication lag, and error counts.
- Add launch-specific alerts with lower thresholds during rollout, then tune them after the traffic pattern stabilizes.
- Include new tables in backup, replication, restore, and disaster recovery procedures; validate restore tests cover the new data paths.

## 6. Security, Compliance, And Auditing

- Classify every new field by sensitivity and confirm encryption at rest, encryption in transit, least-privilege access, and environment-specific data handling.
- Limit support and analytics access to the minimum required columns, especially for PHI/PII.
- Integrate access auditing and logging requirements: who accessed what, from where, when, and through which service or role.
- Review retention and deletion obligations before launch so the database design supports compliance operations instead of fighting them later.
- Document decisions for HIPAA/SOC2-style audit readiness and for safe internal AI usage on sanitized or governed data.

## Recommended Panel Answer

My process would be: requirements and data modeling first, then formal schema review, data-quality and governance controls, backward-compatible migration rollout, performance and observability validation, and finally security/compliance signoff. The important principle is that a high-profile launch should be delivered through smaller reversible steps, with feature flags and monitoring, instead of one large schema change that risks existing users or downstream data consumers.
