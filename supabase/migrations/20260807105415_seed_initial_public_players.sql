BEGIN;

-- Stable identifiers make this seed deterministic and safe to run again.
-- Unknown profile, joining, and contract values remain null by design.

insert into public.clubs (
  id,
  slug,
  name,
  visibility,
  created_at,
  updated_at
)
values (
  '10000000-0000-4000-8000-000000000001',
  'chelsea-football-club',
  'Chelsea Football Club',
  'public',
  '2026-08-07T10:54:15+09:00',
  '2026-08-07T10:54:15+09:00'
)
on conflict (id) do update
set
  slug = excluded.slug,
  name = excluded.name,
  visibility = excluded.visibility,
  updated_at = excluded.updated_at;

insert into public.teams (
  id,
  club_id,
  slug,
  name,
  team_level,
  visibility,
  created_at,
  updated_at
)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'first-team',
  'First Team',
  'first_team',
  'public',
  '2026-08-07T10:54:15+09:00',
  '2026-08-07T10:54:15+09:00'
)
on conflict (id) do update
set
  club_id = excluded.club_id,
  slug = excluded.slug,
  name = excluded.name,
  team_level = excluded.team_level,
  visibility = excluded.visibility,
  updated_at = excluded.updated_at;

insert into public.sources (
  id,
  url,
  publisher,
  retrieved_at,
  visibility,
  created_at
)
values
  (
    '30000000-0000-4000-8000-000000000001',
    'https://www.chelseafc.com/en/teams/profile/cole-palmer',
    'Chelsea Football Club',
    '2026-08-07T10:54:15+09:00',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '30000000-0000-4000-8000-000000000002',
    'https://www.chelseafc.com/en/teams/profile/moises-caicedo',
    'Chelsea Football Club',
    '2026-08-07T10:54:15+09:00',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '30000000-0000-4000-8000-000000000003',
    'https://www.chelseafc.com/en/teams/profile/reece-james',
    'Chelsea Football Club',
    '2026-08-07T10:54:15+09:00',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '30000000-0000-4000-8000-000000000004',
    'https://www.chelseafc.com/en/news/article/cole-palmer-change-squad-number-ahead-2025-26-season',
    'Chelsea Football Club',
    '2026-08-07T10:54:15+09:00',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '30000000-0000-4000-8000-000000000005',
    'https://www.chelseafc.com/en/news/article/match-report-chelsea-2-0-lafc',
    'Chelsea Football Club',
    '2026-08-07T10:54:15+09:00',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '30000000-0000-4000-8000-000000000006',
    'https://www.chelseafc.com/en/news/article/moises-caicedo-squad-number-confirmed',
    'Chelsea Football Club',
    '2026-08-07T10:54:15+09:00',
    'public',
    '2026-08-07T10:54:15+09:00'
  )
on conflict (id) do update
set
  url = excluded.url,
  publisher = excluded.publisher,
  retrieved_at = excluded.retrieved_at,
  visibility = excluded.visibility;

insert into public.people (
  id,
  slug,
  display_name,
  visibility,
  created_at,
  updated_at
)
values
  (
    '40000000-0000-4000-8000-000000000001',
    'cole-palmer',
    'Cole Palmer',
    'public',
    '2026-08-07T10:54:15+09:00',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '40000000-0000-4000-8000-000000000002',
    'moises-caicedo',
    'Moises Caicedo',
    'public',
    '2026-08-07T10:54:15+09:00',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '40000000-0000-4000-8000-000000000003',
    'reece-james',
    'Reece James',
    'public',
    '2026-08-07T10:54:15+09:00',
    '2026-08-07T10:54:15+09:00'
  )
on conflict (id) do update
set
  slug = excluded.slug,
  display_name = excluded.display_name,
  visibility = excluded.visibility,
  updated_at = excluded.updated_at;

insert into public.player_profiles (
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
)
values
  (
    '40000000-0000-4000-8000-000000000001',
    'イングランド',
    null,
    null,
    null,
    '攻撃的ミッドフィールダー／ウインガー',
    '狭い局面での創造性と、得点に関わるプレーを持ち味とする攻撃的な選手です。',
    '30000000-0000-4000-8000-000000000001',
    'public',
    '2026-08-07T10:54:15+09:00',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '40000000-0000-4000-8000-000000000002',
    'エクアドル',
    null,
    null,
    null,
    'ミッドフィールダー',
    '中盤でボールを奪い、攻守のつながりを支える運動量豊富な選手です。',
    '30000000-0000-4000-8000-000000000002',
    'public',
    '2026-08-07T10:54:15+09:00',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '40000000-0000-4000-8000-000000000003',
    'イングランド',
    null,
    null,
    null,
    'ディフェンダー',
    '守備と前進の両面でチームを支える、アカデミー出身の選手です。',
    '30000000-0000-4000-8000-000000000003',
    'public',
    '2026-08-07T10:54:15+09:00',
    '2026-08-07T10:54:15+09:00'
  )
on conflict (person_id) do update
set
  nationality = excluded.nationality,
  date_of_birth = excluded.date_of_birth,
  height_cm = excluded.height_cm,
  preferred_foot = excluded.preferred_foot,
  primary_position = excluded.primary_position,
  summary = excluded.summary,
  source_id = excluded.source_id,
  visibility = excluded.visibility,
  updated_at = excluded.updated_at;

-- A squad assignment records first-team membership only. It intentionally
-- does not claim a joining date or contract period.
insert into public.role_assignments (
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
)
values
  (
    '50000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    null,
    'squad',
    null,
    null,
    'unknown',
    '2026-08-07T10:54:15+09:00',
    null,
    'actual_change',
    '30000000-0000-4000-8000-000000000001',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '50000000-0000-4000-8000-000000000002',
    '40000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    null,
    'squad',
    null,
    null,
    'unknown',
    '2026-08-07T10:54:15+09:00',
    null,
    'actual_change',
    '30000000-0000-4000-8000-000000000002',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '50000000-0000-4000-8000-000000000003',
    '40000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'player',
    null,
    'squad',
    null,
    null,
    'unknown',
    '2026-08-07T10:54:15+09:00',
    null,
    'actual_change',
    '30000000-0000-4000-8000-000000000003',
    'public',
    '2026-08-07T10:54:15+09:00'
  )
on conflict (id) do update
set
  person_id = excluded.person_id,
  club_id = excluded.club_id,
  team_id = excluded.team_id,
  role_type = excluded.role_type,
  role_title = excluded.role_title,
  assignment_type = excluded.assignment_type,
  valid_from = excluded.valid_from,
  valid_to = excluded.valid_to,
  valid_from_precision = excluded.valid_from_precision,
  recorded_at = excluded.recorded_at,
  superseded_at = excluded.superseded_at,
  change_type = excluded.change_type,
  source_id = excluded.source_id,
  visibility = excluded.visibility;

-- The change announcement establishes Palmer's No.10 selection, while the
-- 2025-06-16 LAFC match report corroborates its first competitive use.
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
values
  (
    '60000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    10,
    '2025-06-16',
    null,
    '2026-08-07T10:54:15+09:00',
    null,
    'actual_change',
    '30000000-0000-4000-8000-000000000004',
    'public'
  ),
  (
    '60000000-0000-4000-8000-000000000002',
    '40000000-0000-4000-8000-000000000002',
    '20000000-0000-4000-8000-000000000001',
    25,
    '2023-08-16',
    null,
    '2026-08-07T10:54:15+09:00',
    null,
    'actual_change',
    '30000000-0000-4000-8000-000000000006',
    'public'
  )
on conflict (id) do update
set
  person_id = excluded.person_id,
  team_id = excluded.team_id,
  squad_number = excluded.squad_number,
  valid_from = excluded.valid_from,
  valid_to = excluded.valid_to,
  recorded_at = excluded.recorded_at,
  superseded_at = excluded.superseded_at,
  change_type = excluded.change_type,
  source_id = excluded.source_id,
  visibility = excluded.visibility;

-- Reece James's current No.24 is not inserted because its effective start
-- date has not been confirmed.

COMMIT;
