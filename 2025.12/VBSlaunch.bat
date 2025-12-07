@echo off
:: =============================================
:: 恢复 Windows 虚拟化功能、Hyper-V、VBS 相关配置
:: 作用：逆转之前的禁用操作，恢复虚拟化、安全功能
:: =============================================

echo.
echo 正在恢复 Windows 虚拟化与安全功能，请耐心等待...
echo.

:: -------------------------------
:: 1. 重新启用所有被禁用的 Hyper-V 相关功能
:: -------------------------------

dism /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V-All /NoRestart
dism /Online /Enable-Feature /All /FeatureName:IsolatedUserMode /NoRestart
dism /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V-Hypervisor /NoRestart
dism /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V-Online /NoRestart
dism /Online /Enable-Feature /All /FeatureName:HypervisorPlatform /NoRestart

echo.
echo [?] 已重新启用 Hyper-V 及相关虚拟化功能（需重启生效）。
echo.

:: -------------------------------
:: 2. 恢复 Hyper-V Hypervisor 启动类型为 Auto（启用）
:: -------------------------------

bcdedit /set hypervisorlaunchtype Auto

echo.
echo [?] 已恢复 HypervisorLaunchType 为 Auto（启用 Hyper-V 虚拟机监控程序）。
echo.

:: -------------------------------
:: 3. 清理之前可能添加的引导项（自定义 DebugTool / SecConfig 引导）
::    我们尝试查找并删除之前创建的 {0cb3b571-...} 引导项
:: -------------------------------

for /f "tokens=2 delims={}" %%i in ('bcdedit /enum ^| findstr /i "{0cb3b571-2f2e-4343-a879-d86a476d7215}"') do (
    set "customGuid={%%i}"
)

if defined customGuid (
    echo.
    echo [!] 发现之前创建的自定义引导项：%customGuid%
    echo [+] 正在删除该自定义引导项...
    bcdedit /delete %customGuid% /cleanup
    echo [?] 已删除自定义引导项。
) else (
    echo.
    echo [i] 未检测到之前创建的自定义引导项（可能已被删除或不存在）。
)

echo.
echo [+] 检查并清理异常的 bootsequence 设置...
bcdedit /deletevalue {bootmgr} bootsequence 2>nul

echo.
echo [?] 已尝试清除可能存在的异常 bootsequence 引导顺序设置。
echo.

:: -------------------------------
:: 4. （可选）提示用户手动检查 VBS 是否恢复
::    如果之前替换过 SecConfig.efi，可能需要手动还原该文件
:: -------------------------------

echo.
echo [i] 注意：关于 VBS（基于虚拟化的安全）和 LSA 保护功能：
echo.
echo       - 我们已通过 bcdedit 恢复 hypervisorlaunchtype 为 Auto，
echo         这有助于 VBS 在支持的情况下正常加载。
echo.
echo       - 如果你之前手动替换过 EFI 分区中的 SecConfig.efi 文件，
echo         可能需要手动还原该文件（或通过系统还原/重置恢复），
echo         否则 VBS 可能仍然处于禁用状态。
echo.
echo       - VBS 的完整恢复可能需要：
echo           * 确保 BIOS/UEFI 中启用了 VT-x/AMD-V 和 Secure Boot
echo           * 确保没有其他引导配置禁用 VBS
echo           * 某些情况下需通过组策略或注册表开启
echo.
echo       - 你可以前往“Windows 安全中心”->“设备安全性”->“核心隔离”
echo         查看 VBS 是否已启用。
echo.
echo [?] 其他核心 Windows 虚拟化功能已恢复，重启后生效。
echo.

:: -------------------------------
:: 5. 提示用户重启计算机
:: -------------------------------

echo.
echo =========================================================
echo.
echo             ? 恢复操作已完成，大部分设置需重启生效！
echo.
echo             请保存您的工作，然后重启计算机以完全恢复功能。
echo.
echo =========================================================
echo.

pause