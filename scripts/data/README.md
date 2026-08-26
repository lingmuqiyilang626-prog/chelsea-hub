# Data script application ledger

Data payloads added from v0.5 onward should be paired with a separate `psql`
wrapper. The payload remains ordinary SQL. The wrapper stores the lowercase
SHA-256 digest of the payload's exact bytes, then includes the payload inside the
same transaction.

Keeping the digest outside the payload avoids a self-referential checksum. Do
not normalize line endings between hashing and execution.

Calculate the payload digest with one of these commands:

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath scripts/data/PAYLOAD.sql).Hash.ToLowerInvariant()
```

```sh
sha256sum scripts/data/PAYLOAD.sql
```

A wrapper should use this structure:

```sql
\set ON_ERROR_STOP on

begin;

do $application$
begin
  if not public.register_data_script_application(
    'scripts/data/PAYLOAD.sql',
    'LOWERCASE_SHA256_OF_PAYLOAD'
  ) then
    raise exception using
      errcode = 'P0002',
      message = 'data script was already applied with this checksum';
  end if;
end
$application$;

\ir PAYLOAD.sql

commit;
```

The first registration and the payload commit together. Any registration or
payload error rolls both back. A repeated name and checksum stops before the
payload, without changing `applied_at`; a repeated name with a different
checksum raises constraint `data_script_applications_script_checksum_immutable`.

The already released
`20260818_palmer_squad_number_history.sql` is not wrapped or baseline-registered
by this change. Its released bytes remain untouched, and ledger enforcement
starts with future data payloads.

For squad-number corrections, `superseded_at` may be set once from `NULL` to a
timestamp at or after `recorded_at`. After that first setting it is immutable:
clearing it or changing it to either an earlier or later timestamp is rejected.
An UPDATE that supplies the identical timestamp remains valid. Corrections must
supersede the old row and INSERT a new `change_type = 'correction'` row.
