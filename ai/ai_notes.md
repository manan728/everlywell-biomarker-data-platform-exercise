# AI Notes For Monitoring And Tuning

AI should accelerate DBA judgment, not replace it. For an Everlywell-like platform handling sensitive health-adjacent data, I would keep AI integrations read-only by default, redact PHI/PII before analysis, and require human approval for migrations or parameter changes.

## Practical Uses

- Query fingerprint triage: group slow queries from `pg_stat_statements`, identify which services generate them, and summarize likely causes.
- Index recommendation assistant: propose candidate indexes with estimated write overhead, duplicate-index risk, and sample `EXPLAIN` evidence.
- Incident summaries: convert CloudWatch alarms, Datadog events, deploy markers, and slow-query deltas into short on-call handoff notes.
- Migration review: flag risky DDL patterns such as blocking indexes, unbounded backfills, missing rollback plans, or new nullable columns without validation strategy.

## Guardrails

- Do not send raw PHI/PII to external models.
- Use read-only telemetry and sanitized schema metadata for automated analysis.
- Require DBA approval before creating indexes, changing RDS parameters, or modifying application queries.
- Track AI suggestions as pull-request comments or tickets so decisions remain auditable.

## Example AI Workflow

1. Nightly job exports sanitized `pg_stat_statements` deltas.
2. AI groups query fingerprints by regression, service, and likely root cause.
3. DBA reviews the top candidates and runs `EXPLAIN (ANALYZE, BUFFERS)` in staging.
4. Approved fixes become migration PRs with CI checks and rollout notes.
