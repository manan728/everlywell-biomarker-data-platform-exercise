-- Original exercise query.
-- Problem: lower(email) does not match the existing btree index on users(email).
-- Secondary concern: the join needs an index on user_addresses(user_id).

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
