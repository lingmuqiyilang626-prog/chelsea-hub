# Data script application ledger

Data payloads added from v0.5 onward are applied with
`scripts/data/Invoke-DataScript.ps1`. The runner stores the lowercase SHA-256
digest of the payload's exact bytes. It invokes one `psql` process with `-X`,
`--single-transaction`, and `-v ON_ERROR_STOP=1`; ledger registration and the
conditionally included payload therefore use one database connection and one
explicit transaction.

The runner supports Windows PowerShell 5.1 and PowerShell 7. If script execution
is disabled in Windows PowerShell 5.1, enable it for the current process only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Do not change the machine-wide or current-user execution policy for this task.

Keeping the digest outside the payload avoids a self-referential checksum. Do
not normalize line endings between hashing and execution.

Calculate the payload digest with one of these commands:

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath scripts/data/PAYLOAD.sql).Hash.ToLowerInvariant()
```

```sh
sha256sum scripts/data/PAYLOAD.sql
```

Run a local payload from Windows PowerShell with:

```powershell
& scripts/data/Invoke-DataScript.ps1 `
  -PayloadPath scripts/data/PAYLOAD.sql `
  -Target local
```

Use `-Target linked` only in an explicitly authorised production operation.
Linked execution requires `PGHOST`, `PGUSER`, and `PGDATABASE` in process scope
and `psql` on PATH (or `-PsqlPath`). It does not accept a password or connection
string argument. If `PGPASSWORD` is absent, the runner uses
`Read-Host -AsSecureString`, sets it only in process scope, and clears it and the
SecureString conversion buffer in `finally`.

The runner calls `register_data_script_application()`, stores its result with
psql `\gset`, and uses `\if` to stream the payload only when the result is true.
The first registration and payload commit together; with
`ON_ERROR_STOP=1`, any payload error makes `psql` exit non-zero and
`--single-transaction` rolls back both. A repeated name and checksum skips the
payload with exit code zero and does not change `applied_at`. A repeated name
with a different checksum raises constraint
`data_script_applications_script_checksum_immutable`.

Payloads must not contain transaction-control statements such as `BEGIN`,
`START TRANSACTION`, `COMMIT`, or `ROLLBACK`. They neither need nor may manage a
transaction: the runner owns the transaction boundary. A `DO` block is allowed
for procedural checks and writes because its internal PL/pgSQL `BEGIN ... END`
is a block, not transaction control.

Do not normalize line endings between review and execution. The runner hashes
the exact payload bytes, decodes the reviewed file as strict UTF-8, never writes
a generated wrapper to disk, and returns a non-zero exit code for psql or SQL
failure.

The already released
`20260818_palmer_squad_number_history.sql` is not wrapped or baseline-registered
by this change. Its released bytes remain untouched, and ledger enforcement
starts with future data payloads.

For squad-number corrections, `superseded_at` may be set once from `NULL` to a
timestamp at or after `recorded_at`. After that first setting it is immutable:
clearing it or changing it to either an earlier or later timestamp is rejected.
An UPDATE that supplies the identical timestamp remains valid. Corrections must
supersede the old row and INSERT a new `change_type = 'correction'` row.

For the Palmer correction, the No.20 row remains unsuperseded but is not
currently effective because its `valid_to` is in the past. The original No.10
row is superseded. The new No.10 correction is both unsuperseded and currently
effective.

For history rows with a source, `recorded_at` must be at or after the source's
initial `created_at`. Source `created_at` is immutable after registration;
supplying the identical timestamp is allowed. `retrieved_at` may advance when a
source is checked again and is not used as the chronology boundary.
