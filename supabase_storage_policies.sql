-- 1. Create the 'avatars' bucket (if it doesn't exist)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 2. Create the 'restaurants' bucket (if it doesn't exist)
insert into storage.buckets (id, name, public)
values ('restaurants', 'restaurants', true)
on conflict (id) do nothing;

-- 3. Enable RLS on storage.objects (usually enabled by default, but good to ensure)
-- 3. (Skipped) RLS is already enabled by default.

-- 4. Policies for 'avatars' bucket
-- Allow any authenticated user to upload an avatar
create policy "Authenticated users can upload avatars"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'avatars' );

-- Allow anyone (public) to view avatars
create policy "Public can view avatars"
on storage.objects for select
to public
using ( bucket_id = 'avatars' );

-- Allow users to update their own uploads
create policy "Users can update own avatars"
on storage.objects for update
to authenticated
using ( bucket_id = 'avatars' )
with check ( bucket_id = 'avatars' );

-- 5. Policies for 'restaurants' bucket
-- Allow any authenticated user (owners) to upload restaurant images
create policy "Authenticated users can upload restaurant images"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'restaurants' );

-- Allow anyone (public) to view restaurant images
create policy "Public can view restaurant images"
on storage.objects for select
to public
using ( bucket_id = 'restaurants' );
