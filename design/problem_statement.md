# Problem Statement

The exercise asks for a DBA response to four production-style concerns:

1. Recommend at least two strategies to monitor PostgreSQL RDS database-call performance and alert on bad-performing queries.
2. Diagnose a query that consistently takes 10-30 seconds against about 1M `users` rows and about 2.5M `user_addresses` rows.
3. Propose at least three strategies to support customer-support search across `first_name`, `last_name`, `email`, `phone_number`, `city`, and `zipcode`.
4. Describe a high-level process for reviewing and implementing new columns/tables for a high-profile product launch while protecting data quality and existing integrations.

This repository answers those questions with version-controlled artifacts rather than a prose-only response.

The detailed answer for question 4 lives in `design/change_review_process.md`.

## Exercise Query

```sql
SELECT
    u.id,
    u.email,
    ua.id,
    u.first_name user_first_name,
    u.last_name user_last_name,
    ua.address1,
    ua.address2,
    ua.city,
    ua.state_name,
    ua.zipcode,
    ua.phone
FROM "users" u
LEFT JOIN user_addresses ua ON ua.user_id = u.id
WHERE lower(email) = 'xyz@gmail.com';
```

## Core Diagnosis

The existing unique index is on `users(email)`, but the query filters on `lower(email)`. 
PostgreSQL cannot use a normal btree index on `email` for that expression. Once the user is found, 
the join to `user_addresses` also needs a supporting index on `user_addresses(user_id)` 
so PostgreSQL can avoid scanning or inefficiently probing a multi-million-row table.
