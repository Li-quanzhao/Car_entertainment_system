# ============================================================
# 安装 Agent Server 为 Windows 服务（使用 NSSM）
# ============================================================
# 前置条件：
#   1. 下载 NSSM: https://nssm.cc/download
#      解压到 C:\tools\nssm\nssm.exe
#   2. 以管理员身份运行此脚本
# ============================================================

param(
    [string]$NssmPath = "C:\tools\nssm\nssm.exe",
    [string]$ProjectDir = "E:\car_hmi_project",
    [string]$ServiceName = "CarAgentServer",
    [string]$PythonExe = "python",
    [string]$DisplayName = "Car Entertainment Agent Server",
    [string]$Description = "车载娱乐系统 AI Agent 后端服务，提供对话、工具执行等功能。"
)

$ErrorActionPreference = "Stop"

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)
if (-not $isAdmin) {
    Write-Warning "需要管理员权限！请以管理员身份运行 PowerShell。"
    exit 1
}

# 检查 NSSM
if (-not (Test-Path $NssmPath)) {
    Write-Warning "NSSM 未找到: $NssmPath"
    Write-Host "请从 https://nssm.cc/download 下载并解压到 C:\tools\nssm\"
    exit 1
}

# 检查 Agent 目录
$AgentMain = "$ProjectDir\agent\server.py"
if (-not (Test-Path $AgentMain)) {
    Write-Warning "Agent Server 未找到: $AgentMain"
    exit 1
}

# 停止已存在的服务
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[service] 停止已有服务..."
    & $NssmPath stop $ServiceName 2>&1 | Out-Null
    Start-Sleep 1
    & $NssmPath remove $ServiceName confirm 2>&1 | Out-Null
    Start-Sleep 1
}

# 安装服务
Write-Host "[service] 安装服务 '$ServiceName'..."
$agentDir = "$ProjectDir\agent"
$appParams = "-u", "server.py"

& $NssmPath install $ServiceName $PythonExe $appParams 2>&1 | Out-Null

# 配置服务
& $NssmPath set $ServiceName DisplayName $DisplayName
& $NssmPath set $ServiceName Description $Description
& $NssmPath set $ServiceName AppDirectory $agentDir
& $NssmPath set $ServiceName AppStdout "$ProjectDir\logs\agent_stdout.log"
& $NssmPath set $ServiceName AppStderr "$ProjectDir\logs\agent_stderr.log"
& $NssmPath set $ServiceName AppRotateFiles 1
& $NssmPath set $ServiceName AppRotateBytes 10485760  # 10 MB
& $NssmPath set $ServiceName Start SERVICE_AUTO_START
& $NssmPath set $ServiceName ObjectName LocalSystem

# 创建日志目录
New-Item -ItemType Directory -Force -Path "$ProjectDir\logs" | Out-Null

# 启动服务
Write-Host "[service] 启动服务..."
& $NssmPath start $ServiceName 2>&1 | Out-Null
Start-Sleep 2

# 验证
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "[service] ✅ 服务安装成功！"
    Write-Host "        名称: $ServiceName"
    Write-Host "        状态: $($svc.Status)"
    Write-Host "        日志: $ProjectDir\logs\"
    Write-Host ""
    Write-Host "   管理命令:"
    Write-Host "      停止:  $NssmPath stop $ServiceName"
    Write-Host "      启动:  $NssmPath start $ServiceName"
    Write-Host "      重启:  $NssmPath restart $ServiceName"
    Write-Host "      卸载:  $NssmPath remove $ServiceName confirm"
} else {
    Write-Warning "[service] ❌ 服务启动失败，检查日志: $ProjectDir\logs\"
}
