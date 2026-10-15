# One-time setup: points YASB and GlazeWM at this repo and enables the git hooks.
# Close YASB and GlazeWM first. Existing config folders are backed up, not deleted.
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

$running = Get-Process -Name yasb, glazewm -ErrorAction SilentlyContinue
if ($running) {
    throw "Close YASB and GlazeWM first, then run setup.ps1 again."
}

# Replaces $link with a junction to $target (no admin needed).
function Link-Folder([string]$link, [string]$target) {
    New-Item -ItemType Directory -Force -Path (Split-Path $link -Parent) | Out-Null
    if (Test-Path $link) {
        $item = Get-Item $link -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            if ("$($item.Target)" -eq $target) { Write-Host "  $link already linked"; return }
            cmd /c rmdir "$link" | Out-Null  # removes the junction only
        } else {
            $backup = "$link.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
            Rename-Item $link $backup
            Write-Host "  Backed up $link -> $backup"
        }
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "  $link -> $target"
}

Link-Folder (Join-Path $env:USERPROFILE '.config\yasb') (Join-Path $repo 'yasb')
Link-Folder (Join-Path $env:USERPROFILE '.glzr\glazewm') (Join-Path $repo 'glazewm')

git -C $repo config core.hooksPath .githooks
Write-Host "Git hooks enabled."

$created = $false
foreach ($app in 'yasb', 'glazewm') {
    $machine = Join-Path $repo "$app\machine.yaml"
    if (-not (Test-Path $machine)) {
        Copy-Item (Join-Path $repo "$app\machine.example.yaml") $machine
        Write-Host "Created $app\machine.yaml from the example."
        $created = $true
    }
}

if ($created) {
    Write-Host "Tweak the new machine.yaml file(s), run .\build.ps1, then start YASB and GlazeWM."
} else {
    & (Join-Path $repo 'build.ps1')
    Write-Host "Done. Start YASB and GlazeWM."
}
