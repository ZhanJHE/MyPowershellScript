

@echo off

echo Please place this .bat script file in the Ruijie client folder, 
echo specifically in the same directory as “RuijieSupplicant.exe” and “8021x.exe”.
echo Please use UTF-8 encoding to run this script.
echo use chcp 65001 to set encoding in cmd or powershell.
echo 
echo 请将这个.bat脚本文件放到Ruijie客户端的文件夹下，即"RuijieSupplicant.exe"和"8021x.exe"同级文件夹 
chcp 65001 > nul

rem 切换当前目录到批处理文件所在的目录。
rem %~dp0 会扩展为批处理文件的驱动器号和路径。
cd /d "%~dp0"

rem 将 8021.exe 重命名为 8021x.exe。
rem 这通常是为了阻止主程序（RuijieSupplicant.exe）找到并执行这个文件。
rem 8021.exe 很可能是锐捷客户端用于802.1X认证的组件。
rename 8021.exe 8021x.exe

rem 启动锐捷客户端的主程序。使用 start 命令以非阻塞方式启动，这样脚本可以继续执行。
start "" "RuijieSupplicant.exe"

rem 等待4秒。
rem 这个延迟是为了给主程序一些时间来启动和运行。
timeout /T 4

rem 强制终止名为 8021x.exe 的进程及其所有子进程。
rem /f 表示强制终止，/t 表示终止进程树，/im 表示通过映像名称指定进程。
rem 即使主程序以某种方式启动了重命名后的文件，此命令也会将其关闭。
taskkill /f /t /im 8021x.exe

rem 将 8021x.exe 重命名回 8021.exe，恢复原始文件名。
rename 8021x.exe 8021.exe

rem 等待1秒。
timeout /T 1

rem 再次尝试终止 8021x.exe 进程。
rem 这是一个备用措施，以防进程在第一次被终止后又重新启动。
taskkill /f /t /im 8021x.exe

:: 这个脚本用来跳过 锐捷客户端的 8021x.exe 进程对多个网卡的检测
:: 通过临时关闭并重命名 8021x.exe 文件为 8021.exe，使其无法被主程序找到和执行，从而达到跳过检测的目的。
:: 不管用可以尝试更改延迟时间
:: 还有，锐捷校园网客户端就是一坨狗屎
:: 我本来想用bat脚本写，发现这老掉牙的cmd和bat总会莫名其妙把一些中文注释当做命令执行，
:: 导致脚本执行时出现错误。
:: 最后我只能用powershell脚本写了。