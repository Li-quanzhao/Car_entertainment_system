# ============================================================
# 卸载 Agent Server Windows 服务
# ============================================================

param(
    [string]$NssmPath = "C:\tools\nssm\nssm.exe",
    [string]$ServiceName = "CarAgentServer"
)

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)
if (-not $isAdmin) {
    Write-Warning "需要管理员权限！"
    exit 1
}

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $existing) {
    Write-Host "[service] 服务 '$ServiceName' 不存在。"
    exit 0
}

Write-Host "[service] 停止服务 '$ServiceName'..."
& $NssmPath stop $ServiceName 2>&1 | Out-Null
Start-Sleep 2

Write-Host "[service] 卸载服务..."
& $NssmPath remove $ServiceName confirm 2>&1 | Out-Null

Write-Host "[service] ✅ 服务已卸载: $ServiceName"
