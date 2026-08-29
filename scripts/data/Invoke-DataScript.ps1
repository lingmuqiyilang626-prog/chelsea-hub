[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $PayloadPath,

  [ValidateSet('local', 'linked')]
  [string] $Target = 'local',

  [string] $PsqlPath = 'psql',

  [string] $LocalContainer = ''
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$resolvedPayload = (Resolve-Path -LiteralPath $PayloadPath).Path
$relativePayload = [System.IO.Path]::GetRelativePath(
  $repositoryRoot,
  $resolvedPayload
).Replace('\', '/')

if ($relativePayload.StartsWith('../', [System.StringComparison]::Ordinal) -or
  [System.IO.Path]::IsPathRooted($relativePayload)) {
  throw 'Payload must be inside the repository.'
}

$checksum = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedPayload).Hash.ToLowerInvariant()
$sqlScriptName = $relativePayload.Replace("'", "''")
$payload = [System.IO.File]::ReadAllText(
  $resolvedPayload,
  [System.Text.UTF8Encoding]::new($false, $true)
)

$wrapper = @"
\set ON_ERROR_STOP on
\set VERBOSITY verbose
select public.register_data_script_application(
  '$sqlScriptName',
  '$checksum'
) as should_apply
\gset

\if :should_apply
$payload
\echo Applied data script $relativePayload.
\else
\echo Data script $relativePayload is already applied; payload skipped.
\endif
"@

$psqlArguments = @(
  '-X',
  '--single-transaction',
  '-v',
  'ON_ERROR_STOP=1'
)

$securePassword = $null
$passwordPointer = [IntPtr]::Zero
$runnerSetPassword = $false
$exitCode = 0

try {
  if ($Target -eq 'local') {
    if ([string]::IsNullOrWhiteSpace($LocalContainer)) {
      $projectDirectoryName = Split-Path -Leaf $repositoryRoot
      $LocalContainer = "supabase_db_$projectDirectoryName"
    }

    $wrapper | docker exec -i $LocalContainer psql @psqlArguments -U postgres -d postgres
  }
  else {
    foreach ($requiredVariable in @('PGHOST', 'PGUSER', 'PGDATABASE')) {
      if ([string]::IsNullOrWhiteSpace(
        [Environment]::GetEnvironmentVariable($requiredVariable, 'Process')
      )) {
        throw "$requiredVariable must be set in the process environment for linked execution."
      }
    }

    if ([string]::IsNullOrEmpty(
      [Environment]::GetEnvironmentVariable('PGPASSWORD', 'Process')
    )) {
      $securePassword = Read-Host 'Database password' -AsSecureString
      $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $securePassword
      )
      $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
        $passwordPointer
      )
      [Environment]::SetEnvironmentVariable('PGPASSWORD', $plainPassword, 'Process')
      $plainPassword = $null
      $runnerSetPassword = $true
    }

    $wrapper | & $PsqlPath @psqlArguments
  }

  $exitCode = $LASTEXITCODE
}
finally {
  if ($runnerSetPassword) {
    [Environment]::SetEnvironmentVariable('PGPASSWORD', $null, 'Process')
  }

  if ($passwordPointer -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    $passwordPointer = [IntPtr]::Zero
  }

  if ($null -ne $securePassword) {
    $securePassword.Dispose()
    $securePassword = $null
  }
}

exit $exitCode
