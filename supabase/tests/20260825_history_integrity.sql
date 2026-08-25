begin;

create temporary table history_integrity_test_results (
  test_name text primary key,
  result text not null check (result in ('PASS', 'FAIL')),
  details text not null
) on commit drop;

insert into public.clubs (id, slug, name, visibility)
values (
  '00000000-0000-4000-8000-000000001001',
  'history-integrity-club',
  'History Integrity Club',
  'public'
);

insert into public.teams (id, club_id, slug, name, team_level, visibility)
values (
  '00000000-0000-4000-8000-000000001002',
  '00000000-0000-4000-8000-000000001001',
  'history-integrity-team',
  'History Integrity Team',
  'first_team',
  'public'
);

insert into public.people (id, slug, display_name, visibility)
values (
  '00000000-0000-4000-8000-000000001003',
  'history-integrity-person',
  'History Integrity Person',
  'public'
);

insert into public.sources (
  id,
  url,
  publisher,
  retrieved_at,
  visibility,
  created_at
)
values (
  '00000000-0000-4000-8000-000000001004',
  'https://example.test/history-integrity',
  'History Integrity Test',
  '2026-08-25 00:00:00+00',
  'public',
  '2026-08-25 00:00:00+00'
);

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
  '00000000-0000-4000-8000-000000001005',
  '00000000-0000-4000-8000-000000001003',
  '00000000-0000-4000-8000-000000001002',
  98,
  '2026-08-01',
  null,
  '2026-08-25 00:00:00+00',
  null,
  'actual_change',
  '00000000-0000-4000-8000-000000001004',
  'public'
);

update public.squad_number_history
set superseded_at = '2026-08-25 01:00:00+00'
where id = '00000000-0000-4000-8000-000000001005';

do $supersession_guards$
declare
  caught_state text;
  caught_constraint text;
begin
  begin
    update public.squad_number_history
    set superseded_at = null
    where id = '00000000-0000-4000-8000-000000001005';
    raise exception 'Expected removal of superseded_at to fail.';
  exception
    when check_violation then
      get stacked diagnostics
        caught_state = returned_sqlstate,
        caught_constraint = constraint_name;
      if caught_state <> '23514'
        or caught_constraint <> 'squad_number_history_superseded_at_monotonic' then
        raise;
      end if;
  end;

  begin
    update public.squad_number_history
    set superseded_at = '2026-08-25 00:30:00+00'
    where id = '00000000-0000-4000-8000-000000001005';
    raise exception 'Expected backward superseded_at movement to fail.';
  exception
    when check_violation then
      get stacked diagnostics
        caught_state = returned_sqlstate,
        caught_constraint = constraint_name;
      if caught_state <> '23514'
        or caught_constraint <> 'squad_number_history_superseded_at_monotonic' then
        raise;
      end if;
  end;

  begin
    update public.squad_number_history
    set superseded_at = '2026-08-25 01:30:00+00'
    where id = '00000000-0000-4000-8000-000000001005';
    raise exception 'Expected forward superseded_at movement to fail.';
  exception
    when check_violation then
      get stacked diagnostics
        caught_state = returned_sqlstate,
        caught_constraint = constraint_name;
      if caught_state <> '23514'
        or caught_constraint <> 'squad_number_history_superseded_at_monotonic' then
        raise;
      end if;
  end;
end
$supersession_guards$;

update public.squad_number_history
set superseded_at = '2026-08-25 01:00:00+00'
where id = '00000000-0000-4000-8000-000000001005';

do $unchanged_supersession$
begin
  if not exists (
    select 1
    from public.squad_number_history
    where id = '00000000-0000-4000-8000-000000001005'
      and superseded_at = '2026-08-25 01:00:00+00'
  ) then
    raise exception 'Same-timestamp supersession update changed the row unexpectedly.';
  end if;
end
$unchanged_supersession$;

insert into history_integrity_test_results values
  (
    '01_supersession_removal_rejected',
    'PASS',
    'A superseded row could not be returned to current state.'
  ),
  (
    '02_supersession_backdating_rejected',
    'PASS',
    'An established supersession timestamp could not move backward.'
  ),
  (
    '03_supersession_forward_change_rejected',
    'PASS',
    'An established supersession timestamp could not move forward.'
  ),
  (
    '04_unchanged_supersession_allowed',
    'PASS',
    'Updating an established supersession to the identical timestamp succeeded.'
  );

do $legacy_upsert$
declare
  caught_state text;
  caught_constraint text;
begin
  begin
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
      '00000000-0000-4000-8000-000000001005',
      '00000000-0000-4000-8000-000000001003',
      '00000000-0000-4000-8000-000000001002',
      98,
      '2026-08-01',
      null,
      '2026-08-25 00:00:00+00',
      null,
      'actual_change',
      '00000000-0000-4000-8000-000000001004',
      'public'
    )
    on conflict (id) do update set
      squad_number = excluded.squad_number,
      valid_from = excluded.valid_from,
      valid_to = excluded.valid_to,
      superseded_at = excluded.superseded_at,
      change_type = excluded.change_type,
      source_id = excluded.source_id,
      visibility = excluded.visibility;
    raise exception 'Expected legacy upsert to fail.';
  exception
    when check_violation then
      get stacked diagnostics
        caught_state = returned_sqlstate,
        caught_constraint = constraint_name;
      if caught_state <> '23514'
        or caught_constraint <> 'squad_number_history_superseded_at_monotonic' then
        raise;
      end if;
  end;
end
$legacy_upsert$;

insert into history_integrity_test_results values (
  '05_legacy_upsert_rejected',
  'PASS',
  'A v0.4-style upsert could not clear correction state.'
);

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
  '00000000-0000-4000-8000-000000001006',
  '00000000-0000-4000-8000-000000001003',
  '00000000-0000-4000-8000-000000001002',
  97,
  '2026-08-01',
  null,
  '2026-08-25 01:00:00+00',
  null,
  'correction',
  '00000000-0000-4000-8000-000000001004',
  'public'
);

do $correction$
declare
  current_numbers text;
begin
  if not exists (
    select 1
    from public.squad_number_history
    where id = '00000000-0000-4000-8000-000000001006'
      and change_type = 'correction'
      and superseded_at is null
  ) then
    raise exception 'Expected current correction row was not inserted.';
  end if;

  select string_agg(numbers.squad_number::text, ',' order by numbers.squad_number)
  into current_numbers
  from public.current_public_squad_numbers as numbers
  where numbers.person_id = '00000000-0000-4000-8000-000000001003'
    and numbers.team_id = '00000000-0000-4000-8000-000000001002';

  if current_numbers is distinct from '97' then
    raise exception 'Current view returned %, expected corrected number 97 only.', current_numbers;
  end if;
end
$correction$;

insert into history_integrity_test_results values
  (
    '06_correction_insert_succeeds',
    'PASS',
    'The append-oriented correction flow remains valid.'
  ),
  (
    '07_current_view_uses_correction',
    'PASS',
    'The current view returns only the non-superseded correction row.'
  );

set local role anon;

do $anon_update$
declare
  caught_state text;
begin
  begin
    update public.squad_number_history
    set squad_number = 96
    where id = '00000000-0000-4000-8000-000000001006';
    raise exception 'Expected anon update to fail.';
  exception
    when insufficient_privilege then
      get stacked diagnostics caught_state = returned_sqlstate;
      if caught_state <> '42501' then
        raise;
      end if;
  end;
end
$anon_update$;

reset role;

insert into history_integrity_test_results values (
  '08_anon_update_rejected',
  'PASS',
  'Anon lacks UPDATE privilege on squad-number history.'
);

do $ledger_permissions$
begin
  if has_table_privilege(
    'anon',
    'public.data_script_applications',
    'INSERT,UPDATE,DELETE'
  ) or has_table_privilege(
    'authenticated',
    'public.data_script_applications',
    'INSERT,UPDATE,DELETE'
  ) or has_function_privilege(
    'anon',
    'public.register_data_script_application(text,text)',
    'EXECUTE'
  ) or has_function_privilege(
    'authenticated',
    'public.register_data_script_application(text,text)',
    'EXECUTE'
  ) then
    raise exception 'Client roles unexpectedly have ledger write access.';
  end if;

  if not (
    select relrowsecurity
    from pg_catalog.pg_class
    where oid = 'public.data_script_applications'::regclass
  ) then
    raise exception 'RLS is not enabled on the data-script ledger.';
  end if;
end
$ledger_permissions$;

insert into history_integrity_test_results values (
  '09_ledger_client_writes_rejected',
  'PASS',
  'Anon and authenticated cannot write the RLS-enabled ledger or call its registration function.'
);

do $ledger$
declare
  first_registration boolean;
  repeat_registration boolean;
  first_applied_at timestamptz;
  repeated_applied_at timestamptz;
  caught_state text;
  caught_constraint text;
begin
  select public.register_data_script_application(
    'tests/history-integrity.sql',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  ) into first_registration;

  select applied_at
  into first_applied_at
  from public.data_script_applications
  where script_name = 'tests/history-integrity.sql';

  select public.register_data_script_application(
    'tests/history-integrity.sql',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  ) into repeat_registration;

  select applied_at
  into repeated_applied_at
  from public.data_script_applications
  where script_name = 'tests/history-integrity.sql';

  if first_registration is distinct from true then
    raise exception 'First ledger registration did not report insertion.';
  end if;

  if repeat_registration is distinct from false then
    raise exception 'Same-checksum ledger check did not report prior application.';
  end if;

  if first_applied_at is distinct from repeated_applied_at then
    raise exception 'Same-checksum ledger check changed applied_at.';
  end if;

  begin
    perform public.register_data_script_application(
      'tests/history-integrity.sql',
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    );
    raise exception 'Expected changed-checksum registration to fail.';
  exception
    when check_violation then
      get stacked diagnostics
        caught_state = returned_sqlstate,
        caught_constraint = constraint_name;
      if caught_state <> '23514'
        or caught_constraint <> 'data_script_applications_script_checksum_immutable' then
        raise;
      end if;
  end;
end
$ledger$;

insert into history_integrity_test_results values
  (
    '10_ledger_first_registration',
    'PASS',
    'The first script registration inserted one ledger row.'
  ),
  (
    '11_ledger_same_checksum_is_stable',
    'PASS',
    'A same-name, same-checksum check returned already-applied.'
  ),
  (
    '12_ledger_changed_checksum_rejected',
    'PASS',
    'A same-name, changed-checksum registration raised the expected constraint error.'
  ),
  (
    '13_ledger_applied_at_immutable',
    'PASS',
    'A same-checksum check did not change applied_at.'
  );

select test_name, result, details
from history_integrity_test_results
order by test_name;

rollback;

do $rollback_verified$
begin
  if exists (
    select 1
    from public.people
    where id = '00000000-0000-4000-8000-000000001003'
  ) or exists (
    select 1
    from public.clubs
    where id = '00000000-0000-4000-8000-000000001001'
  ) or exists (
    select 1
    from public.teams
    where id = '00000000-0000-4000-8000-000000001002'
  ) or exists (
    select 1
    from public.sources
    where id = '00000000-0000-4000-8000-000000001004'
  ) or exists (
    select 1
    from public.squad_number_history
    where id in (
      '00000000-0000-4000-8000-000000001005',
      '00000000-0000-4000-8000-000000001006'
    )
  ) or exists (
    select 1
    from public.data_script_applications
    where script_name = 'tests/history-integrity.sql'
  ) then
    raise exception 'History-integrity fixtures remained after ROLLBACK.';
  end if;
end
$rollback_verified$;

select
  '14_rollback_verified' as test_name,
  'PASS' as result,
  'All history and ledger fixtures were rolled back.' as details;
