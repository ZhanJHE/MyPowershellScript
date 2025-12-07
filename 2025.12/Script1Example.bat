:: 关闭命令回显，使脚本输出更整洁
@echo off

:: 尝试将代码页设置为UTF-8 (65001)，以提高在不同环境下的兼容性
:: chcp 65001 > nul

:: 设置窗口标题
title My Batch Script Example

:: 设置文本颜色为绿色 (A)，背景为黑色 (0)
color 0A

:: ==========================================================================
:: 1. 变量
::    - 使用 `set` 命令定义变量。
::    - 使用 `%variable_name%` 来引用变量的值。
::    - `set /a` 用于数学计算。
:: ==========================================================================
echo.
echo --- 1. 变量示例 ---

:: 字符串变量
set GREETING=Hello, Batch Learner!

:: 数字变量
set NUMBER=10

:: 使用 /a 开关进行数学运算
set /a RESULT = %NUMBER% * 5

echo %GREETING%
echo The number is: %NUMBER%
echo The result of %NUMBER% * 5 is: %RESULT%


:: ==========================================================================
:: 2. 用户输入
::    - 使用 `set /p` 提示用户输入并将其存储在变量中。
:: ==========================================================================
echo.
echo --- 2. 用户输入示例 ---

set /p USER_NAME="Please enter your name: "
echo Hello, %USER_NAME%! Welcome.


:: ==========================================================================
:: 3. 控制流 - IF/ELSE
::    - `if` 用于条件判断。
::    - `==` 用于字符串比较。
::    - `EQU` (等于), `NEQ` (不等于), `LSS` (小于), `LEQ` (小于等于), 
::      `GTR` (大于), `GEQ` (大于等于) 用于数字比较。
::    - `if exist` 检查文件或目录是否存在。
:: ==========================================================================
echo.
echo --- 3. IF/ELSE 示例 ---

if /i "%USER_NAME%"=="Admin" (
    echo Welcome, Administrator!
) else (
    echo Welcome, regular user!
)

if %RESULT% GEQ 50 (
    echo The result %RESULT% is greater than or equal to 50.
) else (
    echo The result %RESULT% is less than 50.
)


:: ==========================================================================
:: 4. 控制流 - FOR 循环
::    - `for` 是一个非常强大的命令，用于迭代。
:: ==========================================================================
echo.
echo --- 4. FOR 循环示例 ---

:: 迭代一组字符串
echo.
echo Iterating through a list of strings:
for %%a in (Apple, Banana, Cherry) do (
    echo Fruit: %%a
)

:: 迭代数字范围 (从1到5，步长为1)
echo.
echo Iterating through a range of numbers:
for /L %%i in (1, 1, 5) do (
    echo Count: %%i
)

:: 迭代目录中的文件
echo.
echo Iterating through files in the current directory:
for %%f in (*.bat) do (
    echo Found batch file: %%f
)


:: ==========================================================================
:: 5. 系统信息
::    - 批处理有一些内置的动态变量来获取系统信息。
::    - 也可以调用外部命令如 `systeminfo`。
:: ==========================================================================
echo.
echo --- 5. 系统信息示例 ---

echo Computer Name: %COMPUTERNAME%
echo User Name:     %USERNAME%
echo Date:          %DATE%
echo Time:          %TIME%
echo OS:            %OS%
echo System Drive:  %SystemDrive%

:: 从 `systeminfo` 命令中筛选特定信息
echo.
echo Getting specific info from systeminfo...
systeminfo | findstr /B /C:"OS Name" /C:"Total Physical Memory"


:: ==========================================================================
:: 6. 文件和目录操作
:: ==========================================================================
echo.
echo --- 6. 文件和目录操作示例 ---

set TEMP_DIR=BatchDemo
set TEMP_FILE=%TEMP_DIR%\MyTestFile.txt

:: 检查并创建目录
if not exist "%TEMP_DIR%" (
    mkdir %TEMP_DIR%
    echo Directory '%TEMP_DIR%' created.
)

:: 写入文件 (覆盖)
echo This is the first line. > %TEMP_FILE%

:: 追加到文件
echo This is the second line, appended. >> %TEMP_FILE%

echo Content written to '%TEMP_FILE%'.

:: 读取并显示文件内容
echo.
echo Reading content from '%TEMP_FILE%':
type %TEMP_FILE%

:: 清理
echo.
echo Cleaning up...
if exist "%TEMP_FILE%" del %TEMP_FILE%
if exist "%TEMP_DIR%" rmdir %TEMP_DIR%
echo Temporary file and directory removed.


:: ==========================================================================
:: 7. 函数 (子程序)
::    - 使用标签 (`:label_name`) 定义子程序。
::    - 使用 `call :label_name` 调用子程序。
::    - 使用 `goto :eof` 从子程序返回。
::    - `%1`, `%2`, ... 用于接收传递的参数。
:: ==========================================================================
echo.
echo --- 7. 函数 (子程序) 示例 ---

:: 调用子程序并传递参数
call :PrintMessage "This is an argument" 123

echo Back in the main script.


:: ==========================================================================
:: 脚本主体结束
:: ==========================================================================
echo.
echo --- Script Finished ---

:: `goto :eof` 跳转到文件末尾，防止代码执行到下面的子程序中
goto :eof


:: --------------------------------------------------------------------------
:: 子程序定义区域
:: --------------------------------------------------------------------------

:PrintMessage
:: 这是一个子程序，它会打印接收到的参数
echo.
echo --- Inside :PrintMessage subroutine --- 
echo Received first argument: %~1
echo Received second argument: %~2
echo.

:: 从子程序返回到调用它的地方
goto :eof