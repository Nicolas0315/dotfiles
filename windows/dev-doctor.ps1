#requires -Version 7.0
<# Read-only tool execution audit. Does not access accounts, auth stores or secrets.
   Native Windows and WSL-only tools are separate; WSL is never started.
   Exit: 0=required/AI probes passed, 1=required/AI unavailable, 2=invalid matrix.
   Recommended failures remain visible and are not full-environment success. #>
[CmdletBinding()]
param(
    [string]$MatrixPath = (Join-Path $PSScriptRoot '..\tools\matrix.tsv'),
    [switch]$Json,
    [ValidateRange(1,120)][int]$TimeoutSeconds = 15
)
. (Join-Path $PSScriptRoot 'dev-tools.ps1')
try { $matrix = @(Read-DevMatrix $MatrixPath) }
catch { Write-Error 'Tool matrix missing or invalid'; exit 2 }
$results = @(foreach ($row in $matrix) {
    if ($row.Package -eq 'wsl') {
        $probe=[pscustomobject]@{Status='wsl_not_checked'; Version=''; ExitCode=$null; Path=$null}
    } else { $probe=Invoke-DevProbe $row.Check $TimeoutSeconds }
    [pscustomobject]@{Name=$row.Name; Group=$row.Group; Status=$probe.Status; Version=$probe.Version; ExitCode=$probe.ExitCode; Path=$probe.Path}
})
$requiredFailures=@($results | Where-Object { $_.Group -in @('req','ai') -and $_.Status -ne 'ok' }).Count
$recommendedFailures=@($results | Where-Object { $_.Group -eq 'rec' -and $_.Status -notin @('ok','wsl_not_checked') }).Count
$report=[pscustomobject]@{
    Schema='dotfiles.dev-doctor.v1'; MeasuredAt=(Get-Date).ToUniversalTime().ToString('o')
    Mode='read-only'; PowerShell=$PSVersionTable.PSVersion.ToString()
    MatrixSha256=(Get-FileHash -LiteralPath $MatrixPath -Algorithm SHA256).Hash
    RequiredFailures=$requiredFailures; RecommendedFailures=$recommendedFailures
    WslNotChecked=@($results | Where-Object Status -eq 'wsl_not_checked').Count
    Auth='not_checked'; Tools=$results
}
if ($Json) { $report | ConvertTo-Json -Depth 5 }
else {
    $results | Format-Table Name,Group,Status,Version -AutoSize
    Write-Output "Required/AI failures: $requiredFailures; recommended failures: $recommendedFailures; WSL unchecked: $($report.WslNotChecked); auth unchecked"
}
if ($requiredFailures -gt 0) { exit 1 }
exit 0
