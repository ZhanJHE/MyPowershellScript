#Requires -RunAsAdministrator
<#
.SYNOPSIS
    通过导出和导入 XML 配置文件来管理 Windows 的默认文件关联。
.DESCRIPTION
    此脚本使用 DISM (Deployment Image Servicing and Management) 工具来处理默认应用程序的关联。
    它会执行以下步骤：
    1. 将当前用户的默认应用程序关联导出一个 XML 文件。
    2. 使用记事本 (Notepad) 打开这个 XML 文件，让用户可以手动编辑。
    3. 等待用户完成编辑并关闭记事本。
    4. 将用户修改后的 XML 文件重新导入系统，以应用新的文件关联设置。
    5. 清理临时生成的 XML 文件。
    这种方法对于设置 UWP 应用的关联尤其有效。
.NOTES
    - 此脚本必须以管理员权限运行才能使用 DISM 工具成功导入配置。
    - 请在记事本中仔细编辑 XML 文件。错误的格式可能导致导入失败。
    - 建议在修改前备份原始的 XML 文件内容。
#>

# --- 脚本主要逻辑 ---

# 定义临时 XML 文件的路径，存储在用户的临时文件夹中
$tempXmlPath = "$env:TEMP\DefaultAppAssociations.xml"

# 1. 导出当前的默认应用关联配置
Write-Host "正在导出当前的默认应用关联配置到: $tempXmlPath" -ForegroundColor Green
dism.exe /Online /Export-DefaultAppAssociations:"$tempXmlPath"

# 检查导出是否成功
if (-not (Test-Path $tempXmlPath)) {
    Write-Error "导出默认应用关联失败，脚本无法继续。"
    return
}

Write-Host "导出成功！" -ForegroundColor Green
Write-Host "现在将使用记事本打开该文件，请在其中修改您希望变更的文件关联。" -ForegroundColor Yellow
Write-Host "完成修改后，请保存文件并关闭记事本，脚本将自动继续执行导入操作。" -ForegroundColor Yellow

# 2. 使用记事本打开 XML 文件，并等待用户编辑完成
# Start-Process -Wait 会暂停脚本，直到记事本进程关闭
try {
    Start-Process notepad.exe -ArgumentList "`"$tempXmlPath`"" -Wait -ErrorAction Stop
} catch {
    Write-Error "无法启动记事本。请检查 notepad.exe 是否在您的系统路径中。"
    # 清理临时文件
    Remove-Item -Path $tempXmlPath -Force
    return
}


# 3. 提示用户确认是否导入
$confirmation = Read-Host "您已经关闭了记事本。是否要导入刚才修改的配置？(y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "操作已取消。临时文件 '$tempXmlPath' 已被保留，您可以稍后手动导入。" -ForegroundColor Yellow
    return
}

# 4. 将修改后的 XML 文件导入系统
Write-Host "正在导入修改后的文件关联配置..." -ForegroundColor Green
dism.exe /Online /Import-DefaultAppAssociations:"$tempXmlPath"

# 检查上一条命令的执行结果
if ($LASTEXITCODE -eq 0) {
    Write-Host "文件关联配置已成功导入！" -ForegroundColor Green
    Write-Host "更改可能需要您注销并重新登录，或重启文件资源管理器后才能完全生效。" -ForegroundColor Yellow
} else {
    Write-Error "导入配置文件时发生错误。返回代码: $LASTEXITCODE"
    Write-Host "临时文件 '$tempXmlPath' 已被保留，以便您检查和排错。" -ForegroundColor Yellow
}

# 5. 清理临时文件 (仅在成功导入后)
if ($LASTEXITCODE -eq 0) {
    Write-Host "正在清理临时文件..."
    Remove-Item -Path $tempXmlPath -Force
}

Write-Host "脚本执行完毕。"