# Run from an extracted portable package. No settings or registry changes.
$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot 'chiaki.exe'
if (!(Test-Path -LiteralPath $exe)) { throw 'Place this script beside chiaki.exe.' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir = Join-Path $PSScriptRoot "diagnostics-$stamp"
New-Item -ItemType Directory -Path $logDir | Out-Null
$oldStderr = $env:QT_FORCE_STDERR_LOGGING
try {
    $env:QT_FORCE_STDERR_LOGGING = '1'
    $info = Join-Path $PSScriptRoot 'build-info.txt'
    if (Test-Path -LiteralPath $info) { Copy-Item -LiteralPath $info -Destination $logDir }
    Get-FileHash -LiteralPath $exe -Algorithm SHA256 | Format-List | Out-File (Join-Path $logDir 'executable.txt')
    $process = Start-Process -FilePath $exe -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -Wait `
        -RedirectStandardOutput (Join-Path $logDir 'stdout.log') `
        -RedirectStandardError (Join-Path $logDir 'stderr.log')
    "Exit code: $($process.ExitCode)" | Set-Content (Join-Path $logDir 'exit.txt')
    Write-Host "Diagnostics saved to $logDir"
} finally {
    $env:QT_FORCE_STDERR_LOGGING = $oldStderr
}
