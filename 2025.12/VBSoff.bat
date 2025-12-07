@echo off

REM 使用DISM（部署映像服务和管理工具）在线禁用Windows功能。
REM /Online 表示对当前正在运行的操作系统进行操作。
REM /Disable-Feature 表示禁用一个特定的功能。
REM /NoRestart 表示执行操作后不自动重启计算机。

REM 禁用所有Hyper-V相关的功能。
dism /Online /Disable-Feature:microsoft-hyper-v-all /NoRestart

REM 禁用独立用户模式（Isolated User Mode），这是VBS（基于虚拟化的安全）的一部分。
dism /Online /Disable-Feature:IsolatedUserMode /NoRestart

REM 明确禁用Hyper-V虚拟机监控程序。
dism /Online /Disable-Feature:Microsoft-Hyper-V-Hypervisor /NoRestart

REM 禁用Hyper-V服务。
dism /Online /Disable-Feature:Microsoft-Hyper-V-Online /NoRestart

REM 禁用虚拟机平台。
dism /Online /Disable-Feature:HypervisorPlatform /NoRestart

REM ===========================================

REM 将EFI系统分区（ESP）挂载到驱动器 X:。
REM ESP分区包含了启动加载器等启动所需的文件。
REM /s 参数表示将系统分区挂载到指定的驱动器号。
mountvol X: /s

REM 将一个安全启动配置文件从系统目录复制到EFI分区的Microsoft启动目录下。
REM 这可能是为了创建一个带有特定安全设置的启动项。
copy %WINDIR%\System32\SecConfig.efi X:\EFI\Microsoft\Boot\SecConfig.efi /Y

REM 使用bcdedit（启动配置数据编辑器）创建一个新的启动加载器项。
REM {0cb3b571-2f2e-4343-a879-d86a476d7215} 是这个新启动项的唯一标识符（GUID）。
REM /d "DebugTool" 为这个启动项设置一个描述，显示在启动菜单中。
REM /application osloader 指定这是一个操作系统加载器类型的启动项。
bcdedit /create {0cb3b571-2f2e-4343-a879-d86a476d7215} /d "DebugTool" /application osloader

REM 设置新创建的启动项的路径，指向我们刚刚复制的efi文件。
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} path "\EFI\Microsoft\Boot\SecConfig.efi"

REM 将新的启动项设置为下一次启动时默认选择的项（仅一次）。
bcdedit /set {bootmgr} bootsequence {0cb3b571-2f2e-4343-a879-d86a476d7215}

REM 为新的启动项设置加载选项，以禁用特定的安全功能。
REM DISABLE-LSA-ISO 禁用了LSA（本地安全机构）保护。
REM DISABLE-VBS 禁用了基于虚拟化的安全（VBS）。
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} loadoptions DISABLE-LSA-ISO,DISABLE-VBS

REM 指定新的启动项所在的设备分区为我们之前挂载的 X: 驱动器。
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} device partition=X:

REM 操作完成后，卸载EFI系统分区。
mountvol X: /d

REM 将Hypervisor的启动类型设置为关闭。这是禁用Hyper-V的另一种方式。
bcdedit /set hypervisorlaunchtype off

echo.
echo.
echo.
echo.
echo =======================================================
echo 当前操作已完成，接下来请关闭此窗口并重启电脑，然后根据屏幕提示完成剩下操作。

REM 暂停脚本执行，等待用户按键，但将输出重定向到nul以隐藏"请按任意键继续..."的提示。
pause > nul
echo.
echo.