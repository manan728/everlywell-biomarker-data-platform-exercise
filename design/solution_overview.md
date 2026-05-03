# Solution Overview

Assume a health diagnostics platform like Everlywell, where customer support needs to search user and address records in RDS PostgreSQL. The immediate database issue is a slow lookup query caused by a function-wrapped email predicate and a missing join-key index. The broader operating model is to pair query-level observability, safe migration practices, and AI-assisted analysis so performance work becomes repeatable.

## Architecture Sketch

See [`architecture.md`](architecture.md) for the application, RDS PostgreSQL, CloudWatch, Datadog, and future CDC/search architecture.

## Key Recommendations

| Area | Recommendation | Why it matters |
| --- | --- | --- |
| Q1: Monitoring | Combine Postgres-native telemetry, RDS/CloudWatch, Datadog APM, and AI-assisted anomaly detection | Covers database, application, and platform layers |
| Slow query | Add `users(lower(email))` expression index and `user_addresses(user_id)` index | Matches the predicate and join pattern from the exercise query |
| Search | Exact + trigram in Postgres first; plan **hybrid** OpenSearch (BM25 + vector) or **pgvector** for semantic retrieval when workflows need it | Matches ops cost to support UX; AI-forward path is explicit |
| Product launches | Require data model review, migration plan, backfill plan, rollback plan, and data-quality checks | Protects existing data and reduces launch risk |

## Q1: Monitoring And Alerting

I would monitor database calls in layers: native PostgreSQL/RDS telemetry for query facts, application APM for user-facing impact, and AI-assisted anomaly detection for faster triage.

### Strategy 1: Postgres-Native Telemetry And RDS

Core tools:

- `pg_stat_statements` for normalized query fingerprints, calls, mean time, total time, rows, and buffer behavior.
- `auto_explain` for slow execution plans above a threshold, such as 500 ms, including timing and buffer details.
- RDS Performance Insights for top SQL by load, waits, CPU, I/O, and time windows.
- CloudWatch metrics and PostgreSQL logs as the base signal for alarms and retention.

To set up:

- Enable `pg_stat_statements` and rank queries by total time, mean time, call count, rows returned, and shared buffer reads/hits.
- Enable `auto_explain` for slow plans only.
- Export PostgreSQL logs to CloudWatch and integrate with Datadog/Prometheus to setup monitoring for CPU, connections, read/write latency, deadlocks, lock waits, and disk growth.
- Send RDS and query-derived metrics into Datadog/Prometheus for dashboards, SLOs, and alert routing.

Pros:

- Low-friction on RDS, strong query-level visibility, and useful plan evidence for tuning.
- Good for top-N offender analysis, capacity planning, and before/after validation after index changes.

Cons:

- Manual interpretation of data and tuning of thresholds.
- `auto_explain` and slow-query logging can create heavy log volume if configured too broadly.

Alert examples:

- P95 query latency by normalized query family above a threshold for 10-15 minutes.
- Read and write response rate for the service
- Error rates for a given time period at the application layer.
- Deadlocks, lock timeouts, or long-running transactions above threshold.
- RDS CPU, connection saturation, read/write latency, IOPs, or storage growth outside normal range.

### Strategy 2: Application-Side Instrumentation And APM

Core tools:

- Datadog APM, or a similar tracing agent in the application tier.
- SQL tracing enabled so each HTTP/API request shows database spans, timings, and query patterns.
- Service, endpoint, environment, and env/owner/service tags to identify database and application ownership.

To set up:

- Trace customer-facing workflows such as the support "search users" screen from API endpoint to SQL spans.
- Group latency by service, endpoint, and query fingerprint to identify which DB calls hurt user-facing SLAs.
- Correlate traces with deploy markers, DB exceptions, connection pool metrics, and RDS wait events.

Pros:

- Ties database performance directly to customer experience and business workflows.
- Helps decide whether to tune SQL, add indexes, adjust connection pools, change application code, or scale infrastructure.

Cons:

- Requires application instrumentation, sampling decisions, privacy controls, and usually APM licensing.
- SQL capture must be configured carefully so PHI/PII and bind values are not exposed unnecessarily.

Alert examples:

- P95 endpoint latency above SLO with DB spans contributing most of the time.
- Error-rate spikes tied to database exceptions such as timeouts, deadlocks, or connection pool exhaustion.
- A newly deployed service version increases query count or DB time per request.

### Strategy 3: AI-Assisted Analysis And Anomaly Detection

For an AI-first operating model, use automation to reduce time-to-diagnosis while keeping humans in control of production changes.

- Feed sanitized query metrics into anomaly detection: latency, rows, I/O, plan hash, call frequency, waits, and error patterns.
- Use Datadog anomaly service, or an internal ML job to detect workload shifts and unusual query behavior.
- Use an internal LLM assistant to summarize workload changes, for example: "In the last 24 hours, a new query on `user_addresses.city` accounts for 30% of DB load and appears to be missing a supporting index."
- Auto-open tickets or Slack alerts with the normalized query, time window, owner, `EXPLAIN` output, dashboard links, and suggested diagnostic steps.
- Add guardrails: redact PHI/PII, avoid raw bind values, and require human review before applying indexes or parameter changes.

My recommendation would be to start with Strategy 1 and Strategy 2 together. 
Then implement Strategy 3 to make the monitoring program efficient and more proactive.

## Q2: Slow Query Diagnosis

The slow query filters on `lower(email)`, but the exercise schema only has a unique btree index on `users(email)`. PostgreSQL cannot use that plain index for the expression predicate, so it may scan far more of the 1M-row `users` table than necessary. After finding the user, the join also needs an index on `user_addresses(user_id)` to avoid inefficient access into a 2.5M-row address table.

Core diagnosis:

- The existing unique index is on `users(email)`, but the query applies `lower(email)`.
- A normal btree index on `email` does not satisfy an expression predicate on `lower(email)`.
- The query should qualify the column as `u.email` to avoid ambiguity as schemas evolve.
- The `LEFT JOIN` into `user_addresses` can still be expensive unless `user_addresses(user_id)` is indexed.
- If one user can have multiple addresses, the result size and join strategy should be checked with `EXPLAIN (ANALYZE, BUFFERS)`.

**Evidence:** See [`explain_analyze_comparison.md`](explain_analyze_comparison.md) for side-by-side representative `EXPLAIN (ANALYZE, BUFFERS)` plans (seq scan + heap probe vs index-driven nested loop) so the performance delta is visible, not only described.

Recommended fix:

- Add `CREATE INDEX CONCURRENTLY users_lower_email_idx ON users (lower(email));`
- Add `CREATE INDEX CONCURRENTLY user_addresses_user_id_idx ON user_addresses (user_id);`
- Longer term, consider `citext` or a normalized `email_lower` column if case-insensitive email lookup is a core application contract.

See `db/indexes.sql`, `db/queries/slow_query_before.sql`, and `db/queries/slow_query_after.sql`.

## Q3: Search Strategy

I would propose **at least four** tiers and choose based on how support actually searches and how “AI-forward” the product needs to be.

1. **Exact indexed lookup in Postgres** for email, phone, and zipcode. Simple, fast, auditable, and the right default for PHI-aware support tooling.
2. **Trigram / full-text in Postgres** (`pg_trgm`, optional `tsvector`) for partial names and city. Good typo tolerance at the character level without a new service.
3. **Dedicated search index (OpenSearch/Elasticsearch) fed by CDC** when you need relevance tuning, highlighting, cross-field ranking, and independent scale. For an AI-integrated platform, plan this as **hybrid search**: **BM25 (keyword)** on structured fields plus **kNN vector search** on embeddings of allowed text (e.g. concatenated name + city, not raw clinical content), merged with RRF or weighted scores. Keyword handles exact ticket numbers and zipcodes; vectors handle messy free-text.
4. **Semantic retrieval in Postgres with `pgvector`** when you want similarity search (nicknames, noisy input, multilingual transliteration) **without** standing up a search cluster. Store embeddings only for minimized text, pre-filter on exact fields where possible, and tune IVFFlat/HNSW with realistic load tests.

**Tradeoff summary**

| Strategy | Pros | Cons |
| --- | --- | --- |
| Exact Postgres | Lowest ops; predictable plans | Poor for fuzzy discovery |
| Trigram / FTS in Postgres | Stays in RDS; good for names/city | Index size; ranking is manual |
| Hybrid OpenSearch | Best relevance and scale; true hybrid keyword + semantic | CDC, security, eventual consistency |
| pgvector in RDS | One datastore; semantic “near match” | Embedding pipeline; index tuning; governance |

**Top recommendation:** Ship **(1) + (2)** immediately with clear data-minimization rules. If leadership wants an **AI-forward** support experience, charter **(3) hybrid OpenSearch** as the strategic search plane; use **(4)** when semantic retrieval is required but cluster overhead is unacceptable.

See `db/queries/search_strategies.sql`. For **slow-query** plan before/after evidence, see [`explain_analyze_comparison.md`](explain_analyze_comparison.md).

## Q4: Product Launch Schema Change Process

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
- **Natural language to SQL (guarded):** use an internal LLM with **read-only** access to a *sanitized* schema catalog (no production data) to draft support queries; enforce **human review**, row limits, and `EXPLAIN` in staging before any adoption. Never send live PHI to external models.
- **RAG over runbooks:** retrieve internal DBA playbooks and past incidents to propose index candidates and parameter checks; treat outputs as hypotheses validated with `EXPLAIN (ANALYZE, BUFFERS)` and load tests.
- **Hybrid retrieval product-side:** combine lexical filters (email, zip) with embedding similarity in OpenSearch or pgvector; the database still owns transactional truth—search is a **derived** view.
