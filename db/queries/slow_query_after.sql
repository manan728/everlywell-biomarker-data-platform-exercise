-- Optimized version after adding:
--   CREATE INDEX CONCURRENTLY users_lower_email_idx ON users (lower(email));
--   CREATE INDEX CONCURRENTLY user_addresses_user_id_idx ON user_addresses (user_id);
--
-- Longer-term option: use citext for email or store a normalized email_lower column
-- if case-insensitive email lookup is a common application contract.

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
