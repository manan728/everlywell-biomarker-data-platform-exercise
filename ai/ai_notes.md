# AI Notes For Monitoring And Tuning

While AI can accelerate human judgment, for an Everlywell-like platform handling sensitive health-adjacent data, I have kept AI integrations read-only by default, redact PHI/PII before analysis, and require human approval for migrations or parameter changes.

## Practical Uses

- Query fingerprint triage: group slow queries from `pg_stat_statements`, identify which services generate them, and summarize likely causes.
- Index recommendation assistant: propose candidate indexes with estimated write overhead, duplicate-index risk, and sample `EXPLAIN` evidence.
- Incident summaries: convert CloudWatch alarms, Datadog events, deploy markers, and slow-query deltas into short on-call handoff notes.
- Migration review: flag risky DDL patterns such as blocking indexes, unbounded backfills, missing rollback plans, or new nullable columns without validation strategy.
- **Natural language to SQL (support and internal tools):** an LLM can turn a constrained English request (“find users in Austin with zip 78701”) into parameterized SQL **when** it only sees anonymized column metadata, approved join paths, and guardrails (no dynamic identifiers, `LIMIT` enforced, read-only role). Outputs should be treated as **drafts**: a human or CI step runs `EXPLAIN` in staging and rejects cross-join or table-scan shapes.
- **Tuning copilot:** given *sanitized* `EXPLAIN` plans and `pg_stat_statements` rows, suggest rewritten predicates (e.g. match expression indexes), `work_mem` hypotheses, or autovacuum concerns—always verified by a DBA before production change.
- **Semantic search operations:** embedding generation is a batch or stream job; LLMs can help classify which fields may be embedded under policy, but the store (pgvector or OpenSearch kNN) and **hybrid** ranking policy remain engineering-owned.

## Guardrails

- Do not send raw PHI/PII to external models.
- Use read-only telemetry and sanitized schema metadata for automated analysis.
- Require approval before creating indexes, changing RDS parameters, or modifying application queries.
- Track AI suggestions as pull-request comments or tickets so decisions remain auditable.

## Example AI Workflow

1. Nightly job exports sanitized `pg_stat_statements` deltas.
2. AI groups query fingerprints by regression, service, and likely root cause.
3. Human review for the top candidates and review of `EXPLAIN (ANALYZE, BUFFERS)` in staging.
4. Approved fixes then can translate into PRs with CI checks and rollout notes.

## NL→SQL And Hybrid Search
- **Why LLMs here:** they shrink the gap between support phrasing and safe, parameterized queries, and they help draft migration checklists—not autonomous DDL.
- **Why not only LLMs:** they do not replace cardinality-aware planning; `EXPLAIN` and production statistics remain the source of truth for performance claims.
- **Hybrid retrieval:** pair **lexical** retrieval (zip, email, exact tokens) with **vector** retrieval (embedding of allowed name/address text) so you get both precision and recall; merge scores in the search tier (OpenSearch) or in application code for pgvector + SQL filters.
