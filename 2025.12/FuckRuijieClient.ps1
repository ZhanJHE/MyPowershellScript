#Requires -RunAsAdministrator



# --- 脚本介绍 ---
# 这个脚本实现跳过锐捷客户端的 8021x.exe 进程对多个网卡的检测
# 原理：
# 通过临时关闭并重命名 8021x.exe 文件，使其无法被主程序找到和执行，从而达到跳过检测的目的。
# 不管用可以尝试更改使用不同的延迟时间。

# 补充说明：
# bat脚本总会莫名其妙把一些中文注释当做命令执行，导致脚本执行时出现错误，最后我只能用powershell脚本写了，其实不写中文注释的话bat更方便
# 傻逼锐捷客户端会把Windows WSL或者HyperV的网卡当做桥接的物理机
# 还有，锐捷校园网就是一坨屎

# 使用方法：
# 1.将这个 .ps1 脚本文件放到锐捷客户端的文件夹
# 2.打开管理员权限的Powershell终端
# 3.在终端中运行脚本
# 4.如果脚本没生效，可以尝试更改使用不同的延迟时间
# 作者仓库：https://github.com/ZhanJHE/MyPowershellScript
# 注意！！！
# 这个脚本的目的是为了解决锐捷客户端和本地虚拟机网卡冲突的问题，仅供交流研究，切勿用于违法途径
# 脚本实现思路来源于网络，并非原创。特此声明

# --- 使用说明 ---
Write-Host "请将这个 .ps1 脚本文件放到锐捷客户端的文件夹下，" -ForegroundColor Yellow
Write-Host "即与 'RuijieSupplicant.exe' 放在同一目录下。" -ForegroundColor Yellow
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
# 必须检测到 RuijieSupplicant.exe，必须检测到 "8021.exe" 和 "8021x.exe" 任意一个
if (-not (Test-Path -Path $ruijieApp)) {
    Write-Warning "错误：找不到 '$ruijieApp'。"
    Write-Warning "请确保此脚本与锐捷客户端程序放在同一目录下。"
    Read-Host "按任意键退出"
    exit
}

if (-not (Test-Path -Path $authComponent) -and -not (Test-Path -Path $tempAuthComponent)) {
    Write-Warning "错误：找不到 '$authComponent' 或 '$tempAuthComponent' 中的任意一个。"
    Write-Warning "请确保此脚本与锐捷客户端程序放在同一目录下。"
    Read-Host "按任意键退出"
    exit
}

# 1. 将 8021.exe 强制重命名为 8021x.exe
#    为了配合锐捷客户端主程序（RuijieSupplicant.exe）找到并执行这个文件。
Write-Host "步骤 1: 正在强制重命名 '$authComponent'..."
try {
    Rename-Item -Path $authComponent -NewName $tempAuthComponent -Force -ErrorAction Stop
    Write-Host "  重命名成功。" -ForegroundColor Green
} catch {
    Write-Warning "  重命名 '$authComponent' 失败。首次运行脚本时，命名失败是正常现象"
}

# 循环执行步骤2到6，最多5次，或直到网络连通
$loopCount = 0
$maxLoops = 5
$networkConnected = $false

while ($loopCount -lt $maxLoops -and -not $networkConnected) {
    $loopCount++
    Write-Host "`n循环次数: $loopCount / $maxLoops" -ForegroundColor Cyan
    
    # 2. 启动锐捷客户端的主程序
    Write-Host "步骤 2: 正在启动 '$ruijieApp'..."
    Start-Process -FilePath $ruijieApp

    # 3. 等待 (4 + $loopCount) 秒
    #    这个延迟是为了给主程序一些时间来启动和运行，每次循环增加1秒。
    $delay = 4 + $loopCount
    Write-Host "步骤 3: 等待 $delay 秒..."
    Start-Sleep -Seconds $delay

    # 4. 强制终止名为 8021x.exe 的进程
    #    把进程挂掉不让它检测
    Write-Host "步骤 4: 正在尝试强制终止 '8021x.exe' 进程 ..."
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

    # 检查网络是否连通
    Write-Host "正在检查网络连通性..."
    $networkConnected = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
    if ($networkConnected) {
        Write-Host "网络已连通！" -ForegroundColor Green
    } else {
        Write-Host "网络未连通，继续下一次循环..." -ForegroundColor Red
    }
    
    # 每次循环结束后等待1秒
    Start-Sleep -Seconds 1
}

if ($networkConnected) {
    Write-Host "`n网络已成功连通。" -ForegroundColor Green
} else {
    Write-Host "`n已达到最大循环次数，但网络仍未连通。" -ForegroundColor Red
}

Write-Host ""
Write-Host "操作完成。" -ForegroundColor Green
Read-Host "按任意键退出..."