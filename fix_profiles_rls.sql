-- Fix Profiles RLS Policies

-- Enable RLS
alter table public.profiles enable row level security;

-- Drop existing policies to ensure a clean slate
drop policy if exists "Public profiles are viewable by everyone." on profiles;
drop policy if exists "Users can insert their own profile." on profiles;
drop policy if exists "Users can update own profile." on profiles;

-- Re-create Policies

-- 1. Allow public read access
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

-- 2. Allow users to insert their own profile
create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

-- 3. Allow users to update their own profile
create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );
