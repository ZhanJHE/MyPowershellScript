# PowerShell 文件和目录操作示例

# 设定一个基础路径用于存放本脚本创建的文件夹和文件
$basePath = ".\TempFile" # 使用相对路径

# --------------------------------------------------------------------------
# 1. 创建目录
#    - `Test-Path` 用于检查路径是否存在。
#    - `New-Item` 用于创建新项目，通过 `-ItemType` 参数指定为目录。
# --------------------------------------------------------------------------
Write-Host "--- 1. 创建目录 ---"
if (-not (Test-Path -Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory | Out-Null
    Write-Host "目录 '$basePath' 已创建。"
} else {
    Write-Host "目录 '$basePath' 已存在。"
}
Write-Host ""

# --------------------------------------------------------------------------
# 2. 创建文件并写入内容
#    - `Set-Content` 或 `Out-File` 可以用来创建文件并写入内容。
#    - `Set-Content` 是一个简单的写入命令。
#    - `Out-File` 提供更多选项，如编码。
# --------------------------------------------------------------------------
Write-Host "--- 2. 创建文件并写入内容 ---"
$filePath = Join-Path -Path $basePath -ChildPath "MyFile.txt"
$fileContent = "这是写入文件的第一行内容。`n这是第二行。"

Set-Content -Path $filePath -Value $fileContent
# 或者使用 Out-File: $fileContent | Out-File -FilePath $filePath

Write-Host "文件 '$filePath' 已创建并写入内容。"
Write-Host ""

# --------------------------------------------------------------------------
# 3. 读取文件内容
#    - `Get-Content` 用于读取文件内容。
#    - 默认情况下，它会逐行读取内容并返回一个字符串数组。
# --------------------------------------------------------------------------
Write-Host "--- 3. 读取文件内容 ---"
if (Test-Path -Path $filePath) {
    Write-Host "开始读取文件 '$filePath':"
    $readContent = Get-Content -Path $filePath
    foreach ($line in $readContent) {
        Write-Host "  $line"
    }
} else {
    Write-Host "文件 '$filePath' 不存在。"
}
Write-Host ""

# --------------------------------------------------------------------------
# 4. 追加内容到文件
#    - `Add-Content` 用于向现有文件追加内容。
# --------------------------------------------------------------------------
Write-Host "--- 4. 追加内容到文件 ---"
$appendedContent = "这是追加的一行内容。"
Add-Content -Path $filePath -Value $appendedContent
Write-Host "已向文件 '$filePath' 追加内容。"
Write-Host "追加后的文件内容："
Get-Content -Path $filePath | ForEach-Object { Write-Host "  $_" }
Write-Host ""

# --------------------------------------------------------------------------
# 5. 复制文件
#    - `Copy-Item` 用于复制文件或目录。
# --------------------------------------------------------------------------
Write-Host "--- 5. 复制文件 ---"
$copiedFilePath = Join-Path -Path $basePath -ChildPath "MyFile_Copy.txt"
Copy-Item -Path $filePath -Destination $copiedFilePath
Write-Host "文件已从 '$filePath' 复制到 '$copiedFilePath'。"
Write-Host ""

# --------------------------------------------------------------------------
# 6. 移动文件
#    - `Move-Item` 用于移动文件或目录。
#    - 我们将创建一个新目录来存放移动后的文件。
# --------------------------------------------------------------------------
Write-Host "--- 6. 移动文件 ---"
$destinationDir = Join-Path -Path $basePath -ChildPath "MovedFiles"
if (-not (Test-Path -Path $destinationDir)) {
    New-Item -Path $destinationDir -ItemType Directory | Out-Null
}
$movedFilePath = Join-Path -Path $destinationDir -ChildPath "MyFile_Copy.txt"
Move-Item -Path $copiedFilePath -Destination $movedFilePath
Write-Host "文件已从 '$copiedFilePath' 移动到 '$movedFilePath'。"
Write-Host ""

# --------------------------------------------------------------------------
# 7. 重命名文件
#    - `Rename-Item` 用于重命名文件或目录。
# --------------------------------------------------------------------------
Write-Host "--- 7. 重命名文件 ---"
$renamedFilePath = Join-Path -Path (Split-Path $movedFilePath) -ChildPath "MyFile_Renamed.txt"
Rename-Item -Path $movedFilePath -NewName "MyFile_Renamed.txt"
Write-Host "文件已从 '$movedFilePath' 重命名为 '$renamedFilePath'。"
Write-Host ""

# --------------------------------------------------------------------------
# 8. 清理：删除文件和目录
#    - `Remove-Item` 用于删除文件或目录。
#    - 使用 `-Recurse` 参数可以删除非空目录。
#    - 使用 `-Force` 参数可以删除隐藏或只读文件。
# --------------------------------------------------------------------------
Write-Host "--- 8. 清理 ---"
Write-Host "准备删除本脚本创建的所有文件和目录..."
# Read-Host "按 Enter 键继续..." # 如果希望手动确认，可以取消此行注释

Remove-Item -Path $basePath -Recurse -Force

if (-not (Test-Path -Path $basePath)) {
    Write-Host "目录 '$basePath' 及其所有内容已成功删除。"
} else {
    Write-Host "删除目录 '$basePath' 失败。"
}
Write-Host ""

Write-Host "--- 脚本结束 ---"