# windows-hardening-toolkit

[![CI](https://img.shields.io/github/actions/workflow/status/vtino17/windows-hardening-toolkit/ci.yml?style=flat-square&label=CI)](https://github.com/vtino17/windows-hardening-toolkit/actions)
# Windows Hardening Toolkit

CIS-based Windows Server security automation with PowerShell scripts, Group Policy templates, and audit configurations.

Unlike one-liner guides, this repo provides **production-ready, tested scripts** that can be deployed domain-wide or locally on standalone servers.

## What's Inside

### PowerShell Modules

| Module | Description | Domain | Standalone |
|--------|-------------|--------|------------|
| `Invoke-SecurityBaseline` | Applies 120+ CIS-hardening registry settings | ✅ | ✅ |
| `Set-AuditPolicy` | Configures advanced audit policy (EventLog) | ✅ | ✅ |
| `Invoke-AppLockerRules` | Deploys AppLocker allow-list rules | ✅ | ✅ |
| `Disable-LegacyProtocols` | Disables SMBv1, LLMNR, NBT-NS, WPAD | ✅ | ✅ |
| `Set-LocalPolicies` | User rights assignment, security options | ✅ | ✅ |
| `Invoke-WindowsDefenderConfig` | Attack surface reduction + ASR rules | ✅ | ✅ |
| `Get-ComplianceReport` | HTML report of hardening status | ✅ | ✅ |
| `Invoke-BitLockerDeployment` | Deploy BitLocker with MBAM/GPO | ✅ | ❌ |

### Group Policy Objects

```
GPOs/
├── CIS-Level1-DomainController/
├── CIS-Level1-MemberServer/
├── CIS-Level2-DomainController/
├── Windows-Defender-ASR/
├── AppLocker-Strict/
├── Audit-Advanced/
└── PowerShell-Logging/
```

---

## Quick Start

### Standalone Server (no domain)

```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process
.\Invoke-SecurityBaseline.ps1 -Level 1 -Reboot
```

This applies 120+ registry-based security settings:

```powershell
# Sample of what gets applied
# - Disable LLMNR (defends against Responder attacks)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
    -Name "EnableMulticast" -Value 0 -PropertyType DWord

# - Disable SMBv1
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

# - Require NTLMv2, minimum 128-bit
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "LMCompatibilityLevel" -Value 5 -PropertyType DWord

# - Enable PowerShell logging
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -Name "EnableScriptBlockLogging" -Value 1 -PropertyType DWord

# - Disable WPAD (mitigates proxy hijacking)
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" `
    -Name "WpadOverride" -Value 0 -PropertyType DWord
```

### Domain Environment

```powershell
# Apply via GPO (recommended)
Copy-Item -Path .\GPOs\CIS-Level1-MemberServer\* -Destination "\\domain.local\SYSVOL\*\Policies"
gpupdate /force

# Remote via PowerShell
Invoke-Command -ComputerName SERVER01 -FilePath .\Invoke-SecurityBaseline.ps1 -ArgumentList 1,$true
```

---

## Audit Policy (EventLog)

Configures Windows Event Logging for SOC visibility — events that actually matter for detecting attacks:

```xml
<AuditPolicy>
  <!-- Account Logon -->
  <Event id="4624" level="INFO">Successful logon (track lateral movement)</Event>
  <Event id="4625" level="WARN">Failed logon (brute-force detection)</Event>
  <Event id="4768" level="CRITICAL">Kerberos TGT requested (golden ticket detect)</Event>
  <Event id="4769" level="WARN">Kerberos service ticket (kerberoasting detect)</Event>

  <!-- Object Access -->
  <Event id="4663" level="INFO">Object accessed (file/registry monitor)</Event>

  <!-- Process Creation (Sysmon interop) -->
  <Event id="4688" level="INFO">Process created (parent-child chain)</Event>
  <Event id="4689" level="INFO">Process exited</Event>

  <!-- Privilege Use -->
  <Event id="4672" level="WARN">Admin logon (privilege escalation detect)</Event>

  <!-- Account Management -->
  <Event id="4720" level="INFO">User account created</Event>
  <Event id="4732" level="INFO">Member added to security group</Event>
  <Event id="4742" level="INFO">Computer account changed</Event>

  <!-- Directory Service -->
  <Event id="5136" level="CRITICAL">AD object modified (DC sync attack)</Event>
  <Event id="4662" level="CRITICAL">Operation on AD object (DCSync attempt)</Event>
</AuditPolicy>
```

Apply with:

```powershell
.\Set-AuditPolicy.ps1 -Template advanced -Verbose
```

---

## Windows Defender ASR Rules

```powershell
# Universal ASR rules for all servers
$asrRules = @(
    @{GUID="b2b3f8c6-0d9c-4f5e-8fad-6f5a4f7b6c1a"; Rule="Block Office communication app from creating child processes"},
    @{GUID="d4f6d6b7-4c6d-4f4a-9b5a-2f5c7a3b6c1a"; Rule="Block credential stealing from Windows lsass"},
    @{GUID="e6b5b5a7-5c6d-4f5a-9b5a-3f5c7a3b6c1a"; Rule="Block executable content from email client and webmail"},
    @{GUID="f8c4c4d7-6c7d-4f6a-9b5a-4f5c7a3b6c1a"; Rule="Block Office applications from creating executable content"},
    @{GUID="a8c4c4d7-6c7d-4f6a-9b5a-4f5c7a3b6c1a"; Rule="Block all Office applications from creating child processes"},
    @{GUID="c8c4c4d7-6c7d-4f6a-9b5a-4f5c7a3b6c1a"; Rule="Block abuse of exploited vulnerable signed drivers"}
)
```

---

## Compliance Report

Generate an HTML report showing hardening status. Useful for audits and infosec reviews:

```powershell
.\Get-ComplianceReport.ps1 -OutputPath .\reports\server01.html
```

Sample output sections:
| Category | Pass | Fail | N/A | Score |
|----------|------|------|-----|-------|
| Account Policies | 8 | 1 | 0 | 89% |
| Security Options | 42 | 3 | 2 | 93% |
| Audit Policy | 14 | 0 | 0 | 100% |
| Windows Defender | 11 | 1 | 1 | 92% |
| **Total** | **75** | **5** | **3** | **94%** |

---

## File Structure

```
windows-hardening-toolkit/
├── README.md
├── LICENSE
├── scripts/
│   ├── Invoke-SecurityBaseline.ps1
│   ├── Set-AuditPolicy.ps1
│   ├── Invoke-AppLockerRules.ps1
│   ├── Disable-LegacyProtocols.ps1
│   ├── Set-LocalPolicies.ps1
│   ├── Invoke-WindowsDefenderConfig.ps1
│   ├── Get-ComplianceReport.ps1
│   └── Invoke-BitLockerDeployment.ps1
├── GPOs/
│   ├── CIS-Level1-DomainController/
│   ├── CIS-Level1-MemberServer/
│   └── AppLocker-Strict/
├── configs/
│   ├── asr-rules.json
│   ├── audit-policy.xml
│   └── user-rights.csv
└── reports/
```

---

## Prerequisites

- Windows Server 2019/2022 (or Windows 10/11 for workstations)
- PowerShell 5.1+
- Local Administrator rights (for standalone) or Domain Admin (for GPO deployment)
- For BitLocker: TPM 2.0 + Secure Boot

---

## Related

- [MikroTik Hardening](https://github.com/vtino17/mikrotik-hardening)
- [Wazuh Custom Decoders](https://github.com/vtino17/wazuh-custom-decoders)

---

**Author:** [vtino17](https://github.com/vtino17) — Network Engineer & System Administrator

