# Everlywell DBA Technical Exercise

This repository is a lightweight, presentation-ready answer to the Everly Health AI First - Senior Database Engineer exercise. It treats the prompt like a real database change proposal: schema, query tuning, search options, monitoring as code, CI checks, and an AI-first operational layer.

## Motivation & Assumptions

- Assume a health diagnostics platform similar to Everlywell, with customer support searching PHI/PII-adjacent user and address data in AWS RDS PostgreSQL.
- The exercise query is slow because it applies `lower(email)` without a matching expression index, then joins into a 2.5M row address table without an explicit `user_id` access path.
- Operationally, I would want query-level telemetry from `pg_stat_statements`, RDS/CloudWatch metrics, application traces, and Datadog monitors tied back to service ownership.
- Changes should be small, testable, reversible, and reviewed as database migrations with rollout and rollback notes.
- The AI-first angle is practical: use AI to summarize noisy telemetry and propose hypotheses, while DBAs still validate with `EXPLAIN`, production-safe rollout, and business context.

## Repo Layout

- `design/` contains the exercise framing, solution overview, and a change-review process for new product-launch data model changes.
- `db/schema.sql` mirrors the exercise table structures and constraints.
- `db/indexes.sql` adds the concrete indexes I would recommend first.
- `db/queries/slow_query_before.sql` and `db/queries/slow_query_after.sql` show the original query and the tuned version.
- `db/queries/search_strategies.sql` captures three support-search strategies with tradeoffs.
- `infra/terraform/` models an RDS PostgreSQL instance, CloudWatch alarms, and optional Datadog monitors.
- `scripts/` includes helper checks and an `EXPLAIN` runner.
- `ai/ai_notes.md` describes how I would bring AI into monitoring and tuning without giving it unsafe write access.
- `.gitlab-ci.yml` and `.github/workflows/ci.yml` show how I would wire this into CI/CD.

## Repo Tour

1. Start with `design/problem_statement.md` to map the repository back to the four exercise questions.
2. Review `db/queries/slow_query_before.sql`; the main issue is that `lower(email)` cannot use the existing plain unique index on `users(email)`.
3. Open `db/indexes.sql` and `db/queries/slow_query_after.sql`; the fix is an expression index on `lower(email)` plus an index on the address join key.
4. See `db/queries/search_strategies.sql`; it separates exact lookup, fuzzy human-name lookup, and future search-service architecture.
5. Review `design/change_review_process.md` for Q4; it shows how I would protect data quality, existing systems, security, and downstream consumers during a high-profile product launch.
6. Finally see `infra/terraform/` and `ai/ai_notes.md`; monitoring and AI are part of the operating model, not an afterthought.

## In Real Life

Ship this as database migrations through GitLab CI/CD, run `EXPLAIN (ANALYZE, BUFFERS)` in a staging environment with production-like row counts, deploy indexes concurrently in production, and watch RDS metrics, `pg_stat_statements`, and Datadog APM for changes in P95/P99 latency. 
For Everlywell-like workloads, I would also tag dashboards by application service and query fingerprint so support, engineering, and stakeholder teams can discuss the same evidence.

## AI-First Opportunities

- Auto-label expensive queries by fingerprint, likely root cause, affected service, and recent deployment correlation.
- Use AI-assisted recommendations for indexes, vacuum/analyze health, parameter tuning, and query rewrites, with DBA approval gates.
- Generate short on-call summaries from `pg_stat_statements`, slow logs, CloudWatch alarms, and Datadog incidents.

## Local Checks

```bash
./scripts/static_check.sh
./scripts/explain.sh "$DATABASE_URL" db/queries/slow_query_after.sql
```

`explain.sh` expects a PostgreSQL connection string. 
## The repo is runnable in pieces, rather than as a full application.
