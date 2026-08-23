BEGIN;

create temporary table palmer_squad_number_history_test_results (
  test_name text primary key,
  result text not null check (result in ('PASS', 'FAIL')),
  details text not null
) on commit drop;

do $history$
declare
  observed text;
begin
  select string_agg(
    history.squad_number || ':' || history.valid_from || ':' ||
      coalesce(history.valid_to::text, 'infinity'),
    ',' order by history.valid_from
  )
  into observed
  from public.squad_number_history as history
  where history.person_id = '40000000-0000-4000-8000-000000000001'
    and history.team_id = '20000000-0000-4000-8000-000000000001'
    and history.superseded_at is null;

  if observed is distinct from
    '20:2023-09-01:2025-06-16,10:2025-06-16:infinity' then
    raise exception
      'Palmer history was %, expected adjacent No.20 and No.10 periods.',
      observed;
  end if;

  if exists (
    select 1
    from public.squad_number_history as history
    where history.person_id = '40000000-0000-4000-8000-000000000001'
      and history.team_id = '20000000-0000-4000-8000-000000000001'
      and (
        history.change_type <> 'actual_change'
        or history.superseded_at is not null
      )
  ) then
    raise exception 'Palmer history must contain only current actual_change rows.';
  end if;
end
$history$;

insert into palmer_squad_number_history_test_results values (
  '01_history_periods',
  'PASS',
  'Palmer has exactly the adjacent No.20 and No.10 actual-change periods.'
);

do $current_number$
declare
  observed text;
begin
  select string_agg(numbers.squad_number::text, ',' order by numbers.squad_number)
  into observed
  from public.current_public_squad_numbers as numbers
  where numbers.person_slug = 'cole-palmer'
    and numbers.team_id = '20000000-0000-4000-8000-000000000001';

  if observed is distinct from '10' then
    raise exception 'Palmer current number was %, expected 10 only.', observed;
  end if;
end
$current_number$;

insert into palmer_squad_number_history_test_results values (
  '02_current_view',
  'PASS',
  'The current public view returns only Palmer No.10.'
);

do $ranges$
declare
  active_on_boundary smallint;
begin
  if exists (
    select 1
    from public.squad_number_history as earlier
    join public.squad_number_history as later
      on earlier.id < later.id
      and earlier.person_id = later.person_id
      and earlier.team_id = later.team_id
      and daterange(earlier.valid_from, earlier.valid_to, '[)')
        && daterange(later.valid_from, later.valid_to, '[)')
    where earlier.person_id = '40000000-0000-4000-8000-000000000001'
      and earlier.team_id = '20000000-0000-4000-8000-000000000001'
      and earlier.superseded_at is null
      and later.superseded_at is null
  ) then
    raise exception 'Palmer squad-number periods overlap.';
  end if;

  select history.squad_number
  into active_on_boundary
  from public.squad_number_history as history
  where history.person_id = '40000000-0000-4000-8000-000000000001'
    and history.team_id = '20000000-0000-4000-8000-000000000001'
    and history.superseded_at is null
    and daterange(history.valid_from, history.valid_to, '[)') @> date '2025-06-16';

  if active_on_boundary is distinct from 10 then
    raise exception
      'Palmer number on 2025-06-16 was %, expected 10.',
      active_on_boundary;
  end if;
end
$ranges$;

insert into palmer_squad_number_history_test_results values (
  '03_half_open_boundary',
  'PASS',
  'The periods do not overlap and No.10 is active on the boundary date.'
);

do $sources$
declare
  linked_sources text;
  registered_sources integer;
begin
  select string_agg(
    history.squad_number || ':' || sources.url,
    ',' order by history.squad_number
  )
  into linked_sources
  from public.squad_number_history as history
  join public.sources as sources
    on sources.id = history.source_id
  where history.person_id = '40000000-0000-4000-8000-000000000001'
    and history.team_id = '20000000-0000-4000-8000-000000000001'
    and history.superseded_at is null
    and sources.publisher = 'Chelsea Football Club'
    and sources.visibility = 'public'
    and sources.retrieved_at::date = date '2026-08-18';

  if linked_sources is distinct from
    '10:https://www.chelseafc.com/en/match/chelsea-vs-los-angeles-football-club-fifa-club-world-cup-2025-06-16,' ||
    '20:https://www.chelseafc.com/en/news/article/palmer-squad-number-confirmed' then
    raise exception 'Palmer linked sources were not the expected official URLs.';
  end if;

  select count(*)
  into registered_sources
  from public.sources as sources
  where sources.url in (
    'https://www.chelseafc.com/en/news/article/palmer-squad-number-confirmed',
    'https://www.chelseafc.com/en/news/article/cole-palmer-change-squad-number-ahead-2025-26-season',
    'https://www.chelseafc.com/en/match/chelsea-vs-los-angeles-football-club-fifa-club-world-cup-2025-06-16'
  )
    and sources.publisher = 'Chelsea Football Club'
    and sources.visibility = 'public'
    and sources.retrieved_at::date = date '2026-08-18';

  if registered_sources <> 3 then
    raise exception
      'Registered Palmer official sources were %, expected 3.',
      registered_sources;
  end if;
end
$sources$;

insert into palmer_squad_number_history_test_results values (
  '04_official_sources',
  'PASS',
  'All three official sources are public and the dated history rows use the appropriate evidence.'
);

do $idempotency_and_isolation$
declare
  palmer_rows integer;
  caicedo_rows text;
begin
  select count(*)
  into palmer_rows
  from public.squad_number_history as history
  where history.person_id = '40000000-0000-4000-8000-000000000001'
    and history.team_id = '20000000-0000-4000-8000-000000000001';

  if palmer_rows <> 2 then
    raise exception
      'Palmer history contained % rows, expected exactly 2.',
      palmer_rows;
  end if;

  select string_agg(
    history.squad_number || ':' || history.valid_from || ':' ||
      coalesce(history.valid_to::text, 'infinity'),
    ',' order by history.valid_from
  )
  into caicedo_rows
  from public.squad_number_history as history
  where history.person_id = '40000000-0000-4000-8000-000000000002'
    and history.team_id = '20000000-0000-4000-8000-000000000001';

  if caicedo_rows is distinct from '25:2023-08-16:infinity' then
    raise exception
      'Caicedo history changed unexpectedly: %.',
      caicedo_rows;
  end if;
end
$idempotency_and_isolation$;

insert into palmer_squad_number_history_test_results values (
  '05_idempotency_and_isolation',
  'PASS',
  'Palmer has two logical rows and Caicedo remains unchanged.'
);

select test_name, result, details
from palmer_squad_number_history_test_results
order by test_name;

ROLLBACK;
