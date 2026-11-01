-- =====================================================================
-- Maison & Patrimoine : base de données Supabase
-- À coller une seule fois dans Supabase > SQL Editor > New query > Run.
-- Avant de lancer : remplacez l'adresse e-mail à la fin du fichier.
-- =====================================================================

-- 1. Les membres de la famille autorisés à ouvrir le carnet
create table if not exists public.membres (
  email      text primary key,
  nom        text,
  ajoute_le  timestamptz not null default now()
);

-- Vrai si la personne connectée fait partie des membres
create or replace function public.est_membre()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.membres
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 2. Le carnet : une seule ligne qui contient toutes les données de l'application
create table if not exists public.carnet (
  id          int primary key default 1 check (id = 1),
  data        jsonb not null,
  version     bigint not null default 1,
  updated_at  timestamptz not null default now(),
  updated_by  text
);

-- 3. Historique automatique : chaque modification garde la version précédente
create table if not exists public.carnet_historique (
  id          bigint generated always as identity primary key,
  version     bigint not null,
  data        jsonb not null,
  modifie_le  timestamptz not null,
  modifie_par text,
  archive_le  timestamptz not null default now()
);

create or replace function public.carnet_avant_modif()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.carnet_historique (version, data, modifie_le, modifie_par)
  values (old.version, old.data, old.updated_at, old.updated_by);
  -- on garde les 500 dernières versions
  delete from public.carnet_historique
  where id in (select id from public.carnet_historique order by id desc offset 500);
  new.updated_at := now();
  new.updated_by := auth.jwt() ->> 'email';
  return new;
end;
$$;

drop trigger if exists carnet_avant_modif on public.carnet;
create trigger carnet_avant_modif
  before update on public.carnet
  for each row execute function public.carnet_avant_modif();

-- 4. Sécurité : seuls les membres lisent et modifient
alter table public.membres            enable row level security;
alter table public.carnet             enable row level security;
alter table public.carnet_historique  enable row level security;

drop policy if exists "membre voit sa ligne" on public.membres;
create policy "membre voit sa ligne" on public.membres
  for select to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'));

drop policy if exists "membres lisent le carnet" on public.carnet;
create policy "membres lisent le carnet" on public.carnet
  for select to authenticated using (public.est_membre());

drop policy if exists "membres creent le carnet" on public.carnet;
create policy "membres creent le carnet" on public.carnet
  for insert to authenticated with check (public.est_membre());

drop policy if exists "membres modifient le carnet" on public.carnet;
create policy "membres modifient le carnet" on public.carnet
  for update to authenticated using (public.est_membre()) with check (public.est_membre());

drop policy if exists "membres lisent l historique" on public.carnet_historique;
create policy "membres lisent l historique" on public.carnet_historique
  for select to authenticated using (public.est_membre());

-- 5. Stockage privé des justificatifs, factures et photos
insert into storage.buckets (id, name, public, file_size_limit)
values ('justificatifs', 'justificatifs', false, 20971520)
on conflict (id) do nothing;

drop policy if exists "membres lisent les fichiers" on storage.objects;
create policy "membres lisent les fichiers" on storage.objects
  for select to authenticated
  using (bucket_id = 'justificatifs' and public.est_membre());

drop policy if exists "membres ajoutent des fichiers" on storage.objects;
create policy "membres ajoutent des fichiers" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'justificatifs' and public.est_membre());

drop policy if exists "membres modifient les fichiers" on storage.objects;
create policy "membres modifient les fichiers" on storage.objects
  for update to authenticated
  using (bucket_id = 'justificatifs' and public.est_membre());

drop policy if exists "membres suppriment les fichiers" on storage.objects;
create policy "membres suppriment les fichiers" on storage.objects
  for delete to authenticated
  using (bucket_id = 'justificatifs' and public.est_membre());

-- 6. Les membres : REMPLACEZ par les vraies adresses e-mail de la famille
insert into public.membres (email, nom) values
  ('votre-adresse@exemple.fr', 'Moi')
--, ('adresse-de-maman@exemple.fr', 'Maman')
on conflict (email) do nothing;
