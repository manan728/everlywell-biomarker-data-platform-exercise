# Problem Statement

This repository responds to the original DBA technical exercise with version-controlled SQL, infrastructure, CI, and design notes.

## Original Exercise Questions

1. For a Postgres AWS RDS database, give at least two strategies you would recommend to monitor the performance of all database calls from the application. What do you recommend using for setting up alerts to notify bad performing queries?

2. Performance monitor picked the query below as taking between 10-30 seconds consistently. The `users` table has about 1 million rows and the `user_addresses` table has about 2.5 million rows. What do you think is causing this query to take this long for every execution?

3. The application engineering team gets a request from the customer support team to add searching capability for looking up users in the `users` and `user_addresses` tables. At the very least, they want to add searching by any of the following fields: `first_name`, `last_name`, `email`, `phone_number`, `city`, and `zipcode`. As the DBA, recommend at least three different strategies to support this request. Give pros and cons of each strategy. What would be your top recommendation?

4. The application team has requested that several new columns and tables be added to the database in order to support a high-profile new product launch that is expected to increase users and revenue on the platform. What high-level process would you propose for reviewing and implementing those changes to ensure they are properly structured to ensure data quality and integrate reliably with existing data?

## Provided Schema

The schema from the exercise is captured in [`../db/schema.sql`](../db/schema.sql).

## Slow Query From Exercise

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

## Answer Map

- Q1 monitoring and alerting: [`solution_overview.md`](solution_overview.md#q1-monitoring-and-alerting), [`../infra/terraform`](../infra/terraform)
- Q2 slow query diagnosis: [`solution_overview.md`](solution_overview.md#q2-slow-query-diagnosis), [`../db/indexes.sql`](../db/indexes.sql), [`../db/queries/slow_query_before.sql`](../db/queries/slow_query_before.sql), [`../db/queries/slow_query_after.sql`](../db/queries/slow_query_after.sql)
- Q3 search strategies: [`solution_overview.md`](solution_overview.md#q3-search-strategy), [`../db/queries/search_strategies.sql`](../db/queries/search_strategies.sql)
- Q4 product-launch change process: [`solution_overview.md`](solution_overview.md#q4-product-launch-schema-change-process), [`change_review_process.md`](change_review_process.md)
