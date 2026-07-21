param(
  [Parameter(Mandatory=$true)][string]$BackupFile,
  [Parameter(Mandatory=$true)][string]$ConfirmDatabaseName
)

$ErrorActionPreference = 'Stop'
if (-not $env:DATABASE_URL) { throw 'DATABASE_URL must be set.' }
$source = (Resolve-Path -LiteralPath $BackupFile).Path
$databaseUri = [Uri]$env:DATABASE_URL
$actualName = $databaseUri.AbsolutePath.Trim('/').Split('?')[0]
if ($ConfirmDatabaseName -ne $actualName) { throw "Confirmation does not match target database '$actualName'." }
Write-Warning "Restoring $source into database '$actualName'. Existing database objects may be overwritten."
& pg_restore --clean --if-exists --no-owner --no-acl --dbname=$env:DATABASE_URL $source
if ($LASTEXITCODE -ne 0) { throw "pg_restore failed with exit code $LASTEXITCODE" }
Write-Output "Restore completed for database: $actualName"
