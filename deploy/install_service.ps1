# ============================================================
# Install Agent Server as Windows Service (using NSSM)
# ============================================================
# Prerequisites:
#   1. NSSM downloaded to C:\tools\nssm\nssm.exe
#   2. Run this script as Administrator
# ============================================================

param(
    [string]$NssmPath = "C:\tools\nssm\nssm.exe",
    [string]$ProjectDir = "E:\car_hmi_project",
    [string]$ServiceName = "CarAgentServer",
    [string]$PythonExe = "E:\car_hmi_project\.venv\Scripts\python.exe",
    [string]$DisplayName = "Car Entertainment Agent Server",
    [string]$Description = "Car Entertainment AI Agent Backend Service"
)

$ErrorActionPreference = "Stop"

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)
if (-not $isAdmin) {
    Write-Warning "Administrator privileges required! Run PowerShell as Administrator."
    exit 1
}

# Check NSSM
if (-not (Test-Path $NssmPath)) {
    Write-Warning "NSSM not found: $NssmPath"
    Write-Host "Download from https://nssm.cc/download and extract to C:\tools\nssm\"
    exit 1
}

# Check Agent directory
$AgentMain = "$ProjectDir\agent\server.py"
if (-not (Test-Path $AgentMain)) {
    Write-Warning "Agent Server not found: $AgentMain"
    exit 1
}

# Stop existing service if any
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[service] Stopping existing service..."
    & $NssmPath stop $ServiceName 2>&1 | Out-Null
    Start-Sleep 1
    & $NssmPath remove $ServiceName confirm 2>&1 | Out-Null
    Start-Sleep 1
}

# Install service
Write-Host "[service] Installing service '$ServiceName'..."
$agentDir = "$ProjectDir\agent"
$appParams = "-u", "server.py"

& $NssmPath install $ServiceName $PythonExe $appParams 2>&1 | Out-Null

# Configure service
& $NssmPath set $ServiceName DisplayName $DisplayName
& $NssmPath set $ServiceName Description $Description
& $NssmPath set $ServiceName AppDirectory $agentDir
& $NssmPath set $ServiceName AppStdout "$ProjectDir\logs\agent_stdout.log"
& $NssmPath set $ServiceName AppStderr "$ProjectDir\logs\agent_stderr.log"
& $NssmPath set $ServiceName AppRotateFiles 1
& $NssmPath set $ServiceName AppRotateBytes 10485760  # 10 MB
& $NssmPath set $ServiceName Start SERVICE_AUTO_START
& $NssmPath set $ServiceName ObjectName LocalSystem

# Create log directory
New-Item -ItemType Directory -Force -Path "$ProjectDir\logs" | Out-Null

# Start service
Write-Host "[service] Starting service..."
& $NssmPath start $ServiceName 2>&1 | Out-Null
Start-Sleep 2

# Verify
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "[service] Service installed successfully!"
    Write-Host "        Name: $ServiceName"
    Write-Host "        Status: $($svc.Status)"
    Write-Host "        Logs: $ProjectDir\logs\"
    Write-Host ""
    Write-Host "   Management commands:"
    Write-Host "      Stop:    $NssmPath stop $ServiceName"
    Write-Host "      Start:   $NssmPath start $ServiceName"
    Write-Host "      Restart: $NssmPath restart $ServiceName"
    Write-Host "      Remove:  $NssmPath remove $ServiceName confirm"
} else {
    Write-Warning "[service] Service start failed, check logs: $ProjectDir\logs\"
}
