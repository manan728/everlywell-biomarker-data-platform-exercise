-- Same logical query as slow_query_before.sql after the indexes in db/indexes.sql
-- (expression index on lower(email) and btree on user_addresses.user_id).
-- Those indexes are what fix the plan; the original WHERE lower(email) = '...'
-- would use them too once created.
--
-- Edits here are optional hygiene: qualify u.email, use lower() on both sides for
-- parameterized lookups (lower(u.email) = lower($1)), and clearer output aliases.
--
-- Longer-term option: citext or a normalized email_lower column if case-insensitive
-- email is a core contract.

SELECT
    u.id,
    u.email,
    ua.id AS user_address_id,
    u.first_name AS user_first_name,
    u.last_name AS user_last_name,
    ua.address1,
    ua.address2,
    ua.city,
    ua.state_name,
    ua.zipcode,
    ua.phone
FROM users AS u
LEFT JOIN user_addresses AS ua
    ON ua.user_id = u.id
WHERE lower(u.email) = lower('xyz@gmail.com');
