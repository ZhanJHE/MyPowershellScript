# PowerShell 管道 (`|`) 操作示例

# 管道 (`|`) 是 PowerShell 的核心功能之一。它允许你将一个命令 (cmdlet) 的输出
# “管道传送”给另一个命令作为输入。这使得你可以将简单的、独立的命令组合起来，
# 形成强大的命令行工具链。

# --------------------------------------------------------------------------
# 1. 基础示例：过滤进程
#    - `Get-Process`：获取当前正在运行的所有进程。
#    - `Where-Object`：根据指定的条件过滤通过管道传递给它的对象。
#      (简写形式是 `?`)
#    - `$_`：在 `Where-Object` 和 `ForEach-Object` 的脚本块中，`$_` 代表
#      当前通过管道传递的对象。
# --------------------------------------------------------------------------
Write-Host "--- 1. 过滤正在运行的进程 (例如，查找所有名为 'svchost' 的进程) ---"

# Get-Process 的输出是一个进程对象数组。每个对象都通过管道传递给 Where-Object。
# Where-Object 检查每个进程对象的 ProcessName 属性是否等于 "svchost"。
Get-Process | Where-Object { $_.ProcessName -eq "svchost" } | Format-Table -AutoSize

Write-Host "上面的命令等同于："
Write-Host "# Get-Process | ? { `$_.ProcessName -eq \`"svchost\`" } | Format-Table -AutoSize"
Write-Host ""

# --------------------------------------------------------------------------
# 2. 排序对象
#    - `Sort-Object`：对通过管道传递的对象进行排序。
#      (简写形式是 `sort`)
#    - `-Descending`：指定降序排序。
# --------------------------------------------------------------------------
Write-Host "--- 2. 获取内存使用量最高的5个进程 ---"

# 1. `Get-Process` 获取所有进程。
# 2. `Sort-Object WS` 按工作集（内存使用量）对它们进行排序。
# 3. `Select-Object -First 5` 选择排序后的前5个结果。
Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 5 | Format-Table -AutoSize

Write-Host ""

# --------------------------------------------------------------------------
# 3. 对每个对象执行操作
#    - `Get-ChildItem`：获取目录中的项（文件和文件夹）。
#      (简写形式是 `gci` 或 `ls`)
#    - `ForEach-Object`：对通过管道传递的每个对象执行一个操作。
#      (简写形式是 `foreach` 或 `%`)
# --------------------------------------------------------------------------
Write-Host "--- 3. 计算当前目录下每个文件的行数 ---"

# 创建一些临时文件用于演示
if (-not (Test-Path -Path ".\\PipeDemo")) { New-Item -Path ".\\PipeDemo" -ItemType Directory | Out-Null }
Set-Content -Path ".\\PipeDemo\\file1.txt" -Value "one`ntwo`nthree"
Set-Content -Path ".\\PipeDemo\\file2.txt" -Value "four`nfive`nsix`nseven"

# 1. `Get-ChildItem` 获取 PipeDemo 目录下的所有文件。
# 2. `ForEach-Object` 遍历每个文件对象。
# 3. 在循环内部，`Get-Content $_.FullName` 读取当前文件的内容。
# 4. `Measure-Object -Line` 计算内容的行数。
Get-ChildItem -Path ".\\PipeDemo" -File | ForEach-Object {
    $file = $_.Name
    $lineCount = (Get-Content -Path $_.FullName | Measure-Object -Line).Lines
    Write-Host "文件 '$file' 有 $lineCount 行。"
}

# 清理临时文件
Remove-Item -Path ".\\PipeDemo" -Recurse -Force

Write-Host ""

# --------------------------------------------------------------------------
# 4. 组合多个管道
#    - `Get-Service`：获取系统服务。
# --------------------------------------------------------------------------
Write-Host "--- 4. 查找所有已停止的服务，按显示名称排序，并显示名称和状态 ---"

# 1. `Get-Service` 获取所有服务。
# 2. `Where-Object` 过滤出状态为 "Stopped" 的服务。
# 3. `Sort-Object` 按 DisplayName 属性对它们进行排序。
# 4. `Format-Table` 选择要显示的属性 (DisplayName, Status) 并自动调整列宽。
Get-Service | Where-Object { $_.Status -eq 'Stopped' } | Sort-Object -Property DisplayName | Format-Table -Property DisplayName, Status -AutoSize


Write-Host "--- 脚本结束 ---"