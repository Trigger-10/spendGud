-- Run this in Supabase: SQL Editor > New query > paste > Run
-- Safe to run more than once.

create table if not exists public.expenses (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  amount     numeric(12,2) not null check (amount > 0),
  category   text not null default 'Other',
  note       text not null default '',
  spent_on   date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists expenses_user_date_idx on public.expenses (user_id, spent_on desc);

-- Let logged-in users reach the table through the Data API (needed on newer Supabase projects)
grant select, insert, update, delete on public.expenses to authenticated;
grant select, insert, update, delete on public.expenses to service_role;

-- Each user can only see and change their own rows
alter table public.expenses enable row level security;

drop policy if exists "read own expenses"   on public.expenses;
drop policy if exists "insert own expenses" on public.expenses;
drop policy if exists "update own expenses" on public.expenses;
drop policy if exists "delete own expenses" on public.expenses;

create policy "read own expenses"   on public.expenses for select to authenticated using (auth.uid() = user_id);
create policy "insert own expenses" on public.expenses for insert to authenticated with check (auth.uid() = user_id);
create policy "update own expenses" on public.expenses for update to authenticated using (auth.uid() = user_id);
create policy "delete own expenses" on public.expenses for delete to authenticated using (auth.uid() = user_id);

-- Real-time updates (ignore the "already member" message if you see it)
do $$ begin
  alter publication supabase_realtime add table public.expenses;
exception when duplicate_object then null;
end $$;

-- Added for the calendar / time feature (safe to run again)
alter table public.expenses add column if not exists spent_time time;
