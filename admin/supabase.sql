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
