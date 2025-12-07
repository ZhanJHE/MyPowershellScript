

# 脚本：Restart-Explorer.ps1
# 功能：重启 Windows 文件资源管理器

chcp 65001 | Out-Null

Write-Host "正在尝试重启 Windows 文件资源管理器..." -ForegroundColor Yellow

# 查找并强制停止 explorer.exe 进程
$explorerProcess = Get-Process -Name explorer -ErrorAction SilentlyContinue

if ($explorerProcess) {
    try {
        Stop-Process -Name explorer -Force -ErrorAction Stop
        Write-Host "文件资源管理器已成功停止。" -ForegroundColor Green
        Write-Host "Windows 将在几秒钟内自动重启它。" -ForegroundColor Green
    } catch {
        Write-Warning "停止文件资源管理器时出错: $_"
    }
} else {
    Write-Host "文件资源管理器当前未运行。" -ForegroundColor Cyan
    Write-Host "正在尝试启动它..."
    try {
        Start-Process explorer.exe
        Write-Host "文件资源管理器已启动。" -ForegroundColor Green
    } catch {
        Write-Warning "启动文件资源管理器时出错: $_"
    }
}

Write-Host ""
Write-Host "脚本执行完毕。"
Read-Host "按任意键退出..."