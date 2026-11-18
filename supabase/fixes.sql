-- =====================================================================
-- ProNear – security fixes (run in Supabase Dashboard → SQL Editor)
-- Run section by section, top to bottom. Each section is safe to re-run.
-- MUST be run BEFORE installing the new app build.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) PRIVATE table for CNIC / face data (owner-only)
-- ---------------------------------------------------------------------
create table if not exists public.user_verifications (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  cnic             text unique,
  cnic_front_path  text,
  cnic_back_path   text,
  face_path        text,
  face_embedding   text,
  status           text not null default 'pending'
                   check (status in ('pending','approved','rejected')),
  admin_note       text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.user_verifications enable row level security;

drop policy if exists "uv own select" on public.user_verifications;
drop policy if exists "uv own insert" on public.user_verifications;
drop policy if exists "uv own update" on public.user_verifications;

create policy "uv own select" on public.user_verifications
  for select to authenticated using (user_id = auth.uid());
create policy "uv own insert" on public.user_verifications
  for insert to authenticated with check (user_id = auth.uid() and status = 'pending');
-- owner may re-submit images, but only while not approved, and cannot approve himself
create policy "uv own update" on public.user_verifications
  for update to authenticated
  using (user_id = auth.uid() and status <> 'approved')
  with check (user_id = auth.uid() and status = 'pending');


-- ---------------------------------------------------------------------
-- 2) Move existing CNIC data out of public.users (old registrations)
-- ---------------------------------------------------------------------
insert into public.user_verifications (user_id, cnic, cnic_front_path, cnic_back_path, face_path, face_embedding, status)
select u.id, u.cnic, u.cnic_front_image, u.cnic_back_image, u.face_image, u.face_embedding, 'pending'
from public.users u
where u.cnic is not null
  and exists (select 1 from auth.users a where a.id = u.id)
on conflict (user_id) do nothing;

-- wipe sensitive columns from the publicly-readable users table
update public.users
set cnic = null, cnic_front_image = null, cnic_back_image = null,
    face_image = null, face_embedding = null,
    cnic_verified = false, face_verified = false
where cnic is not null or cnic_front_image is not null;


-- ---------------------------------------------------------------------
-- 3) CNIC duplicate check without exposing other users (used by the app)
-- ---------------------------------------------------------------------
create or replace function public.cnic_registration_info(p_cnic text)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
           'email', regexp_replace(u.email, '^(.{2}).*(@.*)$', '\1***\2'),
           'role',  u.role)
  from public.user_verifications v
  join public.users u on u.id = v.user_id
  where v.cnic = p_cnic
  limit 1
$$;

revoke all on function public.cnic_registration_info(text) from public, anon;
grant execute on function public.cnic_registration_info(text) to authenticated;


-- ---------------------------------------------------------------------
-- 4) App users can NEVER set verified flags themselves
--    (only SQL editor / service_role / admin can)
-- ---------------------------------------------------------------------
create or replace function public.protect_verified_flags()
returns trigger
language plpgsql
as $$
begin
  if coalesce(auth.role(), '') in ('authenticated', 'anon') then
    if tg_table_name = 'users' then
      if tg_op = 'INSERT' then
        new.cnic_verified := false;
        new.face_verified := false;
      else
        new.cnic_verified := old.cnic_verified;
        new.face_verified := old.face_verified;
      end if;
    elsif tg_table_name = 'providers' then
      if tg_op = 'INSERT' then
        new.is_verified := false;
      else
        new.is_verified := old.is_verified;
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_verified_users on public.users;
create trigger trg_protect_verified_users
  before insert or update on public.users
  for each row execute function public.protect_verified_flags();

do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='providers' and column_name='is_verified') then
    execute 'drop trigger if exists trg_protect_verified_providers on public.providers';
    execute 'create trigger trg_protect_verified_providers
               before insert or update on public.providers
               for each row execute function public.protect_verified_flags()';
  else
    raise notice 'providers.is_verified column not found – add it: alter table public.providers add column is_verified boolean default false;';
  end if;
end $$;


-- ---------------------------------------------------------------------
-- 5) Storage: verification bucket PRIVATE + owner-folder policies
--    Paths used by the app: '<auth uid>/...'
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('verification_images', 'verification_images', false)
on conflict (id) do update set public = false;

drop policy if exists "verif own insert" on storage.objects;
drop policy if exists "verif own select" on storage.objects;
drop policy if exists "verif own delete" on storage.objects;
create policy "verif own insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'verification_images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "verif own select" on storage.objects for select to authenticated
  using (bucket_id = 'verification_images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "verif own delete" on storage.objects for delete to authenticated
  using (bucket_id = 'verification_images' and (storage.foldername(name))[1] = auth.uid()::text);

-- Public-read buckets (profile photos, products, portfolio, chat images):
-- anyone can VIEW (bucket is public), but only the owner can write/delete
-- inside their own '<uid>/' folder.
do $$
declare b text;
begin
  foreach b in array array['profiles','portfolio_media','chat_images'] loop
    execute format('drop policy if exists "%s own insert" on storage.objects', b);
    execute format('drop policy if exists "%s own update" on storage.objects', b);
    execute format('drop policy if exists "%s own delete" on storage.objects', b);
    execute format($p$create policy "%1$s own insert" on storage.objects for insert to authenticated
                     with check (bucket_id = %1$L and (storage.foldername(name))[1] = auth.uid()::text)$p$, b);
    execute format($p$create policy "%1$s own update" on storage.objects for update to authenticated
                     using (bucket_id = %1$L and (storage.foldername(name))[1] = auth.uid()::text)$p$, b);
    execute format($p$create policy "%1$s own delete" on storage.objects for delete to authenticated
                     using (bucket_id = %1$L and (storage.foldername(name))[1] = auth.uid()::text)$p$, b);
  end loop;
end $$;

-- !! After running: Dashboard → Storage → Policies. DELETE any older policy on
-- these buckets that allows insert/update/delete for everyone
-- (e.g. "Allow all", "Public upload", using (true)). Policies are OR-ed, so an
-- old open policy cancels the protection above.


-- ---------------------------------------------------------------------
-- 6) Reviews: one review per customer per provider, only after a completed
--    job, and provider rating auto-updates
-- ---------------------------------------------------------------------
alter table public.reviews enable row level security;

drop policy if exists "reviews read all" on public.reviews;
drop policy if exists "reviews insert after completed job" on public.reviews;
create policy "reviews read all" on public.reviews for select using (true);
create policy "reviews insert after completed job" on public.reviews
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.service_requests r
                where r.user_id = auth.uid()
                  and r.provider_id = reviews.provider_id
                  and r.status = 'completed')
  );

-- fails if duplicates already exist – then delete the duplicates first
create unique index if not exists reviews_one_per_user_provider
  on public.reviews (user_id, provider_id);

create or replace function public.refresh_provider_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare pid uuid := coalesce(new.provider_id, old.provider_id);
begin
  update public.providers
     set rating = coalesce((select round(avg(rating)::numeric, 1) from public.reviews where provider_id = pid), 0)
   where id = pid;
  return null;
end;
$$;

drop trigger if exists trg_refresh_provider_rating on public.reviews;
create trigger trg_refresh_provider_rating
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_provider_rating();


-- ---------------------------------------------------------------------
-- 7) service_requests: allow the new 'cancelled' status (only if there is a
--    CHECK constraint on status). Inspect first:
-- ---------------------------------------------------------------------
select conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.service_requests'::regclass and contype = 'c';
-- If a status check exists WITHOUT 'cancelled', replace it, e.g.:
-- alter table public.service_requests drop constraint <conname>;
-- alter table public.service_requests add constraint service_requests_status_check
--   check (status in ('pending','accepted','rejected','completed','cancelled'));


-- ---------------------------------------------------------------------
-- 8) CHECKS – run and read the output (see FIX_GUIDE.md §RLS review)
-- ---------------------------------------------------------------------
-- RLS on/off per table (every row should say true)
select tablename, rowsecurity from pg_tables where schemaname = 'public' order by 1;

-- All current policies
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies where schemaname = 'public' order by 1, 2;

-- Trigger that creates public.users on signup? (app now also does it itself)
select tgname, pg_get_triggerdef(t.oid)
from pg_trigger t join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'auth' and c.relname = 'users' and not tgisinternal;

-- RPCs the app calls – both must exist
select proname, prosecdef from pg_proc
where proname in ('delete_my_account', 'delete_message_for_everyone', 'cnic_registration_info');

-- Buckets
select id, public from storage.buckets;


-- =====================================================================
-- ADMIN: approve / reject a provider (run manually after viewing images)
-- =====================================================================
-- Pending list:
--   select v.user_id, u.full_name, u.email, v.cnic, v.cnic_front_path, v.cnic_back_path, v.face_path, v.created_at
--   from public.user_verifications v join public.users u on u.id = v.user_id
--   where v.status = 'pending' order by v.created_at;
--
-- View images: Dashboard → Storage → verification_images → <user_id> folder
--
-- Approve:
--   update public.user_verifications set status = 'approved', updated_at = now() where user_id = '<USER_ID>';
--   update public.users     set cnic_verified = true, face_verified = true where id = '<USER_ID>';
--   update public.providers set is_verified = true where user_id = '<USER_ID>';
--
-- Reject:
--   update public.user_verifications set status = 'rejected', admin_note = 'CNIC unclear', updated_at = now() where user_id = '<USER_ID>';
