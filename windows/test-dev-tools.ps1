#requires -Version 7.0
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'dev-tools.ps1')
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $testRoot | Out-Null
$oldPath=$env:PATH
$oldGitConfig=$env:GIT_CONFIG_GLOBAL
$oldChildFile=$env:DOTFILES_TEST_CHILD_FILE
function Assert-Equal($actual,$expected,$label) {
    if($actual -ne $expected){throw "$label expected=$expected actual=$actual"}
    Write-Output "PASS $label"
}
try {
    $env:PATH="$testRoot;$oldPath"
    Set-Content (Join-Path $testRoot 'fixture-ok.cmd') "@echo off`r`necho fixture 1.2.3`r`nexit /b 0" -Encoding ascii
    Set-Content (Join-Path $testRoot 'fixture-fail.cmd') "@echo off`r`necho looks-valid 1.0`r`nexit /b 7" -Encoding ascii
    Set-Content (Join-Path $testRoot 'fixture-empty.cmd') "@echo off`r`nexit /b 0" -Encoding ascii
    Set-Content (Join-Path $testRoot 'fixture-wait.ps1') 'Start-Sleep -Seconds 30; Write-Output late' -Encoding utf8
    Assert-Equal (Invoke-DevProbe 'fixture-ok --version').Status ok 'cmd wrapper success'
    $failed=Invoke-DevProbe 'fixture-fail --version'
    Assert-Equal $failed.Status failed 'nonzero with version text'
    Assert-Equal $failed.ExitCode 7 'native exit preserved'
    Assert-Equal $failed.Version '' 'failed stdout suppressed'
    Assert-Equal (Invoke-DevProbe 'fixture-empty --version').Status failed 'empty stdout not success'
    Assert-Equal (Invoke-DevProbe 'fixture-absent-6138 --version').Status missing 'absent command'
    Assert-Equal (Invoke-DevProbe 'fixture-wait.ps1 --version' 1).Status timed_out 'timeout'
    $env:DOTFILES_TEST_CHILD_FILE=Join-Path $testRoot 'child-pid.txt'
    Set-Content (Join-Path $testRoot 'fixture-child.ps1') '$child=Start-Process -FilePath (Join-Path $PSHOME "pwsh.exe") -ArgumentList "-NoProfile -Command Start-Sleep -Seconds 30" -WindowStyle Hidden -PassThru; Set-Content $env:DOTFILES_TEST_CHILD_FILE $child.Id; Write-Output "fixture 1.0"' -Encoding utf8
    Assert-Equal (Invoke-DevProbe 'fixture-child.ps1 --version').Status ok 'version with descendant'
    $childId=[int](Get-Content $env:DOTFILES_TEST_CHILD_FILE)
    Assert-Equal ([bool](Get-Process -Id $childId -ErrorAction SilentlyContinue)) $false 'descendant stopped after successful probe'
    $matrix=Join-Path $testRoot 'matrix.tsv'
    Set-Content $matrix "fixture`treq`tfixture`twinget:Fixture.Tool`tfixture-fail --version"
    $output=@(& (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File (Join-Path $PSScriptRoot 'dev-doctor.ps1') -MatrixPath $matrix -Json)
    Assert-Equal $LASTEXITCODE 1 'doctor required failure exit'
    Assert-Equal (($output -join "`n" | ConvertFrom-Json).RequiredFailures) 1 'doctor required failure count'
    Set-Content $matrix "fixture`trec`tfixture`twsl`tfixture-fail --version"
    $output=@(& (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File (Join-Path $PSScriptRoot 'dev-doctor.ps1') -MatrixPath $matrix -Json)
    Assert-Equal $LASTEXITCODE 0 'WSL excluded from native failures'
    Assert-Equal (($output -join "`n" | ConvertFrom-Json).Tools[0].Status) wsl_not_checked 'WSL remains unverified'
    Set-Content $matrix 'malformed'
    $rejected=$false
    try { Read-DevMatrix $matrix | Out-Null } catch { $rejected=$true }
    Assert-Equal $rejected $true 'invalid matrix rejected'
    Set-Content $matrix "fixture`treq`tfixture`twinget:Fixture.Tool`tfixture-ok --version"
    Add-Content $matrix "fixture`treq`tfixture`twinget:Fixture.Tool`tfixture-ok --version"
    $rejected=$false
    try { Read-DevMatrix $matrix | Out-Null } catch { $rejected=$true }
    Assert-Equal $rejected $true 'duplicate matrix rejected'
    # Fake manager and isolated Git config: no install or user config mutation.
    $env:GIT_CONFIG_GLOBAL=Join-Path $testRoot 'gitconfig'
    Set-Content (Join-Path $testRoot 'winget.cmd') "@echo off`r`nexit /b 9" -Encoding ascii
    Set-Content $matrix "fixture`treq`tfixture`twinget:Fixture.Tool`tfixture-absent-6138 --version"
    $setup=Join-Path $PSScriptRoot 'setup.ps1'
    $output=@(& (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File $setup -MatrixPath $matrix -Apply 2>&1)
    Assert-Equal $LASTEXITCODE 1 'installer failure exits nonzero'
    Assert-Equal (($output -join "`n") -match 'install failed \(exit 9\)') $true 'installer failure reported'
    Set-Content (Join-Path $testRoot 'winget.cmd') "@echo off`r`nexit /b 0" -Encoding ascii
    $output=@(& (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File $setup -MatrixPath $matrix -Apply 2>&1)
    Assert-Equal $LASTEXITCODE 1 'installer zero without executable is unverified'
    $output=@(& (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File $setup -MatrixPath $matrix 2>&1)
    Assert-Equal $LASTEXITCODE 0 'dry run exits zero'
    Assert-Equal (($output -join "`n") -match 'DRY-RUN: 1 install') $true 'dry run preserves plan'
} finally {
    $env:PATH=$oldPath
    $env:GIT_CONFIG_GLOBAL=$oldGitConfig
    $env:DOTFILES_TEST_CHILD_FILE=$oldChildFile
    $resolved=[IO.Path]::GetFullPath($testRoot)
    $tempBase=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if($resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf).StartsWith('dotfiles-test-')) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
