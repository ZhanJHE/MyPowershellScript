

<#
作者：ZhanJH
邮箱：magic_211_cs@126.com
Github：https://github.com/ZhanJHE
这个脚本最早是为了应付暨大的校园网，傻逼锐捷校园网网络认证客户端会把Windows HyperV虚拟机自带的的HyperV Adapter网卡识别成物理网卡，从而导致网络认证失败。
锐捷客户端做的就是一坨屎，希望有朝一日能更新下这个烂软件。（就算把客户端开源了扔GitHub上应该也会有闲的没事的大学生帮忙维护的吧？网上锐捷路由器破解教程一大堆） 
在我的GitHub上有与这个脚本对应的快速恢复HyperV功能的脚本，在
https://github.com/ZhanJHE/MyPowershellScript
中的HyperVlaunch.ps1
#>

# 切换当前控制台代码页为 UTF-8，防止中文字符乱码
chcp 65001 | Out-Null

#Requires -RunAsAdministrator

# 检查是否以管理员权限运行
# 创建一个代表当前用户的 WindowsPrincipal 对象
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
# 检查当前用户是否属于管理员角色
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 如果不是管理员，则输出错误信息并退出
    Write-Error "错误：请以管理员身份运行此脚本！"
    Write-Host "右键点击脚本文件，选择“以管理员身份运行”"
    Read-Host "按任意键退出"
    exit
}

# 打印脚本标题
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  Windows虚拟机功能启用脚本 (PowerShell)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# 询问用户是否确认执行操作
$choice = Read-Host "确定要启用WSL、Hyper-V等虚拟机功能吗？(y/N)"
# 如果用户输入不是 'y'，则取消操作并退出
if ($choice -ne 'y') {
    Write-Host "操作已取消。"
    Read-Host "按任意键退出"
    exit
}

Write-Host ""
Write-Host "开始启用虚拟机相关功能..." -ForegroundColor Yellow
Write-Host "==============================================="

# 定义需要启用的 Windows 功能列表
$features = @(
    "Microsoft-Hyper-V-All",         # 包含所有 Hyper-V 相关功能
    "VirtualMachinePlatform",        # 虚拟机平台
    "Microsoft-Windows-Subsystem-Linux" # 适用于 Linux 的 Windows 子系统 (WSL)
)

# 遍历功能列表并逐个启用
foreach ($feature in $features) {
    Write-Host "正在启用 $feature..."
    # 获取指定功能的当前状态
    $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature
    # 如果功能当前是禁用的
    if ($featureState.State -eq "Disabled") {
        try {
            # 尝试启用该功能，-All 表示启用所有父功能，-NoRestart 表示不自动重启，-ErrorAction Stop 表示遇到错误时停止执行
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction Stop
            Write-Host "  成功启用 $feature。" -ForegroundColor Green
        } catch {
            # 如果启用失败，则输出警告信息
            Write-Warning "  启用 $feature 失败。"
        }
    } else {
        # 如果功能已经是启用状态，则提示用户
        Write-Host "  $feature 已经启用或未安装。" -ForegroundColor Cyan
    }
}

# 启用 Hyper-V 相关的虚拟网络适配器
Write-Host "正在启用 Hyper-V 虚拟网络适配器..."
try {
    # 获取所有接口描述中包含 "Hyper-V" 且当前状态为 "Disabled" 的网络适配器（-IncludeHidden 包括隐藏的适配器）
    $hypervAdapters = Get-NetAdapter -IncludeHidden | Where-Object { $_.InterfaceDescription -like "*Hyper-V*" -and $_.Status -eq "Disabled" }
    # 如果找到了适配器
    if ($hypervAdapters) {
        # 启用所有找到的适配器，-Confirm:$false 表示不需要用户确认
        $hypervAdapters | Enable-NetAdapter -Confirm:$false
        Write-Host "  已启用以下 Hyper-V 网络适配器:" -ForegroundColor Green
        # 列出所有被启用的适配器名称
        $hypervAdapters.Name | ForEach-Object { Write-Host "    - $_" }
    } else {
        # 如果没有找到，则提示用户
        Write-Host "  未找到已禁用的 Hyper-V 虚拟网络适配器。" -ForegroundColor Cyan
    }
} catch {
    # 如果过程中出现错误，则输出警告
    Write-Warning "  检查或启用 Hyper-V 网络适配器时出错。"
}


# 使用 bcdedit 命令修改系统启动配置
Write-Host "正在修改 BCDEDIT 启动选项以启用 Hypervisor..."
# 定义需要修改的启动项和对应的值
$bcdSettings = @{
    "hypervisorlaunchtype" = "auto";    # 自动启动 Hypervisor
    "{current} vsmlaunchtype" = "auto"; # 自动启动基于虚拟化的安全 (VBS)
    "{current} vm" = "yes";             # 启用虚拟机
}

# 遍历并应用设置
foreach ($setting in $bcdSettings.GetEnumerator()) {
    Write-Host "  正在设置 $($setting.Name) = $($setting.Value)..."
    try {
        # 执行 bcdedit 命令
        bcdedit /set $($setting.Name) $($setting.Value)
        Write-Host "    设置成功。" -ForegroundColor Green
    } catch {
        # 如果设置失败，则输出警告
        Write-Warning "    设置 $($setting.Name) 失败。"
    }
}


Write-Host ""
Write-Host "==============================================="
Write-Host "虚拟机功能启用完成！" -ForegroundColor Green
Write-Host ""
# 显示当前的 BCDEDIT 配置，以便用户确认
Write-Host "当前 BCDEDIT 中与虚拟化相关的部分配置：" -ForegroundColor Yellow
bcdedit | findstr /i "hypervisorlaunchtype vsmlaunchtype vm"
Write-Host ""
Write-Host "注意：要使所有更改完全生效，您需要重启计算机。" -ForegroundColor Yellow
Write-Host ""

# 询问用户是否立即重启
$restartChoice = Read-Host "是否立即重启计算机？(y/N)"
if ($restartChoice -eq 'y') {
    Write-Host "计算机将在10秒后重启..."
    # 执行重启命令，/r 表示重启，/t 10 表示延迟10秒
    shutdown /r /t 10
} else {
    Write-Host "请手动重启计算机以使更改生效。"
}

# 等待用户按键后退出脚本
Read-Host "按任意键退出"