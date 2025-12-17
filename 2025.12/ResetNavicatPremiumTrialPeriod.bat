@echo off

REM =====================================================================================
REM 警告：此脚本会删除注册表项，可能导致 Navicat 或其他程序不稳定。
REM 请确保您知道自己在做什么，并以管理员身份运行此脚本。
REM =====================================================================================

REM --- 第一部分：删除 Navicat 的更新和注册信息 ---

REM 打印提示信息，说明将要删除 Navicat 的更新历史记录相关的注册表项。
echo Delete HKEY_CURRENT_USER\Software\PremiumSoft\NavicatPremium\Update

REM 使用 reg delete 命令强制删除指定的注册表项，/f 参数表示无需确认。
reg delete HKEY_CURRENT_USER\Software\PremiumSoft\NavicatPremium\Update /f

REM 打印提示信息，说明将要删除 Navicat 的注册信息。
REM 这些信息通常包含了版本和语言。
echo Delete HKEY_CURRENT_USER\Software\PremiumSoft\NavicatPremium\Registration[version and language]

REM 使用 for 循环来查找并删除所有与注册相关的项。
REM 'REG QUERY ... /s' 会递归查询 NavicatPremium 目录下的所有项。
REM '| findstr /L Registration' 会筛选出所有路径中包含 "Registration" 的行。
REM 'for /f %%i in (...)' 会遍历筛选出的每一行（即每一个注册表项的完整路径）。
REM 'reg delete %%i /va /f' 会删除该项下的所有值（/va），从而清除注册信息。
for /f %%i in ('"REG QUERY "HKEY_CURRENT_USER\Software\PremiumSoft\NavicatPremium" /s | findstr /L Registration"') do (
    reg delete %%i /va /f
)

REM --- 第二部分：通过查找 CLSID 中的特定子项来清除痕迹 ---
REM Navicat 可能通过在 CLSID 中创建带有特定名称（如 Info, ShellFolder）的项来记录试用信息。
REM 这部分脚本的目的就是找到并删除这些项。
REM 警告：这是一个非常宽泛的搜索，可能会误删其他正常程序的注册表项。

echo Delete Info and ShellFolder under HKEY_CURRENT_USER\Software\Classes\CLSID

REM 遍历当前用户 CLSID 下的所有项。
REM 'reg query "HKEY_CURRENT_USER\Software\Classes\CLSID"' 列出所有顶级 CLSID 项。
REM 'for /f "tokens=*" %%a in (...)' 会遍历每一个 CLSID 项的路径。
for /f "tokens=*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Classes\CLSID"') do (
  REM 在每个 CLSID 项内部，搜索名为 "Info" 的子项或值。
  REM 'reg query "%%a" /f "Info" /s /e' 在当前 CLSID (%%a) 下递归搜索（/s）精确匹配（/e）的 "Info" 项。
  REM 'findstr /i "Info"' 确保找到了匹配项。
  REM 如果找到，则打印并删除整个 CLSID 项 (%%a)。
  for /f "tokens=*" %%l in ('reg query "%%a" /f "Info" /s /e ^| findstr /i "Info"') do (
    echo Delete: %%a
    reg delete %%a /f
  )
  
  REM 同样，在每个 CLSID 项内部，搜索名为 "ShellFolder" 的子项或值。
  REM 如果找到，也删除整个 CLSID 项。
  for /f "tokens=*" %%l in ('reg query "%%a" /f "ShellFolder" /s /e ^| findstr /i "ShellFolder"') do (
    echo Delete: %%a
    reg delete %%a /f
  )
)