# Run as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Break
}

# Disable visual effects
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

# Optimize for performance
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

# Disable animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00))

# Disable transparency
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0

# Optimize for background services
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38

# Disable Windows Search indexing
Stop-Service "WSearch" -Force
Set-Service "WSearch" -StartupType Disabled

Write-Host "Performance optimizations applied successfully!" 