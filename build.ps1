<#
.SYNOPSIS
    Builds yasb/config.yaml from the shared and per-machine pieces.

.DESCRIPTION
    YASB only reads a single config.yaml, so it's assembled from:

        yasb/base.yaml      shared    top-level settings
        yasb/machine.yaml   per-PC    bars + machine-only widgets (git-ignored)
        yasb/widgets.yaml   shared    widget definitions

    The output is written next to them in yasb/, which is where YASB reads
    from once setup.ps1 has run. YASB reloads by itself when it changes.

    The pieces are joined byte for byte so Nerd Font glyphs survive.

    Runs automatically after `git pull` (see .githooks/). Run it by hand after
    editing machine.yaml.
#>
$ErrorActionPreference = 'Stop'
$yasb = Join-Path $PSScriptRoot 'yasb'
$machine = Join-Path $yasb 'machine.yaml'

if (-not (Test-Path $machine)) {
    throw "yasb\machine.yaml not found. Copy yasb\machine.example.yaml to yasb\machine.yaml, tweak it for this PC, then run build.ps1 again."
}

$out = New-Object System.Collections.Generic.List[byte]
foreach ($name in 'base.yaml', 'machine.yaml', 'widgets.yaml') {
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $yasb $name))
    $out.AddRange($bytes)
    # Keep the last line of one piece from running into the next.
    if ($bytes.Length -gt 0 -and $bytes[-1] -ne 10) { $out.Add(10) }
}

$target = Join-Path $yasb 'config.yaml'
[System.IO.File]::WriteAllBytes($target, $out.ToArray())
Write-Host "Built $target"
