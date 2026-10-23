-- Smart Attendance Online: run this in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'User',
  role text not null check (role in ('super_admin','college_admin','staff')),
  organization text not null default 'College Workspace',
  created_at timestamptz not null default now()
);
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  roll_no text not null unique,
  course text not null,
  year_semester text,
  phone text,
  email text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);
create table if not exists public.student_requests (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  roll_no text not null,
  course text not null,
  year_semester text,
  email text,
  phone text,
  requested_by uuid not null references auth.users(id),
  requested_by_name text,
  status text not null default 'Pending' check (status in ('Pending','Approved','Rejected')),
  reviewed_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null default current_date,
  status text not null check (status in ('Present','Absent','On Leave')),
  marked_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_id, attendance_date)
);
create table if not exists public.organization_settings (
  id integer primary key check (id = 1),
  college_name text not null default 'College Workspace',
  logo_url text,
  address text,
  phone text,
  email text,
  theme text not null default 'light' check (theme in ('light','dark')),
  primary_color text not null default '#4263eb' check (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);
insert into public.organization_settings (id, college_name) values (1, 'College Workspace') on conflict (id) do nothing;
create index if not exists attendance_date_idx on public.attendance_records(attendance_date);
create index if not exists requests_status_idx on public.student_requests(status);
create or replace function public.current_app_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(public.current_app_role() in ('super_admin','college_admin'),false) $$;
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.student_requests enable row level security;
alter table public.attendance_records enable row level security;
alter table public.organization_settings enable row level security;
-- Profiles: users can read their own profile; admins can read profiles. No role self-edit policy.
drop policy if exists "read own or admin profiles" on public.profiles;
create policy "read own or admin profiles" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
drop policy if exists "admin insert profiles" on public.profiles;
create policy "admin insert profiles" on public.profiles for insert to authenticated with check (public.is_admin());
drop policy if exists "admin update profiles" on public.profiles;
create policy "admin update profiles" on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());
-- Students: authenticated users can read active students; admins manage student records.
drop policy if exists "read active students" on public.students;
create policy "read active students" on public.students for select to authenticated using (is_active=true or public.is_admin());
drop policy if exists "admin insert students" on public.students;
create policy "admin insert students" on public.students for insert to authenticated with check (public.is_admin());
drop policy if exists "admin update students" on public.students;
create policy "admin update students" on public.students for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin delete students" on public.students;
create policy "admin delete students" on public.students for delete to authenticated using (public.is_admin());
-- Requests: staff may submit/read their own; admins can review all.
drop policy if exists "read own or admin requests" on public.student_requests;
create policy "read own or admin requests" on public.student_requests for select to authenticated using (requested_by=auth.uid() or public.is_admin());
drop policy if exists "staff submit requests" on public.student_requests;
create policy "staff submit requests" on public.student_requests for insert to authenticated with check (requested_by=auth.uid() and public.current_app_role()='staff');
drop policy if exists "admin review requests" on public.student_requests;
create policy "admin review requests" on public.student_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
-- Attendance: signed-in staff/admin can read attendance; staff can mark it; admins can edit/delete.
drop policy if exists "read attendance" on public.attendance_records;
create policy "read attendance" on public.attendance_records for select to authenticated using (public.current_app_role() in ('staff','college_admin','super_admin'));
drop policy if exists "staff mark attendance" on public.attendance_records;
create policy "staff mark attendance" on public.attendance_records for insert to authenticated with check (marked_by=auth.uid() and public.current_app_role() in ('staff','college_admin','super_admin'));
drop policy if exists "staff update attendance" on public.attendance_records;
create policy "staff update attendance" on public.attendance_records for update to authenticated using (public.current_app_role() in ('staff','college_admin','super_admin')) with check (marked_by=auth.uid() or public.is_admin());
drop policy if exists "admin delete attendance" on public.attendance_records;
create policy "admin delete attendance" on public.attendance_records for delete to authenticated using (public.is_admin());

-- Shared college profile and theme: all signed-in users can read; only admins can change.
drop policy if exists "authenticated read organization settings" on public.organization_settings;
create policy "authenticated read organization settings" on public.organization_settings for select to authenticated using (true);
drop policy if exists "admin insert organization settings" on public.organization_settings;
create policy "admin insert organization settings" on public.organization_settings for insert to authenticated with check (public.is_admin());
drop policy if exists "admin update organization settings" on public.organization_settings;
create policy "admin update organization settings" on public.organization_settings for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Enable live updates for the shared settings and operational tables.
do $$ begin
  alter publication supabase_realtime add table public.organization_settings;
exception when duplicate_object then null;
when undefined_object then raise notice 'supabase_realtime publication not found; enable Realtime for these tables in Supabase Dashboard.';
end $$;
do $$ begin
  alter publication supabase_realtime add table public.students;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.student_requests;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.attendance_records;
exception when duplicate_object then null; when undefined_object then null; end $$;
