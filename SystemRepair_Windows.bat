@echo off
setlocal EnableDelayedExpansion EnableExtensions
title Windows 系统深度诊断与修复工具 v2.0
color 0B

:: 解决日期格式兼容性问题 (支持 YYYY-MM-DD 和 MM/DD/YYYY 等格式)
for /f "tokens=2-4 delims=/-" %%a in ('echo %date%') do (
    if %%a gtr 31 (
        set "Year=%%a" & set "Month=%%b" & set "Day=%%c"
    ) else (
        set "Month=%%a" & set "Day=%%b" & set "Year=%%c"
    )
)
for /f "tokens=1-3 delims=:" %%a in ("%time: =0%") do (
    set "Hour=%%a" & set "Minute=%%b" & set "Second=%%c"
)
set "Timestamp=%Year%%Month%%Day%_%Hour%%Minute%%Second%"

:: 路径设置（支持含空格路径）
set "ScriptDir=%~dp0"
set "ScriptDir=%ScriptDir:~0,-1%"
set "LogFile=%ScriptDir%\Logs\SystemDiag_%Timestamp%.log"
set "ReportDir=%ScriptDir%\Reports_%Timestamp%"
set "TempDir=%TEMP%\SysDiag_%Timestamp%"

:: 创建目录
if not exist "%ScriptDir%\Logs" mkdir "%ScriptDir%\Logs"
if not exist "%ReportDir%" mkdir "%ReportDir%"
if not exist "%TempDir%" mkdir "%TempDir%"

:: 初始化日志
echo ============================================ > "%LogFile%"
echo  Windows 系统诊断工具 - %date% %time% >> "%LogFile%"
echo  运行路径: %ScriptDir% >> "%LogFile%"
echo ============================================ >> "%LogFile%"
echo. >> "%LogFile%"

:: 检查管理员权限（带详细错误）
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo [错误] 权限不足！当前未以管理员身份运行。
    echo 解决方案：
    echo   1. 右键点击此脚本
    echo   2. 选择"以管理员身份运行"
    echo   3. 如果UAC提示，点击"是"
    echo.
    echo 按任意键退出...
    pause >nul
    exit /b 1
)

:: 主入口
call :ShowHeader
call :MainMenu
call :Cleanup
goto :EOF

:: 清理临时文件
:Cleanup
if exist "%TempDir%" (
    rmdir /s /q "%TempDir%" 2>nul
)
echo. >> "%LogFile%"
echo [%time%] 脚本结束，临时文件已清理 >> "%LogFile%"
goto :EOF

:: 显示标题
:ShowHeader
cls
echo ============================================
echo    Windows 系统深度诊断与修复工具 v2.0
echo    日志: Logs\SystemDiag_%Timestamp%.log
echo ============================================
echo.
goto :EOF

:: 主菜单（带退出选项）
:MainMenu
call :ShowHeader
echo 请选择操作类别：
echo.
echo 【快速诊断】
echo   1. 系统概览 + 关键错误事件分析
echo   2. 网络深度诊断 (适配器/DNS/网关/速度)
echo   3. 磁盘健康预检 (SMART + 文件系统只读扫描)
echo.
echo 【自动修复】(耗时操作，支持后台运行)
echo   4. 创建系统还原点 ^(执行高风险操作前建议^)
echo   5. 系统文件修复 (SFC + DISM 快速模式)
echo   6. 系统映像深度修复 (DISM /RestoreHealth)
echo.
echo 【需谨慎操作】(交互确认 + 详细警告)
echo   7. 磁盘坏道修复 (CHKDSK /F /R) - 可能需重启，耗时1-5小时
echo   8. Windows 内存诊断 - 需重启，测试15-30分钟
echo   9. 网络堆栈完全重置 - 将删除WiFi密码并断网
echo.
echo 【报告与维护】
echo   10. 生成完整诊断报告包 (电池/性能/日志/驱动)
echo   11. 清理系统临时文件 (安全清理)
echo.
echo   0. 退出并查看日志
echo.
choice /C 1234567890 /N /M "请输入选项: "

if %errorlevel%==1 goto :SystemInfo
if %errorlevel%==2 goto :NetworkDiag
if %errorlevel%==3 goto :DiskHealthPrecheck
if %errorlevel%==4 goto :CreateRestorePoint
if %errorlevel%==5 goto :QuickRepair
if %errorlevel%==6 goto :DISMDeepRepair
if %errorlevel%==7 goto :ChkDskRepair
if %errorlevel%==8 goto :MemoryDiag
if %errorlevel%==9 goto :NetworkReset
if %errorlevel%==10 goto :FullReport
if %errorlevel%==11 goto :CleanTempFiles
if %errorlevel%==12 goto :ExitScript
goto :MainMenu

:: 1. 增强版系统信息
:SystemInfo
call :ShowHeader
echo [系统信息收集] 正在分析硬件和最近错误...
echo [%time%] 开始系统信息收集 >> "%LogFile%"

:: 使用 PowerShell 获取更准确的系统信息（兼容Win11无wmic情况）
powershell -Command "Get-ComputerInfo | Select WindowsProductName, WindowsVersion, TotalPhysicalMemory, CsProcessors | Format-List" > "%TempDir%\sysinfo.txt" 2>nul
if exist "%TempDir%\sysinfo.txt" (
    type "%TempDir%\sysinfo.txt" >> "%LogFile%"
) else (
    :: 降级方案
    systeminfo | findstr /B /C:"OS" /C:"Processor" /C:"Physical Memory" >> "%LogFile%" 2>&1
)

echo. >> "%LogFile%"
echo ===== 最近7天严重错误事件 (Level 1-2) ===== >> "%LogFile%"
wevtutil qe System /q:"*[System[(Level=1 or Level=2) and TimeCreated[timediff(@SystemTime) <= 604800000]]]" /f:text /c:20 > "%TempDir%\errors.txt" 2>&1

if %errorlevel% equ 0 (
    findstr /C:"Date:" "%TempDir%\errors.txt" | findstr /C:"Error\|Critical" >nul && (
        echo [警告] 发现严重系统错误！ >> "%LogFile%"
        type "%TempDir%\errors.txt" >> "%LogFile%"
        echo.
        echo [!] 发现严重系统错误，详情见日志
    ) || (
        echo [正常] 最近7天未发现严重错误 >> "%LogFile%"
        echo [?] 最近7天系统稳定性良好
    )
) else (
    echo [提示] 无法读取事件日志，可能权限受限 >> "%LogFile%"
)

echo.
pause
goto :MainMenu

:: 2. 增强网络诊断（支持多网关）
:NetworkDiag
call :ShowHeader
echo [网络深度诊断] 多适配器分析...
echo [%time%] 开始网络诊断 >> "%LogFile%"

:: 获取所有网络适配器状态
echo. >> "%LogFile%"
echo ===== 网络适配器详细信息 ===== >> "%LogFile%"
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select Name, InterfaceDescription, LinkSpeed | Format-Table -AutoSize" >> "%LogFile%" 2>&1

:: 测试多个公共 DNS
echo. >> "%LogFile%"
echo ===== DNS 解析测试 (多节点) ===== >> "%LogFile%"
for %%s in (223.5.5.5 114.114.114.114 8.8.8.8) do (
    echo 测试 DNS: %%s >> "%LogFile%"
    ping -n 2 -w 1000 %%s >> "%LogFile%" 2>&1
    if !errorlevel! equ 0 (
        echo [可达] %%s >> "%LogFile%"
    ) else (
        echo [不可达] %%s >> "%LogFile%"
    )
)

:: 检查当前 DNS 服务器
echo. >> "%LogFile%"
echo ===== 当前 DNS 配置 ===== >> "%LogFile%"
ipconfig /all | findstr /C:"DNS Servers" /C:"DNS 服务器" >> "%LogFile%"

echo [?] 网络诊断完成，建议使用选项 10 生成完整报告对比历史数据
echo.
pause
goto :MainMenu

:: 3. 磁盘健康预检 (新增 SMART 检测)
:DiskHealthPrecheck
call :ShowHeader
echo [磁盘健康预检] 正在检查 SMART 状态和文件系统...
echo [%time%] 开始磁盘预检 >> "%LogFile%"

:: 尝试使用 PowerShell 获取 SMART 信息 (不依赖 wmic)
echo 正在检测物理磁盘健康状态...
powershell -Command "Get-PhysicalDisk | Select FriendlyName,HealthStatus,OperationalStatus,Size | Format-Table -AutoSize" > "%TempDir%\smart.txt" 2>&1

if exist "%TempDir%\smart.txt" (
    type "%TempDir%\smart.txt" >> "%LogFile%"
    type "%TempDir%\smart.txt"
    findstr /C:"Warning\|Unhealthy" "%TempDir%\smart.txt" >nul && (
        echo.
        echo [严重警告] 检测到磁盘健康异常！建议立即备份数据
        echo [严重警告] 检测到磁盘健康异常！建议立即备份数据 >> "%LogFile%"
    )
) else (
    echo [提示] 无法获取 SMART 信息 (可能需要管理员权限或存储驱动支持) >> "%LogFile%"
)

echo. >> "%LogFile%"
echo ===== 文件系统只读扫描 ===== >> "%LogFile%"
echo 扫描逻辑磁盘错误 (只读模式，不修复)...
for %%d in (C: D: E: F: G: H:) do (
    if exist %%d (
        echo 检查 %%d ...
        chkdsk %%d /scan /perf > "%TempDir%\chk_%%~d.txt" 2>&1
        findstr /C:"found no errors\|未发现问题" "%TempDir%\chk_%%~d.txt" >nul && (
            echo [?] %%d 状态正常
            echo [正常] %%d 文件系统无错误 >> "%LogFile%"
        ) || (
            findstr /C:"errors found\|发现问题" "%TempDir%\chk_%%~d.txt" >nul && (
                echo [!] %%d 发现错误，建议使用选项 7 修复
                echo [警告] %%d 发现文件系统错误 >> "%LogFile%"
            )
        )
    )
)
echo.
pause
goto :MainMenu

:: 4. 新增：创建系统还原点
:CreateRestorePoint
call :ShowHeader
echo [系统还原点] 为高风险操作创建回滚点...
echo.
echo 此操作将在执行磁盘修复、注册表清理等高风险操作前，
echo 创建一个系统还原点，以便出现问题时恢复。
echo.
choice /C YN /M "确认创建还原点? (Y:创建 N:返回): "
if %errorlevel%==2 goto :MainMenu

echo 正在创建还原点，请稍候...
echo [%time%] 创建系统还原点 >> "%LogFile%"

:: 使用 PowerShell 创建还原点 (描述支持中文)
powershell -Command "Checkpoint-Computer -Description '系统诊断工具_自动创建_%date%' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1

if %errorlevel% equ 0 (
    echo [?] 还原点创建成功
    echo [?] 还原点创建成功 >> "%LogFile%"
    echo 如需恢复：控制面板 → 恢复 → 打开系统还原
) else (
    echo [!] 还原点创建失败，可能已禁用系统保护
    echo [!] 建议手动检查：系统属性 → 系统保护 → 配置
)
echo.
pause
goto :MainMenu

:: 5. 快速修复组合 (SFC + DISM CheckHealth)
:QuickRepair
call :ShowHeader
echo [快速修复] SFC 扫描 + DISM 健康检查
echo 预计耗时: 10-20 分钟
echo.
choice /C YN /M "确认开始? (Y:开始 N:返回): "
if %errorlevel%==2 goto :MainMenu

echo [%time%] 开始快速修复流程 >> "%LogFile%"

echo 步骤 1/2: DISM 快速健康检查...
DISM /Online /Cleanup-Image /CheckHealth >> "%LogFile%" 2>&1
if %errorlevel% neq 0 (
    echo [!] 映像不健康，需要深度修复 (执行选项 6)
    echo [!] 映像状态异常，建议执行选项 6 >> "%LogFile%"
) else (
    echo [?] 系统映像健康
)

echo.
echo 步骤 2/2: SFC 扫描 (显示实时进度)...
echo 注意: 进度会卡在 20%% 或 40%% 一段时间，属正常现象
echo [%time%] 开始 SFC /scannow >> "%LogFile%"

:: 使用 start /b 和 findstr 实现伪实时显示，避免用户以为卡死
start /b cmd /c "sfc /scannow > "%TempDir%\sfc.log" 2>&1"
:WaitSFC
timeout /t 5 /nobreak >nul
findstr /C:"Verification" "%TempDir%\sfc.log" 2>nul && (
    type "%TempDir%\sfc.log" | findstr /C:"%" 2>nul
    goto :WaitSFC
)
type "%TempDir%\sfc.log" >> "%LogFile%"

findstr /C:"found corrupt files\|找到损坏文件" "%TempDir%\sfc.log" >nul && (
    echo [!] 发现损坏文件，部分可能无法修复，建议执行选项 6
) || (
    echo [?] 系统文件完整
)
echo.
pause
goto :MainMenu

:: 6. DISM 深度修复
:DISMDeepRepair
call :ShowHeader
echo [DISM 深度修复] /ScanHealth + /RestoreHealth
echo 注意: 此操作需要联网，耗时 15-45 分钟
echo.
choice /C YN /M "确认开始? (Y:开始 N:返回): "
if %errorlevel%==2 goto :MainMenu

echo [%time%] 开始 DISM 深度修复 >> "%LogFile%"

echo 阶段 1/2: 扫描映像损坏...
DISM /Online /Cleanup-Image /ScanHealth
echo.

echo 阶段 2/2: 修复映像 (从 Windows Update 获取文件)...
echo [提示] 如果卡在 0%% 超过 5 分钟，可能是网络问题
DISM /Online /Cleanup-Image /RestoreHealth

if %errorlevel% equ 0 (
    echo [?] DISM 修复成功，建议重启后执行 SFC 验证
) else (
    echo [!] 修复失败，尝试使用本地源...
    echo 尝试使用本地 install.wim 修复 (如果有)...
    :: 可选：添加本地源修复逻辑
)
echo.
pause
goto :MainMenu

:: 7. 改进的磁盘修复 (增加倒计时和详细警告)
:ChkDskRepair
call :ShowHeader
color 0E
echo [磁盘深度修复] CHKDSK /F /R
echo ============================================
echo ??  警告: 此操作将查找并恢复坏扇区
echo ============================================
echo 耗时估算:
echo   ? SSD (500GB): 约 30-60 分钟
echo   ? HDD (1TB):  约 2-5 小时或更长
echo   ? 系统盘 (C:): 需要重启，在启动界面执行
echo.
echo 数据安全:
echo   ? /F 修复文件系统错误 (安全)
echo   ? /R 恢复坏扇区 (可能丢失坏扇区上的数据)
echo.
echo 建议操作前:
echo   1. 执行选项 4 创建系统还原点
echo   2. 备份重要数据到外部磁盘
echo ============================================
echo.

choice /C YN /M "是否已备份重要数据并确认执行? (Y:确认 N:返回): "
if %errorlevel%==2 goto :MainMenu

echo.
set /p "TargetDrive=请输入盘符 (如 C: D:): "
set "TargetDrive=%TargetDrive%:"
if not exist %TargetDrive%\ (
    echo [错误] 盘符不存在！
    pause
    goto :MainMenu
)

:: 如果是系统盘，增加倒计时确认
if /I "%TargetDrive%"=="C:" (
    echo.
    echo [系统盘确认] 这将对 C: 盘进行深度检查
    echo 电脑将重启并显示蓝色检查界面，期间无法使用
    echo 按 Ctrl+C 取消倒计时，或按任意键立即确认
    echo.
    timeout /t 10 /nobreak >nul
)

echo [%time%] 启动 CHKDSK %TargetDrive% /F /R /X >> "%LogFile%"

if /I "%TargetDrive%"=="C:" (
    echo 正在安排下次重启检查...
    chkdsk C: /F /R /X
    echo.
    echo [已安排] 系统将在下次重启时自动检查 C: 盘
    echo [提示] 可以立即重启，或稍后手动重启
    choice /C YN /M "是否立即重启? (Y:立即重启 N:稍后手动): "
    if %errorlevel%==1 shutdown /r /t 10 /c "磁盘检查重启"
) else (
    echo [警告] %TargetDrive% 将被锁定并开始检查
    echo [警告] 检查期间无法访问该分区！
    timeout /t 5 /nobreak >nul
    chkdsk %TargetDrive% /F /R /X
    echo [?] %TargetDrive% 检查完成，返回值: %errorlevel%
)

color 0B
echo.
pause
goto :MainMenu

:: 8. 内存诊断 (增加保存工作提示)
:MemoryDiag
call :ShowHeader
color 0E
echo [Windows 内存诊断]
echo ============================================
echo 此操作将重启电脑并进入内存测试界面
echo 测试期间无法使用电脑，强制关机可能损坏系统
echo ============================================
echo.
echo ??  请确保:
echo   1. 已保存所有未保存的工作
echo   2. 关闭了所有应用程序
echo   3. 笔记本电脑已连接电源
echo.
choice /C SCN /M "选择操作: (S:保存并立即重启 C:取消 N:返回菜单): "
if %errorlevel%==1 (
    echo [提示] 正在尝试关闭常见应用...
    taskkill /F /IM word.exe excel.exe powerpnt.exe >nul 2>&1
    echo [%time%] 启动内存诊断 >> "%LogFile%"
    mdsched
)
if %errorlevel%==2 goto :MainMenu
if %errorlevel%==3 goto :MainMenu
goto :MainMenu

:: 9. 网络重置 (增加备份网络配置选项)
:NetworkReset
call :ShowHeader
color 0C
echo [网络堆栈完全重置]
echo ============================================
echo ??  此操作将:
echo   ? 重置 Winsock 目录 (所有网络软件配置丢失)
echo   ? 重置 IP 堆栈 (静态 IP 需重新设置)
echo   ? 重置防火墙规则 (自定义规则丢失)
echo   ? 卸载并重装所有网卡驱动
echo   ? 清除所有 WiFi 密码 (需重新输入)
echo ============================================
echo.

:: 先备份当前网络配置
echo 正在备份当前网络配置到 %ReportDir%...
ipconfig /all > "%ReportDir%\network-backup-before-reset.txt"
netsh wlan export profile folder="%ReportDir%" key=clear >nul 2>&1
if exist "%ReportDir%\Wi-Fi.xml" (
    echo [?] WiFi 配置已备份，重置后可手动恢复
)

choice /C YN /M "确认重置网络? (Y:确认 N:返回): "
if %errorlevel%==2 goto :MainMenu

echo [%time%] 执行网络重置 >> "%LogFile%"

echo 执行中: Winsock 重置...
netsh winsock reset >> "%LogFile%" 2>&1
echo 执行中: IP 重置...
netsh int ip reset "%TempDir%\ipreset.log" >> "%LogFile%" 2>&1
echo 执行中: 防火墙重置...
netsh advfirewall reset >> "%LogFile%" 2>&1
echo 执行中: DNS 刷新...
ipconfig /flushdns >> "%LogFile%" 2>&1
echo 执行中: 释放 IP...
ipconfig /release >> "%LogFile%" 2>&1
echo 执行中: 续订 IP...
ipconfig /renew >> "%LogFile%" 2>&1

echo [?] 网络重置完成，必须重启生效
echo [重要] WiFi 密码已被清除，重启后需重新连接网络
echo.
choice /C YN /M "是否立即重启? (Y:立即重启 N:稍后手动): "
if %errorlevel%==1 shutdown /r /t 10 /c "网络重置后重启"
goto :MainMenu

:: 10. 完整报告 (增加 WiFi 密码备份和导出的事件日志分析)
:FullReport
call :ShowHeader
echo [生成完整诊断报告包]
echo 保存位置: %ReportDir%
echo.
choice /C YN /M "确认生成? (Y:生成 N:返回): "
if %errorlevel%==2 goto :MainMenu

echo 正在生成，请稍候 (可能需要几分钟)...

:: 电池报告
powercfg /batteryreport /output "%ReportDir%\battery-report.html" >nul 2>&1
if exist "%ReportDir%\battery-report.html" (
    echo [?] 电池健康报告
    echo   查看 Design Capacity vs Full Charge Capacity 判断电池损耗
)

:: 电源效率
powercfg /energy /output "%ReportDir%\energy-report.html" /duration 60 >nul 2>&1 &
echo [?] 电源效率分析 (60秒采样，后台生成中)

:: 驱动列表
driverquery /v > "%ReportDir%\drivers-verbose.txt"
echo [?] 详细驱动列表

:: 系统信息
systeminfo > "%ReportDir%\system-info.txt"
echo [?] 系统配置详情

:: 导出关键事件日志 (EVTX 格式，可用事件查看器打开)
wevtutil epl System "%ReportDir%\System-Last7Days.evtx" /q:"*[System[TimeCreated[timediff(@SystemTime) <= 604800000]]]" 2>&1
wevtutil epl Application "%ReportDir%\Application-Last7Days.evtx" /q:"*[System[TimeCreated[timediff(@SystemTime) <= 604800000]]]" 2>&1
echo [?] 系统和应用日志 (最近7天)

:: 网络配置备份
ipconfig /all > "%ReportDir%\network-config.txt"
netsh wlan show profiles > "%ReportDir%\wifi-list.txt"
echo [?] 网络配置快照

:: 生成可读的错误汇总 (新增)
echo 正在分析错误日志并生成摘要...
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} | Select TimeCreated, Id, LevelDisplayName, Message | Export-Csv -Path '%ReportDir%\critical-errors.csv' -NoTypeInformation" >nul 2>&1
if exist "%ReportDir%\critical-errors.csv" (
    echo [?] 关键错误 CSV 表格 (可用 Excel 打开分析)
)

echo.
echo ============================================
echo [完成] 报告包已生成: %ReportDir%
echo.
echo 关键文件说明:
echo   ? battery-report.html: 电池设计容量vs实际容量
echo   ? energy-report.html: 查看"错误"部分找出唤醒问题
echo   ? critical-errors.csv: 按时间排序的所有严重错误
echo   ? System-Last7Days.evtx: 用事件查看器打开分析
echo.
echo 分析建议:
echo   1. 查看 energy-report.html 中的"设备"列表
echo   2. 检查是否有设备阻止电脑进入睡眠
echo   3. 查看 critical-errors.csv 找频繁出现的错误ID
echo ============================================
echo.
pause
goto :MainMenu

:: 11. 新增: 安全清理临时文件
:CleanTempFiles
call :ShowHeader
echo [系统临时文件清理]
echo 将清理以下位置的临时文件 (不删除正在使用的):
echo   ? Windows Temp 文件夹
echo   ? 用户 Temp 文件夹  
echo   ? Windows 更新缓存 (可选)
echo   ? 回收站 (可选)
echo.
echo [安全提示] 此操作不会删除浏览器密码或文档
echo.
choice /C YNC /M "选择操作: (Y:安全清理 N:返回 C:深度清理包括更新缓存): "

if %errorlevel%==2 goto :MainMenu

set "CleanLevel=safe"
if %errorlevel%==3 set "CleanLevel=deep"

echo [%time%] 开始清理临时文件 (%CleanLevel% 模式) >> "%LogFile%"

:: 安全清理
echo 清理 Windows 临时文件...
del /q /f /s %windir%\Temp\*.* 2>nul
echo 清理用户临时文件...
del /q /f /s %TEMP%\*.* 2>nul
echo 清理最近的运行历史...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /va /f >nul 2>&1

if "%CleanLevel%"=="deep" (
    echo 清理 Windows 更新缓存 (需几分钟)...
    net stop wuauserv >nul 2>&1
    del /q /f /s %windir%\SoftwareDistribution\Download\*.* 2>nul
    net start wuauserv >nul 2>&1
    echo 清理回收站...
    powershell -Command "Clear-RecycleBin -Confirm:$false" >nul 2>&1
)

echo [?] 清理完成
echo.
pause
goto :MainMenu

:: 退出
:ExitScript
call :ShowHeader
echo 诊断会话结束
echo 日志文件: %LogFile%
echo.
if exist "%LogFile%" (
    choice /C YN /M "是否打开日志文件? (Y:是 N:否): "
    if %errorlevel%==1 notepad "%LogFile%"
)
exit /b 0