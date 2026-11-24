-- ==============================================================================
-- LAGANSTAFF PERMISSION FIX & POSTGREST PRIVILEGES
-- Run this in Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. Schema Access
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Grant Access to All Tables (Row Level Security will enforce actual user data isolation)
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;

-- 3. Grant Access to All Sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- 4. Grant Access to All Stored Functions / RPCs
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- 5. Set Default Privileges for Any Future Objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- 6. Activate Test Number: 7052417102 (Confirms email & phone for Dev/Test Mode)
UPDATE auth.users
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  phone_confirmed_at = COALESCE(phone_confirmed_at, NOW()),
  phone = '+917052417102',
  updated_at = NOW()
WHERE email = 'user7052417102@gmail.com';

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

-- Verification query
SELECT id, email, phone, email_confirmed_at, phone_confirmed_at
FROM auth.users
WHERE email = 'user7052417102@gmail.com';
