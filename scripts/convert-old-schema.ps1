# Convert legacy 8-column catalog CSV (title, iswc, isrc, name, role,
# share_percent, ipi, society) into the new 9-column Kataloghub schema
# (work_id, title, writer_name, writer_ipi, role_code, share, agreement_type,
# iswc, isrc).
#
# Mapping:
#   work_id          generated per unique title (W-001, W-002, ...)
#   title            <- title (unchanged)
#   writer_name      <- name
#   writer_ipi       <- ipi (preserved as string; Excel scientific notation
#                          like 7.13E+08 is left as-is — fix in Excel before
#                          export, or post-process the CSV)
#   role_code        <- role
#   share            <- share_percent
#   agreement_type   <- "SE" if society is foreign (TONO/GEMA/SACEM/...),
#                       else "E" (default for STIM and blank)
#   iswc             <- iswc
#   isrc             <- isrc
#   society          dropped
#
# Usage:
#   pwsh scripts/convert-old-schema.ps1 -InputFile path\to\old.csv
#   pwsh scripts/convert-old-schema.ps1 -InputFile in.csv -OutputFile out.csv

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string] $InputFile,
  [string] $OutputFile
)

if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }

if (-not $OutputFile) {
  $dir  = [System.IO.Path]::GetDirectoryName((Resolve-Path $InputFile))
  $base = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
  $OutputFile = Join-Path $dir "$base-new-schema.csv"
}

$foreignSocieties = @(
  'TONO','GEMA','SACEM','PRS','BMI','ASCAP','SOCAN','ICE','MLC','SIAE',
  'BUMA','SUISA','ZAIKS','AKM','AUSTRO','SABAM','SACM','SADAIC','APRA','JASRAC'
)

$rows = Import-Csv -Path $InputFile -Encoding UTF8
if (-not $rows) { throw "Input CSV is empty or unreadable: $InputFile" }

$first = $rows[0]
$required = @('title','iswc','isrc','name','role','share_percent','ipi','society')
foreach ($col in $required) {
  if (-not $first.PSObject.Properties.Match($col).Count) {
    throw "Input CSV missing legacy column: $col"
  }
}

$workIdMap = @{}
$nextId = 1
$out = foreach ($r in $rows) {
  $title = $r.title
  if (-not $workIdMap.ContainsKey($title)) {
    $workIdMap[$title] = ('W-{0:D3}' -f $nextId)
    $nextId++
  }
  $soc = ($r.society + '').ToUpper().Trim()
  $agreement = if ($foreignSocieties -contains $soc) { 'SE' } else { 'E' }
  [PSCustomObject][ordered]@{
    work_id        = $workIdMap[$title]
    title          = $title
    writer_name    = $r.name
    writer_ipi     = $r.ipi
    role_code      = $r.role
    share          = $r.share_percent
    agreement_type = $agreement
    iswc           = $r.iswc
    isrc           = $r.isrc
  }
}

$out | Export-Csv -Path $OutputFile -Encoding UTF8 -NoTypeInformation -UseQuotes Never -ErrorAction SilentlyContinue
if (-not (Test-Path $OutputFile)) {
  # PowerShell 5.1 fallback: -UseQuotes / -ErrorAction may not exist
  $out | Export-Csv -Path $OutputFile -Encoding UTF8 -NoTypeInformation
}

Write-Output ("Converted {0} rows → {1}" -f $rows.Count, $OutputFile)
Write-Output ("Unique works: {0}" -f $workIdMap.Count)
