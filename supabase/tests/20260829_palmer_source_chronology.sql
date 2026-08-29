begin;

create temporary table palmer_source_chronology_test_results (
  test_name text primary key,
  result text not null check (result in ('PASS', 'FAIL')),
  details text not null
) on commit drop;

do $corrected_history$
declare
  current_numbers text;
begin
  if not exists (
    select 1 from public.squad_number_history
    where id = '60000000-0000-4000-8000-000000000001'
      and squad_number = 10
      and valid_from = date '2025-06-16'
      and valid_to is null
      and recorded_at = timestamptz '2026-08-07 10:54:15+09'
      and superseded_at is not null
      and change_type = 'actual_change'
      and source_id = '30000000-0000-4000-8000-000000000004'
  ) then raise exception 'The original Palmer No.10 row was not restored and superseded.';
  end if;

  if not exists (
    select 1 from public.squad_number_history
    where id = '60000000-0000-4000-8000-000000000004'
      and squad_number = 10
      and valid_from = date '2025-06-16'
      and valid_to is null
      and superseded_at is null
      and change_type = 'correction'
      and source_id = '30000000-0000-4000-8000-000000000005'
  ) then raise exception 'The current Palmer No.10 correction row is not in the expected state.';
  end if;

  if (select count(*) from public.squad_number_history
      where person_id = '40000000-0000-4000-8000-000000000001'
        and team_id = '20000000-0000-4000-8000-000000000001'
        and squad_number = 10 and superseded_at is null) <> 1 then
    raise exception 'Palmer must have exactly one current No.10 history row.';
  end if;

  if not exists (
    select 1
    from public.squad_number_history as old_history
    join public.squad_number_history as correction
      on correction.id = '60000000-0000-4000-8000-000000000004'
    where old_history.id = '60000000-0000-4000-8000-000000000001'
      and old_history.superseded_at = correction.recorded_at
  ) then raise exception 'Correction time and supersession time differ.';
  end if;

  if exists (
    select 1
    from public.squad_number_history as history
    join public.sources as sources on sources.id = history.source_id
    where history.person_id = '40000000-0000-4000-8000-000000000001'
      and history.recorded_at < sources.created_at
  ) then raise exception 'A Palmer history row still predates its source.';
  end if;

  select string_agg(squad_number::text, ',' order by squad_number)
  into current_numbers
  from public.current_public_squad_numbers
  where person_id = '40000000-0000-4000-8000-000000000001'
    and team_id = '20000000-0000-4000-8000-000000000001';
  if current_numbers is distinct from '10' then
    raise exception 'Current view returned %, expected Palmer No.10 only.', current_numbers;
  end if;

  if not exists (
    select 1 from public.squad_number_history
    where id = '60000000-0000-4000-8000-000000000003'
      and squad_number = 20
      and valid_from = date '2023-09-01'
      and valid_to = date '2025-06-16'
      and recorded_at = timestamptz '2026-08-18 00:00:00+00'
      and superseded_at is null
      and source_id = '30000000-0000-4000-8000-000000000007'
  ) then raise exception 'Palmer No.20 history changed unexpectedly.';
  end if;

  if not exists (
    select 1
    from public.squad_number_history as number_20
    join public.squad_number_history as number_10
      on number_10.id = '60000000-0000-4000-8000-000000000004'
    where number_20.id = '60000000-0000-4000-8000-000000000003'
      and number_20.valid_to = number_10.valid_from
      and not (daterange(number_20.valid_from, number_20.valid_to, '[)')
        && daterange(number_10.valid_from, number_10.valid_to, '[)'))
  ) then raise exception 'Palmer periods are not adjacent non-overlapping half-open ranges.';
  end if;

  if (select string_agg(squad_number || ':' || valid_from || ':' ||
      coalesce(valid_to::text, 'infinity'), ',' order by valid_from)
      from public.squad_number_history
      where person_id = '40000000-0000-4000-8000-000000000002'
        and team_id = '20000000-0000-4000-8000-000000000001')
      is distinct from '25:2023-08-16:infinity' then
    raise exception 'Caicedo No.25 history changed unexpectedly.';
  end if;
end
$corrected_history$;

insert into palmer_source_chronology_test_results values
  ('01_original_uuid_retained', 'PASS', 'The original No.10 UUID remains as history.'),
  ('02_original_source_restored', 'PASS', 'The original source is the v0.2 change announcement.'),
  ('03_original_row_superseded', 'PASS', 'The original No.10 row is superseded.'),
  ('04_single_current_correction', 'PASS', 'Exactly one current No.10 correction exists.'),
  ('05_correction_uses_match_report', 'PASS', 'The correction uses the v0.2 LAFC report.'),
  ('06_all_palmer_sources_chronological', 'PASS', 'All Palmer rows satisfy source chronology.'),
  ('07_current_view_no_10_only', 'PASS', 'The current view returns No.10 once.'),
  ('08_half_open_periods_preserved', 'PASS', 'No.20 and No.10 remain adjacent half-open periods.'),
  ('09_caicedo_unchanged', 'PASS', 'Caicedo No.25 remains unchanged.');

insert into public.sources (id, url, publisher, retrieved_at, visibility, created_at)
values (
  '00000000-0000-4000-8000-000000001301',
  'https://example.test/future-source',
  'Chronology Test',
  '2026-08-30 00:00:00+00',
  'private',
  '2026-08-30 00:00:00+00'
);

do $invalid_history_changes$
declare caught_state text; caught_constraint text;
begin
  begin
    insert into public.squad_number_history (
      id, person_id, team_id, squad_number, valid_from, valid_to,
      recorded_at, superseded_at, change_type, source_id, visibility
    ) values (
      '00000000-0000-4000-8000-000000001302',
      '40000000-0000-4000-8000-000000000001',
      '20000000-0000-4000-8000-000000000001',
      99, date '1900-01-01', date '1900-01-02',
      '2026-08-29 00:00:00+00', null, 'correction',
      '00000000-0000-4000-8000-000000001301', 'private'
    );
    raise exception 'Expected invalid chronology INSERT to fail.';
  exception when check_violation then
    get stacked diagnostics caught_state = returned_sqlstate, caught_constraint = constraint_name;
    if caught_state <> '23514' or caught_constraint <> 'squad_number_history_source_chronology' then raise; end if;
  end;

  begin
    update public.squad_number_history
    set source_id = '00000000-0000-4000-8000-000000001301'
    where id = '60000000-0000-4000-8000-000000000004';
    raise exception 'Expected invalid source_id UPDATE to fail.';
  exception when check_violation then
    get stacked diagnostics caught_state = returned_sqlstate, caught_constraint = constraint_name;
    if caught_state <> '23514' or caught_constraint <> 'squad_number_history_source_chronology' then raise; end if;
  end;
end
$invalid_history_changes$;

insert into palmer_source_chronology_test_results values
  ('10_invalid_insert_rejected', 'PASS', 'Invalid chronology INSERT raised SQLSTATE 23514.'),
  ('11_invalid_source_update_rejected', 'PASS', 'Invalid source_id UPDATE raised SQLSTATE 23514.');

do $source_created_at_guards$
declare caught_state text; caught_constraint text;
begin
  begin
    update public.sources set created_at = '2026-08-29 23:00:00+00'
    where id = '00000000-0000-4000-8000-000000001301';
    raise exception 'Expected backward created_at change to fail.';
  exception when check_violation then
    get stacked diagnostics caught_state = returned_sqlstate, caught_constraint = constraint_name;
    if caught_state <> '23514' or caught_constraint <> 'sources_created_at_immutable' then raise; end if;
  end;
  begin
    update public.sources set created_at = '2026-08-30 01:00:00+00'
    where id = '00000000-0000-4000-8000-000000001301';
    raise exception 'Expected forward created_at change to fail.';
  exception when check_violation then
    get stacked diagnostics caught_state = returned_sqlstate, caught_constraint = constraint_name;
    if caught_state <> '23514' or caught_constraint <> 'sources_created_at_immutable' then raise; end if;
  end;
  update public.sources set created_at = '2026-08-30 00:00:00+00'
  where id = '00000000-0000-4000-8000-000000001301';
end
$source_created_at_guards$;

insert into palmer_source_chronology_test_results values
  ('12_source_created_at_changes_rejected', 'PASS', 'Past and future created_at changes are rejected.'),
  ('13_same_source_created_at_allowed', 'PASS', 'An identical created_at UPDATE succeeds.');

do $legacy_v0_4_upsert$
declare caught_state text; caught_constraint text;
begin
  begin
    insert into public.squad_number_history (
      id, person_id, team_id, squad_number, valid_from, valid_to,
      recorded_at, superseded_at, change_type, source_id, visibility
    ) values (
      '60000000-0000-4000-8000-000000000001',
      '40000000-0000-4000-8000-000000000001',
      '20000000-0000-4000-8000-000000000001',
      10, '2025-06-16', null, '2026-08-07 10:54:15+09', null,
      'actual_change', '30000000-0000-4000-8000-000000000008', 'public'
    ) on conflict (id) do update set
      person_id = excluded.person_id, team_id = excluded.team_id,
      squad_number = excluded.squad_number, valid_from = excluded.valid_from,
      valid_to = excluded.valid_to, superseded_at = excluded.superseded_at,
      change_type = excluded.change_type, source_id = excluded.source_id,
      visibility = excluded.visibility;
    raise exception 'Expected the v0.4 upsert to fail.';
  exception when check_violation then
    get stacked diagnostics caught_state = returned_sqlstate, caught_constraint = constraint_name;
    if caught_state <> '23514' or caught_constraint not in (
      'squad_number_history_source_chronology',
      'squad_number_history_superseded_at_monotonic'
    ) then raise; end if;
  end;
end
$legacy_v0_4_upsert$;

insert into palmer_source_chronology_test_results values
  ('14_legacy_v0_4_rejected', 'PASS', 'The v0.4 upsert cannot restore the old row.');

do $ledger_reapplication$
declare
  stored_checksum text; changed_checksum text;
  first_applied_at timestamptz; repeated_applied_at timestamptz;
  registration_result boolean; caught_state text; caught_constraint text;
begin
  select checksum, applied_at into stored_checksum, first_applied_at
  from public.data_script_applications
  where script_name = 'scripts/data/20260829_correct_palmer_squad_number_source_chronology.sql';
  if stored_checksum is null then raise exception 'Correction is absent from the ledger.'; end if;

  select public.register_data_script_application(
    'scripts/data/20260829_correct_palmer_squad_number_source_chronology.sql', stored_checksum
  ) into registration_result;
  select applied_at into repeated_applied_at from public.data_script_applications
  where script_name = 'scripts/data/20260829_correct_palmer_squad_number_source_chronology.sql';
  if registration_result is distinct from false or repeated_applied_at is distinct from first_applied_at then
    raise exception 'Same-checksum registration was not stable.';
  end if;

  changed_checksum := case left(stored_checksum, 1) when '0' then '1' else '0' end || substring(stored_checksum from 2);
  begin
    perform public.register_data_script_application(
      'scripts/data/20260829_correct_palmer_squad_number_source_chronology.sql', changed_checksum
    );
    raise exception 'Expected changed checksum to fail.';
  exception when check_violation then
    get stacked diagnostics caught_state = returned_sqlstate, caught_constraint = constraint_name;
    if caught_state <> '23514' or caught_constraint <> 'data_script_applications_script_checksum_immutable' then raise; end if;
  end;
end
$ledger_reapplication$;

insert into palmer_source_chronology_test_results values
  ('15_same_checksum_skips_payload', 'PASS', 'Same checksum reports already applied.'),
  ('16_changed_checksum_rejected', 'PASS', 'Changed checksum raises SQLSTATE 23514.'),
  ('17_applied_at_unchanged', 'PASS', 'Rechecking does not change applied_at.');

select test_name, result, details from palmer_source_chronology_test_results order by test_name;
rollback;

do $rollback_verified$
begin
  if exists (select 1 from public.sources where id = '00000000-0000-4000-8000-000000001301')
    or exists (select 1 from public.squad_number_history where id = '00000000-0000-4000-8000-000000001302') then
    raise exception 'Chronology test fixtures remained after ROLLBACK.';
  end if;
end
$rollback_verified$;

select '18_rollback_verified' as test_name, 'PASS' as result,
  'All chronology fixtures were rolled back.' as details;
