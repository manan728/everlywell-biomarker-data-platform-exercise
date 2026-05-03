-- Minimal sample data for local experimentation. Values are synthetic.

INSERT INTO users (
    encrypted_password,
    password_salt,
    email,
    created_at,
    updated_at,
    first_name,
    last_name,
    phone_number
)
VALUES
    ('redacted', 'salt-a', 'xyz@gmail.com', now(), now(), 'Avery', 'Sample', '5125550100'),
    ('redacted', 'salt-b', 'care@example.com', now(), now(), 'Jordan', 'Care', '5125550101')
ON CONFLICT DO NOTHING;

INSERT INTO user_addresses (
    user_id,
    firstname,
    lastname,
    address1,
    address2,
    city,
    zipcode,
    phone,
    state_name,
    created_at,
    updated_at
)
SELECT
    u.id,
    u.first_name,
    u.last_name,
    '123 Wellness Way',
    NULL,
    'Austin',
    '78701',
    u.phone_number,
    'TX',
    now(),
    now()
FROM users u
WHERE u.email IN ('xyz@gmail.com', 'care@example.com');
