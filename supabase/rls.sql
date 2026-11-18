-- =====================================================================
-- ProNear – Row Level Security (RLS)
--
-- PROBLEM FOUND: RLS is OFF on users, providers, service_requests, messages,
-- chat_rooms, notifications, favorites, business_products, ... so the
-- policies that exist are NOT enforced. Anyone with the anon key (it is inside
-- the APK) can read/modify/delete every row.
--
-- HOW TO RUN (in this order, one block at a time):
--   STEP 0  preflight checks   (read-only)
--   STEP 1  helper functions + policies   (safe: no effect while RLS is off)
--   STEP 2  enable RLS        (this is the moment protection starts)
--   STEP 3  test the app      (checklist in FIX_GUIDE.md)
--   ROLLBACK  if something breaks, run the rollback block, then tell me the error
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 0 – PREFLIGHT (run each query separately, send me the output)
-- ---------------------------------------------------------------------
-- (0a) delete_my_account / delete_message_for_everyone MUST be security definer
--      (prosecdef = true), otherwise they will stop working once RLS is on.
select proname, prosecdef from pg_proc
where proname in ('delete_my_account', 'delete_message_for_everyone', 'cnic_registration_info');

-- (0b) the function behind trigger on_auth_user_created MUST be security definer,
--      otherwise sign-up breaks once RLS is on for public.users.
select t.tgname, p.proname as function_name, p.prosecdef
from pg_trigger t join pg_proc p on p.oid = t.tgfoid
where t.tgname = 'on_auth_user_created';
-- If prosecdef = false for (0a) or (0b), fix it BEFORE step 2:
--   alter function public.<function_name>(<args>) security definer set search_path = public;
--   e.g.  alter function public.handle_new_user() security definer set search_path = public;

-- (0c) storage policies (any "true" or no bucket check = open to everyone)
select policyname, cmd, roles, qual, with_check
from pg_policies where schemaname = 'storage' and tablename = 'objects' order by 1;


-- ---------------------------------------------------------------------
-- STEP S – STORAGE CLEANUP (run now; found from your (0c) output)
-- Policies are OR-ed, so each old "bucket only" policy below cancels the
-- owner-only policies. Examples of what they allow today:
--   * any logged-in user can VIEW every provider's CNIC / face photo
--   * anyone, even NOT logged in, can upload / overwrite / DELETE files in `profiles`
-- The owner-only policies (named "... own insert/update/delete", "verif own ...")
-- stay and keep everything working.
-- ---------------------------------------------------------------------
-- verification_images (CNIC / face): keep only "verif own *"
drop policy if exists "Allow authenticated users to delete their verification images" on storage.objects;
drop policy if exists "Allow authenticated users to update their verification images" on storage.objects;
drop policy if exists "Allow authenticated users to upload verification images" on storage.objects;
drop policy if exists "Allow authenticated users to view verification images" on storage.objects;

-- profiles (profile photos, business photo, product images)
drop policy if exists "profiles 1ige2ga_1" on storage.objects;              -- INSERT for anyone (even logged out)
drop policy if exists "profiles 1ige2ga_2" on storage.objects;              -- UPDATE for anyone
drop policy if exists "profiles 1ige2ga_3" on storage.objects;              -- DELETE for anyone
drop policy if exists "Authenticated upload 1ige2ga_0" on storage.objects;  -- upload into other users' folders

-- portfolio_media / chat_images: remove the "bucket only" upload policies
drop policy if exists "Allow authenticated users to upload portfolio media" on storage.objects;
drop policy if exists "Allow users to upload chat images" on storage.objects;

-- provider_images: bucket is unused, close the upload hole
drop policy if exists "Allow authenticated users to upload provider images" on storage.objects;
drop policy if exists "Allow authenticated users to view provider images" on storage.objects;

-- Re-run query (0c) afterwards: every INSERT / UPDATE / DELETE policy should now
-- contain "storage.foldername(name))[1] = auth.uid()" (or owner = auth.uid()).


-- ---------------------------------------------------------------------
-- STEP 1 – HELPER FUNCTIONS + POLICIES  (safe to run now)
-- ---------------------------------------------------------------------

-- providers.id is NOT the same as users.id. Several old policies compared
-- auth.uid() with providers.id (e.g. chat_rooms.provider_id), which would lock
-- providers out. These helpers map the logged-in user to their provider row(s).
create or replace function public.my_provider_ids()
returns setof uuid
language sql stable security definer
set search_path = public
as $$ select id from public.providers where user_id = auth.uid() $$;

create or replace function public.is_room_member(p_room uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.chat_rooms r
    where r.id = p_room
      and (r.user_id = auth.uid()
           or r.provider_id in (select public.my_provider_ids()))
  )
$$;

revoke all on function public.my_provider_ids() from public, anon;
revoke all on function public.is_room_member(uuid) from public, anon;
grant execute on function public.my_provider_ids() to authenticated;
grant execute on function public.is_room_member(uuid) to authenticated;

-- Drop old policies on the tables I rewrite (providers/reviews/user_verifications stay)
do $$
declare r record;
begin
  for r in select schemaname, tablename, policyname from pg_policies
           where schemaname = 'public'
             and tablename in ('users','chat_rooms','messages','service_requests','notifications',
                               'favorites','provider_services','provider_certificates',
                               'provider_portfolio','business_products','categories',
                               'business_categories','provider_availability')
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

-- ---- users -----------------------------------------------------------
-- Other people's name / photo / online status are needed in chat and provider
-- lists, so logged-in users can read rows. Anonymous visitors cannot.
-- (phone/email are still readable by logged-in users: see FIX_GUIDE Part D.)
create policy "users read (logged in)" on public.users
  for select to authenticated using (true);
create policy "users insert own" on public.users
  for insert to authenticated with check (id = auth.uid());
create policy "users update own" on public.users
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- ---- public catalogue (read-only for the app) -------------------------
create policy "categories read" on public.categories for select using (true);
create policy "business_categories read" on public.business_categories for select using (true);
create policy "provider_availability read" on public.provider_availability for select using (true);

-- ---- provider-owned data: everyone reads, only the owner writes --------
do $$
declare t text;
begin
  foreach t in array array['provider_services','provider_certificates','provider_portfolio','business_products'] loop
    execute format('create policy "%1$s read" on public.%1$s for select using (true)', t);
    execute format('create policy "%1$s owner insert" on public.%1$s for insert to authenticated
                      with check (provider_id in (select public.my_provider_ids()))', t);
    execute format('create policy "%1$s owner update" on public.%1$s for update to authenticated
                      using (provider_id in (select public.my_provider_ids()))
                      with check (provider_id in (select public.my_provider_ids()))', t);
    execute format('create policy "%1$s owner delete" on public.%1$s for delete to authenticated
                      using (provider_id in (select public.my_provider_ids()))', t);
  end loop;
end $$;

-- ---- favorites: private to the customer --------------------------------
create policy "favorites own select" on public.favorites for select to authenticated using (user_id = auth.uid());
create policy "favorites own insert" on public.favorites for insert to authenticated with check (user_id = auth.uid());
create policy "favorites own delete" on public.favorites for delete to authenticated using (user_id = auth.uid());

-- ---- notifications ------------------------------------------------------
-- The app inserts notifications for the OTHER person (new request, accepted,
-- new message), so any logged-in user may insert. Read/update/delete: own only.
-- (Part D: move inserts to DB triggers so this can be locked down.)
create policy "notifications own select" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "notifications own update" on public.notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications own delete" on public.notifications for delete to authenticated using (user_id = auth.uid());
create policy "notifications insert (logged in)" on public.notifications for insert to authenticated with check (auth.uid() is not null);

-- ---- service_requests ---------------------------------------------------
create policy "requests select participants" on public.service_requests
  for select to authenticated
  using (user_id = auth.uid() or provider_id in (select public.my_provider_ids()));
create policy "requests insert own" on public.service_requests
  for insert to authenticated with check (user_id = auth.uid());
-- provider: accept / reject / complete / on_the_way ...
create policy "requests update by provider" on public.service_requests
  for update to authenticated
  using (provider_id in (select public.my_provider_ids()))
  with check (provider_id in (select public.my_provider_ids()));
-- customer: can only cancel while still pending
create policy "requests cancel by customer" on public.service_requests
  for update to authenticated
  using (user_id = auth.uid() and status = 'pending')
  with check (user_id = auth.uid() and status = 'cancelled');

-- ---- chat_rooms ----------------------------------------------------------
-- (the provider creates the room when accepting, with user_id = the customer)
create policy "rooms select participants" on public.chat_rooms
  for select to authenticated
  using (user_id = auth.uid() or provider_id in (select public.my_provider_ids()));
create policy "rooms insert participants" on public.chat_rooms
  for insert to authenticated
  with check (user_id = auth.uid() or provider_id in (select public.my_provider_ids()));
create policy "rooms update participants" on public.chat_rooms
  for update to authenticated
  using (user_id = auth.uid() or provider_id in (select public.my_provider_ids()))
  with check (user_id = auth.uid() or provider_id in (select public.my_provider_ids()));

-- ---- messages ------------------------------------------------------------
create policy "messages select members" on public.messages
  for select to authenticated using (public.is_room_member(room_id));
create policy "messages insert members" on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.is_room_member(room_id));
create policy "messages update members" on public.messages
  for update to authenticated
  using (public.is_room_member(room_id)) with check (public.is_room_member(room_id));


-- ---------------------------------------------------------------------
-- STEP 2 – ENABLE RLS  (run only after STEP 0 is OK)
-- ---------------------------------------------------------------------
alter table public.users                 enable row level security;
alter table public.providers             enable row level security;  -- policies already existed
alter table public.provider_services     enable row level security;
alter table public.provider_certificates enable row level security;
alter table public.provider_portfolio    enable row level security;
alter table public.provider_availability enable row level security;
alter table public.business_products     enable row level security;
alter table public.business_categories   enable row level security;
alter table public.categories            enable row level security;
alter table public.favorites             enable row level security;
alter table public.notifications         enable row level security;
alter table public.service_requests      enable row level security;
alter table public.chat_rooms            enable row level security;
alter table public.messages              enable row level security;
-- (spatial_ref_sys is a PostGIS system table: leave it alone)


-- ---------------------------------------------------------------------
-- ROLLBACK – only if the app breaks after STEP 2. Tell me which screen failed
-- and the exact error, then I will fix the policy. This turns protection OFF.
-- ---------------------------------------------------------------------
-- alter table public.users                 disable row level security;
-- alter table public.providers             disable row level security;
-- alter table public.provider_services     disable row level security;
-- alter table public.provider_certificates disable row level security;
-- alter table public.provider_portfolio    disable row level security;
-- alter table public.provider_availability disable row level security;
-- alter table public.business_products     disable row level security;
-- alter table public.business_categories   disable row level security;
-- alter table public.categories            disable row level security;
-- alter table public.favorites             disable row level security;
-- alter table public.notifications         disable row level security;
-- alter table public.service_requests      disable row level security;
-- alter table public.chat_rooms            disable row level security;
-- alter table public.messages              disable row level security;
