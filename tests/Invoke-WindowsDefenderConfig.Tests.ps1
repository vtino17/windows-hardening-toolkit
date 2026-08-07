$ErrorActionPreference = "Stop"
$scriptPath = Join-Path $PSScriptRoot "..\scripts\Invoke-WindowsDefenderConfig.ps1"
$content = Get-Content -Raw -Path $scriptPath

$addCalls = ([regex]::Matches(
    $content,
    'Add-MpPreference\s+-ControlledFolderAccessProtectedFolders'
)).Count
$replacingCalls = ([regex]::Matches(
    $content,
    'Set-MpPreference\s+-ControlledFolderAccessProtectedFolders'
)).Count

if ($addCalls -ne 1) {
    throw "Expected exactly one additive protected-folder update; found $addCalls"
}
if ($replacingCalls -ne 0) {
    throw "Protected folders must not be replaced with Set-MpPreference"
}
foreach ($folder in @("Documents", "Pictures", "Desktop", "Downloads")) {
    if ($content -notmatch [regex]::Escape("USERPROFILE\$folder")) {
        throw "Missing protected folder: $folder"
    }
}
