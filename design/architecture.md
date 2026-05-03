# Architecture Sketch

The exercise does not require a running application, but this is the operating model I would present for an Everlywell-like RDS PostgreSQL environment.

```text
Application services
        |
        | SQL calls with tracing / service tags
        v
AWS RDS PostgreSQL
        |
        +--> pg_stat_statements / auto_explain / PostgreSQL logs
        +--> RDS Performance Insights
        +--> CloudWatch metrics and alarms
        +--> Datadog APM, dashboards, monitors, and SLOs
        +--> AI-assisted anomaly summaries and ticket creation

Future search/analytics option:
RDS logical replication / CDC --> Kafka --> OpenSearch (hybrid: BM25 + vector kNN) / analytics consumers
Optional in-DB semantic path: RDS PostgreSQL + pgvector for smaller-scope similarity search
```

## Signal Flow

| Layer | Signals | Used for |
| --- | --- | --- |
| Application | Endpoint latency, SQL spans, errors, deploy markers | Tying database behavior to user-facing workflows |
| PostgreSQL | Query fingerprints, execution time, buffers, slow plans, locks | Diagnosing expensive or unstable SQL |
| RDS / AWS | CPU, IOPS, latency, connections, storage, Performance Insights waits | Capacity and platform health |
| Datadog / Observability | SLOs, monitors, dashboards, traces | Alerting and incident response |
| AI / Automation | Anomaly summaries, workload diffs, suggested diagnostics | Faster triage with human approval gates |
