resource "datadog_monitor" "postgres_p95_query_latency" {
  count = var.datadog_enabled ? 1 : 0

  name    = "Postgres P95 query latency elevated - ${var.environment}"
  type    = "query alert"
  message = "P95 database call latency is elevated. Check pg_stat_statements, recent deploys, and RDS wait events."

  query = "avg(last_15m):p95:trace.postgres.query.duration{env:${var.environment}} > 1"

  monitor_thresholds {
    warning  = 0.5
    critical = 1
  }

  tags = [
    "service:biomarker-data-platform",
    "env:${var.environment}",
    "managed-by:terraform"
  ]
}

resource "datadog_monitor" "postgres_error_rate" {
  count = var.datadog_enabled ? 1 : 0

  name    = "Postgres error rate elevated - ${var.environment}"
  type    = "query alert"
  message = "Database errors are elevated. Check application traces, failed migrations, locks, and connection pool saturation."

  query = "sum(last_10m):sum:trace.postgres.query.errors{env:${var.environment}}.as_count() > 25"

  monitor_thresholds {
    warning  = 10
    critical = 25
  }

  tags = [
    "service:biomarker-data-platform",
    "env:${var.environment}",
    "managed-by:terraform"
  ]
}
