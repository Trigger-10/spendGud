-- spendGud database setup
-- Supabase: SQL Editor > New query > paste all of this > Run
-- Safe to run more than once, and safe on a database that already has an older version.

create table if not exists public.expenses (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  amount     numeric(12,2) not null check (amount > 0),
  category   text not null default 'Other',
  note       text not null default '',
  spent_on   date not null default current_date,
  spent_time time,
  created_at timestamptz not null default now()
);

-- For databases created with an older version of this file
alter table public.expenses add column if not exists spent_time time;

create index if not exists expenses_user_date_idx on public.expenses (user_id, spent_on desc);

-- Let logged-in users reach the table through the Data API
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

-- Real-time updates
do $$ begin
  alter publication supabase_realtime add table public.expenses;
exception when duplicate_object then null;
end $$;
