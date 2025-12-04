# 脚本名称: Launch-FuckRuijie.ps1
# 功能: 检测管理员权限，然后调用并执行位于锐捷客户端目录下的 FuckRuijieClient.ps1 脚本。


# 检查当前是否以管理员身份运行
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "需要管理员权限来执行目标脚本，请重新启动此脚本以获取管理员权限。" -ForegroundColor Yellow
    exit
}

# --- 2. 定义并检查目标脚本路径 ---
# 如果代码执行到这里，说明已经拥有管理员权限。
Write-Host "启动器已获得管理员权限。" -ForegroundColor Green

# 目标脚本的完整路径
$targetScriptPath = "C:\Program Files\Ruijie Networks\Ruijie Supplicant\FuckRuijieClient.ps1"

Write-Host "准备执行目标脚本: $targetScriptPath"

# 检查目标脚本文件是否存在
if (Test-Path -Path $targetScriptPath -PathType Leaf) {
    Write-Host "成功找到目标脚本，正在执行..." -ForegroundColor Green
    Write-Host "---------------------------------------------------"

    # --- 3. 跳转并执行目标脚本 ---
    try {
        # 使用调用操作符 (&) 执行目标脚本
        & $targetScriptPath
    } catch {
        # 如果执行过程中发生错误，则显示错误信息
        Write-Error "执行目标脚本时发生严重错误:"
        Write-Error $_.Exception.Message
    }

    Write-Host "---------------------------------------------------"
    Write-Host "目标脚本执行流程结束。"

} else {
    # 如果找不到目标脚本
    Write-Warning "错误：在指定路径下未找到目标脚本！"
    Write-Warning "请确认 'FuckRuijieClient.ps1' 文件确实存在于以下路径:"
    Write-Warning "$targetScriptPath"
}

# Write-Host ""
# Read-Host "启动器 (Launch-FuckRuijie.ps1) 执行完毕，按任意键退出。"