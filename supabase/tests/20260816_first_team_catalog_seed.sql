BEGIN;

create temporary table expected_first_team_catalog (
  slug text primary key,
  position_group text not null
) on commit drop;

insert into expected_first_team_catalog values
  ('robert-sanchez', 'goalkeeper'),
  ('mike-penders', 'goalkeeper'),
  ('teddy-sharman-lowe', 'goalkeeper'),
  ('gabriel-slonina', 'goalkeeper'),
  ('marco-palestra', 'defender'),
  ('tosin-adarabioyo', 'defender'),
  ('benoit-badiashile', 'defender'),
  ('levi-colwill', 'defender'),
  ('mamadou-sarr', 'defender'),
  ('jorrel-hato', 'defender'),
  ('reece-james', 'defender'),
  ('malo-gusto', 'defender'),
  ('wesley-fofana', 'defender'),
  ('aaron-anselmino', 'defender'),
  ('josh-acheampong', 'defender'),
  ('olutayo-subuloye', 'defender'),
  ('pep-chavarria', 'defender'),
  ('maxence-lacroix', 'defender'),
  ('enzo-fernandez', 'midfielder'),
  ('dario-essugo', 'midfielder'),
  ('moises-caicedo', 'midfielder'),
  ('reggie-watson', 'midfielder'),
  ('mahdi-nicoll-jazuli', 'midfielder'),
  ('omari-kellyman', 'midfielder'),
  ('romeo-lavia', 'midfielder'),
  ('reggie-walsh', 'midfielder'),
  ('landon-emenalo', 'midfielder'),
  ('valentin-barco', 'midfielder'),
  ('jordan-henderson', 'midfielder'),
  ('pedro-neto', 'forward'),
  ('liam-delap', 'forward'),
  ('cole-palmer', 'forward'),
  ('jamie-gittens', 'forward'),
  ('nicolas-jackson', 'forward'),
  ('morgan-rogers', 'forward'),
  ('danny-welbeck', 'forward'),
  ('joao-pedro', 'forward'),
  ('marc-guiu', 'forward'),
  ('estevao', 'forward'),
  ('mykhailo-mudryk', 'forward'),
  ('geovany-quenda', 'forward'),
  ('emmanuel-emegha', 'forward');

create temporary table first_team_catalog_seed_test_results (
  test_name text primary key,
  result text not null,
  details text not null
) on commit drop;

do $catalog_membership$
declare
  observed_count integer;
  missing_slugs text;
  unexpected_slugs text;
begin
  select count(*)
  into observed_count
  from public.current_public_role_assignments as assignments
  join public.people as people on people.id = assignments.person_id
  where assignments.club_id = '10000000-0000-4000-8000-000000000001'
    and assignments.team_id = '20000000-0000-4000-8000-000000000001'
    and assignments.role_type = 'player'
    and assignments.assignment_type = 'squad';

  if observed_count <> 42 then
    raise exception
      'First-team catalog seed test failed: current public squad count was %, expected 42.',
      observed_count;
  end if;

  select string_agg(expected.slug, ', ' order by expected.slug)
  into missing_slugs
  from expected_first_team_catalog as expected
  where not exists (
    select 1
    from public.current_public_role_assignments as assignments
    join public.people as people on people.id = assignments.person_id
    where people.slug = expected.slug
      and assignments.team_id = '20000000-0000-4000-8000-000000000001'
      and assignments.role_type = 'player'
      and assignments.assignment_type = 'squad'
  );

  if missing_slugs is not null then
    raise exception
      'First-team catalog seed test failed: expected slugs were missing: %.',
      missing_slugs;
  end if;

  select string_agg(people.slug, ', ' order by people.slug)
  into unexpected_slugs
  from public.current_public_role_assignments as assignments
  join public.people as people on people.id = assignments.person_id
  where assignments.team_id = '20000000-0000-4000-8000-000000000001'
    and assignments.role_type = 'player'
    and assignments.assignment_type = 'squad'
    and not exists (
      select 1
      from expected_first_team_catalog as expected
      where expected.slug = people.slug
    );

  if unexpected_slugs is not null then
    raise exception
      'First-team catalog seed test failed: unexpected slugs were present: %.',
      unexpected_slugs;
  end if;
end
$catalog_membership$;

insert into first_team_catalog_seed_test_results values (
  '01_exact_membership',
  'PASS',
  'The current public Chelsea first-team squad exactly matched the 42 expected slugs.'
);

do $profile_counts$
declare
  people_count integer;
  distinct_slug_count integer;
  profile_count integer;
  profile_source_count integer;
  dob_count integer;
  height_count integer;
  foot_count integer;
  joined_count integer;
begin
  select
    count(*),
    count(distinct people.slug),
    count(profiles.person_id),
    count(profile_sources.id),
    count(profiles.date_of_birth),
    count(profiles.height_cm),
    count(profiles.preferred_foot),
    count(profiles.joined_at)
  into
    people_count,
    distinct_slug_count,
    profile_count,
    profile_source_count,
    dob_count,
    height_count,
    foot_count,
    joined_count
  from expected_first_team_catalog as expected
  left join public.people as people on people.slug = expected.slug
  left join public.player_profiles as profiles on profiles.person_id = people.id
  left join public.sources as profile_sources
    on profile_sources.id = profiles.source_id
    and profile_sources.publisher = 'Chelsea Football Club'
    and profile_sources.url = 'https://www.chelseafc.com/en/teams/profile/' || expected.slug
    and profile_sources.retrieved_at::date = '2026-08-16';

  if people_count <> 42 or distinct_slug_count <> 42 then
    raise exception
      'First-team catalog seed test failed: people/distinct slugs were %/%, expected 42/42.',
      people_count,
      distinct_slug_count;
  end if;

  if profile_count <> 42 or profile_source_count <> 42 then
    raise exception
      'First-team catalog seed test failed: profiles/profile sources were %/%, expected 42/42.',
      profile_count,
      profile_source_count;
  end if;

  if dob_count <> 42 or height_count <> 39 or foot_count <> 4 or joined_count <> 4 then
    raise exception
      'First-team catalog seed test failed: DOB/height/foot/joined counts were %/%/%/%, expected 42/39/4/4.',
      dob_count,
      height_count,
      foot_count,
      joined_count;
  end if;
end
$profile_counts$;

insert into first_team_catalog_seed_test_results values (
  '02_profile_completeness',
  'PASS',
  'All 42 people, unique slugs, profiles, profile sources, and expected nullable attribute counts were correct.'
);

do $position_groups$
declare
  mismatch text;
  observed jsonb;
begin
  select string_agg(expected.slug, ', ' order by expected.slug)
  into mismatch
  from expected_first_team_catalog as expected
  join public.people as people on people.slug = expected.slug
  join public.player_profiles as profiles on profiles.person_id = people.id
  where profiles.position_group <> expected.position_group;

  if mismatch is not null then
    raise exception
      'First-team catalog seed test failed: position groups differed for %.',
      mismatch;
  end if;

  select jsonb_object_agg(group_counts.position_group, group_counts.player_count)
  into observed
  from (
    select profiles.position_group, count(*) as player_count
    from expected_first_team_catalog as expected
    join public.people as people on people.slug = expected.slug
    join public.player_profiles as profiles on profiles.person_id = people.id
    group by profiles.position_group
  ) as group_counts;

  if observed <> '{"goalkeeper": 4, "defender": 14, "midfielder": 11, "forward": 13}'::jsonb then
    raise exception
      'First-team catalog seed test failed: position-group counts were %.',
      observed;
  end if;
end
$position_groups$;

insert into first_team_catalog_seed_test_results values (
  '03_position_groups',
  'PASS',
  'Position groups matched the expected rows and counts: 4 goalkeepers, 14 defenders, 11 midfielders, 13 forwards.'
);

do $nullable_values$
declare
  observed integer;
begin
  select count(*)
  into observed
  from public.people as people
  join public.player_profiles as profiles on profiles.person_id = people.id
  where people.slug = 'nicolas-jackson'
    and profiles.nationality is null;

  if observed <> 1 then
    raise exception
      'First-team catalog seed test failed: Nicolas Jackson nationality-null count was %, expected 1.',
      observed;
  end if;

  select count(*)
  into observed
  from expected_first_team_catalog as expected
  join public.people as people on people.slug = expected.slug
  join public.player_profiles as profiles on profiles.person_id = people.id
  where expected.slug not in ('cole-palmer', 'moises-caicedo', 'reece-james')
    and profiles.summary is null;

  if observed <> 39 then
    raise exception
      'First-team catalog seed test failed: new-player null summaries were %, expected 39.',
      observed;
  end if;

  select count(*)
  into observed
  from public.people as people
  join public.player_profiles as profiles on profiles.person_id = people.id
  where people.slug in ('cole-palmer', 'moises-caicedo', 'reece-james')
    and nullif(btrim(profiles.summary), '') is not null;

  if observed <> 3 then
    raise exception
      'First-team catalog seed test failed: preserved existing summaries were %, expected 3.',
      observed;
  end if;

  select count(*)
  into observed
  from expected_first_team_catalog as expected
  join public.people as people on people.slug = expected.slug
  join public.current_public_role_assignments as assignments
    on assignments.person_id = people.id
  where assignments.assignment_type = 'contracted';

  if observed <> 0 then
    raise exception
      'First-team catalog seed test failed: current contracted assignments were %, expected 0.',
      observed;
  end if;
end
$nullable_values$;

insert into first_team_catalog_seed_test_results values (
  '04_nullable_values',
  'PASS',
  'Nicolas Jackson nationality, 39 new summaries, and all contract-until values remained null; existing summaries were preserved.'
);

do $specific_attributes$
declare
  observed text;
begin
  select string_agg(people.slug || ':' || profiles.preferred_foot, ',' order by people.slug)
  into observed
  from expected_first_team_catalog as expected
  join public.people as people on people.slug = expected.slug
  join public.player_profiles as profiles on profiles.person_id = people.id
  where profiles.preferred_foot is not null;

  if observed <> 'benoit-badiashile:left,mykhailo-mudryk:right,pedro-neto:left,reece-james:right' then
    raise exception
      'First-team catalog seed test failed: preferred-foot rows were %.',
      observed;
  end if;

  select string_agg(people.slug || ':' || profiles.joined_at::text, ',' order by people.slug)
  into observed
  from expected_first_team_catalog as expected
  join public.people as people on people.slug = expected.slug
  join public.player_profiles as profiles on profiles.person_id = people.id
  where profiles.joined_at is not null;

  if observed <> 'jamie-gittens:2025-07-05,marc-guiu:2024-07-01,marco-palestra:2026-07-01,pedro-neto:2024-08-11' then
    raise exception
      'First-team catalog seed test failed: joined-at rows were %.',
      observed;
  end if;
end
$specific_attributes$;

insert into first_team_catalog_seed_test_results values (
  '05_specific_attributes',
  'PASS',
  'The four preferred-foot values and four exact joined-at dates matched the verified input.'
);

do $assignment_integrity$
declare
  observed integer;
begin
  select count(*)
  into observed
  from (
    select assignments.person_id, assignments.team_id, count(*)
    from public.role_assignments as assignments
    join public.people as people on people.id = assignments.person_id
    join expected_first_team_catalog as expected on expected.slug = people.slug
    where assignments.role_type = 'player'
      and assignments.assignment_type = 'squad'
      and assignments.superseded_at is null
    group by assignments.person_id, assignments.team_id
    having count(*) > 1
  ) as duplicates;

  if observed <> 0 then
    raise exception
      'First-team catalog seed test failed: duplicate person/team squad assignments were %.',
      observed;
  end if;

  select count(*)
  into observed
  from expected_first_team_catalog as expected
  join public.people as people on people.slug = expected.slug
  join public.role_assignments as assignments on assignments.person_id = people.id
  join public.sources as sources on sources.id = assignments.source_id
  where assignments.team_id = '20000000-0000-4000-8000-000000000001'
    and assignments.role_type = 'player'
    and assignments.assignment_type = 'squad'
    and assignments.valid_from is null
    and assignments.valid_from_precision = 'unknown'
    and assignments.valid_to is null
    and sources.url = 'https://www.chelseafc.com/en/teams/mens-profiles'
    and sources.retrieved_at::date = '2026-08-16';

  if observed <> 42 then
    raise exception
      'First-team catalog seed test failed: canonical sourced squad assignments were %, expected 42.',
      observed;
  end if;
end
$assignment_integrity$;

insert into first_team_catalog_seed_test_results values (
  '06_assignment_integrity',
  'PASS',
  'All 42 assignments used the listing source and unknown start precision without logical duplicates.'
);

do $squad_numbers$
declare
  observed text;
begin
  select string_agg(numbers.person_slug || ':' || numbers.squad_number, ',' order by numbers.person_slug)
  into observed
  from public.current_public_squad_numbers as numbers
  where numbers.team_id = '20000000-0000-4000-8000-000000000001';

  if observed is distinct from 'cole-palmer:10,moises-caicedo:25' then
    raise exception
      'First-team catalog seed test failed: current squad numbers were %, expected Palmer 10 and Caicedo 25 only.',
      observed;
  end if;
end
$squad_numbers$;

insert into first_team_catalog_seed_test_results values (
  '07_squad_numbers',
  'PASS',
  'No squad numbers were added; only the existing Palmer 10 and Caicedo 25 remained current.'
);

do $excluded_people$
declare
  observed text;
begin
  select string_agg(people.slug, ', ' order by people.slug)
  into observed
  from public.people as people
  where people.slug in (
    'filip-jorgensen',
    'max-merrick',
    'hudson-sands',
    'genesis-antwi',
    'harrison-murray-campbell',
    'ishe-samuels-smith',
    'kaiden-wilson',
    'ollie-harrison',
    'kendry-paez',
    'alejandro-garnacho',
    'ryan-kavuma-mcqueen',
    'jesse-derry',
    'dastan-satpayev',
    'ted-curd',
    'harrison-bettoni',
    'xabi-alonso'
  );

  if observed is not null then
    raise exception
      'First-team catalog seed test failed: excluded people were inserted: %.',
      observed;
  end if;
end
$excluded_people$;

insert into first_team_catalog_seed_test_results values (
  '08_excluded_people',
  'PASS',
  'Representative on-loan, academy-only, and staff slugs were not inserted.'
);

set local role anon;

do $anon_access$
declare
  observed integer;
begin
  select count(*)
  into observed
  from public.current_public_role_assignments as assignments
  where assignments.team_id = '20000000-0000-4000-8000-000000000001'
    and assignments.role_type = 'player'
    and assignments.assignment_type = 'squad';

  if observed <> 42 then
    raise exception
      'First-team catalog seed test failed: anon current public squad count was %, expected 42.',
      observed;
  end if;
end
$anon_access$;

reset role;

insert into first_team_catalog_seed_test_results values (
  '09_anon_access',
  'PASS',
  'Anon could read all 42 current public first-team assignments.'
);

select test_name, result, details
from first_team_catalog_seed_test_results
order by test_name;

ROLLBACK;
