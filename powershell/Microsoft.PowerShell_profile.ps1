# Disable PowerShell update check
$env:POWERSHELL_UPDATECHECK = 'Off'

# Starship
Invoke-Expression (&starship init powershell)

# PSReadLine configuration for better command-line editing
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -BellStyle None

# Terminal Icons
Import-Module -Name Terminal-Icons

# Key handlers
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
