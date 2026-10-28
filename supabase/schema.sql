-- =====================================================================
-- Vokabelheft – Datenbank-Schema für Supabase
-- Einmal komplett im Supabase SQL Editor ausführen.
-- =====================================================================

-- ---------- Tabellen ----------

-- Vokabeln: eine Zeile pro Wort. Die id bleibt stabil, damit der Lernstand
-- erhalten bleibt, wenn ein Wort korrigiert wird.
create table if not exists public.vocab (
  id          text primary key,
  unit        text not null,
  en          text not null,
  de          text not null,
  sort        integer not null default 0,
  created_at  timestamptz not null default now()
);

-- Profile: eine Zeile pro Login. Wird automatisch angelegt (Trigger unten).
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text not null unique,
  display_name  text not null,
  role          text not null default 'kid' check (role in ('kid','admin')),
  created_at    timestamptz not null default now()
);

-- Lernstand: eine Zeile pro Kind und Wort.
create table if not exists public.progress (
  user_id      uuid not null references auth.users(id) on delete cascade,
  word_id      text not null references public.vocab(id) on delete cascade,
  box          smallint not null default 1 check (box between 1 and 5),
  right_count  integer not null default 0,
  wrong_count  integer not null default 0,
  last_seen    timestamptz,
  updated_at   timestamptz not null default now(),
  primary key (user_id, word_id)
);

-- ---------- Hilfsfunktion: ist der aktuelle Nutzer Admin? ----------
-- security definer, damit die Prüfung nicht selbst an den Zugriffsregeln hängt.
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- ---------- Profil automatisch anlegen ----------
-- Kinder werden im Supabase-Dashboard mit E-Mail "<benutzername>@vokabelheft.local"
-- angelegt. Der Teil vor dem @ wird Benutzername und Anzeigename.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  uname text := lower(split_part(new.email, '@', 1));
begin
  insert into public.profiles (id, username, display_name)
  values (new.id, uname, initcap(uname))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Zugriffsregeln (Row Level Security) ----------
alter table public.vocab    enable row level security;
alter table public.profiles enable row level security;
alter table public.progress enable row level security;

-- Vokabeln: alle Angemeldeten lesen, nur Admin schreibt.
drop policy if exists "vocab_read"  on public.vocab;
drop policy if exists "vocab_admin" on public.vocab;
create policy "vocab_read"  on public.vocab for select to authenticated using (true);
create policy "vocab_admin" on public.vocab for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- Profile: jeder sieht das eigene, Admin sieht alle. Kinder können nichts ändern
-- (insbesondere nicht ihre Rolle). Anzeigename ändert der Admin.
drop policy if exists "profiles_read"  on public.profiles;
drop policy if exists "profiles_admin" on public.profiles;
create policy "profiles_read"  on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "profiles_admin" on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Lernstand: jedes Kind liest und schreibt nur die eigenen Zeilen, Admin liest alle.
drop policy if exists "progress_read"   on public.progress;
drop policy if exists "progress_insert" on public.progress;
drop policy if exists "progress_update" on public.progress;
drop policy if exists "progress_delete" on public.progress;
create policy "progress_read"   on public.progress for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "progress_insert" on public.progress for insert to authenticated with check (user_id = auth.uid());
create policy "progress_update" on public.progress for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "progress_delete" on public.progress for delete to authenticated using (user_id = auth.uid());

-- Nicht angemeldete Besucher bekommen gar nichts.
revoke all on public.vocab, public.profiles, public.progress from anon;

-- ---------- Übersicht für den Admin ----------
create or replace view public.progress_overview
with (security_invoker = true) as
select p.id as user_id, p.display_name, p.username,
       count(pr.word_id) filter (where pr.box >= 4) as words_mastered,
       count(pr.word_id)                            as words_seen,
       max(pr.last_seen)                            as last_practice
from public.profiles p
left join public.progress pr on pr.user_id = p.id
where p.role = 'kid'
group by p.id, p.display_name, p.username;

revoke all on public.progress_overview from anon;
