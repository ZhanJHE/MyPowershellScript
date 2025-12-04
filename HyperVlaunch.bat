@echo off
echo ===============================================
echo   Windows虚拟机功能恢复脚本
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

echo 正在恢复虚拟机相关功能...
echo ===============================================

:: 1. 启用Hyper-V
echo [1/8] 启用Hyper-V...
bcdedit /set hypervisorlaunchtype auto >nul
if %errorLevel% equ 0 (
    echo   已设置 hypervisorlaunchtype = auto
) else (
    echo   错误：设置hypervisorlaunchtype失败
)

:: 2. 启用Windows Hypervisor Platform
echo [2/8] 启用Windows Hypervisor Platform...
bcdedit /deletevalue hypervisorschedulertype >nul
if %errorLevel% equ 0 (
    echo   已恢复 hypervisorschedulertype 默认设置
) else (
    echo   警告：恢复hypervisorschedulertype失败
)

:: 3. 启用虚拟机监控程序
echo [3/8] 启用虚拟机监控程序...
bcdedit /deletevalue {current} isolationoptions >nul
if %errorLevel% equ 0 (
    echo   已删除 isolationoptions 限制
) else (
    echo   警告：删除isolationoptions失败
)

:: 4. 恢复虚拟化安全功能
echo [4/8] 恢复虚拟化安全功能...
bcdedit /deletevalue {current} launchtype >nul
if %errorLevel% equ 0 (
    echo   已恢复 launchtype 默认设置
) else (
    echo   警告：恢复launchtype失败
)

:: 5. 恢复Credential Guard设置
echo [5/8] 恢复Credential Guard设置...
bcdedit /deletevalue {current} loadoptions >nul
if %errorLevel% equ 0 (
    echo   已删除 loadoptions 限制
) else (
    echo   警告：删除loadoptions失败
)

:: 6. 恢复VBS设置
echo [6/8] 恢复基于虚拟化的安全(VBS)...
bcdedit /deletevalue {current} vsmlaunchtype >nul
if %errorLevel% equ 0 (
    echo   已恢复 vsmlaunchtype 默认设置
) else (
    echo   警告：恢复vsmlaunchtype失败
)

:: 7. 恢复嵌套虚拟化设置
echo [7/8] 恢复嵌套虚拟化设置...
bcdedit /set {current} nx OptOut >nul
if %errorLevel% equ 0 (
    echo   已设置 nx = OptOut
) else (
    echo   警告：设置nx失败
)

:: 8. 启用WSL2的虚拟机平台
echo [8/8] 启用WSL2虚拟机平台...
bcdedit /deletevalue {current} vm >nul
if %errorLevel% equ 0 (
    echo   已删除 vm 限制
) else (
    echo   警告：删除vm限制失败
)

echo.
echo ===============================================
echo 虚拟机功能恢复完成！
echo.
echo 当前启动配置状态：
bcdedit | findstr /i "hypervisor"
bcdedit | findstr /i "launchtype"
bcdedit | findstr /i "vm"

echo.
echo 注意：要使更改生效，您需要重启计算机。
echo ===============================================

set /p restart="是否立即重启计算机？(y/N): "
if /i "%restart%" equ "y" (
    echo 计算机将在10秒后重启...
    shutdown /r /t 10
) else (
    echo 请手动重启计算机以使更改生效。
)

pause