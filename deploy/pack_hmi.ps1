# ============================================================
# Car Entertainment System — 打包脚本
# 将 HMI 可执行文件 + Qt DLL + Agent 打包到 deploy/dist/
# ============================================================

param(
    [string]$BuildDir = "E:\car_hmi_project\hmi\build",
    [string]$QtBinDir = "E:\Qt\6.11.1\mingw_64\bin",
    [string]$AgentDir = "E:\car_hmi_project\agent",
    [string]$OutputDir = "$PSScriptRoot\dist"
)

$ErrorActionPreference = "Stop"

Write-Host "[pack] 输出目录: $OutputDir"

# 1. 创建输出目录结构
@(
    "$OutputDir\hmi",
    "$OutputDir\hmi\translations",
    "$OutputDir\hmi\platforms",
    "$OutputDir\agent",
    "$OutputDir\agent\proto"
) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

# 2. 复制 HMI 可执行文件
Write-Host "[pack] 复制 HMI..."
Copy-Item "$BuildDir\car_hmi.exe" "$OutputDir\hmi\" -Force

# 3. 复制 Qt DLL（使用 windeployqt 自动收集依赖）
Write-Host "[pack] 运行 windeployqt..."
$windeployqt = "$QtBinDir\windeployqt.exe"
& $windeployqt --release --no-compiler-runtime --no-system-d3d-compiler `
    "$OutputDir\hmi\car_hmi.exe" 2>&1 | Out-Null

# 4. 复制翻译文件
Write-Host "[pack] 复制翻译文件..."
Copy-Item "$BuildDir\..\translations\*.qm" "$OutputDir\hmi\translations\" -Force

# 5. 复制 Agent Python 代码
Write-Host "[pack] 复制 Agent..."
Copy-Item "$AgentDir\*.py" "$OutputDir\agent\" -Force
Copy-Item "$AgentDir\requirements.txt" "$OutputDir\agent\" -Force
Copy-Item "$AgentDir\.env" "$OutputDir\agent\" -Force -ErrorAction SilentlyContinue
Copy-Item "$AgentDir\proto\*.py" "$OutputDir\agent\proto\" -Force
Copy-Item "$AgentDir\..\llm_agent\*.py" "$OutputDir\agent\" -Force -ErrorAction SilentlyContinue

# 6. 复制启动脚本
Write-Host "[pack] 复制启动脚本..."
@"
@echo off
echo ========================================
echo Car Entertainment System - 启动
echo ========================================
echo.
echo [1/2] 启动 Agent Server...
start "Agent Server" cmd /c "cd /d %~dp0agent && python server.py"
echo.
echo [2/2] 启动 HMI...
start "" "%~dp0hmi\car_hmi.exe"
echo.
echo 系统已启动！
pause
"@ | Out-File -FilePath "$OutputDir\start.bat" -Encoding ASCII

@"
@echo off
echo 正在停止 Agent Server...
taskkill /f /im python.exe 2>nul
echo 正在关闭 HMI...
taskkill /f /im car_hmi.exe 2>nul
echo 已停止。
pause
"@ | Out-File -FilePath "$OutputDir\stop.bat" -Encoding ASCII

# 7. 统计打包结果
$hmiSize = (Get-ChildItem "$OutputDir\hmi" -Recurse | Measure-Object -Property Length -Sum).Sum
$agentSize = (Get-ChildItem "$OutputDir\agent" -Recurse | Measure-Object -Property Length -Sum).Sum
$fileCount = (Get-ChildItem "$OutputDir" -Recurse -File).Count

Write-Host "[pack] 打包完成!"
Write-Host "       文件数: $fileCount"
Write-Host "       HMI 大小: $([math]::Round($hmiSize / 1MB, 2)) MB"
Write-Host "       Agent 大小: $([math]::Round($agentSize / 1MB, 2)) MB"
Write-Host "       输出目录: $OutputDir"
Write-Host "       启动: $OutputDir\start.bat"
