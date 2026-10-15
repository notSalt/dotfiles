# Builds yasb/config.yaml and glazewm/config.yaml from shared + per-machine pieces.
# Runs after every `git pull` (see .githooks); run it by hand after editing a machine.yaml.
$ErrorActionPreference = 'Stop'

# Joins files byte for byte (keeps Nerd Font glyphs intact).
function Join-Pieces([string]$dir, [string[]]$names) {
    $out = New-Object System.Collections.Generic.List[byte]
    foreach ($name in $names) {
        $path = Join-Path $dir $name
        if (-not (Test-Path $path)) { continue }
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $out.AddRange($bytes)
        if ($bytes.Length -gt 0 -and $bytes[-1] -ne 10) { $out.Add(10) }
    }
    $target = Join-Path $dir 'config.yaml'
    [System.IO.File]::WriteAllBytes($target, $out.ToArray())
    Write-Host "Built $target"
}

$yasb = Join-Path $PSScriptRoot 'yasb'
if (-not (Test-Path (Join-Path $yasb 'machine.yaml'))) {
    throw "Missing yasb\machine.yaml. Copy it from yasb\machine.example.yaml and tweak it first."
}
Join-Pieces $yasb 'base.yaml', 'machine.yaml', 'widgets.yaml'

# glazewm/machine.yaml is optional.
Join-Pieces (Join-Path $PSScriptRoot 'glazewm') 'base.yaml', 'machine.yaml'
