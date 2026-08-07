BEGIN;

create schema if not exists extensions;
create extension if not exists btree_gist with schema extensions;

set search_path = public, extensions;

create table public.people (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  display_name text not null,
  visibility text not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint people_slug_key unique (slug),
  constraint people_slug_not_blank check (btrim(slug) <> ''),
  constraint people_display_name_not_blank check (btrim(display_name) <> ''),
  constraint people_visibility_check check (visibility in ('public', 'private'))
);

comment on table public.people is
  'Canonical identities for people referenced by Chelsea Hub.';
comment on constraint people_visibility_check on public.people is
  'Prevents people from becoming visible without an explicit public value.';

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  visibility text not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clubs_slug_key unique (slug),
  constraint clubs_slug_not_blank check (btrim(slug) <> ''),
  constraint clubs_name_not_blank check (btrim(name) <> ''),
  constraint clubs_visibility_check check (visibility in ('public', 'private'))
);

comment on table public.clubs is
  'Clubs that own teams or appear in role assignment history.';
comment on constraint clubs_visibility_check on public.clubs is
  'Keeps new club rows private unless publication is explicit.';

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs (id),
  slug text not null,
  name text not null,
  team_level text not null,
  visibility text not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint teams_club_slug_key unique (club_id, slug),
  constraint teams_id_club_id_key unique (id, club_id),
  constraint teams_slug_not_blank check (btrim(slug) <> ''),
  constraint teams_name_not_blank check (btrim(name) <> ''),
  constraint teams_team_level_check check (
    team_level in ('first_team', 'u21', 'u18', 'u16', 'other')
  ),
  constraint teams_visibility_check check (visibility in ('public', 'private'))
);

comment on table public.teams is
  'Club teams, including age-group teams whose rows default to private.';
comment on constraint teams_id_club_id_key on public.teams is
  'Supports composite foreign keys that guarantee team and club consistency.';
comment on constraint teams_team_level_check on public.teams is
  'Restricts team classification to the supported levels.';

create table public.sources (
  id uuid primary key default gen_random_uuid(),
  url text not null,
  publisher text,
  retrieved_at timestamptz,
  visibility text not null default 'private',
  created_at timestamptz not null default now(),
  constraint sources_url_not_blank check (btrim(url) <> ''),
  constraint sources_visibility_check check (visibility in ('public', 'private'))
);

comment on table public.sources is
  'Source references and retrieval timestamps without copied source content.';
comment on constraint sources_url_not_blank on public.sources is
  'Rejects source records without a usable URL.';

create table public.player_profiles (
  person_id uuid primary key references public.people (id),
  nationality text,
  date_of_birth date,
  height_cm smallint,
  preferred_foot text,
  primary_position text,
  summary text,
  source_id uuid references public.sources (id),
  visibility text not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint player_profiles_height_cm_check check (
    height_cm is null or height_cm between 100 and 250
  ),
  constraint player_profiles_visibility_check check (
    visibility in ('public', 'private')
  )
);

comment on table public.player_profiles is
  'Nullable player attributes; unknown values remain null rather than inferred.';
comment on constraint player_profiles_height_cm_check on public.player_profiles is
  'Allows unknown height while rejecting values outside a realistic range.';

create table public.role_assignments (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people (id),
  club_id uuid not null references public.clubs (id),
  team_id uuid,
  role_type text not null,
  role_title text,
  assignment_type text not null,
  valid_from date,
  valid_to date,
  valid_from_precision text not null default 'unknown',
  recorded_at timestamptz not null default now(),
  superseded_at timestamptz,
  change_type text not null,
  source_id uuid references public.sources (id),
  visibility text not null default 'private',
  created_at timestamptz not null default now(),
  constraint role_assignments_team_club_fkey
    foreign key (team_id, club_id)
    references public.teams (id, club_id),
  constraint role_assignments_role_type_check check (
    role_type in ('player', 'head_coach', 'coach', 'staff', 'executive', 'owner')
  ),
  constraint role_assignments_assignment_type_check check (
    assignment_type in (
      'squad',
      'contracted',
      'loan',
      'staff',
      'executive',
      'ownership'
    )
  ),
  constraint role_assignments_valid_dates_check check (
    valid_to is null or (valid_from is not null and valid_to > valid_from)
  ),
  constraint role_assignments_valid_from_precision_check check (
    (valid_from_precision = 'unknown' and valid_from is null)
    or (valid_from_precision = 'day' and valid_from is not null)
    or (
      valid_from_precision = 'month'
      and valid_from is not null
      and extract(day from valid_from) = 1
    )
    or (
      valid_from_precision = 'year'
      and valid_from is not null
      and extract(month from valid_from) = 1
      and extract(day from valid_from) = 1
    )
  ),
  constraint role_assignments_superseded_at_check check (
    superseded_at is null or superseded_at >= recorded_at
  ),
  constraint role_assignments_change_type_check check (
    change_type in ('actual_change', 'correction')
  ),
  constraint role_assignments_visibility_check check (
    visibility in ('public', 'private')
  ),
  constraint role_assignments_no_confirmed_overlap
    exclude using gist (
      person_id with =,
      club_id with =,
      role_type with =,
      assignment_type with =,
      daterange(valid_from, valid_to, '[)') with &&
    )
    where (
      valid_from is not null
      and superseded_at is null
    )
);

comment on table public.role_assignments is
  'Append-oriented role history with correction and supersession metadata; direct correction links are deferred to the management-access design.';
comment on constraint role_assignments_team_club_fkey on public.role_assignments is
  'Guarantees that an assigned team belongs to the assignment club.';
comment on constraint role_assignments_valid_from_precision_check
  on public.role_assignments is
  'Unknown dates are null; month precision uses the first day of the month and year precision uses January 1.';
comment on constraint role_assignments_no_confirmed_overlap on public.role_assignments is
  'Prevents overlapping confirmed current-history periods using half-open date ranges.';

create table public.squad_number_history (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people (id),
  team_id uuid not null references public.teams (id),
  squad_number smallint not null,
  valid_from date not null,
  valid_to date,
  recorded_at timestamptz not null default now(),
  superseded_at timestamptz,
  change_type text not null,
  source_id uuid references public.sources (id),
  visibility text not null default 'private',
  constraint squad_number_history_number_check check (
    squad_number between 1 and 99
  ),
  constraint squad_number_history_valid_dates_check check (
    valid_to is null or valid_to > valid_from
  ),
  constraint squad_number_history_superseded_at_check check (
    superseded_at is null or superseded_at >= recorded_at
  ),
  constraint squad_number_history_change_type_check check (
    change_type in ('actual_change', 'correction')
  ),
  constraint squad_number_history_visibility_check check (
    visibility in ('public', 'private')
  ),
  constraint squad_number_history_no_person_team_overlap
    exclude using gist (
      person_id with =,
      team_id with =,
      daterange(valid_from, valid_to, '[)') with &&
    )
    where (superseded_at is null),
  constraint squad_number_history_no_team_number_overlap
    exclude using gist (
      team_id with =,
      squad_number with =,
      daterange(valid_from, valid_to, '[)') with &&
    )
    where (superseded_at is null)
);

comment on table public.squad_number_history is
  'Dated squad-number history retaining superseded corrections.';
comment on constraint squad_number_history_no_person_team_overlap
  on public.squad_number_history is
  'Allows only one current-history squad number per person and team at a time.';
comment on constraint squad_number_history_no_team_number_overlap
  on public.squad_number_history is
  'Prevents a current-history number being assigned twice on one team.';

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  person_id uuid references public.people (id),
  asset_type text not null,
  local_reference text,
  source_url text,
  author text,
  license_name text,
  license_url text,
  usage_scope text not null default 'private_only',
  created_at timestamptz not null default now(),
  constraint media_assets_asset_type_check check (
    asset_type in ('photo', 'illustration', 'emblem')
  ),
  constraint media_assets_usage_scope_check check (
    usage_scope in ('private_only', 'publishable')
  )
);

comment on table public.media_assets is
  'Metadata and references for media; binary file contents are not stored here.';
comment on constraint media_assets_usage_scope_check on public.media_assets is
  'Defaults media to private-only until publication rights are confirmed.';

create table public.app_users (
  user_id uuid primary key references auth.users (id),
  access_level text not null,
  created_at timestamptz not null default now(),
  constraint app_users_access_level_check check (access_level = 'owner')
);

comment on table public.app_users is
  'Application owner allowlist keyed to Supabase Auth users.';
comment on constraint app_users_access_level_check on public.app_users is
  'Restricts the initial authorization model to the owner access level.';

alter table public.people enable row level security;
alter table public.clubs enable row level security;
alter table public.teams enable row level security;
alter table public.sources enable row level security;
alter table public.player_profiles enable row level security;
alter table public.role_assignments enable row level security;
alter table public.squad_number_history enable row level security;
alter table public.media_assets enable row level security;
alter table public.app_users enable row level security;

create policy people_public_select
  on public.people
  for select
  to anon, authenticated
  using (visibility = 'public');

create policy people_owner_select
  on public.people
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy clubs_public_select
  on public.clubs
  for select
  to anon, authenticated
  using (visibility = 'public');

create policy clubs_owner_select
  on public.clubs
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy teams_public_select
  on public.teams
  for select
  to anon, authenticated
  using (
    visibility = 'public'
    and exists (
      select 1
      from public.clubs as policy_club
      where policy_club.id = teams.club_id
        and policy_club.visibility = 'public'
    )
  );

create policy teams_owner_select
  on public.teams
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy sources_public_select
  on public.sources
  for select
  to anon, authenticated
  using (visibility = 'public');

create policy sources_owner_select
  on public.sources
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy player_profiles_public_select
  on public.player_profiles
  for select
  to anon, authenticated
  using (
    visibility = 'public'
    and exists (
      select 1
      from public.people as policy_person
      where policy_person.id = player_profiles.person_id
        and policy_person.visibility = 'public'
    )
    and (
      source_id is null
      or exists (
        select 1
        from public.sources as policy_source
        where policy_source.id = player_profiles.source_id
          and policy_source.visibility = 'public'
      )
    )
  );

create policy player_profiles_owner_select
  on public.player_profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy role_assignments_public_select
  on public.role_assignments
  for select
  to anon, authenticated
  using (
    visibility = 'public'
    and exists (
      select 1
      from public.people as policy_person
      where policy_person.id = role_assignments.person_id
        and policy_person.visibility = 'public'
    )
    and exists (
      select 1
      from public.clubs as policy_club
      where policy_club.id = role_assignments.club_id
        and policy_club.visibility = 'public'
    )
    and (
      team_id is null
      or exists (
        select 1
        from public.teams as policy_team
        join public.clubs as policy_team_club
          on policy_team_club.id = policy_team.club_id
        where policy_team.id = role_assignments.team_id
          and policy_team.club_id = role_assignments.club_id
          and policy_team.visibility = 'public'
          and policy_team_club.visibility = 'public'
      )
    )
    and (
      source_id is null
      or exists (
        select 1
        from public.sources as policy_source
        where policy_source.id = role_assignments.source_id
          and policy_source.visibility = 'public'
      )
    )
  );

create policy role_assignments_owner_select
  on public.role_assignments
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy squad_number_history_public_select
  on public.squad_number_history
  for select
  to anon, authenticated
  using (
    visibility = 'public'
    and exists (
      select 1
      from public.people as policy_person
      where policy_person.id = squad_number_history.person_id
        and policy_person.visibility = 'public'
    )
    and exists (
      select 1
      from public.teams as policy_team
      join public.clubs as policy_team_club
        on policy_team_club.id = policy_team.club_id
      where policy_team.id = squad_number_history.team_id
        and policy_team.visibility = 'public'
        and policy_team_club.visibility = 'public'
    )
    and (
      source_id is null
      or exists (
        select 1
        from public.sources as policy_source
        where policy_source.id = squad_number_history.source_id
          and policy_source.visibility = 'public'
      )
    )
  );

create policy squad_number_history_owner_select
  on public.squad_number_history
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy media_assets_publishable_select
  on public.media_assets
  for select
  to anon, authenticated
  using (
    usage_scope = 'publishable'
    and (
      person_id is null
      or exists (
        select 1
        from public.people as policy_person
        where policy_person.id = media_assets.person_id
          and policy_person.visibility = 'public'
      )
    )
  );

create policy media_assets_owner_select
  on public.media_assets
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.app_users
      where user_id = (select auth.uid())
        and access_level = 'owner'
    )
  );

create policy app_users_self_select
  on public.app_users
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create view public.public_people
with (security_invoker = true)
as
select
  people.id,
  people.slug,
  people.display_name
from public.people as people
where people.visibility = 'public';

comment on view public.public_people is
  'Explicit public projection of people marked for publication.';

create view public.public_teams
with (security_invoker = true)
as
select
  teams.id,
  teams.club_id,
  teams.slug,
  teams.name,
  teams.team_level
from public.teams as teams
join public.clubs as clubs
  on clubs.id = teams.club_id
where teams.visibility = 'public'
  and clubs.visibility = 'public';

comment on view public.public_teams is
  'Explicit public projection of teams marked for publication.';

create view public.current_public_squad_numbers
with (security_invoker = true)
as
select
  squad_numbers.person_id,
  people.slug as person_slug,
  people.display_name,
  squad_numbers.team_id,
  teams.slug as team_slug,
  teams.name as team_name,
  squad_numbers.squad_number,
  squad_numbers.valid_from,
  squad_numbers.valid_to
from public.squad_number_history as squad_numbers
join public.people as people
  on people.id = squad_numbers.person_id
join public.teams as teams
  on teams.id = squad_numbers.team_id
join public.clubs as clubs
  on clubs.id = teams.club_id
left join public.sources as sources
  on sources.id = squad_numbers.source_id
where squad_numbers.visibility = 'public'
  and people.visibility = 'public'
  and teams.visibility = 'public'
  and clubs.visibility = 'public'
  and (
    squad_numbers.source_id is null
    or sources.visibility = 'public'
  )
  and squad_numbers.valid_from <= current_date
  and squad_numbers.valid_to is null
  and squad_numbers.superseded_at is null;

comment on view public.current_public_squad_numbers is
  'Current, non-superseded public squad numbers whose person, team, club, and optional source are public.';

revoke all on table public.people from anon, authenticated;
revoke all on table public.clubs from anon, authenticated;
revoke all on table public.teams from anon, authenticated;
revoke all on table public.sources from anon, authenticated;
revoke all on table public.player_profiles from anon, authenticated;
revoke all on table public.role_assignments from anon, authenticated;
revoke all on table public.squad_number_history from anon, authenticated;
revoke all on table public.media_assets from anon, authenticated;
revoke all on table public.app_users from anon, authenticated;
revoke all on table public.public_people from anon, authenticated;
revoke all on table public.public_teams from anon, authenticated;
revoke all on table public.current_public_squad_numbers from anon, authenticated;

grant select (
  id,
  slug,
  display_name,
  visibility,
  created_at,
  updated_at
) on table public.people to anon, authenticated;

grant select (
  id,
  slug,
  name,
  visibility,
  created_at,
  updated_at
) on table public.clubs to anon, authenticated;

grant select (
  id,
  club_id,
  slug,
  name,
  team_level,
  visibility,
  created_at,
  updated_at
) on table public.teams to anon, authenticated;

grant select (
  id,
  url,
  publisher,
  retrieved_at,
  visibility,
  created_at
) on table public.sources to anon, authenticated;

grant select (
  person_id,
  nationality,
  date_of_birth,
  height_cm,
  preferred_foot,
  primary_position,
  summary,
  source_id,
  visibility,
  created_at,
  updated_at
) on table public.player_profiles to anon, authenticated;

grant select (
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
) on table public.role_assignments to anon, authenticated;

grant select (
  id,
  person_id,
  team_id,
  squad_number,
  valid_from,
  valid_to,
  recorded_at,
  superseded_at,
  change_type,
  source_id,
  visibility
) on table public.squad_number_history to anon, authenticated;

grant select (
  id,
  person_id,
  asset_type,
  local_reference,
  source_url,
  author,
  license_name,
  license_url,
  usage_scope,
  created_at
) on table public.media_assets to anon, authenticated;

grant select (
  user_id,
  access_level,
  created_at
) on table public.app_users to authenticated;

grant select (
  id,
  slug,
  display_name
) on table public.public_people to anon, authenticated;

grant select (
  id,
  club_id,
  slug,
  name,
  team_level
) on table public.public_teams to anon, authenticated;

grant select (
  person_id,
  person_slug,
  display_name,
  team_id,
  team_slug,
  team_name,
  squad_number,
  valid_from,
  valid_to
) on table public.current_public_squad_numbers to anon, authenticated;

COMMIT;
