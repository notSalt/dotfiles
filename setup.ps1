<#
.SYNOPSIS
    One-time setup: makes YASB and GlazeWM read their config from this repo.

.DESCRIPTION
    Replaces the default config folders with directory junctions that point
    into the repo, so a `git pull` updates the live config directly:

        %USERPROFILE%\.config\yasb     ->  <repo>\yasb
        %USERPROFILE%\.glzr\glazewm    ->  <repo>\glazewm

    Junctions don't need admin rights. An existing real folder is renamed to
    <name>.backup-<timestamp> first, so nothing is lost.

    It also tells git to use the hooks in .githooks/, which run build.ps1
    after every pull, and creates yasb\machine.yaml from the example if this
    machine doesn't have one yet.

    Close YASB and GlazeWM before running it (Windows won't rename a folder
    that has open files), then start them again afterwards.
#>
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

$running = Get-Process -Name yasb, glazewm -ErrorAction SilentlyContinue
if ($running) {
    throw "Close YASB and GlazeWM first (running: $(($running.Name | Sort-Object -Unique) -join ', ')), then run setup.ps1 again."
}

function Link-Folder([string]$link, [string]$target) {
    $parent = Split-Path $link -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    if (Test-Path $link) {
        $item = Get-Item $link -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            if ($item.Target -eq $target -or "$($item.Target)" -eq $target) {
                Write-Host "  $link already points to the repo"
                return
            }
            # rmdir removes only the junction itself, never what it points to.
            cmd /c rmdir "$link" | Out-Null
        } else {
            $backup = "$link.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
            Rename-Item $link $backup
            Write-Host "  Backed up $link -> $backup"
        }
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "  $link -> $target"
}

Write-Host "Linking config folders:"
Link-Folder (Join-Path $env:USERPROFILE '.config\yasb') (Join-Path $repo 'yasb')
Link-Folder (Join-Path $env:USERPROFILE '.glzr\glazewm') (Join-Path $repo 'glazewm')

git -C $repo config core.hooksPath .githooks
Write-Host "Git hooks enabled: config.yaml rebuilds after every pull."

$machine = Join-Path $repo 'yasb\machine.yaml'
if (-not (Test-Path $machine)) {
    Copy-Item (Join-Path $repo 'yasb\machine.example.yaml') $machine
    Write-Host ""
    Write-Host "Created yasb\machine.yaml from the example."
    Write-Host "Tweak it for this PC (screens, bar widgets, home label), then run .\build.ps1."
    Write-Host "Start YASB and GlazeWM once config.yaml is built."
    return
}

& (Join-Path $repo 'build.ps1')
Write-Host "Done. Start YASB and GlazeWM again."
