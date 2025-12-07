#Requires -RunAsAdministrator



# --- 脚本核心逻辑 ---
# 这个脚本用来跳过锐捷客户端的 8021x.exe 进程对多个网卡的检测
# 通过临时关闭并重命名 8021x.exe 文件，使其无法被主程序找到和执行，从而达到跳过检测的目的。
# 不管用可以尝试更改延迟时间。
# 还有，锐捷校园网客户端就是一坨狗屎。
# bat脚本总会莫名其妙把一些中文注释当做命令执行，导致脚本执行时出现错误，最后我只能用powershell脚本写了，其实不写中文注释的话bat更方便
# 傻逼锐捷客户端总是喜欢把Windows WSL或者HyperV的网卡当做桥接的物理机

# --- 使用说明 ---
Write-Host "请将这个 .ps1 脚本文件放到锐捷客户端的文件夹下，" -ForegroundColor Yellow
Write-Host "即与 'RuijieSupplicant.exe' 和 '8021.exe' 放在同一目录。" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------"
Write-Host ""

# 切换当前目录到脚本所在目录
try {
    Set-Location -Path $PSScriptRoot -ErrorAction Stop
} catch {
    Write-Warning "无法切换到脚本所在目录。请确保从脚本所在目录运行。"
    Read-Host "按任意键退出"
    exit
}

# 定义文件名
$ruijieApp = "RuijieSupplicant.exe"
$authComponent = "8021.exe"
$tempAuthComponent = "8021x.exe"

# 检查所需文件是否存在
if (-not (Test-Path -Path $ruijieApp) -or -not (Test-Path -Path $authComponent)) {
    Write-Warning "错误：找不到 '$ruijieApp' 或 '$authComponent'。"
    Write-Warning "请确保此脚本与锐捷客户端程序放在同一目录下。"
    Read-Host "按任意键退出"
    exit
}

# 1. 将 8021.exe 强制重命名为 8021x.exe
#    这通常是为了配合锐捷客户端主程序（RuijieSupplicant.exe）找到并执行这个文件。
Write-Host "步骤 1: 正在强制重命名 '$authComponent'..."
try {
    Rename-Item -Path $authComponent -NewName $tempAuthComponent -Force -ErrorAction Stop
    Write-Host "  重命名成功。" -ForegroundColor Green
} catch {
    Write-Warning "  重命名 '$authComponent' 失败。可能是文件正在被使用、权限不足或已重命名。"
    Read-Host "按任意键退出"
    exit
}

# 2. 启动锐捷客户端的主程序
Write-Host "步骤 2: 正在启动 '$ruijieApp'..."
Start-Process -FilePath $ruijieApp

# 3. 等待4秒
#    这个延迟是为了给主程序一些时间来启动和运行。
Write-Host "步骤 3: 等待 4 秒..."
Start-Sleep -Seconds 4

# 4. 强制终止名为 8021x.exe 的进程
#    把进程挂掉不让它检测
Write-Host "步骤 4: 正在尝试强制终止 '8021x.exe' 进程 (如果存在)..."
$proc = Get-Process -Name "8021x" -ErrorAction SilentlyContinue
if ($proc) {
    $proc | Stop-Process -Force
    Write-Host "  已终止进程。" -ForegroundColor Green
} else {
    Write-Host "  未找到 '8021x.exe' 进程。" -ForegroundColor Cyan
}

# 5. 将 8021x.exe 强制重命名为 8021.exe，让主进程找不到它。
Write-Host "步骤 5: 正在将 '$tempAuthComponent' 强制恢复为 '$authComponent'..."
Rename-Item -Path $tempAuthComponent -NewName $authComponent -Force -ErrorAction SilentlyContinue

# 6. 等待1秒并再次尝试强制终止
#    这是一个备用措施，以防进程在第一次被终止后又重新启动。
Start-Sleep -Seconds 1
$proc_again = Get-Process -Name "8021x" -ErrorAction SilentlyContinue
if ($proc_again) {
    $proc_again | Stop-Process -Force
    Write-Host "  再次检测到并终止了 '8021x.exe' 进程。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "操作完成。" -ForegroundColor Green
Read-Host "按任意键退出..."