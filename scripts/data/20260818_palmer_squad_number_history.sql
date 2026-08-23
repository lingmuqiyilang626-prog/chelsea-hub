BEGIN;

-- Operational data update. This script is intentionally separate from the
-- migration history and may be rerun without creating logical duplicates.
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
    '30000000-0000-4000-8000-000000000007',
    'https://www.chelseafc.com/en/news/article/palmer-squad-number-confirmed',
    'Chelsea Football Club',
    '2026-08-18T00:00:00Z',
    'public',
    '2026-08-18T00:00:00Z'
  ),
  (
    '30000000-0000-4000-8000-000000000004',
    'https://www.chelseafc.com/en/news/article/cole-palmer-change-squad-number-ahead-2025-26-season',
    'Chelsea Football Club',
    '2026-08-18T00:00:00Z',
    'public',
    '2026-08-07T10:54:15+09:00'
  ),
  (
    '30000000-0000-4000-8000-000000000008',
    'https://www.chelseafc.com/en/match/chelsea-vs-los-angeles-football-club-fifa-club-world-cup-2025-06-16',
    'Chelsea Football Club',
    '2026-08-18T00:00:00Z',
    'public',
    '2026-08-18T00:00:00Z'
  )
on conflict (id) do update
set
  url = excluded.url,
  publisher = excluded.publisher,
  retrieved_at = excluded.retrieved_at,
  visibility = excluded.visibility;

-- Preserve the existing No.10 row's deterministic UUID and recorded_at.
-- The match page is the source for its confirmed 2025-06-16 effective date.
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
    '30000000-0000-4000-8000-000000000008',
    'public'
  ),
  (
    '60000000-0000-4000-8000-000000000003',
    '40000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    20,
    '2023-09-01',
    '2025-06-16',
    '2026-08-18T00:00:00Z',
    null,
    'actual_change',
    '30000000-0000-4000-8000-000000000007',
    'public'
  )
on conflict (id) do update
set
  person_id = excluded.person_id,
  team_id = excluded.team_id,
  squad_number = excluded.squad_number,
  valid_from = excluded.valid_from,
  valid_to = excluded.valid_to,
  superseded_at = excluded.superseded_at,
  change_type = excluded.change_type,
  source_id = excluded.source_id,
  visibility = excluded.visibility;

COMMIT;
