-- Create a secure view for public booking data
-- This allows users to see WHICH tables are booked without seeing WHO booked them

create or replace view public_bookings as
select
  id,
  restaurant_id,
  table_id as table_label,
  booking_date,
  booking_time,
  status
from bookings
where status in ('confirmed', 'checkedIn', 'reserved', 'occupied');

-- Grant access to authenticated users
grant select on public_bookings to authenticated;
