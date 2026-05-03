#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <postgres-url> <query-file>" >&2
    exit 2
fi

database_url="$1"
query_file="$2"

if [[ ! -f "$query_file" ]]; then
    echo "Query file not found: $query_file" >&2
    exit 2
fi

query_sql="$(sed '/^[[:space:]]*--/d; /^[[:space:]]*$/d' "$query_file" | tr '\n' ' ')"

psql "$database_url" \
    --set=ON_ERROR_STOP=1 \
    --command="EXPLAIN (ANALYZE, BUFFERS, VERBOSE) $query_sql"
