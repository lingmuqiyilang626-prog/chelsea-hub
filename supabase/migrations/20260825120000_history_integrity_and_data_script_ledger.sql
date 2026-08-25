begin;

create function public.enforce_squad_number_supersession_monotonicity()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $function$
begin
  if old.superseded_at is not null
    and new.superseded_at is distinct from old.superseded_at then
    raise exception using
      errcode = '23514',
      constraint = 'squad_number_history_superseded_at_monotonic',
      message = 'squad number history supersession is immutable once set';
  end if;

  return new;
end
$function$;

comment on function public.enforce_squad_number_supersession_monotonicity() is
  'Makes an established squad-number supersession timestamp immutable while allowing an unchanged value.';

revoke all on function public.enforce_squad_number_supersession_monotonicity()
  from public, anon, authenticated;

create trigger squad_number_history_superseded_at_monotonic
before update of superseded_at on public.squad_number_history
for each row
execute function public.enforce_squad_number_supersession_monotonicity();

create table public.data_script_applications (
  script_name text primary key,
  checksum text not null,
  applied_at timestamptz not null default transaction_timestamp(),
  constraint data_script_applications_script_name_not_blank check (
    btrim(script_name) <> ''
  ),
  constraint data_script_applications_checksum_sha256_check check (
    checksum ~ '^[0-9a-f]{64}$'
  )
);

comment on table public.data_script_applications is
  'Immutable application ledger for transactional data scripts; checksum is lowercase SHA-256 of the exact SQL file bytes.';
comment on column public.data_script_applications.checksum is
  'Lowercase hexadecimal SHA-256 digest of the exact data-script file bytes.';
comment on column public.data_script_applications.applied_at is
  'Timestamp of the first successful registration; same-checksum checks never update it.';

alter table public.data_script_applications enable row level security;

revoke all on table public.data_script_applications
  from public, anon, authenticated;
grant select, insert on table public.data_script_applications to service_role;

create function public.register_data_script_application(
  p_script_name text,
  p_checksum text
)
returns boolean
language plpgsql
set search_path = pg_catalog, public
as $function$
declare
  normalized_script_name text := btrim(p_script_name);
  normalized_checksum text := lower(p_checksum);
  existing_checksum text;
  inserted boolean;
begin
  if normalized_script_name is null or normalized_script_name = '' then
    raise exception using
      errcode = '23514',
      constraint = 'data_script_applications_script_name_not_blank',
      message = 'data script name must not be blank';
  end if;

  if normalized_checksum is null
    or normalized_checksum !~ '^[0-9a-f]{64}$' then
    raise exception using
      errcode = '23514',
      constraint = 'data_script_applications_checksum_sha256_check',
      message = 'data script checksum must be a SHA-256 digest';
  end if;

  insert into public.data_script_applications (script_name, checksum)
  values (normalized_script_name, normalized_checksum)
  on conflict (script_name) do nothing
  returning true into inserted;

  if coalesce(inserted, false) then
    return true;
  end if;

  select applications.checksum
  into existing_checksum
  from public.data_script_applications as applications
  where applications.script_name = normalized_script_name;

  if existing_checksum = normalized_checksum then
    return false;
  end if;

  raise exception using
    errcode = '23514',
    constraint = 'data_script_applications_script_checksum_immutable',
    message = format(
      'data script %s was already registered with a different checksum',
      normalized_script_name
    );
end
$function$;

comment on function public.register_data_script_application(text, text) is
  'Registers a data script once, returns false for the same SHA-256, and rejects a changed file with the same name.';

revoke all on function public.register_data_script_application(text, text)
  from public, anon, authenticated;
grant execute on function public.register_data_script_application(text, text)
  to service_role;

commit;
