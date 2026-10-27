-- Einmal im Supabase-SQL-Editor ausführen. Legt die Tabelle für die anonyme Nutzungszählung an.
-- Apps dürfen nur Zeilen hinzufügen (ohne Zeitstempel zu fälschen), lesen darf nur ein angemeldeter Nutzer (der Admin).
create table if not exists public.nutzung (
  id bigint generated always as identity primary key,
  zeit timestamptz not null default now(),
  app text not null check (app in ('live', 'beta')),
  art text not null check (art in ('tag', 'neu')),
  geraet text check (char_length(geraet) <= 20),
  version text check (char_length(version) <= 20)
);

alter table public.nutzung enable row level security;

revoke all on public.nutzung from anon, authenticated;
grant insert (app, art, geraet, version) on public.nutzung to anon;
grant select on public.nutzung to authenticated;

drop policy if exists "Apps duerfen zaehlen" on public.nutzung;
create policy "Apps duerfen zaehlen" on public.nutzung for insert to anon with check (true);

drop policy if exists "Nur Admin liest" on public.nutzung;
create policy "Nur Admin liest" on public.nutzung for select to authenticated using (true);

create index if not exists nutzung_zeit on public.nutzung (zeit);

-- Live-Ansicht: kurze „gerade offen“-Meldungen mit zufälliger Sitzungsnummer, werden nach einem Tag gelöscht.
create table if not exists public.puls (
  id bigint generated always as identity primary key,
  zeit timestamptz not null default now(),
  sitzung uuid not null,
  app text not null check (app in ('live', 'beta')),
  geraet text check (char_length(geraet) <= 20),
  version text check (char_length(version) <= 20)
);
alter table public.puls enable row level security;
revoke all on public.puls from anon, authenticated;
grant insert (sitzung, app, geraet, version) on public.puls to anon;
grant select on public.puls to authenticated;
create policy "Apps melden Puls" on public.puls for insert to anon with check (true);
create policy "Nur Admin liest Puls" on public.puls for select to authenticated using (true);
create index if not exists puls_zeit on public.puls (zeit);

create or replace function public.puls_aufraeumen() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.puls where zeit < now() - interval '1 day';
  return null;
end $$;
revoke all on function public.puls_aufraeumen() from public, anon, authenticated;
drop trigger if exists puls_aufraeumen on public.puls;
create trigger puls_aufraeumen after insert on public.puls for each statement execute function public.puls_aufraeumen();
