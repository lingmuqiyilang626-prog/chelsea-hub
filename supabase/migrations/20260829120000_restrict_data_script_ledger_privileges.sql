begin;

revoke all privileges
on table public.data_script_applications
from service_role;

grant select, insert
on table public.data_script_applications
to service_role;

commit;
