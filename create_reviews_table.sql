-- Create reviews table
create table if not exists public.reviews (
  id uuid default gen_random_uuid() primary key,
  restaurant_id text references public.restaurants(id) on delete cascade not null,
  -- Reference public.profiles to allow embedding profile data (name) in queries
  user_id uuid references public.profiles(id) on delete cascade not null,
  rating double precision not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.reviews enable row level security;

-- Policies

-- 1. Reviews are viewable by everyone
create policy "Reviews are viewable by everyone"
  on reviews for select
  using ( true );

-- 2. Authenticated users can insert their own reviews
create policy "Users can insert their own reviews"
  on reviews for insert
  with check ( auth.uid() = user_id );

-- 3. Users can update their own reviews
create policy "Users can update their own reviews"
  on reviews for update
  using ( auth.uid() = user_id )
  with check ( auth.uid() = user_id );

-- 4. Users can delete their own reviews
create policy "Users can delete their own reviews"
  on reviews for delete
  using ( auth.uid() = user_id );

-- Indexes
create index if not exists reviews_restaurant_id_idx on reviews(restaurant_id);
create index if not exists reviews_user_id_idx on reviews(user_id);
