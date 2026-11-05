<# : batch launcher (auto-elevates to Administrator, then runs the PowerShell below)
@echo off
powershell -nop -ExecutionPolicy Bypass "if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) { Start-Process -Verb RunAs 'cmd.exe' -ArgumentList '/c \"%~dpnx0\" %*' } else { Invoke-Expression ([System.IO.File]::ReadAllText('%~f0')) }"
goto :eof
#>

# =====================================================================
#  ClearMyDefenderHistory  (v2)
#  Clears Windows Defender "Protection history" entries (detections,
#  quarantine, Controlled Folder Access blocks).
#
#  Method: registers a scheduled task that runs ONCE as SYSTEM at the
#  next startup, deletes the Defender history folders before Defender
#  locks them, then removes itself. (A 2024 Defender change blocks
#  deletion while Windows is running, so one restart is required.)
#
#  Scope note: this ONLY clears what Windows Security shows under
#  "Protection history". It does NOT touch system event logs, disk
#  sectors, or OS activity artifacts, and it does not weaken Defender.
# =====================================================================

# ------------------------- OPTIONS -----------------------------------
$ClearAV         = $true    # detected viruses / malware history
$ClearQuarantine = $true    # quarantined items
$ClearCFA        = $true    # Controlled Folder Access block history
$RemoveTask      = $true    # remove the task after it runs once (keep $true)
$CancelInstead   = $false   # set $true to REMOVE a previously scheduled task and exit
# ---------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$TN = "ClearMyDefenderHistory"

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

Say ""
Say "=== ClearMyDefenderHistory ===" Cyan

# --- Re-confirm we are elevated (the launcher should have handled it) ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $isAdmin) { Say "Please run as Administrator." Red; Read-Host "Press Enter to exit"; exit 1 }

# --- Cancel mode: just remove the scheduled task and quit ---
if ($CancelInstead) {
    $existing = schtasks /query /tn $TN 2>$null
    if ($LASTEXITCODE -eq 0) {
        schtasks /delete /f /tn $TN | Out-Null
        Say "Scheduled task '$TN' removed. Nothing was cleared." Green
    } else {
        Say "No scheduled task named '$TN' was found. Nothing to cancel." Yellow
    }
    Read-Host "Press Enter to exit"; exit 0
}

# --- SAFETY CHECK: refuse to silently hide an ACTIVE threat ---
$active = @()
try { $active = @(Get-MpThreat | Where-Object { $_.IsActive }) } catch { }
if ($active.Count -gt 0) {
    Say ""
    Say "WARNING: Defender reports $($active.Count) ACTIVE threat(s) still present:" Red
    foreach ($t in $active) { Say ("  - " + $t.ThreatName) Red }
    Say ""
    Say "Clearing history now would hide a threat that is NOT yet resolved." Yellow
    Say "Recommended: run a full scan and remove the threat FIRST." Yellow
    $go = (Read-Host "Type EXACTLY 'clear anyway' to proceed, or anything else to abort")
    if ($go -ne 'clear anyway') { Say "Aborted. Nothing was changed." Green; Read-Host "Press Enter to exit"; exit 0 }
}

# --- Build the delete commands from the options ---
$Defender   = 'C:\ProgramData\Microsoft\Windows Defender'
$Quarantine = "$Defender\Quarantine"
$Service    = "$Defender\Scans\History\Service"
$db         = "$Defender\Scans\mpenginedb.db*"

$parts = @()
if ($ClearAV)         { $parts += "rd /s /q `"$Service`"";    Say "[will clear] Detection history" }
if ($ClearQuarantine) { $parts += "rd /s /q `"$Quarantine`""; Say "[will clear] Quarantined items" }
if ($ClearCFA)        { $parts += "del /f `"$db`"";           Say "[will clear] Controlled Folder Access history" }
if ($RemoveTask)      { $parts += "schtasks /delete /f /tn $TN" }

if ($parts.Count -eq 0 -or ($ClearAV -eq $false -and $ClearQuarantine -eq $false -and $ClearCFA -eq $false)) {
    Say "All clearing options are disabled. Nothing to do." Yellow; Read-Host "Press Enter to exit"; exit 0
}

$cmd = "/c " + ($parts -join " & ")

# --- Confirm before creating the task ---
Say ""
$ok = (Read-Host "Create a one-time startup task to clear the above? (y/n)").ToLower()
if ($ok -ne 'y') { Say "Aborted. Nothing was changed." Green; Read-Host "Press Enter to exit"; exit 0 }

# --- Register the scheduled task (run once, as SYSTEM, at startup) ---
try {
    $TA = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument $cmd
    $TT = New-ScheduledTaskTrigger -AtStartup
    $TP = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $TS = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -Force -TaskName $TN -Action $TA -Trigger $TT -Principal $TP -Settings $TS `
        -Description "Clear Windows Defender Protection History (one-time, at startup)" | Out-Null
} catch {
    Say "Failed to create the scheduled task: $($_.Exception.Message)" Red
    Read-Host "Press Enter to exit"; exit 1
}

# --- Verify it was actually created ---
schtasks /query /tn $TN >$null 2>&1
if ($LASTEXITCODE -ne 0) { Say "Task creation could not be verified." Red; Read-Host "Press Enter to exit"; exit 1 }

Say ""
Say "Success: a one-time task was created. History will be cleared on the next restart." Green
Say "To verify afterwards, run:  schtasks /query /tn $TN" DarkGray
Say "(It should report 'cannot find' after it runs, proving it ran once and removed itself.)" DarkGray
Say ""

$choice = (Read-Host "Restart now to clear the history? (y/n)").ToLower()
if ($choice -eq 'y') { Restart-Computer } else { Say "No restart. The history will be cleared on your next restart." Yellow; Read-Host "Press Enter to exit" }
