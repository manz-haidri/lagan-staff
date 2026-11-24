-- ==============================================================================
-- LAGANSTAFF: ACTIVATE TEST NUMBER (7052417102)
-- Run this in your Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. Confirm the newly created user in auth.users
UPDATE auth.users
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  phone_confirmed_at = COALESCE(phone_confirmed_at, NOW()),
  phone = '+917052417102',
  updated_at = NOW()
WHERE email = 'user7052417102@gmail.com';

-- 2. Fallback: If not yet in auth.users, create it directly with confirmed status
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  phone,
  phone_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'user7052417102@gmail.com',
  crypt('TestPassword123!', gen_salt('bf')),
  NOW(),
  '+917052417102',
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"phone":"+917052417102"}',
  NOW(),
  NOW(),
  '',
  ''
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE email = 'user7052417102@gmail.com'
);

-- 3. Also grant permissions just in case
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- 4. Verify test user status
SELECT id, email, phone, email_confirmed_at, phone_confirmed_at
FROM auth.users
WHERE email = 'user7052417102@gmail.com';
