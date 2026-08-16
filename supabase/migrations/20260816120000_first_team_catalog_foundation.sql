BEGIN;

alter table public.player_profiles
  add column position_group text;

alter table public.player_profiles
  add constraint player_profiles_position_group_check check (
    position_group is null
    or position_group in ('goalkeeper', 'defender', 'midfielder', 'forward')
  );

comment on column public.player_profiles.position_group is
  'Stable broad position category for filtering; unknown values remain null.';

update public.player_profiles as profiles
set
  position_group = mapped.position_group,
  nationality = mapped.nationality,
  updated_at = now()
from (
  values
    ('cole-palmer', 'forward', 'English'),
    ('moises-caicedo', 'midfielder', 'Ecuadorian'),
    ('reece-james', 'defender', 'English')
) as mapped (slug, position_group, nationality)
join public.people as people
  on people.slug = mapped.slug
where profiles.person_id = people.id;

comment on column public.player_profiles.nationality is
  'Canonical English nationality value from the cited source; localized display labels belong in the application.';

create view public.current_public_role_assignments
with (security_invoker = true)
as
select
  assignments.id,
  assignments.person_id,
  assignments.club_id,
  assignments.team_id,
  assignments.role_type,
  assignments.role_title,
  assignments.assignment_type,
  assignments.valid_from,
  assignments.valid_to,
  assignments.valid_from_precision,
  assignments.source_id
from public.role_assignments as assignments
join public.people as people
  on people.id = assignments.person_id
join public.clubs as clubs
  on clubs.id = assignments.club_id
left join public.teams as teams
  on teams.id = assignments.team_id
  and teams.club_id = assignments.club_id
left join public.sources as sources
  on sources.id = assignments.source_id
where assignments.visibility = 'public'
  and people.visibility = 'public'
  and clubs.visibility = 'public'
  and (
    assignments.team_id is null
    or (
      teams.id is not null
      and teams.visibility = 'public'
    )
  )
  and (
    assignments.source_id is null
    or sources.visibility = 'public'
  )
  and assignments.superseded_at is null
  and (
    assignments.valid_from is null
    or assignments.valid_from <= current_date
  )
  and (
    assignments.valid_to is null
    or current_date < assignments.valid_to
  );

comment on view public.current_public_role_assignments is
  'Current, non-superseded public role assignments whose related person, club, optional team, and optional source are public.';

grant select (position_group)
  on table public.player_profiles to anon, authenticated;

revoke all
  on table public.current_public_role_assignments from anon, authenticated;

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
  source_id
) on table public.current_public_role_assignments to anon, authenticated;

COMMIT;
