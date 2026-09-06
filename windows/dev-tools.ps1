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
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $PSHOME 'pwsh.exe'
    $start.Arguments = '-NoLogo -NoProfile -NonInteractive -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
    $start.UseShellExecute=$false
    $start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true
    $start.RedirectStandardError=$true
    $start.StandardOutputEncoding=[Text.Encoding]::UTF8
    $process=[Diagnostics.Process]::new()
    $process.StartInfo=$start
    $result=[pscustomobject]@{Status='failed'; Version=''; ExitCode=$null; Path=$command.Source}
    $watch=[Diagnostics.Stopwatch]::StartNew()
    try {
        [void]$process.Start()
        $stdout=$process.StandardOutput.ReadToEndAsync()
        $stderr=$process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true)
            $process.WaitForExit()
            $result.Status='timed_out'
        } else {
            $remaining=[Math]::Max(1, $TimeoutSeconds * 1000 - [int]$watch.ElapsedMilliseconds)
            if (-not $stdout.Wait($remaining)) {
                # A descendant can keep the inherited pipe open after its shell exits.
                $result.Status='timed_out'
                return $result
            }
            $data=$stdout.GetAwaiter().GetResult() | ConvertFrom-Json -ErrorAction Stop
            $result.ExitCode=$data.ExitCode
            if ($process.ExitCode -eq 0 -and $data.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($data.Version)) {
                $result.Status='ok'
                $result.Version=$data.Version
            }
        }
    } catch { $result.Status='failed' } finally { $process.Dispose() }
    $result
}
