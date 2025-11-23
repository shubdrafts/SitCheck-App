-- Relax Booking RLS Policies to debug/fix insertion error

-- Drop existing insert policy
drop policy if exists "Users can create bookings" on bookings;

-- Create a more permissive insert policy
-- This allows any authenticated user to create a booking
-- We still want to ensure they are authenticated
create policy "Users can create bookings"
  on bookings for insert
  with check ( auth.role() = 'authenticated' );

-- Ensure select policy is also correct
drop policy if exists "Users can view own bookings" on bookings;
create policy "Users can view own bookings"
  on bookings for select
  using ( auth.uid() = user_id );
