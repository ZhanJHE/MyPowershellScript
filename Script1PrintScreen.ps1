# PowerShell 示例脚本

# --------------------------------------------------------------------------
# 1. 变量
#    - 变量以 `$` 符号开头。
#    - 变量名不区分大小写（但为了清晰起见，最好保持一致）。
#    - 可以使用 Set-Variable cmdlet 创建变量，但通常直接赋值更简单。
# --------------------------------------------------------------------------

# 字符串变量
$greeting = "Hello, PowerShell Learner!"

# 整数变量
$number = 10

# 数组变量
$colors = @("Red", "Green", "Blue")

# --------------------------------------------------------------------------
# 2. 输出到控制台
#    - `Write-Host` 是一个常用的命令，用于向控制台显示输出。
#    - 字符串可以用双引号或单引号括起来。双引号允许变量内插。
# --------------------------------------------------------------------------

Write-Host "--- 输出示例 ---"
Write-Host $greeting
Write-Host "The value of number is: $number"
Write-Host "The first color is: $($colors[0])" # 访问数组元素
Write-Host "" # 打印一个空行

# --------------------------------------------------------------------------
# 3. 循环
#    - `foreach` 循环用于遍历集合（如数组）中的每个项目。
# --------------------------------------------------------------------------

Write-Host "--- 循环示例 ---"
foreach ($color in $colors) {
    Write-Host "Color: $color"
}
Write-Host ""

# --------------------------------------------------------------------------
# 4. 条件语句
#    - `if`, `elseif`, `else` 用于根据条件执行代码块。
#    - 比较运算符：-eq (等于), -ne (不等于), -gt (大于), -lt (小于), -ge (大于等于), -le (小于等于)
# --------------------------------------------------------------------------

Write-Host "--- 条件语句示例 ---"
if ($number -gt 5) {
    Write-Host "$number is greater than 5."
}
elseif ($number -eq 5) {
    Write-Host "$number is equal to 5."
}
else {
    Write-Host "$number is less than 5."
}
Write-Host ""

# --------------------------------------------------------------------------
# 5. 获取用户输入
#    - `Read-Host` 用于提示用户输入并读取他们的响应。
# --------------------------------------------------------------------------

Write-Host "--- 用户输入示例 ---"
$name = Read-Host "Please enter your name"
Write-Host "Hello, $name! Welcome to PowerShell."
Write-Host ""

# --------------------------------------------------------------------------
# 6. 函数
#    - 函数是可重用的代码块。
# --------------------------------------------------------------------------
Write-Host "--- 函数示例 ---"
function Get-Greeting {
    param (
        [string]$personName
    )
    return "Hello, $personName from a function!"
}

$functionGreeting = Get-Greeting -personName "World"
Write-Host $functionGreeting

Write-Host "--- 脚本结束 ---"