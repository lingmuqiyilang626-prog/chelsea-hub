BEGIN;

create temporary table catalog_foundation_test_results (
  test_name text primary key,
  result text not null,
  details text not null
) on commit drop;

do $position_group$
declare
  observed_groups text;
  observed_nationalities text;
begin
  select string_agg(profiles.position_group, ',' order by people.slug)
  into observed_groups
  from public.player_profiles as profiles
  join public.people as people
    on people.id = profiles.person_id
  where people.slug in ('cole-palmer', 'moises-caicedo', 'reece-james');

  if observed_groups is distinct from 'forward,midfielder,defender' then
    raise exception
      'Catalog foundation test failed: existing position groups were %, expected forward,midfielder,defender.',
      observed_groups;
  end if;

  select string_agg(profiles.nationality, ',' order by people.slug)
  into observed_nationalities
  from public.player_profiles as profiles
  join public.people as people
    on people.id = profiles.person_id
  where people.slug in ('cole-palmer', 'moises-caicedo', 'reece-james');

  if observed_nationalities is distinct from 'English,Ecuadorian,English' then
    raise exception
      'Catalog foundation test failed: existing nationalities were %, expected English,Ecuadorian,English.',
      observed_nationalities;
  end if;

  begin
    update public.player_profiles
    set position_group = 'winger'
    where person_id = '40000000-0000-4000-8000-000000000001';
    raise exception
      'Catalog foundation test failed: invalid position group unexpectedly succeeded.';
  exception
    when check_violation then
      null;
  end;
end
$position_group$;

insert into catalog_foundation_test_results values (
  '01_position_group',
  'PASS',
  'Existing players were backfilled, nationalities were normalized, and an unsupported position group was rejected.'
);

insert into public.sources (
  id,
  url,
  publisher,
  retrieved_at,
  visibility
)
values (
  '71000000-0000-4000-8000-000000000001',
  'https://example.com/catalog-foundation-source',
  'Catalog Foundation Test',
  now(),
  'public'
);

insert into public.people (
  id,
  slug,
  display_name,
  visibility
)
values
  (
    '71000000-0000-4000-8000-000000000101',
    'catalog-current-unknown-start',
    'Catalog Current Unknown Start',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000102',
    'catalog-current-dated',
    'Catalog Current Dated',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000103',
    'catalog-ended',
    'Catalog Ended',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000104',
    'catalog-future',
    'Catalog Future',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000105',
    'catalog-superseded',
    'Catalog Superseded',
    'public'
  );

insert into public.role_assignments (
  id,
  person_id,
  club_id,
  team_id,
  role_type,
  assignment_type,
  valid_from,
  valid_to,
  valid_from_precision,
  recorded_at,
  superseded_at,
  change_type,
  source_id,
  visibility
)
values
  (
    '71000000-0000-4000-8000-000000000201',
    '71000000-0000-4000-8000-000000000101',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    'squad',
    null,
    null,
    'unknown',
    now(),
    null,
    'actual_change',
    '71000000-0000-4000-8000-000000000001',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000202',
    '71000000-0000-4000-8000-000000000102',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    'squad',
    current_date - 1,
    current_date + 1,
    'day',
    now(),
    null,
    'actual_change',
    '71000000-0000-4000-8000-000000000001',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000203',
    '71000000-0000-4000-8000-000000000103',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    'squad',
    current_date - 2,
    current_date,
    'day',
    now(),
    null,
    'actual_change',
    '71000000-0000-4000-8000-000000000001',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000204',
    '71000000-0000-4000-8000-000000000104',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    'squad',
    current_date + 1,
    null,
    'day',
    now(),
    null,
    'actual_change',
    '71000000-0000-4000-8000-000000000001',
    'public'
  ),
  (
    '71000000-0000-4000-8000-000000000205',
    '71000000-0000-4000-8000-000000000105',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    'squad',
    current_date - 1,
    null,
    'day',
    now() - interval '2 minutes',
    now() - interval '1 minute',
    'correction',
    '71000000-0000-4000-8000-000000000001',
    'public'
  );

set local role anon;

do $current_assignments$
declare
  observed uuid[];
begin
  select array_agg(assignments.person_id order by assignments.person_id)
  into observed
  from public.current_public_role_assignments as assignments
  where assignments.person_id between
    '71000000-0000-4000-8000-000000000101'
    and '71000000-0000-4000-8000-000000000105';

  if observed is distinct from array[
    '71000000-0000-4000-8000-000000000101'::uuid,
    '71000000-0000-4000-8000-000000000102'::uuid
  ] then
    raise exception
      'Catalog foundation test failed: current assignments were %, expected the unknown-start and dated-current rows.',
      observed;
  end if;
end
$current_assignments$;

reset role;

insert into catalog_foundation_test_results values (
  '02_current_public_role_assignments',
  'PASS',
  'Unknown-start and dated-current roles were visible; ended, future, and superseded roles were hidden.'
);

select test_name, result, details
from catalog_foundation_test_results
order by test_name;

ROLLBACK;
