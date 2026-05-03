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
-- Strategy D (AI-forward / semantic): pgvector in Postgres for similarity search.
-- Use when support needs "close" matches beyond trigrams: nicknames, noisy OCR,
-- transliteration, or short free-text blobs you embed once and query by vector.
-- Pros: stays in RDS, one consistency boundary, works with pre-filter (email, zip)
--       then ORDER BY embedding <=> query_embedding LIMIT k.
-- Cons: embedding pipeline, storage, re-embedding on updates, index tuning (lists
--       for IVFFlat, m/ef_construction for HNSW), and governance for PHI/PII in
--       embedded text (minimize what you embed; prefer hashed IDs + structured fields).
--
-- Example shape (not enabled by default; requires CREATE EXTENSION vector):
--
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS name_embedding vector(1536);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS users_name_embedding_ivfflat_idx
--     ON users USING ivfflat (name_embedding vector_cosine_ops) WITH (lists = 100);
--
-- SELECT u.id, u.email, u.first_name, u.last_name
-- FROM users u
-- WHERE u.name_embedding IS NOT NULL
-- ORDER BY u.name_embedding <=> :query_embedding
-- LIMIT 20;
--
-- Hybrid pattern inside Postgres: combine Strategy A predicates (exact email/zip)
-- with a vector ORDER BY in a subquery, or use Reciprocal Rank Fusion in app code.

-- Strategy C (continued): hybrid keyword + vector in OpenSearch / Elasticsearch.
-- For an AI-forward search *service*, combine:
--   - BM25 (or text analyzers) on names, email tokens, city, zip as keyword fields
--   - kNN / dense_vector query on support-note or "full name line" embeddings
-- RRF (Reciprocal Rank Fusion) or weighted linear combination merges ranked lists.
-- Pros: industry-standard hybrid retrieval, scaling, and relevance tuning.
-- Cons: CDC, security review, and eventual consistency vs OLTP.

-- Top recommendation (tiered):
-- 1) Strategy A + targeted trigram (B) for launch: lowest ops, HIPAA-friendly.
-- 2) When relevance and scale demand it, Strategy C with hybrid BM25 + vector kNN.
-- 3) If you need semantic retrieval without a search cluster, add D (pgvector)
--    behind strict data minimization and DBA review of index parameters.
