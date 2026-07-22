param(
    [string]$OutputPath = "./compliance-report.html"
)

function Check-SecuritySetting {
    param($Path, $Name, $Expected, $Description)
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        $actual = $value.$Name
        $pass = $actual -eq $Expected
        return [PSCustomObject]@{ Check = $Description; Expected = $Expected; Actual = $actual; Pass = $pass }
    } catch {
        return [PSCustomObject]@{ Check = $Description; Expected = $Expected; Actual = "NOT FOUND"; Pass = $false }
    }
}

$results = @()
$results += Check-SecuritySetting "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LMCompatibilityLevel" 5 "NTLMv2 required"
$results += Check-SecuritySetting "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "SMB1" 0 "SMBv1 disabled"
$results += Check-SecuritySetting "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1 "UAC enabled"
$results += Check-SecuritySetting "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RestrictAnonymous" 1 "Anonymous restriction"
$results += Check-SecuritySetting "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 2 "Admin consent prompt"

$mp = Get-MpPreference
$results += [PSCustomObject]@{ Check = "Real-time monitoring"; Expected = "True"; Actual = (-not $mp.DisableRealtimeMonitoring); Pass = (-not $mp.DisableRealtimeMonitoring) }
$results += [PSCustomObject]@{ Check = "Cloud protection"; Expected = "True"; Actual = (-not $mp.DisableCloudProtection); Pass = (-not $mp.DisableCloudProtection) }
$results += [PSCustomObject]@{ Check = "PUA protection"; Expected = "Enabled"; Actual = $mp.PUAProtection; Pass = ($mp.PUAProtection -eq 1) }

$passed = ($results | Where-Object Pass).Count
$failed = ($results | Where-Object { -not $_.Pass }).Count
$total = $results.Count
$score = [math]::Round(($passed / $total) * 100, 1)

$rows = ""
foreach ($r in $results) {
    $color = if ($r.Pass) { "green" } else { "red" }
    $status = if ($r.Pass) { "PASS" } else { "FAIL" }
    $rows += "<tr><td>$($r.Check)</td><td>$($r.Expected)</td><td>$($r.Actual)</td><td style='color:$color'>$status</td></tr>"
}

$html = @"
<!DOCTYPE html>
<html><head><title>Compliance Report</title>
<style>
body{font-family:Arial;margin:20px;background:#f5f5f5}
h1{color:#333}
.summary{background:#fff;padding:20px;border-radius:8px;margin-bottom:20px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
.score{font-size:48px;font-weight:bold;color:#333}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
th{background:#333;color:#fff;padding:12px;text-align:left}
td{padding:10px 12px;border-bottom:1px solid #eee}
</style></head><body>
<h1>Windows Security Compliance Report</h1>
<div class='summary'>
<div class='score'>$score%</div>
<p>$passed of $total checks passed</p>
</div>
<table><thead><tr><th>Check</th><th>Expected</th><th>Actual</th><th>Status</th></tr></thead>
<tbody>$rows</tbody></table>
</body></html>
"@

$html | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Report saved: $OutputPath"
Write-Host "Score: $score% ($passed/$total)"
