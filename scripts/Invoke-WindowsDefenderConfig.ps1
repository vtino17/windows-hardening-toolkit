Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -PUAProtection Enabled
Set-MpPreference -CloudBlockLevel High
Set-MpPreference -CloudTimeout 50
Set-MpPreference -SubmitSamplesConsent Always
Set-MpPreference -LowThreatDefaultAction Remove
Set-MpPreference -ModerateThreatDefaultAction Remove
Set-MpPreference -HighThreatDefaultAction Remove
Set-MpPreference -SevereThreatDefaultAction Remove
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableBlockAtFirstSeen $false
Set-MpPreference -DisableCatchupFullScan $false
Set-MpPreference -DisableCatchupQuickScan $false
Set-MpPreference -DisableCatchupSignatureUpdate $false
Set-MpPreference -SignatureUpdateInterval 4
Set-MpPreference -EnableControlledFolderAccess Enabled
$protectedFolders = @(
    "$env:USERPROFILE\Documents"
    "$env:USERPROFILE\Pictures"
    "$env:USERPROFILE\Desktop"
    "$env:USERPROFILE\Downloads"
)
Add-MpPreference -ControlledFolderAccessProtectedFolders $protectedFolders
Write-Host "Windows Defender hardened with cloud protection and controlled folder access"
