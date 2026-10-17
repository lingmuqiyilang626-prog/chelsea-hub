\set ON_ERROR_STOP on
begin;

create temporary table role_history_results (
  test_name text primary key,
  result text not null check (result = 'PASS')
) on commit drop;

create function pg_temp.role_history_assert(test_name text, condition boolean)
returns void language plpgsql as $$
begin
  if condition is distinct from true then
    raise exception 'Role history check failed: %', test_name;
  end if;
  insert into role_history_results values (test_name, 'PASS');
end
$$;

create function pg_temp.role_history_expect_error(
  test_name text, statement text, expected_state text, expected_constraint text
) returns void language plpgsql as $$
declare caught_state text; caught_constraint text;
begin
  begin
    execute statement;
  exception when others then
    get stacked diagnostics caught_state = returned_sqlstate,
      caught_constraint = constraint_name;
    if caught_state <> expected_state
      or caught_constraint is distinct from expected_constraint then
      raise;
    end if;
  end;
  if caught_state is null then
    raise exception 'Expected failure did not occur: %', test_name;
  end if;
  insert into role_history_results values (test_name, 'PASS');
end
$$;

insert into public.people (id, slug, display_name, visibility) values
  ('00000000-0000-4000-8000-000000001701',
   'role-integrity-fixture', 'Role integrity fixture', 'public');
insert into public.clubs (id, slug, name, visibility) values
  ('00000000-0000-4000-8000-000000001702',
   'role-integrity-fixture', 'Role integrity fixture', 'public');
insert into public.teams (id, club_id, slug, name, team_level, visibility) values
  ('00000000-0000-4000-8000-000000001703',
   '00000000-0000-4000-8000-000000001702',
   'role-integrity-fixture', 'Role integrity fixture', 'first_team', 'public');
insert into public.role_assignments (
  id, person_id, club_id, team_id, role_type, assignment_type,
  valid_from, valid_to, valid_from_precision, recorded_at, change_type, visibility
) values (
  '00000000-0000-4000-8000-000000001704',
  '00000000-0000-4000-8000-000000001701',
  '00000000-0000-4000-8000-000000001702',
  '00000000-0000-4000-8000-000000001703',
  'player', 'squad', null, '2030-01-10', 'unknown',
  '2026-10-17 00:00:00+00', 'actual_change', 'public'
);

select pg_temp.role_history_assert('01_unknown_start_known_end', exists (
  select 1 from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001704'
    and valid_from is null and valid_to = date '2030-01-10'
    and valid_from_precision = 'unknown'
));

select pg_temp.role_history_expect_error('02_equal_dates_rejected', $sql$
  update public.role_assignments
  set valid_from = '2030-01-10', valid_from_precision = 'day'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_valid_dates_check');
select pg_temp.role_history_expect_error('03_reversed_dates_rejected', $sql$
  update public.role_assignments
  set valid_from = '2030-01-11', valid_from_precision = 'day'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_valid_dates_check');
select pg_temp.role_history_expect_error('04_null_start_day_precision_rejected', $sql$
  update public.role_assignments set valid_from_precision = 'day'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_valid_from_precision_check');
select pg_temp.role_history_expect_error('05_known_start_unknown_precision_rejected', $sql$
  update public.role_assignments set valid_from = '2029-12-01'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_valid_from_precision_check');
select pg_temp.role_history_expect_error('06_invalid_month_precision_rejected', $sql$
  update public.role_assignments
  set valid_from = '2029-12-02', valid_from_precision = 'month'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_valid_from_precision_check');
select pg_temp.role_history_expect_error('07_invalid_year_precision_rejected', $sql$
  update public.role_assignments
  set valid_from = '2029-02-01', valid_from_precision = 'year'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_valid_from_precision_check');

select pg_temp.role_history_assert('08_fixed_day_before_end_effective', exists (
  select 1 from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001704'
    and superseded_at is null
    and (valid_from is null or valid_from <= date '2030-01-09')
    and (valid_to is null or date '2030-01-09' < valid_to)
));
select pg_temp.role_history_assert('09_fixed_end_day_not_effective', not exists (
  select 1 from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001704'
    and superseded_at is null
    and (valid_from is null or valid_from <= date '2030-01-10')
    and (valid_to is null or date '2030-01-10' < valid_to)
));

select pg_temp.role_history_expect_error('10_initial_supersession_before_record_rejected', $sql$
  update public.role_assignments set superseded_at = recorded_at - interval '1 second'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_superseded_at_check');
update public.role_assignments set superseded_at = recorded_at
where id = '00000000-0000-4000-8000-000000001704';
select pg_temp.role_history_assert('11_initial_equal_recorded_allowed', exists (
  select 1 from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001704'
    and superseded_at = recorded_at
));
update public.role_assignments set superseded_at = superseded_at
where id = '00000000-0000-4000-8000-000000001704';
select pg_temp.role_history_assert('12_identical_supersession_allowed', exists (
  select 1 from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001704'
    and superseded_at = timestamptz '2026-10-17 00:00:00+00'
));
select pg_temp.role_history_expect_error('13_supersession_clear_rejected', $sql$
  update public.role_assignments set superseded_at = null
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_superseded_at_immutable');
select pg_temp.role_history_expect_error('14_supersession_backward_rejected', $sql$
  update public.role_assignments set superseded_at = superseded_at - interval '1 second'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_superseded_at_immutable');
select pg_temp.role_history_expect_error('15_supersession_forward_rejected', $sql$
  update public.role_assignments set superseded_at = superseded_at + interval '1 second'
  where id = '00000000-0000-4000-8000-000000001704'
$sql$, '23514', 'role_assignments_superseded_at_immutable');

insert into public.role_assignments (
  id, person_id, club_id, team_id, role_type, assignment_type,
  valid_from, valid_to, valid_from_precision, recorded_at, change_type, visibility
) values (
  '00000000-0000-4000-8000-000000001705',
  '00000000-0000-4000-8000-000000001701',
  '00000000-0000-4000-8000-000000001702',
  '00000000-0000-4000-8000-000000001703',
  'player', 'squad', null, '2030-01-11', 'unknown',
  '2026-10-17 00:00:00+00', 'correction', 'public'
);
select pg_temp.role_history_assert('16_correction_inserted_original_retained', (
  select count(*) = 2 and count(*) filter (where superseded_at is null) = 1
    and count(*) filter (where change_type = 'correction') = 1
  from public.role_assignments
  where id in ('00000000-0000-4000-8000-000000001704',
               '00000000-0000-4000-8000-000000001705')
));
select pg_temp.role_history_assert('17_current_view_excludes_superseded', not exists (
  select 1 from public.current_public_role_assignments
  where id = '00000000-0000-4000-8000-000000001704'
));
update public.role_assignments set superseded_at = recorded_at + interval '1 second'
where id = '00000000-0000-4000-8000-000000001705';
select pg_temp.role_history_assert('18_initial_later_than_recorded_allowed', exists (
  select 1 from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001705'
    and superseded_at = recorded_at + interval '1 second'
));

insert into public.role_assignments (
  id, person_id, club_id, team_id, role_type, assignment_type,
  valid_from, valid_to, valid_from_precision, change_type, visibility
) values (
  '00000000-0000-4000-8000-000000001706',
  '00000000-0000-4000-8000-000000001701',
  '00000000-0000-4000-8000-000000001702',
  '00000000-0000-4000-8000-000000001703',
  'player', 'squad', '2030-01-01', '2030-01-10', 'day', 'actual_change', 'public'
);
select pg_temp.role_history_expect_error('19_known_overlap_gist_rejected', $sql$
  insert into public.role_assignments (
    person_id, club_id, team_id, role_type, assignment_type,
    valid_from, valid_to, valid_from_precision, change_type
  ) select person_id, club_id, team_id, role_type, assignment_type,
    date '2030-01-09', date '2030-01-11', 'day', 'actual_change'
  from public.role_assignments
  where id = '00000000-0000-4000-8000-000000001706'
$sql$, '23P01', 'role_assignments_no_confirmed_overlap');

select test_name, result from role_history_results order by test_name;
rollback;

do $rollback_verified$
begin
  if exists (select 1 from public.role_assignments
      where person_id = '00000000-0000-4000-8000-000000001701')
    or exists (select 1 from public.people
      where id = '00000000-0000-4000-8000-000000001701')
    or exists (select 1 from public.teams
      where id = '00000000-0000-4000-8000-000000001703')
    or exists (select 1 from public.clubs
      where id = '00000000-0000-4000-8000-000000001702') then
    raise exception 'Role integrity fixtures remained after ROLLBACK';
  end if;
end
$rollback_verified$;
select '20_fixtures_rolled_back' as test_name, 'PASS' as result;
