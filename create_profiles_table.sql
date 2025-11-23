-- Create the profiles table
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  name text,
  role text,
  bio text,
  "phoneNumber" text,
  "profilePhoto" text
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Policies

-- 1. Allow public read access (so users can see each other's basic info if needed, or just for simplicity)
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
