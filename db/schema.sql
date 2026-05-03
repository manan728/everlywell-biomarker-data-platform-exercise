-- Schema from the DBA technical exercise.
-- This file intentionally mirrors the prompt before adding tuning indexes.

CREATE TABLE IF NOT EXISTS users (
    id serial NOT NULL,
    encrypted_password varchar(128) NULL,
    password_salt varchar(128) NULL,
    email varchar NULL,
    created_at timestamp NOT NULL,
    updated_at timestamp NOT NULL,
    first_name varchar NULL,
    last_name varchar NULL,
    phone_number varchar NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS email_idx_unique
    ON users USING btree (email);

CREATE TABLE IF NOT EXISTS user_addresses (
    id serial NOT NULL,
    user_id int4 NOT NULL,
    firstname varchar NULL,
    lastname varchar NULL,
    address1 varchar NULL,
    address2 varchar NULL,
    city varchar NULL,
    zipcode varchar NULL,
    phone varchar NULL,
    state_name varchar NULL,
    alternative_phone varchar NULL,
    state_id int4 NULL,
    country_id int4 NULL,
    created_at timestamp NOT NULL,
    updated_at timestamp NOT NULL,
    confirmed_at timestamp NULL,
    enterprise_partner_id int4 NULL,
    CONSTRAINT spree_addresses_pkey PRIMARY KEY (id)
);

ALTER TABLE user_addresses
    ADD CONSTRAINT fk_user_addresses_user_id_users_id
    FOREIGN KEY (user_id)
    REFERENCES users(id);
