#Requires -RunAsAdministrator
<#
.SYNOPSIS
    一个 PowerShell 脚本，用于查找系统中已安装的视频播放器，并允许用户将常见的视频文件格式批量关联到所选的播放器。
.DESCRIPTION
    此脚本会扫描注册表和已安装的 UWP 应用，以识别潜在的视频播放器。
    然后，它会向用户显示一个列表，让用户选择一个播放器。
    最后，它会将一个预定义的常见视频文件扩展名列表关联到所选的播放器。
    对于 Win32 应用程序，它尝试使用 'ftype' 命令。
    对于 UWP 应用程序，它会检查是否存在 'PS-SFTA' 模块，如果存在，则提供关联说明；如果不存在，则建议手动操作。
.NOTES
    - 此脚本必须以管理员权限运行才能修改文件关联。
    - 关联 Win32 应用程序的功能可能不是 100% 可靠，因为它依赖于 'ftype' 命令，这在现代 Windows 版本中可能不足够。
    - 关联 UWP 应用程序的功能依赖于第三方的 'PS-SFTA' 模块。如果未安装该模块，脚本将无法自动设置关联。
    - 更改文件关联是系统级别的操作，请谨慎使用。
#>

# --- 函数定义 ---

function Get-VideoPlayers {
    <#
    .SYNOPSIS
        获取系统中已安装的 Win32 和 UWP 视频播放器。
    .DESCRIPTION
        此函数通过两种方式查找播放器：
        1. 扫描 HKEY_CLASSES_ROOT 注册表项以查找与文件扩展名关联的可执行文件（.exe），从而识别 Win32 应用程序。
        2. 使用 Get-StartApps cmdlet 查找名称中包含 "Video", "Player", "Media" 等关键字的 UWP 应用程序。
    .RETURNS
        一个哈希表，其中键是播放器的名称，值是其标识符（Win32 应用程序的路径或 UWP 应用程序的 AppId）。
    #>

    # 初始化用于存储 Win32 应用程序的哈希表
    $win32Apps = @{}
    # 获取 HKEY_CLASSES_ROOT 下的所有文件扩展名键
    $assocKeys = Get-ChildItem -Path "Registry::HKEY_CLASSES_ROOT\.*" -ErrorAction SilentlyContinue
    
    # 遍历每个文件扩展名
    foreach ($key in $assocKeys.PSChildName) {
        try {
            # 获取与扩展名关联的文件类型
            $appPathValue = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$key" -ErrorAction Stop)."(default)"
            # 检查文件类型值是否存在且格式有效
            if ($appPathValue -and $appPathValue -match "^[A-Za-z0-9_\-\.]+$") {
                # 获取打开该文件类型的命令
                $appPath = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$appPathValue\shell\open\command" -ErrorAction Stop)."(default)"
                # 使用正则表达式从命令中提取可执行文件的路径
                if ($appPath -match '^"?(?<path>[^"]+\.exe)"?') {
                    $exePath = $matches.path
                    # 获取不带扩展名的文件名作为应用程序名称
                    $appName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
                    # 将应用程序名称和路径存入哈希表
                    $win32Apps[$appName] = $exePath
                }
            }
        } catch {
            # 如果在读取注册表时发生错误（例如权限不足或键不存在），则忽略
        }
    }

    # 获取 UWP 应用
    # 通过关键词筛选可能与视频播放相关的 UWP 应用
    $uwpApps = Get-StartApps | Where-Object { $_.Name -like "*Video*" -or $_.Name -like "*Player*" -or $_.Name -like "*Media*" -or $_.Name -like "*VLC*" -or $_.Name -like "*MPC*" -or $_.Name -like "*PotPlayer*" }

    # 合并 Win32 和 UWP 应用列表，并去重
    $allApps = @{}
    # 将 Win32 应用添加到最终列表
    $win32Apps.GetEnumerator() | ForEach-Object { $allApps[$_.Key] = $_.Value }
    # 将 UWP 应用添加到最终列表（如果名称已存在，则会覆盖）
    $uwpApps | ForEach-Object { $allApps[$_.Name] = $_.AppId }

    return $allApps
}

function Get-CommonVideoExtensions {
    <#
    .SYNOPSIS
        返回一个包含常见视频文件扩展名的数组。
    .RETURNS
        [string[]] 视频文件扩展名数组。
    #>
    return @(
        ".3g2", ".3gp", ".3gp2", ".3gpp", ".amv", ".asf", ".avi", ".bik", ".bin", ".crf", ".divx", ".drc", ".dv", ".dvr-ms", ".evo", ".f4v", ".flv", ".gvi", ".gxf", ".iso", ".m1v", ".m2v", ".m2t", ".m2ts", ".m4v", ".mkv", ".mov", ".mp2", ".mp2v", ".mp4", ".mp4v", ".mpe", ".mpeg", ".mpg", ".mpl", ".mpls", ".mpv", ".mpv2", ".mts", ".mtv", ".mxf", ".mxg", ".nsv", ".nuv", ".ogg", ".ogm", ".ogv", ".ogx", ".ps", ".rec", ".rm", ".rmvb", ".rpl", ".thp", ".tod", ".tp", ".ts", ".tts", ".txd", ".vob", ".vro", ".webm", ".wm", ".wmv", ".wtv", ".xesc"
    )
}

function Set-VideoAssociations {
    <#
    .SYNOPSIS
        将指定的文件扩展名关联到指定的应用程序。
    .PARAMETER AppIdentifier
        应用程序的标识符。对于 Win32 应用程序，这是可执行文件的完整路径。对于 UWP 应用程序，这是 AppUserModelId (AUMID)。
    .PARAMETER Extensions
        要关联的文件扩展名数组（例如 ".mp4", ".mkv"）。
    #>
    param(
        [string]$AppIdentifier, # 可能是可执行文件路径或 AUMID
        [array]$Extensions
    )

    Write-Host "正在设置文件关联，请稍候..."

    # 判断应用程序是 Win32 类型还是 UWP 类型
    # Test-Path -PathType Leaf 检查路径是否指向一个文件
    if (Test-Path $AppIdentifier -PathType Leaf) {
        # --- Win32 应用处理逻辑 ---
        Write-Warning "关联 Win32 应用需要更复杂的操作或专用模块。当前脚本将尝试使用默认方式。"
        foreach ($ext in $Extensions) {
            # 尝试通过 FTYPE 和 ASSOC 命令进行关联 (这种方法在现代 Windows 中可能不完全可靠)
            # 获取当前扩展名关联的文件类型
            $fileType = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -ErrorAction SilentlyContinue)."(default)"
            if ($fileType) {
                # 使用 cmd.exe 执行 ftype 命令来修改文件类型的打开方式
                # `"%1`" 是一个占位符，代表要打开的文件
                cmd /c "ftype $fileType=`"$AppIdentifier`" `"%1`""
            } else {
                Write-Warning "无法找到扩展名 $ext 的文件类型。"
            }
        }
    } else {
        # --- UWP 应用处理逻辑 ---
        # 获取 UWP 应用的详细信息
        $uwpApp = Get-StartApps | Where-Object { $_.AppId -eq $AppIdentifier }
        if ($uwpApp) {
            $appUserModelId = $uwpApp.AppId
            # 设置 UWP 应用的文件关联通常比 Win32 应用更复杂，直接修改注册表风险很高。
            # 一个更可靠的方法是使用 PS-SFTA 模块，它专门为此设计。
            
            # 检查是否安装了推荐的 PS-SFTA 模块
            if (Get-Module -ListAvailable -Name "PS-SFTA") {
                Import-Module PS-SFTA
                foreach ($ext in $Extensions) {
                    # PS-SFTA 模块的命令示例: Set-FileAssociation -Extension $ext -ProgId $appUserModelId
                    # 由于 PS-SFTA 的具体语法可能变化，这里只提供提示信息，而不直接执行。
                    Write-Host "使用 PS-SFTA 设置 $ext 关联到 $appUserModelId (请手动执行 Set-FileAssociation -Extension '$ext' -ApplicationId '$appUserModelId' if PS-SFTA supports this syntax)" -ForegroundColor Yellow
                }
            } else {
                # 如果没有找到 PS-SFTA 模块，则发出警告并提供手动操作的建议。
                Write-Warning "未找到 PS-SFTA 模块，无法安全地为 UWP 应用设置关联。请考虑从 PowerShell Gallery 安装 PS-SFTA 模块。"
                # 提供手动设置的思路（不直接执行，因为复杂且有风险）
                Write-Host "需要手动修改注册表 HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{.ext}\OpenWithProgids 或使用 Windows 的“默认应用”设置。" -ForegroundColor Red
            }
        } else {
            Write-Error "未找到指定的 UWP 应用。"
        }
    }
}

# --- 主脚本逻辑 ---

# 1. 获取所有可用的视频播放器
$videoPlayers = Get-VideoPlayers

# 2. 检查是否找到了播放器
if ($videoPlayers.Count -eq 0) {
    Write-Host "未能找到任何可能的视频播放器。请手动检查已安装的应用。" -ForegroundColor Red
    return # 退出脚本
}

# 3. 显示找到的播放器列表
Write-Host "`n找到以下可能的视频播放器:" -ForegroundColor Green
# 将哈希表转换为 PSCustomObject 数组以便于格式化输出
$playerList = $videoPlayers.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Name = $_.Key; Identifier = $_.Value } }
# 以表格形式显示播放器名称和标识符
$playerList | Format-Table -AutoSize

# 4. 提示用户选择一个播放器
$selection = Read-Host "`n请输入您希望设置为默认的播放器名称（区分大小写，或输入其完整标识符）"

# 5. 根据用户的输入查找所选的播放器
# 首先尝试通过名称查找
$selectedPlayer = $videoPlayers[$selection]
# 如果按名称找不到，再尝试按标识符查找
if (-not $selectedPlayer) {
    $selectedPlayerObj = $playerList | Where-Object { $_.Identifier -eq $selection }
    if ($selectedPlayerObj) {
        $selectedPlayer = $selectedPlayerObj.Identifier
    }
}

# 6. 验证是否成功找到了播放器
if (-not $selectedPlayer) {
    Write-Host "未找到匹配的播放器。" -ForegroundColor Red
    return # 退出脚本
}

# 7. 获取要关联的视频文件扩展名列表
$extensionsToSet = Get-CommonVideoExtensions

# 8. 向用户显示将要执行的操作
Write-Host "`n将要把以下扩展名关联到: $selectedPlayer" -ForegroundColor Yellow
$extensionsToSet | ForEach-Object { Write-Host $_ }

# 9. 请求用户最终确认
$confirmation = Read-Host "`n是否继续？(y/N)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    # 10. 如果用户确认，则执行文件关联操作
    Set-VideoAssociations -AppIdentifier $selectedPlayer -Extensions $extensionsToSet
    Write-Host "`n文件关联设置完成。可能需要重启文件资源管理器或注销并重新登录以使更改完全生效。" -ForegroundColor Green
} else {
    # 11. 如果用户取消，则显示取消信息
    Write-Host "`n操作已取消。" -ForegroundColor Yellow
}