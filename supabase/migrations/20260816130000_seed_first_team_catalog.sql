BEGIN;

alter table public.player_profiles
  add column if not exists joined_at date;

comment on column public.player_profiles.joined_at is
  'Confirmed calendar date the player joined Chelsea; partial or unknown dates remain null.';

grant select (joined_at)
  on table public.player_profiles to anon, authenticated;

create temporary table first_team_catalog_seed (
  person_id uuid primary key,
  role_id uuid not null unique,
  profile_source_id uuid not null,
  slug text not null unique,
  display_name text not null,
  nationality text,
  primary_position text not null,
  position_group text not null,
  date_of_birth date not null,
  height_cm smallint,
  preferred_foot text,
  joined_at date,
  profile_url text not null unique
) on commit drop;

insert into first_team_catalog_seed values
  ('41000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000001', '31000000-0000-4000-8000-000000000001', 'robert-sanchez', 'Robert Sanchez', 'Spanish', 'Goalkeeper', 'goalkeeper', '1997-11-18', 197, null, null, 'https://www.chelseafc.com/en/teams/profile/robert-sanchez'),
  ('41000000-0000-4000-8000-000000000002', '51000000-0000-4000-8000-000000000002', '31000000-0000-4000-8000-000000000002', 'mike-penders', 'Mike Penders', 'Belgian', 'Goalkeeper', 'goalkeeper', '2005-07-31', 200, null, null, 'https://www.chelseafc.com/en/teams/profile/mike-penders'),
  ('41000000-0000-4000-8000-000000000003', '51000000-0000-4000-8000-000000000003', '31000000-0000-4000-8000-000000000003', 'teddy-sharman-lowe', 'Teddy Sharman-Lowe', 'English', 'Goalkeeper', 'goalkeeper', '2003-03-30', null, null, null, 'https://www.chelseafc.com/en/teams/profile/teddy-sharman-lowe'),
  ('41000000-0000-4000-8000-000000000004', '51000000-0000-4000-8000-000000000004', '31000000-0000-4000-8000-000000000004', 'gabriel-slonina', 'Gaga Slonina', 'American', 'Goalkeeper', 'goalkeeper', '2004-05-15', 193, null, null, 'https://www.chelseafc.com/en/teams/profile/gabriel-slonina'),
  ('41000000-0000-4000-8000-000000000005', '51000000-0000-4000-8000-000000000005', '31000000-0000-4000-8000-000000000005', 'marco-palestra', 'Marco Palestra', 'Italian', 'Full-back/wing-back', 'defender', '2005-03-03', 186, null, '2026-07-01', 'https://www.chelseafc.com/en/teams/profile/marco-palestra'),
  ('41000000-0000-4000-8000-000000000006', '51000000-0000-4000-8000-000000000006', '31000000-0000-4000-8000-000000000006', 'tosin-adarabioyo', 'Tosin Adarabioyo', 'English', 'Centre-back', 'defender', '1997-09-24', 197, null, null, 'https://www.chelseafc.com/en/teams/profile/tosin-adarabioyo'),
  ('41000000-0000-4000-8000-000000000007', '51000000-0000-4000-8000-000000000007', '31000000-0000-4000-8000-000000000007', 'benoit-badiashile', 'Benoit Badiashile', 'French', 'Centre-back', 'defender', '2001-03-26', 194, 'left', null, 'https://www.chelseafc.com/en/teams/profile/benoit-badiashile'),
  ('41000000-0000-4000-8000-000000000008', '51000000-0000-4000-8000-000000000008', '31000000-0000-4000-8000-000000000008', 'levi-colwill', 'Levi Colwill', 'English', 'Centre-back', 'defender', '2003-02-26', 187, null, null, 'https://www.chelseafc.com/en/teams/profile/levi-colwill'),
  ('41000000-0000-4000-8000-000000000009', '51000000-0000-4000-8000-000000000009', '31000000-0000-4000-8000-000000000009', 'mamadou-sarr', 'Mamadou Sarr', 'Senegalese', 'Centre-back', 'defender', '2005-08-29', 194, null, null, 'https://www.chelseafc.com/en/teams/profile/mamadou-sarr'),
  ('41000000-0000-4000-8000-000000000010', '51000000-0000-4000-8000-000000000010', '31000000-0000-4000-8000-000000000010', 'jorrel-hato', 'Jorrel Hato', 'Dutch', 'Defender', 'defender', '2006-03-07', 182, null, null, 'https://www.chelseafc.com/en/teams/profile/jorrel-hato'),
  ('40000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', 'reece-james', 'Reece James', 'English', 'Defender/wing-back/midfielder', 'defender', '1999-12-08', 180, 'right', null, 'https://www.chelseafc.com/en/teams/profile/reece-james'),
  ('41000000-0000-4000-8000-000000000012', '51000000-0000-4000-8000-000000000012', '31000000-0000-4000-8000-000000000012', 'malo-gusto', 'Malo Gusto', 'French', 'Right-back', 'defender', '2003-05-19', 178, null, null, 'https://www.chelseafc.com/en/teams/profile/malo-gusto'),
  ('41000000-0000-4000-8000-000000000013', '51000000-0000-4000-8000-000000000013', '31000000-0000-4000-8000-000000000013', 'wesley-fofana', 'Wesley Fofana', 'French', 'Centre-back', 'defender', '2000-12-17', 185, null, null, 'https://www.chelseafc.com/en/teams/profile/wesley-fofana'),
  ('41000000-0000-4000-8000-000000000014', '51000000-0000-4000-8000-000000000014', '31000000-0000-4000-8000-000000000014', 'aaron-anselmino', 'Aaron Anselmino', 'Argentinian', 'Centre-back', 'defender', '2005-04-29', 186, null, null, 'https://www.chelseafc.com/en/teams/profile/aaron-anselmino'),
  ('41000000-0000-4000-8000-000000000015', '51000000-0000-4000-8000-000000000015', '31000000-0000-4000-8000-000000000015', 'josh-acheampong', 'Josh Acheampong', 'English', 'Defender', 'defender', '2006-05-05', 190, null, null, 'https://www.chelseafc.com/en/teams/profile/josh-acheampong'),
  ('41000000-0000-4000-8000-000000000016', '51000000-0000-4000-8000-000000000016', '31000000-0000-4000-8000-000000000016', 'olutayo-subuloye', 'Olutayo Subuloye', 'English', 'Defender', 'defender', '2007-12-18', 186, null, null, 'https://www.chelseafc.com/en/teams/profile/olutayo-subuloye'),
  ('41000000-0000-4000-8000-000000000017', '51000000-0000-4000-8000-000000000017', '31000000-0000-4000-8000-000000000017', 'pep-chavarria', 'Pep Chavarria', 'Spanish', 'Left-back', 'defender', '1998-04-10', 174, null, null, 'https://www.chelseafc.com/en/teams/profile/pep-chavarria'),
  ('41000000-0000-4000-8000-000000000018', '51000000-0000-4000-8000-000000000018', '31000000-0000-4000-8000-000000000018', 'maxence-lacroix', 'Maxence Lacroix', 'French', 'Centre-back', 'defender', '2000-04-06', 190, null, null, 'https://www.chelseafc.com/en/teams/profile/maxence-lacroix'),
  ('41000000-0000-4000-8000-000000000019', '51000000-0000-4000-8000-000000000019', '31000000-0000-4000-8000-000000000019', 'enzo-fernandez', 'Enzo Fernandez', 'Argentinian', 'Midfielder', 'midfielder', '2001-01-17', 178, null, null, 'https://www.chelseafc.com/en/teams/profile/enzo-fernandez'),
  ('41000000-0000-4000-8000-000000000020', '51000000-0000-4000-8000-000000000020', '31000000-0000-4000-8000-000000000020', 'dario-essugo', 'Dario Essugo', 'Portuguese', 'Midfielder', 'midfielder', '2005-03-14', 180, null, null, 'https://www.chelseafc.com/en/teams/profile/dario-essugo'),
  ('40000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', 'moises-caicedo', 'Moises Caicedo', 'Ecuadorian', 'Midfielder', 'midfielder', '2001-11-02', 178, null, null, 'https://www.chelseafc.com/en/teams/profile/moises-caicedo'),
  ('41000000-0000-4000-8000-000000000022', '51000000-0000-4000-8000-000000000022', '31000000-0000-4000-8000-000000000022', 'reggie-watson', 'Reggie Watson', 'English', 'Central midfielder', 'midfielder', '2010-01-26', null, null, null, 'https://www.chelseafc.com/en/teams/profile/reggie-watson'),
  ('41000000-0000-4000-8000-000000000023', '51000000-0000-4000-8000-000000000023', '31000000-0000-4000-8000-000000000023', 'mahdi-nicoll-jazuli', 'Mahdi Nicoll-Jazuli', 'English', 'Attacking midfielder', 'midfielder', '2010-01-06', null, null, null, 'https://www.chelseafc.com/en/teams/profile/mahdi-nicoll-jazuli'),
  ('41000000-0000-4000-8000-000000000024', '51000000-0000-4000-8000-000000000024', '31000000-0000-4000-8000-000000000024', 'omari-kellyman', 'Omari Kellyman', 'English', 'Midfielder', 'midfielder', '2005-09-15', 191, null, null, 'https://www.chelseafc.com/en/teams/profile/omari-kellyman'),
  ('41000000-0000-4000-8000-000000000025', '51000000-0000-4000-8000-000000000025', '31000000-0000-4000-8000-000000000025', 'romeo-lavia', 'Romeo Lavia', 'Belgian', 'Midfielder', 'midfielder', '2004-01-06', 181, null, null, 'https://www.chelseafc.com/en/teams/profile/romeo-lavia'),
  ('41000000-0000-4000-8000-000000000026', '51000000-0000-4000-8000-000000000026', '31000000-0000-4000-8000-000000000026', 'reggie-walsh', 'Reggie Walsh', 'English', 'Midfielder', 'midfielder', '2008-10-20', 176, null, null, 'https://www.chelseafc.com/en/teams/profile/reggie-walsh'),
  ('41000000-0000-4000-8000-000000000027', '51000000-0000-4000-8000-000000000027', '31000000-0000-4000-8000-000000000027', 'landon-emenalo', 'Landon Emenalo', 'American', 'Midfielder', 'midfielder', '2008-01-18', 177, null, null, 'https://www.chelseafc.com/en/teams/profile/landon-emenalo'),
  ('41000000-0000-4000-8000-000000000028', '51000000-0000-4000-8000-000000000028', '31000000-0000-4000-8000-000000000028', 'valentin-barco', 'Valentin Barco', 'Argentinian', 'Midfielder', 'midfielder', '2004-07-27', 170, null, null, 'https://www.chelseafc.com/en/teams/profile/valentin-barco'),
  ('41000000-0000-4000-8000-000000000029', '51000000-0000-4000-8000-000000000029', '31000000-0000-4000-8000-000000000029', 'jordan-henderson', 'Jordan Henderson', 'English', 'Midfielder', 'midfielder', '1990-06-17', 183, null, null, 'https://www.chelseafc.com/en/teams/profile/jordan-henderson'),
  ('41000000-0000-4000-8000-000000000030', '51000000-0000-4000-8000-000000000030', '31000000-0000-4000-8000-000000000030', 'pedro-neto', 'Pedro Neto', 'Portuguese', 'Winger', 'forward', '2000-03-09', 174, 'left', '2024-08-11', 'https://www.chelseafc.com/en/teams/profile/pedro-neto'),
  ('41000000-0000-4000-8000-000000000031', '51000000-0000-4000-8000-000000000031', '31000000-0000-4000-8000-000000000031', 'liam-delap', 'Liam Delap', 'English', 'Striker', 'forward', '2003-02-08', 187, null, null, 'https://www.chelseafc.com/en/teams/profile/liam-delap'),
  ('40000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'cole-palmer', 'Cole Palmer', 'English', 'Attacking midfielder/winger', 'forward', '2002-05-06', 185, null, null, 'https://www.chelseafc.com/en/teams/profile/cole-palmer'),
  ('41000000-0000-4000-8000-000000000033', '51000000-0000-4000-8000-000000000033', '31000000-0000-4000-8000-000000000033', 'jamie-gittens', 'Jamie Gittens', 'English', 'Winger', 'forward', '2004-08-08', 178, null, '2025-07-05', 'https://www.chelseafc.com/en/teams/profile/jamie-gittens'),
  ('41000000-0000-4000-8000-000000000034', '51000000-0000-4000-8000-000000000034', '31000000-0000-4000-8000-000000000034', 'nicolas-jackson', 'Nicolas Jackson', null, 'Striker', 'forward', '2001-06-20', 187, null, null, 'https://www.chelseafc.com/en/teams/profile/nicolas-jackson'),
  ('41000000-0000-4000-8000-000000000035', '51000000-0000-4000-8000-000000000035', '31000000-0000-4000-8000-000000000035', 'morgan-rogers', 'Morgan Rogers', 'English', 'Attacking midfielder/winger', 'forward', '2002-07-26', 187, null, null, 'https://www.chelseafc.com/en/teams/profile/morgan-rogers'),
  ('41000000-0000-4000-8000-000000000036', '51000000-0000-4000-8000-000000000036', '31000000-0000-4000-8000-000000000036', 'danny-welbeck', 'Danny Welbeck', 'English', 'Striker', 'forward', '1990-11-26', 185, null, null, 'https://www.chelseafc.com/en/teams/profile/danny-welbeck'),
  ('41000000-0000-4000-8000-000000000037', '51000000-0000-4000-8000-000000000037', '31000000-0000-4000-8000-000000000037', 'joao-pedro', 'Joao Pedro', 'Brazilian', 'Forward', 'forward', '2001-09-26', 186, null, null, 'https://www.chelseafc.com/en/teams/profile/joao-pedro'),
  ('41000000-0000-4000-8000-000000000038', '51000000-0000-4000-8000-000000000038', '31000000-0000-4000-8000-000000000038', 'marc-guiu', 'Marc Guiu', 'Spanish', 'Striker', 'forward', '2006-01-04', 187, null, '2024-07-01', 'https://www.chelseafc.com/en/teams/profile/marc-guiu'),
  ('41000000-0000-4000-8000-000000000039', '51000000-0000-4000-8000-000000000039', '31000000-0000-4000-8000-000000000039', 'estevao', 'Estevao Willian', 'Brazilian', 'Forward', 'forward', '2007-04-24', 178, null, null, 'https://www.chelseafc.com/en/teams/profile/estevao'),
  ('41000000-0000-4000-8000-000000000040', '51000000-0000-4000-8000-000000000040', '31000000-0000-4000-8000-000000000040', 'mykhailo-mudryk', 'Mykhailo Mudryk', 'Ukrainian', 'Winger', 'forward', '2001-01-05', 175, 'right', null, 'https://www.chelseafc.com/en/teams/profile/mykhailo-mudryk'),
  ('41000000-0000-4000-8000-000000000041', '51000000-0000-4000-8000-000000000041', '31000000-0000-4000-8000-000000000041', 'geovany-quenda', 'Geovany Quenda', 'Portuguese', 'Winger/wing-back', 'forward', '2007-04-30', 172, null, null, 'https://www.chelseafc.com/en/teams/profile/geovany-quenda'),
  ('41000000-0000-4000-8000-000000000042', '51000000-0000-4000-8000-000000000042', '31000000-0000-4000-8000-000000000042', 'emmanuel-emegha', 'Emmanuel Emegha', 'Dutch', 'Forward', 'forward', '2003-02-03', 196, null, null, 'https://www.chelseafc.com/en/teams/profile/emmanuel-emegha');

insert into public.sources (
  id,
  url,
  publisher,
  retrieved_at,
  visibility,
  created_at
)
values (
  '31000000-0000-4000-8000-000000000100',
  'https://www.chelseafc.com/en/teams/mens-profiles',
  'Chelsea Football Club',
  '2026-08-16T12:00:00+09:00',
  'public',
  '2026-08-16T12:00:00+09:00'
)
on conflict (id) do update
set
  url = excluded.url,
  publisher = excluded.publisher,
  retrieved_at = excluded.retrieved_at,
  visibility = excluded.visibility;

insert into public.sources (
  id,
  url,
  publisher,
  retrieved_at,
  visibility,
  created_at
)
select
  catalog.profile_source_id,
  catalog.profile_url,
  'Chelsea Football Club',
  '2026-08-16T12:00:00+09:00',
  'public',
  '2026-08-16T12:00:00+09:00'
from first_team_catalog_seed as catalog
on conflict (id) do update
set
  url = excluded.url,
  publisher = excluded.publisher,
  retrieved_at = excluded.retrieved_at,
  visibility = excluded.visibility;

insert into public.people (
  id,
  slug,
  display_name,
  visibility,
  created_at,
  updated_at
)
select
  catalog.person_id,
  catalog.slug,
  catalog.display_name,
  'public',
  '2026-08-16T00:00:00+09:00',
  '2026-08-16T00:00:00+09:00'
from first_team_catalog_seed as catalog
on conflict (id) do update
set
  slug = excluded.slug,
  display_name = excluded.display_name,
  visibility = excluded.visibility,
  updated_at = excluded.updated_at;

insert into public.player_profiles (
  person_id,
  nationality,
  date_of_birth,
  height_cm,
  preferred_foot,
  primary_position,
  position_group,
  joined_at,
  summary,
  source_id,
  visibility,
  created_at,
  updated_at
)
select
  catalog.person_id,
  catalog.nationality,
  catalog.date_of_birth,
  catalog.height_cm,
  catalog.preferred_foot,
  catalog.primary_position,
  catalog.position_group,
  catalog.joined_at,
  null,
  catalog.profile_source_id,
  'public',
  '2026-08-16T00:00:00+09:00',
  '2026-08-16T00:00:00+09:00'
from first_team_catalog_seed as catalog
on conflict (person_id) do update
set
  nationality = excluded.nationality,
  date_of_birth = excluded.date_of_birth,
  height_cm = excluded.height_cm,
  preferred_foot = excluded.preferred_foot,
  primary_position = excluded.primary_position,
  position_group = excluded.position_group,
  joined_at = excluded.joined_at,
  source_id = excluded.source_id,
  visibility = excluded.visibility,
  updated_at = excluded.updated_at;

insert into public.role_assignments (
  id,
  person_id,
  club_id,
  team_id,
  role_type,
  role_title,
  assignment_type,
  valid_from,
  valid_to,
  valid_from_precision,
  recorded_at,
  superseded_at,
  change_type,
  source_id,
  visibility,
  created_at
)
select
  catalog.role_id,
  catalog.person_id,
  '10000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  'player',
  null,
  'squad',
  null,
  null,
  'unknown',
  '2026-08-16T00:00:00+09:00',
  null,
  'actual_change',
  '31000000-0000-4000-8000-000000000100',
  'public',
  '2026-08-16T00:00:00+09:00'
from first_team_catalog_seed as catalog
on conflict (id) do update
set
  person_id = excluded.person_id,
  club_id = excluded.club_id,
  team_id = excluded.team_id,
  role_type = excluded.role_type,
  role_title = excluded.role_title,
  assignment_type = excluded.assignment_type,
  valid_from = excluded.valid_from,
  valid_to = excluded.valid_to,
  valid_from_precision = excluded.valid_from_precision,
  recorded_at = excluded.recorded_at,
  superseded_at = excluded.superseded_at,
  change_type = excluded.change_type,
  source_id = excluded.source_id,
  visibility = excluded.visibility;

COMMIT;
