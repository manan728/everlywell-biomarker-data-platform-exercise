-- Customer-support search strategies for users and user_addresses.

-- Strategy A: exact indexed lookup for deterministic fields.
-- Best for email, phone, and zipcode where support usually has an exact value.
-- Pros: simple, cheap, predictable query plans.
-- Cons: weak for misspellings, partial names, transposed phone formats, and broad discovery.

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_lower_email_idx
    ON users (lower(email));

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_phone_number_idx
    ON users (phone_number);

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_phone_idx
    ON user_addresses (phone);

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_zipcode_idx
    ON user_addresses (zipcode);

SELECT
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    ua.city,
    ua.zipcode,
    ua.phone
FROM users AS u
LEFT JOIN user_addresses AS ua
    ON ua.user_id = u.id
WHERE lower(u.email) = lower(:email)
   OR u.phone_number = :phone_number
   OR ua.phone = :phone_number
   OR ua.zipcode = :zipcode;

-- Strategy B: trigram / full-text search for human-entered name and city search.
-- Best when support needs partial matching, typo tolerance, or "starts like" behavior.
-- Pros: better user experience for names/cities without leaving Postgres.
-- Cons: bigger indexes, more tuning, and careful result ranking required.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_first_name_trgm_idx
    ON users USING gin (first_name gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_last_name_trgm_idx
    ON users USING gin (last_name gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_city_trgm_idx
    ON user_addresses USING gin (city gin_trgm_ops);

SELECT
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    ua.city,
    similarity(u.first_name, :first_name) AS first_name_score,
    similarity(u.last_name, :last_name) AS last_name_score
FROM users AS u
LEFT JOIN user_addresses AS ua
    ON ua.user_id = u.id
WHERE u.first_name ILIKE '%' || :first_name || '%'
   OR u.last_name ILIKE '%' || :last_name || '%'
   OR ua.city ILIKE '%' || :city || '%'
ORDER BY
    greatest(
        similarity(u.first_name, :first_name),
        similarity(u.last_name, :last_name),
        similarity(ua.city, :city)
    ) DESC
LIMIT 50;

-- Strategy C: denormalized search document in OpenSearch/Elasticsearch.
-- Best when search becomes a support workflow rather than a point lookup.
-- Pros: rich ranking, typo tolerance, highlighting, filtering, and independent scaling.
-- Cons: CDC pipeline, eventual consistency, privacy controls, and operational complexity.
--
-- Example document:
-- {
--   "user_id": 123,
--   "email": "xyz@gmail.com",
--   "first_name": "Avery",
--   "last_name": "Sample",
--   "phone_numbers": ["5125550100", "5125550199"],
--   "addresses": [
--     {
--       "address1": "123 Wellness Way",
--       "city": "Austin",
--       "state_name": "TX",
--       "zipcode": "78701"
--     }
--   ],
--   "updated_at": "2026-05-02T00:00:00Z"
-- }
--
-- Top recommendation:
-- Start with Strategy A plus targeted trigram indexes from Strategy B. Move to
-- Strategy C only when support needs ranking, typo tolerance, audit-friendly
-- search UX, or cross-domain search that Postgres should not own.
