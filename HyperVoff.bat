@echo off
echo ===============================================
echo   Windows虚拟机功能禁用脚本
echo ===============================================
echo.

:: 检查是否以管理员权限运行
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 错误：请以管理员身份运行此脚本！
    echo 右键点击脚本文件，选择"以管理员身份运行"
    pause
    exit /b 1
)

echo 正在备份当前启动配置...
bcdedit /export "C:\BCD_Backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.bak" >nul
echo 启动配置已备份到：C:\BCD_Backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.bak
echo.

set /p choice="确定要禁用WSL、Hyper-V等虚拟机功能吗？(y/N): "
if /i "%choice%" neq "y" (
    echo 操作已取消。
    pause
    exit /b 0
)

echo.
echo 开始禁用虚拟机相关功能...
echo ===============================================

:: 1. 禁用Hyper-V
echo [1/8] 禁用Hyper-V...
bcdedit /set hypervisorlaunchtype off >nul
if %errorLevel% equ 0 (
    echo   已设置 hypervisorlaunchtype = off
) else (
    echo   错误：设置hypervisorlaunchtype失败
)

:: 2. 禁用Windows Hypervisor Platform
echo [2/8] 禁用Windows Hypervisor Platform...
bcdedit /set hypervisorschedulertype off >nul
if %errorLevel% equ 0 (
    echo   已设置 hypervisorschedulertype = off
) else (
    echo   警告：设置hypervisorschedulertype失败（可能不支持）
)

:: 3. 禁用虚拟机监控程序
echo [3/8] 禁用虚拟机监控程序...
bcdedit /set {current} isolationoptions nohypervisor >nul
if %errorLevel% equ 0 (
    echo   已设置 isolationoptions = nohypervisor
) else (
    echo   警告：设置isolationoptions失败（可能不支持）
)

:: 4. 禁用虚拟化安全功能
echo [4/8] 禁用虚拟化安全功能...
bcdedit /set {current} launchtype auto >nul
if %errorLevel% equ 0 (
    echo   已设置 launchtype = auto
) else (
    echo   警告：设置launchtype失败
)

:: 5. 禁用Credential Guard（依赖虚拟化的安全功能）
echo [5/8] 禁用Credential Guard...
bcdedit /set {current} loadoptions DISABLE-LSA-ISO >nul
if %errorLevel% equ 0 (
    echo   已设置 loadoptions = DISABLE-LSA-ISO
) else (
    echo   警告：设置loadoptions失败（可能不支持）
)

:: 6. 禁用VBS（基于虚拟化的安全）
echo [6/8] 禁用基于虚拟化的安全(VBS)...
bcdedit /set {current} vsmlaunchtype off >nul
if %errorLevel% equ 0 (
    echo   已设置 vsmlaunchtype = off
) else (
    echo   警告：设置vsmlaunchtype失败（可能不支持）
)

:: 7. 禁用嵌套虚拟化
echo [7/8] 禁用嵌套虚拟化...
bcdedit /set {current} nx OptIn >nul
if %errorLevel% equ 0 (
    echo   已设置 nx = OptIn
) else (
    echo   警告：设置nx失败
)

:: 8. 禁用WSL2的虚拟机平台
echo [8/8] 禁用WSL2虚拟机平台...
bcdedit /set {current} vm no >nul
if %errorLevel% equ 0 (
    echo   已设置 vm = no
) else (
    echo   警告：设置vm失败（可能不支持）
)

echo.
echo ===============================================
echo 虚拟机功能禁用完成！
echo.
echo 当前启动配置状态：
bcdedit | findstr /i "hypervisor"
bcdedit | findstr /i "launchtype"
bcdedit | findstr /i "vm"

echo.
echo 注意：要使更改生效，您需要重启计算机。
echo.
echo 如果需要恢复设置，可以使用以下命令：
echo bcdedit /import "C:\BCD_Backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.bak"
echo 或者手动重新启用相关功能。
echo ===============================================

set /p restart="是否立即重启计算机？(y/N): "
if /i "%restart%" equ "y" (
    echo 计算机将在10秒后重启...
    shutdown /r /t 10
) else (
    echo 请手动重启计算机以使更改生效。
)

pause