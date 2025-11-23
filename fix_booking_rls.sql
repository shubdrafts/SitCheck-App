-- Fix Booking RLS Policies

-- Enable RLS
alter table public.bookings enable row level security;

-- Drop existing policies to ensure a clean slate
drop policy if exists "Users can view own bookings" on bookings;
drop policy if exists "Users can create bookings" on bookings;
drop policy if exists "Users can update own bookings" on bookings;
drop policy if exists "Owners can view bookings for their restaurant" on bookings;
drop policy if exists "Owners can update bookings for their restaurant" on bookings;

-- Re-create Policies

-- 1. Users can view their own bookings
create policy "Users can view own bookings"
  on bookings for select
  using ( auth.uid() = user_id );

-- 2. Users can create bookings
-- The check ensures they can only create bookings for themselves
create policy "Users can create bookings"
  on bookings for insert
  with check ( auth.uid() = user_id );

-- 3. Users can update their own bookings (e.g. to cancel)
create policy "Users can update own bookings"
  on bookings for update
  using ( auth.uid() = user_id );

-- 4. Restaurant owners can view bookings for their restaurant
create policy "Owners can view bookings for their restaurant"
  on bookings for select
  using ( 
    exists (
      select 1 from restaurants
      where restaurants.id = bookings.restaurant_id
      and restaurants.owner_id = auth.uid()
    )
  );

-- 5. Restaurant owners can update bookings for their restaurant (e.g. confirm/reject)
create policy "Owners can update bookings for their restaurant"
  on bookings for update
  using ( 
    exists (
      select 1 from restaurants
      where restaurants.id = bookings.restaurant_id
      and restaurants.owner_id = auth.uid()
    )
  );
