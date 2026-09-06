# Shared read-only matrix parsing and bounded version probes (PowerShell 7+).
function Read-DevMatrix {
    param([string]$Path)
    $seen = @{}
    $rows = @(foreach ($line in Get-Content -LiteralPath $Path -ErrorAction Stop) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        $f = $line -split "`t"
        if ($f.Count -ne 5 -or $f[1] -notin @('req','ai','rec') -or
            $f[0] -notmatch '^[a-zA-Z0-9_-]+$' -or $seen.ContainsKey($f[0]) -or
            $f[3] -notmatch '^(wsl|(?:winget|scoop|npm):[a-zA-Z0-9@_./-]+)$' -or
            $f[4] -notmatch '^[a-zA-Z0-9_.-]+(?: +[a-zA-Z0-9_.-]+)*$') {
            throw 'Invalid or duplicate tool matrix row'
        }
        $seen[$f[0]] = $true
        [pscustomobject]@{Name=$f[0]; Group=$f[1]; Package=$f[3]; Check=$f[4]}
    })
    if ($rows.Count -eq 0) { throw 'Empty tool matrix' }
    $rows
}

function Invoke-DevProbe {
    param([string]$Check, [int]$TimeoutSeconds = 15)
    $parts = $Check -split ' +'
    $command = Get-Command $parts[0] -CommandType Application,ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) {
        return [pscustomobject]@{Status='missing'; Version=''; ExitCode=$null; Path=$null}
    }
    # A fresh shell handles .cmd/.ps1 wrappers without PATHEXT ambiguity.
    $tokens = $parts | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }
    $payload = '$ErrorActionPreference="Stop"; $ProgressPreference="SilentlyContinue"; $PSNativeCommandUseErrorActionPreference=$false; [Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); try { $global:LASTEXITCODE=0; $output=@(& COMMAND 2>$null); $ok=$?; $code=$LASTEXITCODE; if(-not $ok -and $code -eq 0){$code=1}; $version=if($code -eq 0){($output | Select-Object -First 1 | Out-String).Trim()}else{""}; @{ExitCode=$code; Version=$version} | ConvertTo-Json -Compress } catch { @{ExitCode=1; Version=""} | ConvertTo-Json -Compress }'
    $payload = $payload.Replace('COMMAND', ($tokens -join ' '))
    # Keep the owning shell alive until the caller terminates its entire tree.
    $payload += '; [Console]::In.ReadLine() | Out-Null'
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $PSHOME 'pwsh.exe'
    $start.Arguments = '-NoLogo -NoProfile -NonInteractive -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
    $start.UseShellExecute=$false
    $start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true
    $start.RedirectStandardOutput=$true
    $start.RedirectStandardError=$true
    $start.StandardOutputEncoding=[Text.Encoding]::UTF8
    $process=[Diagnostics.Process]::new()
    $process.StartInfo=$start
    $result=[pscustomobject]@{Status='failed'; Version=''; ExitCode=$null; Path=$command.Source}
    try {
        [void]$process.Start()
        $stdout=$process.StandardOutput.ReadLineAsync()
        $stderr=$process.StandardError.ReadToEndAsync()
        if (-not $stdout.Wait($TimeoutSeconds * 1000)) {
            $result.Status='timed_out'
        } else {
            $data=$stdout.GetAwaiter().GetResult() | ConvertFrom-Json -ErrorAction Stop
            $result.ExitCode=$data.ExitCode
            if ($data.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($data.Version)) {
                $result.Status='ok'
                $result.Version=$data.Version
            }
        }
    } catch { $result.Status='failed' } finally {
        # The child shell waits on stdin after reporting JSON, preserving ancestry
        # even when the version command leaves descendants with open pipe handles.
        try {
            if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        } catch { $result.Status='failed'; $result.Version='' }
        $process.Dispose()
    }
    $result
}
