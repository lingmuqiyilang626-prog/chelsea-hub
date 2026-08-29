begin;

do $ledger_table_privileges$
declare
  privilege_name text;
begin
  foreach privilege_name in array array['SELECT', 'INSERT']
  loop
    if not has_table_privilege(
      'service_role',
      'public.data_script_applications',
      privilege_name
    ) then
      raise exception
        'Service role is missing expected % privilege on the data-script ledger.',
        privilege_name;
    end if;
  end loop;

  foreach privilege_name in array array[
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'REFERENCES',
    'TRIGGER',
    'MAINTAIN'
  ]
  loop
    if has_table_privilege(
      'service_role',
      'public.data_script_applications',
      privilege_name
    ) then
      raise exception
        'Service role retained unexpected % privilege on the data-script ledger.',
        privilege_name;
    end if;
  end loop;
end
$ledger_table_privileges$;

set local role service_role;

do $service_role_truncate_rejected$
declare
  caught_sqlstate text;
begin
  begin
    truncate table public.data_script_applications;
    raise exception 'Service role unexpectedly truncated the data-script ledger.';
  exception
    when insufficient_privilege then
      get stacked diagnostics caught_sqlstate = returned_sqlstate;

      if caught_sqlstate <> '42501' then
        raise exception
          'Expected SQLSTATE 42501 for rejected TRUNCATE, got %.',
          caught_sqlstate;
      end if;
  end;
end
$service_role_truncate_rejected$;

reset role;

do $client_table_privileges$
declare
  role_name text;
  privilege_name text;
begin
  foreach role_name in array array['anon', 'authenticated']
  loop
    foreach privilege_name in array array[
      'INSERT',
      'UPDATE',
      'DELETE',
      'TRUNCATE',
      'REFERENCES',
      'TRIGGER',
      'MAINTAIN'
    ]
    loop
      if has_table_privilege(
        role_name,
        'public.data_script_applications',
        privilege_name
      ) then
        raise exception
          '% retained unexpected % privilege on the data-script ledger.',
          role_name,
          privilege_name;
      end if;
    end loop;
  end loop;
end
$client_table_privileges$;

do $function_and_rls_unchanged$
begin
  if not has_function_privilege(
    'service_role',
    'public.register_data_script_application(text,text)',
    'EXECUTE'
  ) then
    raise exception 'Service role lost registration-function EXECUTE privilege.';
  end if;

  if has_function_privilege(
    'anon',
    'public.register_data_script_application(text,text)',
    'EXECUTE'
  ) or has_function_privilege(
    'authenticated',
    'public.register_data_script_application(text,text)',
    'EXECUTE'
  ) then
    raise exception 'A client role unexpectedly has registration-function EXECUTE privilege.';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc as procedures
    cross join lateral pg_catalog.aclexplode(
      coalesce(
        procedures.proacl,
        pg_catalog.acldefault('f', procedures.proowner)
      )
    ) as privileges
    where procedures.oid =
      'public.register_data_script_application(text,text)'::regprocedure
      and privileges.grantee = 0
      and privileges.privilege_type = 'EXECUTE'
  ) then
    raise exception 'PUBLIC unexpectedly has registration-function EXECUTE privilege.';
  end if;

  if not (
    select relations.relrowsecurity
    from pg_catalog.pg_class as relations
    where relations.oid = 'public.data_script_applications'::regclass
  ) then
    raise exception 'RLS is not enabled on the data-script ledger.';
  end if;
end
$function_and_rls_unchanged$;

select
  '01_service_role_exact_table_privileges' as test_name,
  'PASS' as result,
  'Service role has SELECT and INSERT only on the data-script ledger.' as details
union all
select
  '02_service_role_truncate_rejected',
  'PASS',
  'Service role TRUNCATE is rejected with SQLSTATE 42501.'
union all
select
  '03_client_table_privileges_unchanged',
  'PASS',
  'Anon and authenticated retain no ledger write or table-management privileges.'
union all
select
  '04_function_and_rls_unchanged',
  'PASS',
  'Registration-function EXECUTE grants and ledger RLS remain unchanged.'
order by test_name;

rollback;
