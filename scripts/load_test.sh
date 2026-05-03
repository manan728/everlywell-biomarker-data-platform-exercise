#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <postgres-url>" >&2
    exit 2
fi

database_url="$1"

psql "$database_url" --set=ON_ERROR_STOP=1 <<'SQL'
\timing on
SELECT count(*) FROM users;
SELECT count(*) FROM user_addresses;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.id,
    u.email,
    ua.id AS user_address_id
FROM users AS u
LEFT JOIN user_addresses AS ua
    ON ua.user_id = u.id
WHERE lower(u.email) = lower('xyz@gmail.com');
SQL
