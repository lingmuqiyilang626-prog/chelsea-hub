do $palmer_source_chronology_correction$
declare
  correction_recorded_at timestamptz := transaction_timestamp();
  affected_rows integer;
begin
  if not exists (
    select 1
    from public.squad_number_history as history
    where history.id = '60000000-0000-4000-8000-000000000001'
      and history.person_id = '40000000-0000-4000-8000-000000000001'
      and history.team_id = '20000000-0000-4000-8000-000000000001'
      and history.squad_number = 10
      and history.valid_from = date '2025-06-16'
      and history.valid_to is null
      and history.recorded_at = timestamptz '2026-08-07 10:54:15+09'
      and history.superseded_at is null
      and history.change_type = 'actual_change'
      and history.source_id = '30000000-0000-4000-8000-000000000008'
      and history.visibility = 'public'
  ) then
    raise exception using
      errcode = '23514',
      constraint = 'palmer_no_10_source_chronology_expected_state',
      message = 'Palmer No.10 history does not match the expected pre-correction state';
  end if;

  if not exists (
    select 1
    from public.squad_number_history as history
    where history.id = '60000000-0000-4000-8000-000000000003'
      and history.person_id = '40000000-0000-4000-8000-000000000001'
      and history.team_id = '20000000-0000-4000-8000-000000000001'
      and history.squad_number = 20
      and history.valid_from = date '2023-09-01'
      and history.valid_to = date '2025-06-16'
      and history.recorded_at = timestamptz '2026-08-18 00:00:00+00'
      and history.superseded_at is null
      and history.change_type = 'actual_change'
      and history.source_id = '30000000-0000-4000-8000-000000000007'
      and history.visibility = 'public'
  ) then
    raise exception using
      errcode = '23514',
      constraint = 'palmer_no_20_expected_state',
      message = 'Palmer No.20 history does not match the expected unchanged state';
  end if;

  update public.squad_number_history
  set
    source_id = '30000000-0000-4000-8000-000000000004',
    superseded_at = correction_recorded_at
  where id = '60000000-0000-4000-8000-000000000001';

  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'Expected to supersede one Palmer No.10 row, updated %.', affected_rows;
  end if;

  insert into public.squad_number_history (
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
  )
  values (
    '60000000-0000-4000-8000-000000000004',
    '40000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    10,
    date '2025-06-16',
    null,
    correction_recorded_at,
    null,
    'correction',
    '30000000-0000-4000-8000-000000000005',
    'public'
  );

  if (
    select string_agg(numbers.squad_number::text, ',' order by numbers.squad_number)
    from public.current_public_squad_numbers as numbers
    where numbers.person_id = '40000000-0000-4000-8000-000000000001'
      and numbers.team_id = '20000000-0000-4000-8000-000000000001'
  ) is distinct from '10' then
    raise exception 'Palmer current squad number is not exactly No.10 after correction.';
  end if;

  if not exists (
    select 1
    from public.squad_number_history as history
    where history.id = '60000000-0000-4000-8000-000000000003'
      and history.squad_number = 20
      and history.valid_from = date '2023-09-01'
      and history.valid_to = date '2025-06-16'
      and history.superseded_at is null
  ) then
    raise exception 'Palmer No.20 history changed during correction.';
  end if;

  if not exists (
    select 1
    from public.squad_number_history as history
    where history.person_id = '40000000-0000-4000-8000-000000000002'
      and history.team_id = '20000000-0000-4000-8000-000000000001'
      and history.squad_number = 25
      and history.valid_from = date '2023-08-16'
      and history.valid_to is null
      and history.superseded_at is null
  ) then
    raise exception 'Caicedo No.25 history changed during Palmer correction.';
  end if;
end
$palmer_source_chronology_correction$;
