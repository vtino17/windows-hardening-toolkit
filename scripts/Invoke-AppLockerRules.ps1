param(
    [ValidateSet("Default", "Strict")]
    [string]$Policy = "Default",
    [switch]$WhatIf
)

$rules = @()

function Add-DefaultRules {
    $rules += New-AppLockerPolicy -RuleType Exe -User Everyone -Action Allow -Path "%PROGRAMFILES%\*"
    $rules += New-AppLockerPolicy -RuleType Exe -User Everyone -Action Allow -Path "%WINDIR%\*"
    $rules += New-AppLockerPolicy -RuleType Exe -User Everyone -Action Allow -Path "%PROGRAMFILES(X86)%\*"
    $rules += New-AppLockerPolicy -RuleType WindowsInstaller -User Everyone -Action Allow -Path "%WINDIR%\Installer\*"
    $rules += New-AppLockerPolicy -RuleType Script -User Everyone -Action Allow -Path "%WINDIR%\*"
}

function Add-StrictRules {
    Add-DefaultRules
    $rules += New-AppLockerPolicy -RuleType Exe -User Everyone -Action Allow -Publisher "CN=*,O=MICROSOFT*"
    $rules += New-AppLockerPolicy -RuleType Exe -User Everyone -Action Deny -Path "%TEMP%\*"
    $rules += New-AppLockerPolicy -RuleType Exe -User Everyone -Action Deny -Path "%APPDATA%\*"
    $rules += New-AppLockerPolicy -RuleType Script -User Everyone -Action Deny -Path "%TEMP%\*"
}

if ($Policy -eq "Default") { Add-DefaultRules } else { Add-StrictRules }

$policy = New-AppLockerPolicy -Rule $rules -User Everyone -RuleType Exe
if ($WhatIf) {
    Write-Host "Preview: $($rules.Count) rules would be applied"
    $policy | Format-List
} else {
    Set-AppLockerPolicy -Policy $policy -Merge
    Write-Host "AppLocker policy applied: $($rules.Count) rules"
}
