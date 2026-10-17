begin;

alter table public.role_assignments
  drop constraint role_assignments_valid_dates_check;

alter table public.role_assignments
  add constraint role_assignments_valid_dates_check check (
    valid_from is null or valid_to is null or valid_to > valid_from
  );

comment on constraint role_assignments_valid_dates_check
  on public.role_assignments is
  'Allows an unknown start with a known exclusive end; when both dates are known the end must be later.';

create function public.enforce_role_assignment_supersession_immutability()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public
as $function$
begin
  if old.superseded_at is not null
    and new.superseded_at is distinct from old.superseded_at then
    raise exception using
      errcode = '23514',
      constraint = 'role_assignments_superseded_at_immutable',
      message = 'role assignment supersession is immutable once set';
  end if;

  return new;
end
$function$;

comment on function public.enforce_role_assignment_supersession_immutability() is
  'Makes an established role-assignment supersession timestamp immutable while allowing an unchanged value.';

revoke all on function public.enforce_role_assignment_supersession_immutability()
  from public, anon, authenticated, service_role;

create trigger role_assignments_superseded_at_immutable
before update of superseded_at on public.role_assignments
for each row
execute function public.enforce_role_assignment_supersession_immutability();

commit;
