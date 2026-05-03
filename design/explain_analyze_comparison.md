# Slow Query: Representative `EXPLAIN (ANALYZE, BUFFERS)` Comparison

This section answers the exercise slow query with **concrete plan shapes**, not only narrative diagnosis. The snippets below are **representative** of what PostgreSQL produces when:

- `users` has ~1M rows and `user_addresses` ~2.5M rows (per the prompt),
- statistics are fresh (`ANALYZE` has been run),
- the **before** state has only `CREATE UNIQUE INDEX email_idx_unique ON users (email)` and **no** index on `user_addresses(user_id)`,
- the **after** state adds `users(lower(email))` and `user_addresses(user_id)` as in `db/indexes.sql`.

**Your exact timings and costs will differ** by instance class, `work_mem`, parallelism, and data skew. Always capture ground truth with:

```bash
./scripts/explain.sh "$DATABASE_URL" db/queries/slow_query_before.sql
./scripts/explain.sh "$DATABASE_URL" db/queries/slow_query_after.sql
```

Use `EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS)` in staging when investigating I/O vs CPU.

---

## Before: expression blocks the email index, join lacks `user_id` index

**Symptoms in the plan**

- `Seq Scan` on `users` with a filter on `lower(email)` — the existing btree on `email` cannot be used for the expression, so the planner scans the heap (or a large fraction of it).
- For each surviving `users` row, the nested loop into `user_addresses` cannot use a supporting btree on `user_id`, so the inner side degrades to repeated **sequential** or **bitmap heap** scans over a large address heap.

**Representative output (abbreviated)**

```text
Nested Loop Left Join  (cost=0.00..482391.42 rows=12 width=...) (actual time=4.2..18432.7 rows=3 loops=1)
  ->  Seq Scan on users u  (cost=0.00..35891.00 rows=1 width=...) (actual time=0.05..8421.3 rows=1 loops=1)
        Filter: (lower((email)::text) = 'xyz@gmail.com'::text)
        Rows Removed by Filter: 999999
        Buffers: shared read=12450 hit=8920
  ->  Seq Scan on user_addresses ua  (cost=0.00..446412.18 rows=3 width=...) (actual time=4.1..10008.2 rows=3 loops=1)
        Filter: (user_id = u.id)
        Rows Removed by Filter: 2499997
        Buffers: shared read=38210 hit=12005
Planning Time: 0.8 ms
Execution Time: 18433.2 ms
```

**How to read this**

- **~8–10+ seconds** can sit on the `users` seq scan alone at 1M rows with cold cache or heavy I/O.
- The **inner seq scan** over ~2.5M `user_addresses` rows per outer row is the other dominant term; with multiple addresses per user, cost scales with table size, not result size.
- **Buffers** lines show whether you are I/O-bound (`read` heavy) or cache-friendly (`hit` heavy).

---

## After: expression index + `user_id` join index

**Symptoms in the plan**

- `Index Scan` (or `Bitmap Index Scan`) on `users` using `users_lower_email_idx` — the predicate matches the index definition.
- Nested loop (or hash join, depending on row counts and memory) into `user_addresses` via **`Index Scan using user_addresses_user_id_idx`**, touching only rows for that user.

**Representative output (abbreviated)**

```text
Nested Loop Left Join  (cost=0.85..24.12 rows=12 width=...) (actual time=0.03..0.42 rows=3 loops=1)
  ->  Index Scan using users_lower_email_idx on users u  (cost=0.43..8.45 rows=1 width=...) (actual time=0.02..0.03 rows=1 loops=1)
        Index Cond: (lower((email)::text) = 'xyz@gmail.com'::text)
        Buffers: shared hit=4 read=0
  ->  Index Scan using user_addresses_user_id_idx on user_addresses ua  (cost=0.42..15.67 rows=12 width=...) (actual time=0.01..0.38 rows=3 loops=1)
        Index Cond: (user_id = u.id)
        Buffers: shared hit=9 read=0
Planning Time: 0.6 ms
Execution Time: 0.45 ms
```

**Order-of-magnitude delta (illustrative)**

| Metric | Before (representative) | After (representative) |
| --- | --- | --- |
| Execution time | Tens of seconds | Sub-millisecond to a few ms (warm cache) |
| `users` access | Seq Scan, ~1M filters | Index Scan on `lower(email)` |
| `user_addresses` access | Heap scan at scale | Index seek on `user_id` |

---

## Presentation tip

When you walk the panel through this, show **one slide with side-by-side plans** (or this doc) and narrate: *wrong index shape for the predicate*, *missing join child index*, then *buffers/time*. That directly addresses “show the performance delta visually” without hand-waving.
