-- Create restaurants table
create table if not exists public.restaurants (
  id text primary key,
  owner_id uuid references auth.users(id) on delete cascade,
  name text not null,
  cuisine text,
  description text,
  price_range text,
  address text,
  location_lat double precision,
  location_lng double precision,
  banner_image text,
  menu_images jsonb default '[]'::jsonb,
  specialties jsonb default '[]'::jsonb,
  tables jsonb default '[]'::jsonb,
  occupancy_status text default 'empty',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.restaurants enable row level security;

-- Drop existing policies if any
drop policy if exists "Restaurants are viewable by everyone" on restaurants;
drop policy if exists "Owners can insert their own restaurant" on restaurants;
drop policy if exists "Owners can update their own restaurant" on restaurants;
drop policy if exists "Owners can delete their own restaurant" on restaurants;

-- Create RLS policies
-- Everyone can view restaurants (public access)
create policy "Restaurants are viewable by everyone"
  on restaurants
  for select
  using ( true );

-- Authenticated users can insert restaurants they own
create policy "Owners can insert their own restaurant"
  on restaurants
  for insert
  with check ( auth.uid() = owner_id );

-- Owners can update their own restaurants
create policy "Owners can update their own restaurant"
  on restaurants
  for update
  using ( auth.uid() = owner_id )
  with check ( auth.uid() = owner_id );

-- Owners can delete their own restaurants
create policy "Owners can delete their own restaurant"
  on restaurants
  for delete
  using ( auth.uid() = owner_id );

-- Create index for faster queries
create index if not exists restaurants_owner_id_idx on restaurants(owner_id);
create index if not exists restaurants_updated_at_idx on restaurants(updated_at desc);
