<#
.SYNOPSIS
    Deploys these dotfiles to this machine.

.DESCRIPTION
    YASB can only read a single config.yaml, so this script builds it from
    shared and per-machine pieces:

        yasb/base.yaml              shared    top-level settings
        yasb/bars.<machine>.yaml    per-PC    bar placement and screens
        yasb/widgets.yaml           shared    widget definitions
        yasb/widgets.<machine>.yaml per-PC    widgets that differ (e.g. home label)

    It also copies the shared styles.css and the GlazeWM files.
    yasb_colors.css is left alone: YASB regenerates it from each machine's
    Windows accent colour.

    Files are joined byte for byte so Nerd Font glyphs survive.

.PARAMETER Machine
    Which per-machine pieces to use ("laptop" or "pc"). Defaults to the
    DOTFILES_MACHINE environment variable. Set it once per machine with:
        setx DOTFILES_MACHINE laptop

.EXAMPLE
    git pull; .\sync.ps1
#>
param(
    [string]$Machine = $env:DOTFILES_MACHINE
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

if (-not $Machine) {
    throw "No machine name. Run 'setx DOTFILES_MACHINE laptop' (or pc), reopen the terminal, then try again."
}

$yasbSrc = Join-Path $repo 'yasb'
$yasbDst = if ($env:YASB_CONFIG_HOME) { $env:YASB_CONFIG_HOME } else { Join-Path $env:USERPROFILE '.config\yasb' }
$glazeSrc = Join-Path $repo 'glazewm'
$glazeDst = Join-Path $env:USERPROFILE '.glzr\glazewm'

$pieces = @(
    'base.yaml',
    "bars.$Machine.yaml",
    'widgets.yaml',
    "widgets.$Machine.yaml"
) | ForEach-Object { Join-Path $yasbSrc $_ }

foreach ($p in $pieces) {
    if (-not (Test-Path $p)) { throw "Missing $p (is '$Machine' the right machine name?)" }
}

New-Item -ItemType Directory -Force -Path $yasbDst, $glazeDst | Out-Null

# Join the pieces as raw bytes, making sure each one ends with a newline so
# the last line of one file never runs into the first line of the next.
$out = New-Object System.Collections.Generic.List[byte]
foreach ($p in $pieces) {
    $bytes = [System.IO.File]::ReadAllBytes($p)
    $out.AddRange($bytes)
    if ($bytes.Length -gt 0 -and $bytes[-1] -ne 10) { $out.Add(10) }
}
[System.IO.File]::WriteAllBytes((Join-Path $yasbDst 'config.yaml'), $out.ToArray())

Copy-Item (Join-Path $yasbSrc 'styles.css') $yasbDst -Force
Copy-Item (Join-Path $glazeSrc 'config.yaml'), (Join-Path $glazeSrc 'glazewm-ws.ahk') $glazeDst -Force

Write-Host "Synced for '$Machine':"
Write-Host "  YASB    -> $yasbDst (reloads by itself)"
Write-Host "  GlazeWM -> $glazeDst (press alt+shift+r to reload)"
