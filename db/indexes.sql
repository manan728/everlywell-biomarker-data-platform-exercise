-- Recommended indexes for the slow exercise query and support-search workflows.
-- In production, create the high-cardinality indexes CONCURRENTLY outside a transaction.

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_lower_email_idx
    ON users (lower(email));

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_user_id_idx
    ON user_addresses (user_id);

-- Optional exact-search indexes for support lookup fields.
CREATE INDEX CONCURRENTLY IF NOT EXISTS users_phone_number_idx
    ON users (phone_number);

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_phone_idx
    ON user_addresses (phone);

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_zipcode_idx
    ON user_addresses (zipcode);

-- Optional fuzzy-search support. Requires pg_trgm GIN indexes for ILIKE or similarity matching.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_first_name_trgm_idx
    ON users USING gin (first_name gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS users_last_name_trgm_idx
    ON users USING gin (last_name gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS user_addresses_city_trgm_idx
    ON user_addresses USING gin (city gin_trgm_ops);
