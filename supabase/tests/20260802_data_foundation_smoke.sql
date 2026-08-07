BEGIN;

-- Run this smoke test after applying 20260802_data_foundation.sql.
-- Owner and ordinary authenticated-user tests require real auth users and are
-- intentionally deferred to a separate authenticated-access test.

create temporary table smoke_test_results (
  test_name text primary key,
  result text not null check (result in ('PASS', 'FAIL')),
  details text not null
) on commit drop;

insert into public.people (
  id,
  slug,
  display_name,
  visibility
)
values
  (
    '00000000-0000-4000-8000-000000000101',
    'smoke-public-person-a',
    'Smoke Public Person A',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000102',
    'smoke-private-person',
    'Smoke Private Person',
    'private'
  ),
  (
    '00000000-0000-4000-8000-000000000103',
    'smoke-public-person-b',
    'Smoke Public Person B',
    'public'
  );

insert into public.clubs (
  id,
  slug,
  name,
  visibility
)
values
  (
    '00000000-0000-4000-8000-000000000201',
    'smoke-public-club',
    'Smoke Public Club',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000202',
    'smoke-private-club',
    'Smoke Private Club',
    'private'
  );

insert into public.teams (
  id,
  club_id,
  slug,
  name,
  team_level,
  visibility
)
values
  (
    '00000000-0000-4000-8000-000000000301',
    '00000000-0000-4000-8000-000000000201',
    'smoke-public-team',
    'Smoke Public Team',
    'first_team',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000302',
    '00000000-0000-4000-8000-000000000201',
    'smoke-private-team',
    'Smoke Private Team',
    'u21',
    'private'
  ),
  (
    '00000000-0000-4000-8000-000000000303',
    '00000000-0000-4000-8000-000000000202',
    'smoke-public-team-private-club',
    'Smoke Public Team With Private Club',
    'other',
    'public'
  );

insert into public.sources (
  id,
  url,
  publisher,
  retrieved_at,
  visibility
)
values
  (
    '00000000-0000-4000-8000-000000000401',
    'urn:smoke:public-source',
    'Smoke Publisher',
    '2026-08-02 00:00:00+00',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000402',
    'urn:smoke:private-source',
    'Smoke Publisher',
    '2026-08-02 00:00:00+00',
    'private'
  );

insert into public.player_profiles (
  person_id,
  summary,
  source_id,
  visibility
)
values
  (
    '00000000-0000-4000-8000-000000000102',
    'Public profile linked to a private smoke-test person.',
    '00000000-0000-4000-8000-000000000401',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000103',
    'Public profile linked to a private smoke-test source.',
    '00000000-0000-4000-8000-000000000402',
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
  change_type,
  source_id,
  visibility
)
values (
  '00000000-0000-4000-8000-000000000601',
  '00000000-0000-4000-8000-000000000101',
  '00000000-0000-4000-8000-000000000201',
  '00000000-0000-4000-8000-000000000302',
  'player',
  'squad',
  '2025-01-01',
  '2025-07-01',
  'day',
  'actual_change',
  '00000000-0000-4000-8000-000000000401',
  'public'
);

insert into public.squad_number_history (
  id,
  person_id,
  team_id,
  squad_number,
  valid_from,
  valid_to,
  change_type,
  source_id,
  visibility
)
values
  (
    '00000000-0000-4000-8000-000000000501',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000301',
    20,
    '2026-01-01',
    '2026-07-01',
    'actual_change',
    '00000000-0000-4000-8000-000000000401',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000502',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000301',
    10,
    '2026-07-01',
    null,
    'actual_change',
    '00000000-0000-4000-8000-000000000401',
    'public'
  ),
  (
    '00000000-0000-4000-8000-000000000503',
    '00000000-0000-4000-8000-000000000103',
    '00000000-0000-4000-8000-000000000301',
    30,
    '2025-01-01',
    '2025-07-01',
    'actual_change',
    '00000000-0000-4000-8000-000000000402',
    'public'
  );

insert into public.media_assets (
  id,
  person_id,
  asset_type,
  local_reference,
  usage_scope
)
values (
  '00000000-0000-4000-8000-000000000701',
  '00000000-0000-4000-8000-000000000102',
  'illustration',
  'smoke-private-person-reference',
  'publishable'
);

insert into smoke_test_results values (
  '01_fixture_setup',
  'PASS',
  'Created explicit public and private synthetic fixtures.'
);

insert into smoke_test_results values (
  '05_half_open_boundary',
  'PASS',
  'Adjacent [2026-01-01, 2026-07-01) and [2026-07-01, infinity) rows were accepted.'
);

do $smoke$
declare
  rejected boolean := false;
begin
  begin
    insert into public.squad_number_history (
      id,
      person_id,
      team_id,
      squad_number,
      valid_from,
      valid_to,
      change_type,
      source_id,
      visibility
    )
    values (
      '00000000-0000-4000-8000-000000000504',
      '00000000-0000-4000-8000-000000000103',
      '00000000-0000-4000-8000-000000000301',
      10,
      '2026-08-01',
      null,
      'actual_change',
      '00000000-0000-4000-8000-000000000401',
      'public'
    );
  exception
    when exclusion_violation then
      rejected := true;
  end;

  if not rejected then
    raise exception 'Smoke test failed: overlapping team and squad number was accepted.';
  end if;
end
$smoke$;

insert into smoke_test_results values (
  '06_overlapping_team_number_rejected',
  'PASS',
  'Overlapping use of squad number 10 on the same team was rejected.'
);

update public.squad_number_history
set superseded_at = recorded_at + interval '1 second'
where id = '00000000-0000-4000-8000-000000000501';

insert into public.squad_number_history (
  id,
  person_id,
  team_id,
  squad_number,
  valid_from,
  valid_to,
  change_type,
  source_id,
  visibility
)
values (
  '00000000-0000-4000-8000-000000000505',
  '00000000-0000-4000-8000-000000000101',
  '00000000-0000-4000-8000-000000000301',
  21,
  '2026-01-01',
  '2026-07-01',
  'correction',
  '00000000-0000-4000-8000-000000000401',
  'public'
);

insert into smoke_test_results values (
  '07_correction_after_supersession',
  'PASS',
  'A corrected row was accepted after the prior interpretation was superseded.'
);

insert into public.squad_number_history (
  id,
  person_id,
  team_id,
  squad_number,
  valid_from,
  valid_to,
  change_type,
  source_id,
  visibility
)
values (
  '00000000-0000-4000-8000-000000000506',
  '00000000-0000-4000-8000-000000000103',
  '00000000-0000-4000-8000-000000000301',
  99,
  '2099-01-01',
  null,
  'actual_change',
  '00000000-0000-4000-8000-000000000401',
  'public'
);

do $smoke$
declare
  rejected boolean := false;
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
      '00000000-0000-4000-8000-000000000507',
      '00000000-0000-4000-8000-000000000103',
      '00000000-0000-4000-8000-000000000301',
      98,
      '2024-01-01',
      '2024-07-01',
      '2026-01-02 00:00:00+00',
      '2026-01-01 00:00:00+00',
      'correction',
      '00000000-0000-4000-8000-000000000401',
      'private'
    );
  exception
    when check_violation then
      rejected := true;
  end;

  if not rejected then
    raise exception 'Smoke test failed: superseded_at before recorded_at was accepted.';
  end if;
end
$smoke$;

insert into smoke_test_results values (
  '10_invalid_supersession_rejected',
  'PASS',
  'A superseded_at value before recorded_at was rejected.'
);

do $smoke$
declare
  rejected boolean := false;
begin
  begin
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
      change_type,
      source_id,
      visibility
    )
    values (
      '00000000-0000-4000-8000-000000000602',
      '00000000-0000-4000-8000-000000000101',
      '00000000-0000-4000-8000-000000000201',
      null,
      'staff',
      'staff',
      null,
      '2026-07-01',
      'unknown',
      'actual_change',
      '00000000-0000-4000-8000-000000000401',
      'private'
    );
  exception
    when check_violation then
      rejected := true;
  end;

  if not rejected then
    raise exception 'Smoke test failed: role assignment with valid_to only was accepted.';
  end if;
end
$smoke$;

insert into smoke_test_results values (
  '11_valid_to_without_valid_from_rejected',
  'PASS',
  'A role assignment with valid_to but no valid_from was rejected.'
);

set local role anon;

do $smoke$
declare
  observed bigint;
begin
  select count(*) into observed
  from public.people
  where id in (
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000102',
    '00000000-0000-4000-8000-000000000103'
  );
  if observed <> 2 then
    raise exception 'Smoke test failed: anon people count was %, expected 2.', observed;
  end if;

  select count(*) into observed
  from public.clubs
  where id in (
    '00000000-0000-4000-8000-000000000201',
    '00000000-0000-4000-8000-000000000202'
  );
  if observed <> 1 then
    raise exception 'Smoke test failed: anon clubs count was %, expected 1.', observed;
  end if;

  select count(*) into observed
  from public.teams
  where id in (
    '00000000-0000-4000-8000-000000000301',
    '00000000-0000-4000-8000-000000000302',
    '00000000-0000-4000-8000-000000000303'
  );
  if observed <> 1 then
    raise exception 'Smoke test failed: anon teams count was %, expected 1.', observed;
  end if;

  select count(*) into observed
  from public.sources
  where id in (
    '00000000-0000-4000-8000-000000000401',
    '00000000-0000-4000-8000-000000000402'
  );
  if observed <> 1 then
    raise exception 'Smoke test failed: anon sources count was %, expected 1.', observed;
  end if;

  select count(*) into observed
  from public.player_profiles
  where person_id in (
    '00000000-0000-4000-8000-000000000102',
    '00000000-0000-4000-8000-000000000103'
  );
  if observed <> 0 then
    raise exception 'Smoke test failed: anon inferred a private profile relation.';
  end if;

  select count(*) into observed
  from public.teams
  where id = '00000000-0000-4000-8000-000000000303';
  if observed <> 0 then
    raise exception 'Smoke test failed: anon inferred a private club through a public team.';
  end if;

  select count(*) into observed
  from public.role_assignments
  where id = '00000000-0000-4000-8000-000000000601';
  if observed <> 0 then
    raise exception 'Smoke test failed: anon inferred a private team through a public role.';
  end if;

  select count(*) into observed
  from public.squad_number_history
  where id = '00000000-0000-4000-8000-000000000503';
  if observed <> 0 then
    raise exception 'Smoke test failed: anon inferred a private source through public history.';
  end if;

  select count(*) into observed
  from public.media_assets
  where id = '00000000-0000-4000-8000-000000000701';
  if observed <> 0 then
    raise exception 'Smoke test failed: anon inferred a private person through publishable media.';
  end if;

  select count(*) into observed
  from public.current_public_squad_numbers
  where person_id = '00000000-0000-4000-8000-000000000103'
    and squad_number = 99;
  if observed <> 0 then
    raise exception 'Smoke test failed: a future squad number appeared in the current view.';
  end if;

  select count(*) into observed
  from public.current_public_squad_numbers
  where person_id = '00000000-0000-4000-8000-000000000101'
    and team_id = '00000000-0000-4000-8000-000000000301'
    and squad_number = 10;
  if observed <> 1 then
    raise exception 'Smoke test failed: current public squad number count was %, expected 1.', observed;
  end if;

  begin
    insert into public.people (
      id,
      slug,
      display_name,
      visibility
    )
    values (
      '00000000-0000-4000-8000-000000000104',
      'smoke-anon-insert',
      'Smoke Anon Insert',
      'public'
    );
    raise exception 'Smoke test failed: anon INSERT unexpectedly succeeded.';
  exception
    when insufficient_privilege then
      null;
  end;

  begin
    update public.people
    set display_name = 'Smoke Anon Update'
    where id = '00000000-0000-4000-8000-000000000101';
    raise exception 'Smoke test failed: anon UPDATE unexpectedly succeeded.';
  exception
    when insufficient_privilege then
      null;
  end;

  begin
    delete from public.people
    where id = '00000000-0000-4000-8000-000000000101';
    raise exception 'Smoke test failed: anon DELETE unexpectedly succeeded.';
  exception
    when insufficient_privilege then
      null;
  end;
end
$smoke$;

reset role;

insert into smoke_test_results values
  (
    '02_anon_public_only',
    'PASS',
    'Anon saw only explicitly public people, clubs, teams, and sources.'
  ),
  (
    '03_related_private_rows_hidden',
    'PASS',
    'Public child rows did not reveal private people, clubs, teams, or sources.'
  ),
  (
    '04_anon_writes_rejected',
    'PASS',
    'Anon INSERT, UPDATE, and DELETE were rejected.'
  ),
  (
    '08_future_number_hidden',
    'PASS',
    'The future-starting squad number was absent from the current view.'
  ),
  (
    '09_current_public_number_visible',
    'PASS',
    'Exactly one current public squad number 10 was visible.'
  );

ROLLBACK;

do $smoke_cleanup$
begin
  if exists (
    select 1
    from public.people
    where id in (
      '00000000-0000-4000-8000-000000000101',
      '00000000-0000-4000-8000-000000000102',
      '00000000-0000-4000-8000-000000000103',
      '00000000-0000-4000-8000-000000000104'
    )
      or slug in (
        'smoke-public-person-a',
        'smoke-private-person',
        'smoke-public-person-b',
        'smoke-anon-insert'
      )
  ) then
    raise exception 'Smoke test failed: people fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.clubs
    where id in (
      '00000000-0000-4000-8000-000000000201',
      '00000000-0000-4000-8000-000000000202'
    )
      or slug in ('smoke-public-club', 'smoke-private-club')
  ) then
    raise exception 'Smoke test failed: club fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.teams
    where id in (
      '00000000-0000-4000-8000-000000000301',
      '00000000-0000-4000-8000-000000000302',
      '00000000-0000-4000-8000-000000000303'
    )
      or slug in (
        'smoke-public-team',
        'smoke-private-team',
        'smoke-public-team-private-club'
      )
  ) then
    raise exception 'Smoke test failed: team fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.sources
    where id in (
      '00000000-0000-4000-8000-000000000401',
      '00000000-0000-4000-8000-000000000402'
    )
  ) then
    raise exception 'Smoke test failed: source fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.player_profiles
    where person_id in (
      '00000000-0000-4000-8000-000000000102',
      '00000000-0000-4000-8000-000000000103'
    )
  ) then
    raise exception 'Smoke test failed: player profile fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.role_assignments
    where id in (
      '00000000-0000-4000-8000-000000000601',
      '00000000-0000-4000-8000-000000000602'
    )
  ) then
    raise exception 'Smoke test failed: role assignment fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.squad_number_history
    where id in (
      '00000000-0000-4000-8000-000000000501',
      '00000000-0000-4000-8000-000000000502',
      '00000000-0000-4000-8000-000000000503',
      '00000000-0000-4000-8000-000000000504',
      '00000000-0000-4000-8000-000000000505',
      '00000000-0000-4000-8000-000000000506',
      '00000000-0000-4000-8000-000000000507'
    )
  ) then
    raise exception 'Smoke test failed: squad number fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.media_assets
    where id = '00000000-0000-4000-8000-000000000701'
  ) then
    raise exception 'Smoke test failed: media fixtures remained after ROLLBACK.';
  end if;

  if exists (
    select 1
    from public.app_users
    where user_id in (
      '00000000-0000-4000-8000-000000000101',
      '00000000-0000-4000-8000-000000000102',
      '00000000-0000-4000-8000-000000000103',
      '00000000-0000-4000-8000-000000000104'
    )
  ) then
    raise exception 'Smoke test failed: app user fixtures remained after ROLLBACK.';
  end if;
end
$smoke_cleanup$;

select
  results.test_name,
  results.result,
  results.details
from (
  values
    (
      '01_fixture_setup',
      'PASS',
      'Created explicit public and private synthetic fixtures.'
    ),
    (
      '02_anon_public_only',
      'PASS',
      'Anon saw only explicitly public people, clubs, teams, and sources.'
    ),
    (
      '03_related_private_rows_hidden',
      'PASS',
      'Public child rows did not reveal private people, clubs, teams, or sources.'
    ),
    (
      '04_anon_writes_rejected',
      'PASS',
      'Anon INSERT, UPDATE, and DELETE were rejected.'
    ),
    (
      '05_half_open_boundary',
      'PASS',
      'Adjacent half-open squad-number periods were accepted.'
    ),
    (
      '06_overlapping_team_number_rejected',
      'PASS',
      'Overlapping use of one squad number on the same team was rejected.'
    ),
    (
      '07_correction_after_supersession',
      'PASS',
      'A corrected row was accepted after the prior interpretation was superseded.'
    ),
    (
      '08_future_number_hidden',
      'PASS',
      'The future-starting squad number was absent from the current view.'
    ),
    (
      '09_current_public_number_visible',
      'PASS',
      'Exactly one current public squad number was visible.'
    ),
    (
      '10_invalid_supersession_rejected',
      'PASS',
      'A superseded_at value before recorded_at was rejected.'
    ),
    (
      '11_valid_to_without_valid_from_rejected',
      'PASS',
      'A role assignment with valid_to but no valid_from was rejected.'
    ),
    (
      '12_rollback_verified',
      'PASS',
      'ROLLBACK completed and no fixed smoke-test identifiers remained.'
    )
) as results (test_name, result, details)
order by results.test_name;
