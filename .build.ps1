<#
.SYNOPSIS
    Build, deploy, and optionally run AudioPitcher.
.DESCRIPTION
    Builds AudioPitcher in Release mode (default) and copies the compiled
    binaries to %LOCALAPPDATA%\xPrograms\audio-pitcher.
#>
[CmdletBinding()]
param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",

    [switch]$Clean,
    [switch]$Run
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$projectPath = Join-Path $repoRoot "AudioPitcher\AudioPitcher.csproj"
$deployDir = (Join-Path $env:LOCALAPPDATA "xPrograms\audio-pitcher")

if (-not (Get-Command "dotnet" -ErrorAction SilentlyContinue)) {
    Write-Error "The 'dotnet' CLI was not found in PATH."
    exit 1
}

if ($Clean) {
    Write-Host "Cleaning bin/obj..." -ForegroundColor Yellow
    foreach ($dir in "bin", "obj") {
        $p = Join-Path $repoRoot "AudioPitcher\$dir"
        if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "Building AudioPitcher ($Configuration)..." -ForegroundColor Cyan
& dotnet build $projectPath -c $Configuration --nologo
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

$outDir = Join-Path $repoRoot "AudioPitcher\bin\$Configuration\net8.0-windows"
if (-not (Test-Path (Join-Path $outDir "AudioPitcher.exe"))) {
    Write-Error "Build output not found in $outDir"
    exit 1
}

if ($Configuration -eq "Release") {
    Get-Process -Name "AudioPitcher" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 300

    New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
    Copy-Item -Path "$outDir\*" -Destination $deployDir -Recurse -Force
    Write-Host "Deployed Release binaries to $deployDir" -ForegroundColor Green
}

if ($Run) {
    $exeToRun = if ($Configuration -eq "Release") { Join-Path $deployDir "AudioPitcher.exe" } else { Join-Path $outDir "AudioPitcher.exe" }
    Start-Process -FilePath $exeToRun
}

