begin;

create function public.enforce_squad_number_history_source_chronology()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $function$
declare
  source_created_at timestamptz;
begin
  if new.source_id is null then
    return new;
  end if;

  select sources.created_at
  into source_created_at
  from public.sources as sources
  where sources.id = new.source_id;

  if source_created_at is not null
    and new.recorded_at < source_created_at then
    raise exception using
      errcode = '23514',
      constraint = 'squad_number_history_source_chronology',
      message = 'squad number history cannot be recorded before its source exists';
  end if;

  return new;
end
$function$;

comment on function public.enforce_squad_number_history_source_chronology() is
  'Rejects new or changed squad-number history whose recorded_at predates its source created_at.';

revoke all on function public.enforce_squad_number_history_source_chronology()
  from public, anon, authenticated;

create trigger squad_number_history_source_chronology
before insert or update of source_id, recorded_at
on public.squad_number_history
for each row
execute function public.enforce_squad_number_history_source_chronology();

create function public.enforce_source_created_at_immutability()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $function$
begin
  if new.created_at is distinct from old.created_at then
    raise exception using
      errcode = '23514',
      constraint = 'sources_created_at_immutable',
      message = 'source created_at is immutable after initial registration';
  end if;

  return new;
end
$function$;

comment on function public.enforce_source_created_at_immutability() is
  'Makes source created_at immutable while allowing an update that supplies the identical timestamp.';

revoke all on function public.enforce_source_created_at_immutability()
  from public, anon, authenticated;

create trigger sources_created_at_immutable
before update of created_at on public.sources
for each row
execute function public.enforce_source_created_at_immutability();

commit;
